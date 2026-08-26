//  CaptureParserTests.swift
//
//  The corpus is the specification. Every case here is a sentence someone
//  would actually type — if the parser can't hold these, the capture field is
//  a form with extra steps.

import Testing
import Foundation
@testable import SillCore

@Suite("Capture parser")
struct CaptureParserTests {

    private var parser: CaptureParser {
        CaptureParser(now: Clock.now, calendar: Clock.calendar)
    }

    // MARK: - Splitting

    @Test("A comma-separated brain dump becomes several tasks")
    func splitsDump() {
        let tasks = parser.parse("pick up parcel, gym, book flights, reply to Sam")
        #expect(tasks.count == 4)
        #expect(tasks.map(\.title) == ["Pick up parcel", "Gym", "Book flights", "Reply to Sam"])
        #expect(tasks.map(\.type) == [.errand, .errand, .admin, .social])
    }

    @Test("The word 'and' never splits — 'salt and pepper' is one thing")
    func doesNotSplitOnAnd() {
        let tasks = parser.parse("buy salt and pepper")
        #expect(tasks.count == 1)
        #expect(tasks[0].title == "Buy salt and pepper")
    }

    @Test("A leading date before a colon applies to everything after it")
    func sharedPrefix() {
        let tasks = parser.parse("tomorrow: gym, laundry")
        #expect(tasks.count == 2)
        #expect(tasks.allSatisfy { $0.day == Clock.day(2026, 8, 27) })
    }

    @Test("A fragment carrying only a date joins the task before it")
    func dateFragmentMergesBack() {
        let tasks = parser.parse("call Ana monday, june 3")
        #expect(tasks.count == 1)
        #expect(tasks[0].title == "Call Ana")
        #expect(tasks[0].day == Clock.day(2026, 8, 31))
    }

    @Test("Input is never swallowed, even when nothing parses cleanly")
    func neverReturnsNothing() {
        let tasks = parser.parse("Monday, June 3")
        #expect(tasks.count == 1)
        #expect(!tasks[0].title.isEmpty)
    }

    // MARK: - Dates

    @Test("Relative days")
    func relativeDays() {
        #expect(parser.parse("gym tomorrow")[0].day == Clock.day(2026, 8, 27))
        #expect(parser.parse("gym today")[0].day == Clock.day(2026, 8, 26))
        #expect(parser.parse("book flights next week")[0].day == Clock.day(2026, 9, 2))
        #expect(parser.parse("submit the tax form in 3 days")[0].day == Clock.day(2026, 8, 29))
        #expect(parser.parse("shopping saturday")[0].day == Clock.day(2026, 8, 29))
    }

    @Test("Named dates")
    func namedDates() {
        #expect(parser.parse("review the deck by 3rd sep")[0].day == Clock.day(2026, 9, 3))
        #expect(parser.parse("dentist june 3")[0].day == Clock.day(2027, 6, 3))
    }

    @Test("A trailing band word is absorbed into the day")
    func bands() {
        let task = parser.parse("call dentist about the crown thing tomorrow morning")[0]
        #expect(task.title == "Call dentist about the crown thing")
        #expect(task.day == Clock.day(2026, 8, 27))
        #expect(task.band == .morning)
        #expect(task.type == .social)
    }

    @Test("'tonight' is today, in the evening")
    func tonight() {
        let task = parser.parse("stretching tonight")[0]
        #expect(task.day == Clock.day(2026, 8, 26))
        #expect(task.band == .evening)
        #expect(task.type == .idle)      // via stemming: stretching → stretch
    }

    // MARK: - Deadlines

    @Test("'before X' backdates to the day before — what people actually mean")
    func beforeBackdates() {
        let task = parser.parse("finish the Q3 deck before the Thursday review")[0]
        #expect(task.title == "Finish the Q3 deck")   // the event noun is swallowed
        #expect(task.day == Clock.day(2026, 8, 26))   // Thursday minus one
        #expect(task.type == .deep)
        #expect(task.due != nil)
    }

    @Test("'by X' is a hard deadline on X itself")
    func byIsHard() {
        let task = parser.parse("draft the proposal by friday 2h")[0]
        #expect(task.day == Clock.day(2026, 8, 28))
        #expect(task.estimateMinutes == 120)
        #expect(task.type == .deep)
        #expect(task.due != nil)
    }

    // MARK: - Times

