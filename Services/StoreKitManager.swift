import Foundation
import StoreKit

/// Manages in-app purchases using StoreKit 2
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published var isPro: Bool = false
    @Published var isRestoring: Bool = false
    @Published var purchaseError: String?

    private let proProductID = "com.pocketaquarium.pro.unlock"
    private var products: [Product] = []

    private init() {
        // Load persisted Pro state
        isPro = ProUnlockManager.shared.isPro
    }

    // MARK: - Product Loading

    /// Load products from App Store Connect
    @MainActor
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: [proProductID])
            products = storeProducts
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    /// Get the Pro product
    func proProduct() -> Product? {
        products.first { $0.id == proProductID }
    }

    // MARK: - Purchase

    /// Purchase Pro unlock
    @MainActor
    func purchasePro() async {
        guard let product = proProduct() else {
            purchaseError = "Product not loaded. Please try again."
            return
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    unlockPro()
                case .unverified:
                    purchaseError = "Purchase could not be verified."
                }
            case .userCancelled:
                purchaseError = nil // Not an error, user cancelled
            case .pending:
                purchaseError = "Purchase is pending approval."
            @unknown default:
                purchaseError = "Unknown purchase result."
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Restore

    /// Restore previous purchases
    @MainActor
    func restorePurchases() async {
        isRestoring = true
        purchaseError = nil

        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
        } catch {
            purchaseError = "Restore failed: \(error.localizedDescription)"
        }

        isRestoring = false
    }

    // MARK: - Verification

    /// Refresh purchased product status
    @MainActor
    func refreshPurchasedProducts() async {
        do {
            var hasPro = false
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else { continue }
                if transaction.productID == proProductID {
                    hasPro = true
                    ProUnlockManager.shared.unlockPro()
                }
            }

            DispatchQueue.main.async {
                self.isPro = hasPro
            }
        } catch {
            print("Failed to refresh purchases: \(error)")
        }
    }

    // MARK: - Helpers

    private func unlockPro() {
        ProUnlockManager.shared.unlockPro()
        DispatchQueue.main.async {
            self.isPro = true
            self.purchaseError = nil
        }
    }
}
