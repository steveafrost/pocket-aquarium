import Foundation
import Combine

/// Manages Pro unlock state via UserDefaults with StoreKit verification
class ProUnlockManager: ObservableObject {
    static let shared = ProUnlockManager()

    @Published var isPro: Bool = false
    @Published var isLoading: Bool = false

    private let defaults = UserDefaults.standard
    private let proKey = "com.pocketaquarium.pro.unlocked"

    private init() {
        loadPersistedState()
    }

    private func loadPersistedState() {
        isPro = defaults.bool(forKey: proKey)
    }

    /// Called after successful StoreKit purchase verification
    func unlockPro() {
        isPro = true
        defaults.set(true, forKey: proKey)
        defaults.synchronize()
    }

    /// Called if purchase verification fails or user restores without valid purchase
    func lockPro() {
        isPro = false
        defaults.set(false, forKey: proKey)
        defaults.synchronize()
    }

    /// Check if a specific Pro feature is accessible
    func canAccess(feature: ProFeature) -> Bool {
        isPro || feature.isFree
    }

    enum ProFeature: String, CaseIterable {
        case multipleFish = "Multiple Fish"
        case allSpecies = "All Species"
        case proTanks = "Pro Tank Backgrounds"
        case decorations = "All Decorations"
        case breeding = "Rare Morph Breeding"
        case sounds = "Ambient Sounds"
        case plantGrowth = "Growing Plants"
        case shareCards = "Share Cards"

        var isFree: Bool {
            false // All these are Pro features
        }

        var description: String {
            switch self {
            case .multipleFish: return "Up to 5 fish in your tank"
            case .allSpecies: return "Betta, Clownfish, Angelfish, Seahorse, Jellyfish"
            case .proTanks: return "Reef, Dark Water, Planted, Castle Ruins, Space"
            case .decorations: return "Over 7 premium decorations"
            case .breeding: return "Breed fish for rare color morphs"
            case .sounds: return "Ambient underwater soundscapes"
            case .plantGrowth: return "Plants that grow over 3 days"
            case .shareCards: return "Share your rare morphs"
            }
        }
    }
}