    @Test("An explicit time that has passed rolls to tomorrow")
    func pastTimeRolls() {
        let task = parser.parse("gym at 7am")[0]
        #expect(task.day == Clock.day(2026, 8, 27))
        #expect(task.band == .morning)
    }

    @Test("A bare hour takes whichever reading comes soonest")
    func bareHourResolvesForward() {
        // 09:30 now, so "at 7" is 7pm tonight rather than 7am this morning.
        let dinner = parser.parse("dinner with Ana at 7")[0]
        #expect(dinner.band == .evening)
        #expect(dinner.day == Clock.day(2026, 8, 26))

        let lunch = parser.parse("lunch with Ida at 12:30")[0]
        #expect(lunch.band == .afternoon)
    }

    @Test("A number that isn't a time stays in the title")
    func numbersAreNotAlwaysTimes() {
        let task = parser.parse("read chapter 3")[0]
        #expect(task.title == "Read chapter 3")
        #expect(task.band == nil)
    }

    @Test("Acronyms keep their capitals")
    func acronymsSurvive() {
        #expect(parser.parse("review PR at 19:00")[0].title == "Review PR")
    }

    // MARK: - Durations

    @Test("Durations in every form people write them")
    func durations() {
        #expect(parser.parse("expenses 15m")[0].estimateMinutes == 15)
        #expect(parser.parse("refactor the sync layer 90 mins")[0].estimateMinutes == 90)
        #expect(parser.parse("write the memo 1.5h")[0].estimateMinutes == 90)
        #expect(parser.parse("half an hour of stretching tonight")[0].estimateMinutes == 30)
        #expect(parser.parse("a call with Ana an hour")[0].estimateMinutes == 60)
    }

    @Test("'quick' sets the estimate but stays in the title")
    func quickIsAHintNotAPhrase() {
        let task = parser.parse("quick call with Priya")[0]
        #expect(task.title == "Quick call with Priya")
        #expect(task.estimateMinutes == 10)
        #expect(task.estimateWasStated)
    }

    @Test("An unstated estimate is flagged as a guess")
    func guessesAreMarked() {
        #expect(parser.parse("buy milk")[0].estimateWasStated == false)
        #expect(parser.parse("buy milk 5m")[0].estimateWasStated == true)
    }

    // MARK: - Recurrence

    @Test("Recurrence defaults to after-completion, not fixed interval")
    func recurrenceAfterCompletion() {
        let task = parser.parse("water the plants every 5 days")[0]
        #expect(task.title == "Water the plants")
        #expect(task.recurrence == Recurrence.every(5))
        #expect(task.recurrence?.kind == .afterCompletion)
    }

    @Test("A named weekday is the one case that is genuinely fixed")
    func recurrenceWeekday() {
        let task = parser.parse("bins out every tuesday")[0]
        #expect(task.title == "Bins out")
        #expect(task.recurrence?.kind == .fixedWeekday)
        #expect(task.recurrence?.weekday == 3)
    }

    @Test("daily and weekly")
    func recurrenceShorthand() {
        #expect(parser.parse("daily standup")[0].recurrence == Recurrence.every(1))
        #expect(parser.parse("weekly review")[0].recurrence == Recurrence.every(7))
    }

    // MARK: - Type

    @Test("Types come from the verb, and the verb counts double")
    func typeFromVerb() {
        #expect(parser.parse("call the bank")[0].type == .social)     // call beats bank
        #expect(parser.parse("chase the invoice")[0].type == .admin)
        #expect(parser.parse("plan the offsite")[0].type == .deep)
        #expect(parser.parse("buy milk")[0].type == .errand)
    }

    @Test("Stemming catches the forms people type")
    func stemming() {
        #expect(parser.parse("meetings tomorrow")[0].type == .social)
        #expect(parser.parse("shopping saturday")[0].type == .errand)
    }

    @Test("With no known word, length decides — and says it was a guess")
    func unknownFallsBackToLength() {
        let short = parser.parse("thingummy 10m")[0]
        #expect(short.type == .admin)
        #expect(short.typeWasRecognised == false)

        let long = parser.parse("thingummy 2h")[0]
        #expect(long.type == .deep)
        #expect(long.typeWasRecognised == false)
    }

    @Test("Empty input produces nothing at all")
    func emptyInput() {
        #expect(parser.parse("").isEmpty)
        #expect(parser.parse("   \n ").isEmpty)
    }
}
