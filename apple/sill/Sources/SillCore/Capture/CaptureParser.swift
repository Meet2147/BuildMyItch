//  CaptureParser.swift
//
//  One line of typing in, real tasks out.
//
//  Deliberately hand-written and deterministic rather than model-driven: it
//  runs on every keystroke behind a 300ms debounce, it has to be identical on
//  four devices, and it has to be testable. The on-device model earns its keep
//  later, on the sentences this can't do — this is the floor, not the ceiling.
//
//  Two rules shape the whole design:
//
//  1. Nothing is silently assigned. Every field it extracts is rendered as an
//     editable chip under the field, so a wrong guess costs one tap.
//  2. It never splits when it isn't sure. Under-splitting leaves you with one
//     task to fix; over-splitting scatters garbage through your list.

import Foundation

public struct CaptureParser: Sendable {

    /// Injected so tests are deterministic and so "at 7" can mean tomorrow
    /// when it's already 9pm.
    public var now: Date
    public var calendar: Calendar

    public init(now: Date = Date(), calendar: Calendar = .current) {
        self.now = now
        self.calendar = calendar
    }

    // MARK: - Entry point

    public func parse(_ input: String) -> [ParsedTask] {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let (context, body) = splitSharedPrefix(trimmed)
        var results: [ParsedTask] = []

        for segment in segments(of: body) {
            guard var partial = parseSegment(segment) else { continue }

            // "Monday, June 3" and friends: a fragment that carries only a
            // date belongs to the task before it, not to a task of its own.
            if partial.title.isEmpty {
                if partial.carriesModifier, !results.isEmpty {
                    apply(partial, to: &results[results.count - 1])
                }
                continue
            }

            if let context {
                if partial.day == nil { partial.day = context.day }
                if partial.band == nil { partial.band = context.band }
            }
            results.append(finalise(partial))
        }

        if results.isEmpty {
            // Whatever we made of it, the user typed something. Handing back
            // nothing is the one outcome a capture field can never have.
            return [finalise(Partial(title: trimmed))]
        }
        return results
    }

    // MARK: - Splitting

    /// `tomorrow: gym, laundry` — a leading fragment that is *only* a date,
    /// followed by a colon, sets the context for everything after it.
    private func splitSharedPrefix(_ input: String) -> (Partial?, String) {
        guard let range = input.range(of: ": ") else { return (nil, input) }
        let head = String(input[input.startIndex..<range.lowerBound])
        guard head.count <= 24, let partial = parseSegment(head),
              partial.title.isEmpty, partial.carriesModifier else {
            return (nil, input)
        }
        return (partial, String(input[range.upperBound...]))
    }

