import Foundation
import Observation

/// App state + persistence. Scans and daily exercise completions are stored
/// as JSON in Application Support — everything stays on-device.
@Observable
final class ScanStore {
    private(set) var scans: [FaceScan] = []
    /// dateKey ("2026-08-21") → completed exercise ids that day.
    private(set) var completions: [String: Set<String>] = [:]
    /// Answers from the onboarding quiz; nil until onboarding completes.
    private(set) var profile: UserProfile?

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("JawForge", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("store.json")
    }()

    private struct Snapshot: Codable {
        var scans: [FaceScan]
        var completions: [String: Set<String>]
        var profile: UserProfile?
    }

    init() {
        load()
    }

    var latestScan: FaceScan? { scans.max(by: { $0.date < $1.date }) }

    /// Saved scans in the trailing 7 days — the free tier's scan quota window.
    var scansInLast7Days: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return scans.filter { $0.date > cutoff }.count
    }

    func setProfile(_ newProfile: UserProfile) {
        profile = newProfile
        save()
    }

    func add(_ scan: FaceScan) {
        scans.append(scan)
        save()
    }

    func delete(_ scan: FaceScan) {
        scans.removeAll { $0.id == scan.id }
        save()
    }

    // MARK: - Daily routine tracking

    static func dateKey(_ date: Date = .now) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    func isCompleted(_ exerciseID: String, on date: Date = .now) -> Bool {
        completions[Self.dateKey(date)]?.contains(exerciseID) ?? false
    }

    func toggleCompletion(_ exerciseID: String, on date: Date = .now) {
        let key = Self.dateKey(date)
        var day = completions[key] ?? []
        if day.contains(exerciseID) { day.remove(exerciseID) } else { day.insert(exerciseID) }
        completions[key] = day
        save()
    }

    func markCompleted(_ exerciseID: String, on date: Date = .now) {
        let key = Self.dateKey(date)
        var day = completions[key] ?? []
        day.insert(exerciseID)
        completions[key] = day
        save()
    }

    /// Consecutive days (ending today or yesterday) with at least one
    /// completed exercise.
    var streak: Int {
        var count = 0
        var day = Date.now
        let calendar = Calendar.current
        // A streak survives if today is merely not-yet-done.
        if completions[Self.dateKey(day)]?.isEmpty ?? true {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        while !(completions[Self.dateKey(day)]?.isEmpty ?? true) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        scans = snapshot.scans
        completions = snapshot.completions
        profile = snapshot.profile
    }

    private func save() {
        let snapshot = Snapshot(scans: scans, completions: completions, profile: profile)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
