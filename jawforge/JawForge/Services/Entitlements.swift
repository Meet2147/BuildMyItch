import Foundation
import Observation

/// Pro subscription state and the free-tier limits.
///
/// This ships with a demo purchase flow so the paywall is fully navigable.
/// To go live, create these auto-renewable subscriptions in App Store
/// Connect and replace `purchase(_:)` / `restore()` with StoreKit 2:
///
///     let products = try await Product.products(for: ProPlan.allCases.map(\.productID))
///     let result = try await product.purchase()
///     for await entitlement in Transaction.currentEntitlements { ... }
///
@Observable
final class Entitlements {
    enum ProPlan: String, CaseIterable, Identifiable {
        case weekly, annual, lifetime
        var id: String { rawValue }

        var productID: String { "com.buildmyitch.jawforge.pro.\(rawValue)" }
        var title: String {
            switch self {
            case .weekly: return "Weekly"
            case .annual: return "Annual"
            case .lifetime: return "Lifetime"
            }
        }
        var price: String {
            switch self {
            case .weekly: return "$3.99"
            case .annual: return "$29.99"
            case .lifetime: return "$79.99"
            }
        }
        var per: String {
            switch self {
            case .weekly: return "per week"
            case .annual: return "per year · $0.58/wk"
            case .lifetime: return "one time"
            }
        }
        var badge: String? {
            switch self {
            case .annual: return "BEST VALUE · 7-DAY FREE TRIAL"
            default: return nil
            }
        }
    }

    /// Free tier: this many scans per rolling week, and this much history.
    static let freeScansPerWeek = 1
    static let freeHistoryLimit = 3

    private(set) var isPro: Bool

    init() {
        isPro = UserDefaults.standard.bool(forKey: "jawforge.isPro")
    }

    func purchase(_ plan: ProPlan) {
        // StoreKit 2 purchase goes here; demo flow unlocks immediately.
        setPro(true)
    }

    func restore() {
        // StoreKit 2: walk Transaction.currentEntitlements and re-unlock.
        setPro(true)
    }

    private func setPro(_ value: Bool) {
        isPro = value
        UserDefaults.standard.set(value, forKey: "jawforge.isPro")
    }
}
