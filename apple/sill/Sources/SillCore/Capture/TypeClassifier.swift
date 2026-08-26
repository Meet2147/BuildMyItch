//  TypeClassifier.swift
//  Decides the shape of attention a task needs, from the words left in the
//  title after the dates and durations have been lifted out.
//
//  Keyword scoring rather than anything cleverer, for three reasons: it's
//  explainable (you can point at the word that decided it), it's instant, and
//  when it's wrong the fix is one tap on a chip. A wrong guess here costs
//  almost nothing, so paying a model for it would be paying for the wrong risk.

import Foundation

enum TypeClassifier {

    struct Result {
        var type: TaskType
        /// False when we fell back to a rule rather than recognising a word.
        /// The UI renders an unrecognised type chip in a lighter weight.
        var recognised: Bool
    }

    static func classify(title: String, statedMinutes: Int?) -> Result {
        let words = title
            .lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)

        guard !words.isEmpty else {
            return Result(type: .admin, recognised: false)
        }

        var scores: [TaskType: Int] = [:]
        for (index, word) in words.enumerated() {
            for (type, vocabulary) in Lexicon.keywords where matches(word, in: vocabulary) {
                // The first word is nearly always the verb, and the verb is
                // what tells you the shape of the work.
                scores[type, default: 0] += (index == 0 ? 2 : 1)
            }
        }

        guard !scores.isEmpty else {
            // No word we know. Length is the only signal left, and it's a
            // decent one: long things need a stretch, short things get batched.
            // Crucially this is *not* recognition — the chip says so.
            let long = (statedMinutes ?? 0) >= 45
            return Result(type: long ? .deep : .admin, recognised: false)
        }

        // Something the user said takes an hour is probably not a two-minute
        // errand, whatever its words look like. Only ever a tie-breaker on top
        // of real recognition, never recognition on its own.
        if let minutes = statedMinutes, minutes >= 45 {
            scores[.deep, default: 0] += 1
        }

        let best = scores.values.max() ?? 0

        let winners = scores.filter { $0.value == best }.map(\.key)
        let type = Lexicon.typePrecedence.first(where: winners.contains) ?? .admin
        return Result(type: type, recognised: true)
    }

    /// Just enough stemming to catch the forms people actually type —
    /// "stretching", "meetings", "booked" — without dragging in a stemmer.
    /// The length floor stops "ring" collapsing to "r".
    private static func matches(_ word: String, in vocabulary: Set<String>) -> Bool {
        if vocabulary.contains(word) { return true }
        for suffix in ["ing", "ed", "es", "s"] where word.hasSuffix(suffix) {
            let stem = String(word.dropLast(suffix.count))
            guard stem.count >= 3 else { continue }
            if vocabulary.contains(stem) { return true }
            // "shopping" → "shopp" → "shop"
            if stem.count >= 4, let last = stem.last, stem.dropLast().last == last,
               vocabulary.contains(String(stem.dropLast())) {
                return true
            }
        }
        return false
    }
}
