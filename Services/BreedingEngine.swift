import Foundation

/// Handles fish breeding mechanics, genetics, and morph inheritance
class BreedingEngine: ObservableObject {
    static let shared = BreedingEngine()

    @Published var activeBreedings: [BreedingPair] = []
    @Published var eggs: [FishEgg] = []

    private let persistence = PersistenceService.shared

    private init() {
        loadSavedState()
    }

    // MARK: - Public API

    /// Check if two fish are compatible for breeding
    func canBreed(_ fish1: Fish, _ fish2: Fish) -> BreedingCompatibility {
        guard fish1.id != fish2.id else {
            return .failure(reason: "A fish cannot breed with itself")
        }
        guard fish1.canBreed && fish2.canBreed else {
            return .failure(reason: "One or both fish need to mature or wait for cooldown")
        }
        guard fish1.speciesID == fish2.speciesID else {
            return .failure(reason: "Only same-species fish can breed")
        }
        guard fish1.isAdult && fish2.isAdult else {
            return .failure(reason: "Both fish must be fully grown")
        }

        // Check Pro
        guard ProUnlockManager.shared.isPro else {
            return .failure(reason: "Breeding requires Pro upgrade")
        }

        return .compatible
    }

    /// Start breeding two fish
    func startBreeding(_ fish1: Fish, _ fish2: Fish) -> Bool {
        let compatibility = canBreed(fish1, fish2)
        guard case .compatible = compatibility else {
            return false
        }

        let incubationPeriod: TimeInterval = 8 * 3600  // 8 hours
        let hatchDate = Date().addingTimeInterval(incubationPeriod)

        let pair = BreedingPair(
            parent1ID: fish1.id,
            parent2ID: fish2.id,
            speciesID: fish1.speciesID,
            startedAt: Date(),
            hatchDate: hatchDate
        )

        DispatchQueue.main.async {
            self.activeBreedings.append(pair)
        }
        saveState()

        // Put both parents on cooldown (24 hours)
        var parent1 = fish1
        var parent2 = fish2
        parent1.breedingCooldown = Date().addingTimeInterval(24 * 3600)
        parent2.breedingCooldown = Date().addingTimeInterval(24 * 3600)
        persistence.updateFish(parent1)
        persistence.updateFish(parent2)

        // Schedule hatching notification
        NotificationService.shared.scheduleNotification(
            title: "Eggs are hatching! 🥚",
            body: "\(fish1.name) & \(fish2.name)'s eggs are ready!",
            identifier: "hatch-\(pair.id)",
            date: hatchDate
        )

        return true
    }

    /// Check if any eggs have hatched
    func checkHatches() {
        let now = Date()
        var hatchedBreedings: [BreedingPair] = []
        var newFish: [Fish] = []

        for pair in activeBreedings where now >= pair.hatchDate && !pair.hatched {
            let baby = produceOffspring(from: pair)
            newFish.append(baby)

            var hatchedPair = pair
            hatchedPair.hatched = true
            hatchedPair.babyFishID = baby.id
            hatchedBreedings.append(hatchedPair)

            // Notify
            NotificationService.shared.scheduleNotification(
                title: "New baby fish! 🐟",
                body: "A \(baby.morph.rawValue) \(baby.species?.displayName ?? "fish") has hatched!",
                identifier: "baby-\(baby.id)"
            )
        }

        for fish in newFish {
            persistence.addFish(fish)
        }

        DispatchQueue.main.async {
            self.activeBreedings.removeAll { pair in
                hatchedBreedings.contains { $0.id == pair.id }
            }
            for hatched in hatchedBreedings {
                self.eggs.append(FishEgg(from: hatched))
            }
        }

        saveState()
    }