    /// Split on commas, semicolons, newlines and ampersands — but never on the
    /// word "and". "salt and pepper" and "black and white" are one thing each,
    /// and there is no cheap way to tell those from "gym and laundry".
    private func segments(of input: String) -> [String] {
        var parts: [String] = [input]
        for separator in ["\n", ",", ";", " & ", " + "] {
            parts = parts.flatMap { $0.components(separatedBy: separator) }
        }
        return parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Segment parsing

    struct Partial {
        var title = ""
        var day: Date?
        var band: Band?
        var due: Date?
        var recurrence: Recurrence?
        var minutes: Int?
        var minutesWereStated = false

        var carriesModifier: Bool {
            day != nil || band != nil || due != nil || recurrence != nil || minutes != nil
        }
    }

    private func apply(_ partial: Partial, to task: inout ParsedTask) {
        if task.day == nil { task.day = partial.day }
        if task.band == nil { task.band = partial.band }
        if task.due == nil { task.due = partial.due }
        if task.recurrence == nil { task.recurrence = partial.recurrence }
        if let minutes = partial.minutes, !task.estimateWasStated {
            task.estimateMinutes = minutes
            task.estimateWasStated = true
        }
    }

    private func parseSegment(_ text: String) -> Partial? {
        let tokens = tokenize(text)
        guard !tokens.isEmpty else { return nil }

        var partial = Partial()
        var consumed = [Bool](repeating: false, count: tokens.count)
        var i = 0

        while i < tokens.count {
            if let match = matchRecurrence(tokens, at: i) {
                partial.recurrence = match.recurrence
                consume(&consumed, from: i, length: match.length)
                i += match.length
            } else if let match = matchDeadline(tokens, at: i) {
                partial.day = match.day
                partial.due = match.due
                if let band = match.band { partial.band = band }
                consume(&consumed, from: i, length: match.length)
                i += match.length
            } else if let match = matchDay(tokens, at: i) {
                partial.day = match.day
                if let band = match.band { partial.band = band }
                consume(&consumed, from: i, length: match.length)
                i += match.length
            } else if let match = matchDuration(tokens, at: i) {
                partial.minutes = match.minutes
                partial.minutesWereStated = true
                consume(&consumed, from: i, length: match.length)
                i += match.length
            } else if let match = matchClock(tokens, at: i) {
                partial.band = match.band
                if partial.day == nil { partial.day = match.day }
                consume(&consumed, from: i, length: match.length)
                i += match.length
            } else {
                i += 1
            }
        }

        let remaining = tokens.indices.filter { !consumed[$0] }.map { tokens[$0] }
        partial.title = buildTitle(from: remaining)

        // "quick call with Sam" — a hint, not a phrase to lift out. The word
        // stays in the title because it's part of what the user wrote.
        if partial.minutes == nil, remaining.contains(where: { $0.lower == "quick" }) {
            partial.minutes = 10
            partial.minutesWereStated = true
        }
        return partial
    }

    // MARK: - Matchers

    private struct DayMatch { var length: Int; var day: Date?; var band: Band? }
    private struct DeadlineMatch { var length: Int; var day: Date?; var due: Date?; var band: Band? }
    private struct RecurrenceMatch { var length: Int; var recurrence: Recurrence }
    private struct DurationMatch { var length: Int; var minutes: Int }
    private struct ClockMatch { var length: Int; var day: Date?; var band: Band }

    /// `every 5 days` · `every monday` · `daily` · `weekly` · `every other day`
    private func matchRecurrence(_ t: [Token], at i: Int) -> RecurrenceMatch? {
        let word = t[i].lower
        if word == "daily" { return .init(length: 1, recurrence: .every(1)) }
        if word == "weekly" { return .init(length: 1, recurrence: .every(7)) }
        guard word == "every" else { return nil }

        guard i + 1 < t.count else { return nil }
        let next = t[i + 1].lower

        if next == "day" { return .init(length: 2, recurrence: .every(1)) }
        if next == "week" { return .init(length: 2, recurrence: .every(7)) }
        if next == "month" { return .init(length: 2, recurrence: .every(30)) }
        if let weekday = Lexicon.weekdays[next] {
            return .init(length: 2, recurrence: .everyWeekday(weekday))
        }
        if next == "other", i + 2 < t.count {
            let unit = t[i + 2].lower
            if unit == "day" { return .init(length: 3, recurrence: .every(2)) }
            if unit == "week" { return .init(length: 3, recurrence: .every(14)) }
        }
        if let number = number(in: next), i + 2 < t.count {
            let unit = t[i + 2].lower
            if unit.hasPrefix("day") { return .init(length: 3, recurrence: .every(Int(number))) }
            if unit.hasPrefix("week") { return .init(length: 3, recurrence: .every(Int(number) * 7)) }
        }
        return nil
    }

    /// `by Thursday` sets a hard deadline on that day.
    /// `before the Thursday review` backdates it to the day before — which is
    /// what people actually mean, and what no other app does.
    private func matchDeadline(_ t: [Token], at i: Int) -> DeadlineMatch? {
        let word = t[i].lower
        guard word == "by" || word == "before" else { return nil }

        var cursor = i + 1
        if cursor < t.count, t[cursor].lower == "the" { cursor += 1 }
        guard cursor < t.count, let day = matchDay(t, at: cursor), let date = day.day else { return nil }

        var length = (cursor - i) + day.length
        let tail = cursor + day.length
        if tail < t.count, Lexicon.eventNouns.contains(t[tail].lower) { length += 1 }

        if word == "by" {
            return .init(length: length, day: date, due: endOfDay(date), band: day.band)
        } else {
            let dayBefore = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            return .init(length: length, day: dayBefore, due: endOfDay(dayBefore), band: nil)
        }
    }

    private func matchDay(_ t: [Token], at i: Int) -> DayMatch? {
        let word = t[i].lower
        let today = calendar.startOfDay(for: now)

        if word == "tonight" {
            return .init(length: 1, day: today, band: .evening)
        }
        if Lexicon.todayWords.contains(word) {
            return absorbBand(t, after: i, length: 1, day: today, band: nil)
        }
        if Lexicon.tomorrowWords.contains(word) {
            let day = calendar.date(byAdding: .day, value: 1, to: today)
            return absorbBand(t, after: i, length: 1, day: day, band: nil)
        }
        if let weekday = Lexicon.weekdays[word] {
            return absorbBand(t, after: i, length: 1, day: date(forWeekday: weekday, nextWeek: false), band: nil)
        }

        // Prefixed forms: this / next / on
        if word == "this" || word == "next" || word == "on", i + 1 < t.count {
            let following = t[i + 1].lower
            if let band = Lexicon.bandWords[following], word == "this" {
                return .init(length: 2, day: today, band: band)
            }
            if let weekday = Lexicon.weekdays[following] {
                let day = date(forWeekday: weekday, nextWeek: word == "next")
                return absorbBand(t, after: i + 1, length: 2, day: day, band: nil)
            }
            if following == "week", word == "next" {
                return .init(length: 2, day: calendar.date(byAdding: .day, value: 7, to: today), band: nil)
            }
            if following == "weekend" {
                return .init(length: 2, day: date(forWeekday: 7, nextWeek: word == "next"), band: nil)
            }
            if Lexicon.tomorrowWords.contains(following) {
                let day = calendar.date(byAdding: .day, value: 1, to: today)
                return absorbBand(t, after: i + 1, length: 2, day: day, band: nil)
            }
        }

        // `june 3` · `3rd june`
        if let month = Lexicon.months[word], i + 1 < t.count,
           let dayOfMonth = ordinal(t[i + 1].lower), let date = date(month: month, day: dayOfMonth) {
            return .init(length: 2, day: date, band: nil)
        }
        if let dayOfMonth = ordinal(word), i + 1 < t.count,
           let month = Lexicon.months[t[i + 1].lower], let date = date(month: month, day: dayOfMonth) {
            return .init(length: 2, day: date, band: nil)
        }

        // `in 3 days` · `in a week`
        if word == "in", i + 2 < t.count {
            let unit = t[i + 2].lower
            let count: Int?
            if t[i + 1].lower == "a" { count = 1 } else { count = number(in: t[i + 1].lower).map(Int.init) }
            if let count {
                if unit.hasPrefix("day") {
                    return .init(length: 3, day: calendar.date(byAdding: .day, value: count, to: today), band: nil)
                }
                if unit.hasPrefix("week") {
                    return .init(length: 3, day: calendar.date(byAdding: .day, value: count * 7, to: today), band: nil)
                }
            }
        }
        return nil
    }

    /// `tomorrow morning` — pull a trailing band word into the day match.
    private func absorbBand(_ t: [Token], after index: Int, length: Int, day: Date?, band: Band?) -> DayMatch {
        if index + 1 < t.count, let found = Lexicon.bandWords[t[index + 1].lower] {
            return .init(length: length + 1, day: day, band: found)
        }
        return .init(length: length, day: day, band: band)
    }

    /// `30 min` · `30m` · `2h` · `1.5h` · `half an hour` · `an hour`
    private func matchDuration(_ t: [Token], at i: Int) -> DurationMatch? {
        let word = t[i].lower

        if word == "half", i + 2 < t.count, t[i + 1].lower == "an", t[i + 2].lower.hasPrefix("hour") {
            return .init(length: 3, minutes: 30)
        }
        if word == "half", i + 1 < t.count, t[i + 1].lower.hasPrefix("hour") {
            return .init(length: 2, minutes: 30)
        }
        if word == "an" || word == "a", i + 1 < t.count, t[i + 1].lower.hasPrefix("hour") {
            return .init(length: 2, minutes: 60)
        }

        guard let split = splitNumeric(word) else { return nil }
        if !split.suffix.isEmpty {
            if let minutes = minutes(value: split.value, unit: split.suffix) {
                return .init(length: 1, minutes: minutes)
            }
            return nil
        }
        // Bare number followed by a unit word: `30 min`, `2 hours`.
        if i + 1 < t.count, let minutes = minutes(value: split.value, unit: t[i + 1].lower) {
            return .init(length: 2, minutes: minutes)
        }
        return nil
    }

    private func minutes(value: Double, unit: String) -> Int? {
        switch unit {
        case "m", "min", "mins", "minute", "minutes":
            return max(1, Int(value.rounded()))
        case "h", "hr", "hrs", "hour", "hours":
            return max(1, Int((value * 60).rounded()))
        default:
            return nil
        }
    }

    /// `at 7` · `7am` · `19:00` · `at 7:30pm`
    private func matchClock(_ t: [Token], at i: Int) -> ClockMatch? {
        if t[i].lower == "at", i + 1 < t.count, let clock = parseClock(t[i + 1].lower, allowBareHour: true) {
            return clockMatch(clock, length: 2)
        }
        if let clock = parseClock(t[i].lower, allowBareHour: false) {
            return clockMatch(clock, length: 1)
        }
        return nil
    }

    private func clockMatch(_ clock: Clock, length: Int) -> ClockMatch {
        let today = calendar.startOfDay(for: now)
        var hour = clock.hour

        // "dinner at 7" is 7pm; "standup at 8" is 8am. There is no rule that
        // gets both from the number alone, so take whichever reading comes
        // soonest — a capture that lands in the past is always wrong.
        if clock.isAmbiguous, hour <= 12 {
            let alternative = hour < 12 ? hour + 12 : hour - 12
            let options = [hour, alternative].compactMap { candidate -> (Int, Date)? in
                guard let date = calendar.date(bySettingHour: candidate, minute: clock.minute, second: 0, of: today)
                else { return nil }
                return (candidate, date)
            }
            if let soonest = options.min(by: { lhs, rhs in
                let lhsPast = lhs.1 < now, rhsPast = rhs.1 < now
                return lhsPast == rhsPast ? lhs.1 < rhs.1 : !lhsPast
            }) {
                hour = soonest.0
            }
        }

        var day = today
        // Typed at 9pm, "gym at 7am" means tomorrow. Assuming today would put a
        // task in the past on the first screen the user sees.
        if let atTime = calendar.date(bySettingHour: hour, minute: clock.minute, second: 0, of: today),
           atTime < now {
            day = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        }
        return .init(length: length, day: day, band: Band.containing(hour: hour))
    }

    /// A bare hour is only a time when something told us to expect one, because
    /// "chapter 3" and "Q3 deck" are far more common than "3".
    private struct Clock {
        var hour: Int
        var minute: Int
        /// No am/pm and no colon — the number could mean either half of the day.
        var isAmbiguous: Bool
    }

    private func parseClock(_ s: String, allowBareHour: Bool) -> Clock? {
        var text = s
        var meridiem: String?
        for suffix in ["am", "pm", "a.m.", "p.m."] where text.hasSuffix(suffix) {
            meridiem = suffix.hasPrefix("a") ? "am" : "pm"
            text = String(text.dropLast(suffix.count))
            break
        }
        text = text.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        guard !text.isEmpty else { return nil }

        var hour = 0
        var minute = 0
        if let colon = text.firstIndex(of: ":") {
            guard let h = Int(text[text.startIndex..<colon]),
                  let m = Int(text[text.index(after: colon)...]) else { return nil }
            hour = h
            minute = m
        } else {
            guard let h = Int(text) else { return nil }
            guard meridiem != nil || allowBareHour else { return nil }
            hour = h
        }
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }

        let ambiguous = meridiem == nil && !text.contains(":")
        switch meridiem {
        case "pm" where hour < 12: hour += 12
        case "am" where hour == 12: hour = 0
        default: break
        }
        return Clock(hour: hour, minute: minute, isAmbiguous: ambiguous)
    }

