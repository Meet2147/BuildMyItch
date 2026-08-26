//  Lexicon.swift
//  Every word the parser knows, in one file, so the vocabulary can be
//  reviewed and argued with as a *list* rather than hunted through code.

import Foundation

enum Lexicon {

    // MARK: Days

    /// `Calendar` weekday numbers: 1 = Sunday ... 7 = Saturday.
    static let weekdays: [String: Int] = [
        "sunday": 1, "sun": 1,
        "monday": 2, "mon": 2,
        "tuesday": 3, "tue": 3, "tues": 3,
        "wednesday": 4, "wed": 4, "weds": 4,
        "thursday": 5, "thu": 5, "thur": 5, "thurs": 5,
        "friday": 6, "fri": 6,
        "saturday": 7, "sat": 7,
    ]

    /// Month names, so "june 3" and "3rd Jun" are dates rather than a task
    /// called "June 3". Nobody would ship a capture field that can't read a date.
    static let months: [String: Int] = [
        "january": 1, "jan": 1, "february": 2, "feb": 2, "march": 3, "mar": 3,
        "april": 4, "apr": 4, "may": 5, "june": 6, "jun": 6, "july": 7, "jul": 7,
        "august": 8, "aug": 8, "september": 9, "sep": 9, "sept": 9,
        "october": 10, "oct": 10, "november": 11, "nov": 11, "december": 12, "dec": 12,
    ]

    /// "before the Thursday review" — the review is the thing being scheduled
    /// around, not part of the task's name. Swallowing the noun keeps the title
    /// clean and stops it hijacking the type classifier.
    static let eventNouns: Set<String> = [
        "review", "meeting", "call", "deadline", "standup", "sync", "demo",
        "presentation", "class", "session", "appointment", "interview",
        "catchup", "checkin", "retro", "launch", "deploy",
    ]

    static let todayWords: Set<String> = ["today"]
    static let tomorrowWords: Set<String> = ["tomorrow", "tmrw", "tmr", "tomo"]

    static let bandWords: [String: Band] = [
        "morning": .morning,
        "afternoon": .afternoon,
        "evening": .evening,
        "night": .evening,
        "tonight": .evening,
        "lunchtime": .afternoon,
    ]

    // MARK: Type keywords
    //
    // Ordered by how strongly they imply the type when they lead the sentence.
    // A keyword in first position counts double — the leading word is almost
    // always the verb, and the verb is what tells you the shape of the work.

    static let keywords: [TaskType: Set<String>] = [
        .social: [
            "call", "ring", "phone", "email", "reply", "respond", "text",
            "message", "msg", "ping", "ask", "meet", "meeting", "invite",
            "thank", "congratulate", "dm", "chat", "interview", "standup",
            "follow", "catch", "sync", "debrief", "introduce", "wish",
        ],
        .errand: [
            "buy", "grab", "pick", "collect", "drop", "post", "mail", "return",
            "deliver", "groceries", "shop", "shopping", "pharmacy", "chemist",
            "bank", "gym", "swim", "dentist", "doctor", "haircut", "barber",
            "petrol", "fuel", "laundry", "dryclean", "parcel", "package",
            "library", "market", "recycling", "bins", "vet",
        ],
        .admin: [
            "pay", "book", "renew", "file", "submit", "form", "tax", "taxes",
            "insurance", "cancel", "register", "order", "schedule", "expenses",
            "expense", "invoice", "invoices", "receipt", "receipts", "bill",
            "bills", "subscription", "password", "backup", "print", "sign",
            "scan", "upload", "transfer", "claim", "chase", "reconcile",
            "rebook", "confirm", "unsubscribe", "archive",
        ],
        .deep: [
            "write", "draft", "finish", "design", "build", "prepare", "prep",
            "research", "plan", "outline", "review", "edit", "revise",
            "refactor", "debug", "implement", "study", "analyse", "analyze",
            "deck", "report", "essay", "chapter", "thesis", "proposal",
            "presentation", "spec", "architecture", "strategy", "rewrite",
            "figure", "solve", "estimate", "audit", "storyboard",
        ],
        .idle: [
            "read", "listen", "watch", "browse", "skim", "tidy", "water",
            "stretch", "meditate", "journal", "practice", "practise", "sort",
        ],
    ]

    /// Tie-break order when two types score the same. Earlier wins.
    /// Social and errand beat admin because they're more specific claims:
    /// "requires a person" and "requires a place" are harder facts than
    /// "is boring paperwork".
    static let typePrecedence: [TaskType] = [.social, .errand, .deep, .admin, .idle]

    // MARK: Title tidying

    /// Words that are meaningless dangling at either end of a title once the
    /// date and duration have been lifted out of the sentence.
    static let danglers: Set<String> = [
        "at", "on", "by", "before", "in", "for", "the", "a", "an",
        "this", "next", "of", "to", "and", "then", "please", "pls",
    ]

    static let noiseOnly: Set<String> = danglers.union(["", "-", "–", "—"])
}
