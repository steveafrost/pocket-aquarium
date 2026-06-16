import Foundation
import Combine

/// Persistence layer for fish, tanks, and app state
class PersistenceService: ObservableObject {
    static let shared = PersistenceService()

    @Published var fish: [Fish] = []
    @Published var tanks: [Tank] = []
    @Published var selectedTankID: UUID?

    private let defaults = UserDefaults.standard
    private let fishKey = "pocketAquarium.fish"
    private let tanksKey = "pocketAquarium.tanks"
    private let selectedTankKey = "pocketAquarium.selectedTank"

    private init() {
        loadAll()
    }

    // MARK: - Fish CRUD

    /// Add a new fish
    func addFish(_ newFish: Fish) {
        // Free users limited to 1 fish
        if !ProUnlockManager.shared.isPro && fish.count >= 1 {
            return
        }
        fish.append(newFish)
        save()
    }

    /// Get a fish by ID
    func fish(with id: UUID) -> Fish? {
        fish.first { $0.id == id }
    }

    /// Update a fish's properties
    func updateFish(_ updatedFish: Fish) {
        guard let index = fish.firstIndex(where: { $0.id == updatedFish.id }) else { return }
        fish[index] = updatedFish
        save()
    }

    /// Remove a fish
    func removeFish(id: UUID) {
        fish.removeAll { $0.id == id }
        save()
    }

    // MARK: - Tank CRUD

    func addTank(_ tank: Tank) {
        tanks.append(tank)
        if selectedTankID == nil {
            selectedTankID = tank.id
        }
        save()
    }

    func updateTank(_ updatedTank: Tank) {
        guard let index = tanks.firstIndex(where: { $0.id == updatedTank.id }) else { return }
        tanks[index] = updatedTank
        save()
    }

    func selectTank(id: UUID) {
        selectedTankID = id
        defaults.set(id.uuidString, forKey: selectedTankKey)
    }

    var selectedTank: Tank? {
        guard let id = selectedTankID else { return nil }
        return tanks.first { $0.id == id }
    }

    // MARK: - Persistence

    private func save() {
        encodeAndSave(fish, forKey: fishKey)
        encodeAndSave(tanks, forKey: tanksKey)
        if let id = selectedTankID {
            defaults.set(id.uuidString, forKey: selectedTankKey)
        }
        defaults.synchronize()
    }

    private func loadAll() {
        fish = loadDecoded(forKey: fishKey) ?? []
        tanks = loadDecoded(forKey: tanksKey) ?? [Tank.defaultTank]

        if let idString = defaults.string(forKey: selectedTankKey),
           let id = UUID(uuidString: idString) {
            selectedTankID = id
        } else {
            selectedTankID = tanks.first?.id
        }
    }

    private func encodeAndSave<T: Encodable>(_ value: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            defaults.set(encoded, forKey: key)
        }
    }

    private func loadDecoded<T: Decodable>(forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