    /// Produce offspring from a breeding pair with genetics
    private func produceOffspring(from pair: BreedingPair) -> Fish {
        let parent1 = persistence.fish.first { $0.id == pair.parent1ID }
        let parent2 = persistence.fish.first { $0.id == pair.parent2ID }

        let baseHue: CGFloat
        let baseSat: CGFloat
        let baseBright: CGFloat

        if let p1 = parent1, let p2 = parent2 {
            // Average parent colors with slight variation
            baseHue = (p1.hue + p2.hue) / 2 + CGFloat.random(in: -0.05...0.05)
            baseSat = (p1.saturation + p2.saturation) / 2
            baseBright = (p1.brightness + p2.brightness) / 2
        } else {
            baseHue = CGFloat.random(in: 0...1)
            baseSat = 0.7
            baseBright = 0.8
        }

        // Determine morph with mutation chance
        let morph = determineMorph(parent1: parent1, parent2: parent2)

        let generation = max(parent1?.generation ?? 1, parent2?.generation ?? 1) + 1

        return Fish(
            name: "Baby \(parent1?.name ?? "Fish")",
            speciesID: pair.speciesID,
            morph: morph,
            hue: (baseHue + 1).truncatingRemainder(dividingBy: 1),
            saturation: min(max(baseSat, 0), 1),
            brightness: min(max(baseBright, 0), 1),
            size: 0.1,  // baby size
            state: .idle,
            happiness: 0.8,
            hungerLevel: 0,
            generation: generation,
            positionX: Double.random(in: 0.2...0.8),
            positionY: Double.random(in: 0.2...0.8)
        )
    }

    /// Determine offspring morph with mutation chances
    private func determineMorph(parent1: Fish?, parent2: Fish?) -> FishMorph {
        let random = Double.random(in: 0...1)
        var cumulative = 0.0

        // Check mutation chances
        for morph in FishMorph.allCases where morph != .normal {
            cumulative += morph.mutationChance
            if random <= cumulative {
                return morph
            }
        }

        // If no mutation, inherit from parents (with small chance of normal)
        // 70% chance of normal, 30% chance of inheriting one parent's morph
        if let p1 = parent1, let p2 = parent2 {
            if Double.random(in: 0...1) < 0.7 {
                return .normal
            }
            return [p1.morph, p2.morph].randomElement() ?? .normal
        }

        return .normal
    }

    // MARK: - Persistence

    private func saveState() {
        if let encoded = try? JSONEncoder().encode(activeBreedings) {
            UserDefaults.standard.set(encoded, forKey: "activeBreedings")
        }
        if let encoded = try? JSONEncoder().encode(eggs) {
            UserDefaults.standard.set(encoded, forKey: "fishEggs")
        }
    }

    private func loadSavedState() {
        if let data = UserDefaults.standard.data(forKey: "activeBreedings"),
           let decoded = try? JSONDecoder().decode([BreedingPair].self, from: data) {
            activeBreedings = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "fishEggs"),
           let decoded = try? JSONDecoder().decode([FishEgg].self, from: data) {
            eggs = decoded
        }
    }
}

// MARK: - Supporting Types

struct BreedingPair: Identifiable, Codable {
    let id: UUID
    let parent1ID: UUID
    let parent2ID: UUID
    let speciesID: String
    let startedAt: Date
    let hatchDate: Date
    var hatched: Bool
    var babyFishID: UUID?

    init(id: UUID = UUID(), parent1ID: UUID, parent2ID: UUID, speciesID: String, startedAt: Date, hatchDate: Date, hatched: Bool = false, babyFishID: UUID? = nil) {
        self.id = id
        self.parent1ID = parent1ID
        self.parent2ID = parent2ID
        self.speciesID = speciesID
        self.startedAt = startedAt
        self.hatchDate = hatchDate
        self.hatched = hatched
        self.babyFishID = babyFishID
    }
}

struct FishEgg: Identifiable, Codable {
    let id: UUID
    let parent1ID: UUID
    let parent2ID: UUID
    let speciesID: String
    let babyFishID: UUID?
    let hatchDate: Date
    let discoveredAt: Date

    init(from pair: BreedingPair) {
        self.id = pair.id
        self.parent1ID = pair.parent1ID
        self.parent2ID = pair.parent2ID
        self.speciesID = pair.speciesID
        self.babyFishID = pair.babyFishID
        self.hatchDate = pair.hatchDate
        self.discoveredAt = Date()
    }
}

enum BreedingCompatibility {
    case compatible
    case failure(reason: String)

    var isCompatible: Bool {
        if case .compatible = self { return true }
        return false
    }

    var failureReason: String? {
        if case .failure(let reason) = self { return reason }
        return nil
    }
}
