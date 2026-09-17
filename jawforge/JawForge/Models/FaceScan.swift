import Foundation

/// One saved scan. Only the numbers are persisted — the photo itself is
/// discarded after analysis so nothing sensitive sits on disk.
struct FaceScan: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let metrics: JawlineMetrics

    init(id: UUID = UUID(), date: Date = .now, metrics: JawlineMetrics) {
        self.id = id
        self.date = date
        self.metrics = metrics
    }

    var overallScore: Double { metrics.overallScore }
}