    // MARK: - Title

    private func buildTitle(from tokens: [Token]) -> String {
        var words = tokens.map(\.raw)

        while let first = words.first, isNoise(first) { words.removeFirst() }
        while let last = words.last, isNoise(last) { words.removeLast() }
        guard !words.isEmpty else { return "" }

        var title = words.joined(separator: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: " -–—:"))
        guard let first = title.first else { return "" }

        // Sentence case, but never touch something that's already capitalised
        // or an acronym — "Q3 deck" must not become "q3 deck".
        if first.isLowercase {
            title.replaceSubrange(title.startIndex...title.startIndex, with: String(first).uppercased())
        }
        return title
    }

    private func isNoise(_ word: String) -> Bool {
        Lexicon.noiseOnly.contains(normalise(word))
    }

    // MARK: - Finalising

    private func finalise(_ partial: Partial) -> ParsedTask {
        let classified = TypeClassifier.classify(
            title: partial.title,
            statedMinutes: partial.minutesWereStated ? partial.minutes : nil
        )
        let minutes = partial.minutes ?? classified.type.defaultEstimate

        return ParsedTask(
            title: partial.title,
            type: classified.type,
            estimateMinutes: minutes,
            day: partial.day,
            band: partial.band,
            due: partial.due,
            recurrence: partial.recurrence,
            estimateWasStated: partial.minutesWereStated,
            typeWasRecognised: classified.recognised
        )
    }

    // MARK: - Dates

    /// `next X` means the next X. If that's today, it means the one after.
    /// English genuinely doesn't agree on this, so the rule is the simple one
    /// and the resolved date is always shown as a chip the user can correct.
    private func date(forWeekday target: Int, nextWeek: Bool) -> Date {
        let today = calendar.startOfDay(for: now)
        let current = calendar.component(.weekday, from: today)
        var delta = target - current
        if delta < 0 { delta += 7 }
        if delta == 0 && nextWeek { delta = 7 }
        return calendar.date(byAdding: .day, value: delta, to: today) ?? today
    }

    /// The next occurrence of a calendar date — this year if it hasn't passed,
    /// next year if it has. Nobody types a date meaning one in the past.
    private func date(month: Int, day: Int) -> Date? {
        let today = calendar.startOfDay(for: now)
        var components = DateComponents()
        components.year = calendar.component(.year, from: today)
        components.month = month
        components.day = day
        guard let candidate = calendar.date(from: components) else { return nil }
        if candidate >= today { return candidate }
        components.year = (components.year ?? 0) + 1
        return calendar.date(from: components)
    }

    /// `3`, `3rd`, `21st` — a day of the month, or nil.
    private func ordinal(_ word: String) -> Int? {
        for suffix in ["st", "nd", "rd", "th"] where word.hasSuffix(suffix) {
            let stem = String(word.dropLast(2))
            if let value = Int(stem), (1...31).contains(value) { return value }
            return nil
        }
        guard let value = Int(word), (1...31).contains(value) else { return nil }
        return value
    }

    private func endOfDay(_ day: Date) -> Date {
        calendar.date(bySettingHour: 23, minute: 59, second: 59, of: day) ?? day
    }

    // MARK: - Tokens

    struct Token {
        let raw: String
        let lower: String
    }

    private func tokenize(_ text: String) -> [Token] {
        text.split(whereSeparator: { $0 == " " || $0 == "\t" })
            .map { Token(raw: String($0), lower: normalise(String($0))) }
            .filter { !$0.raw.isEmpty }
    }

    private func normalise(_ word: String) -> String {
        word.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".,;:!?\"'()[]“”’"))
    }

    private func consume(_ flags: inout [Bool], from index: Int, length: Int) {
        for offset in index..<min(index + length, flags.count) { flags[offset] = true }
    }

    private func number(in word: String) -> Double? {
        guard let split = splitNumeric(word), split.suffix.isEmpty else { return nil }
        return split.value
    }

    private func splitNumeric(_ word: String) -> (value: Double, suffix: String)? {
        var digits = ""
        var index = word.startIndex
        while index < word.endIndex, word[index].isNumber || word[index] == "." {
            digits.append(word[index])
            index = word.index(after: index)
        }
        guard let value = Double(digits) else { return nil }
        return (value, String(word[index...]))
    }
}
