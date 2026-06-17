import SwiftUI

@main
struct PocketAquariumApp: App {
    @StateObject private var persistence = PersistenceService.shared
    @StateObject private var storeKit = StoreKitManager.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var behaviorEngine = FishBehaviorEngine.shared
    @StateObject private var breedingEngine = BreedingEngine.shared
    @StateObject private var phoneMonitor = PhoneStateMonitor.shared
    @StateObject private var animationEngine = AnimationEngine.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(persistence)
                .environmentObject(storeKit)
                .environmentObject(notificationService)
                .environmentObject(behaviorEngine)
                .environmentObject(breedingEngine)
                .environmentObject(phoneMonitor)
                .environmentObject(animationEngine)
                .onAppear {
                    setupApp()
                }
        }
    }

    private func setupApp() {
        // Start monitoring phone state
        phoneMonitor.startMonitoring()

        // Request notification permission
        notificationService.requestAuthorization()

        // Restore purchases
        Task {
            await storeKit.refreshPurchasedProducts()
        }

        // Resume behavior engine for existing fish
        behaviorEngine.resumeAllFish()
    }
}
