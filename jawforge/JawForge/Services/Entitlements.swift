import Foundation
import Observation
import StoreKit

/// Pro subscription state, StoreKit 2 purchases, and the free-tier limits.
///
/// App Store Connect setup required before release:
/// 1. Create a subscription group "JawForge Pro" with two auto-renewable
///    subscriptions matching `ProPlan.weekly` / `.annual` product IDs
///    (give annual a 7-day free-trial introductory offer).
/// 2. Create a non-consumable matching `ProPlan.lifetime`'s product ID.
/// 3. Sign the Paid Applications agreement (Agreements, Tax, and Banking).
///
/// For local testing without App Store Connect, attach
/// `Products.storekit` to the scheme: Product → Scheme → Edit Scheme →
/// Run → Options → StoreKit Configuration.
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
        /// Shown until live products load (and in previews).
        var fallbackPrice: String {
            switch self {
            case .weekly: return "$3.99"
            case .annual: return "$29.99"
            case .lifetime: return "$79.99"
            }
        }
        var per: String {
            switch self {
            case .weekly: return "per week"
            case .annual: return "per year · 7-day free trial"
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

    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    // TODO: host a privacy policy (GitHub Pages works) and point this at it
    // before submission — App Review requires a reachable URL.
    static let privacyURL = URL(string: "https://github.com/Meet2147/BuildMyItch/blob/main/jawforge/PRIVACY.md")!

    private(set) var isPro: Bool
    private(set) var products: [Product] = []
    private(set) var isPurchasing = false
    var purchaseError: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        // Cached so the UI is right instantly offline; the App Store is the
        // source of truth and refreshEntitlements() reconciles at launch.
        isPro = UserDefaults.standard.bool(forKey: "jawforge.isPro")
        updatesTask = Task { [weak self] in await self?.listenForTransactions() }
        Task { [weak self] in
            await self?.loadProducts()
            await self?.refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Products

    func product(for plan: ProPlan) -> Product? {
        products.first { $0.id == plan.productID }
    }

    /// Live localized price when the store has loaded, fallback otherwise.
    func displayPrice(for plan: ProPlan) -> String {
        product(for: plan)?.displayPrice ?? plan.fallbackPrice
    }

    @MainActor
    func loadProducts() async {
        do {
            products = try await Product.products(for: ProPlan.allCases.map(\.productID))
        } catch {
            // Non-fatal: paywall shows fallback prices; purchase surfaces
            // a proper error if tapped while the store is unreachable.
            print("StoreKit product load failed: \(error)")
        }
    }

    // MARK: - Purchase / restore

    @MainActor
    func purchase(_ plan: ProPlan) async {
        if products.isEmpty { await loadProducts() }
        guard let product = product(for: plan) else {
            purchaseError = "The App Store isn't reachable right now. Check your connection and try again."
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    setPro(true)
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    @MainActor
    func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
        } catch {
            purchaseError = error.localizedDescription
            return
        }
        await refreshEntitlements()
        if !isPro {
            purchaseError = "No previous purchases found for this Apple Account."
        }
    }

    /// Walks the user's current entitlements — the App Store's answer to
    /// "does this account own Pro right now?"
    func refreshEntitlements() async {
        var pro = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.revocationDate == nil,
               ProPlan.allCases.contains(where: { $0.productID == transaction.productID }) {
                pro = true
            }
        }
        await MainActor.run { setPro(pro) }
    }

    /// Handles renewals, refunds, Ask to Buy approvals, and purchases made
    /// on other devices, for the app's whole lifetime.
    private func listenForTransactions() async {
        for await update in Transaction.updates {
            if case .verified(let transaction) = update {
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }

    @MainActor
    private func setPro(_ value: Bool) {
        isPro = value
        UserDefaults.standard.set(value, forKey: "jawforge.isPro")
    }
}
