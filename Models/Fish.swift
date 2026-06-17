import Foundation
import CoreGraphics

/// Main fish entity — represents a single virtual fish with its state, mood, and growth
struct Fish: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    let speciesID: String              // maps to FishSpecies.id
    var morph: FishMorph
    var hue: CGFloat                   // base hue 0.0-1.0
    var saturation: CGFloat
    var brightness: CGFloat

    // Growth
    var size: Double                   // 0.0 (baby) -> 1.0 (adult)
    var age: TimeInterval              // seconds since creation
    var creationDate: Date

    // State machine
    var state: FishState
    var lastFedDate: Date?
    var lastInteractionDate: Date?

    // Behavior
    var happiness: Double              // 0.0-1.0
    var hungerLevel: Double            // 0.0 (full) -> 1.0 (starving)

    // Breeding
    var breedingCooldown: Date?
    var generation: Int                // F1, F2, etc.

    // Tank position (for rendering)
    var positionX: Double
    var positionY: Double
    var targetX: Double
    var targetY: Double
    var swimAngle: Double              // radians

    init(
        id: UUID = UUID(),
        name: String = "Fishy",
        speciesID: String = "goldfish",
        morph: FishMorph = .normal,
        hue: CGFloat = 0.08,
        saturation: CGFloat = 0.8,
        brightness: CGFloat = 0.9,
        size: Double = 0.3,
        age: TimeInterval = 0,
        creationDate: Date = Date(),
        state: FishState = .idle,
        lastFedDate: Date? = nil,
        lastInteractionDate: Date? = nil,
        happiness: Double = 0.8,
        hungerLevel: Double = 0.0,
        breedingCooldown: Date? = nil,
        generation: Int = 1,
        positionX: Double = 0.5,
        positionY: Double = 0.5,
        targetX: Double = 0.5,
        targetY: Double = 0.5,
        swimAngle: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.speciesID = speciesID
        self.morph = morph
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.size = size
        self.age = age
        self.creationDate = creationDate
        self.state = state
        self.lastFedDate = lastFedDate
        self.lastInteractionDate = lastInteractionDate
        self.happiness = happiness
        self.hungerLevel = hungerLevel
        self.breedingCooldown = breedingCooldown
        self.generation = generation
        self.positionX = positionX
        self.positionY = positionY
        self.targetX = targetX
        self.targetY = targetY
        self.swimAngle = swimAngle
    }

    // MARK: - Computed properties

    var species: FishSpecies? {
        FishSpecies.all.first { $0.id == speciesID }
    }

    /// Display color taking morph into account
    var displayHue: CGFloat {
        morph.applyColorEffect(to: hue)
    }

    var displaySaturation: CGFloat {
        morph.applySaturation(saturation)
    }

    var displayBrightness: CGFloat {
        morph.applyBrightness(brightness)
    }

    var isAdult: Bool {
        size >= 0.8
    }

    var isFullyGrown: Bool {
        size >= 1.0
    }

    var canBreed: Bool {
        guard isAdult else { return false }
        if let cooldown = breedingCooldown, cooldown > Date() {
            return false
        }
        return true
    }

    var isHungry: Bool {
        hungerLevel > 0.6
    }

    var isStarving: Bool {
        hungerLevel > 0.9
    }

    /// Growth progress as percentage (0-100)
    var growthProgress: Double {
        min(size * 100, 100)
    }

    /// Hours since last fed
    var hoursSinceLastFed: Double? {
        guard let lastFed = lastFedDate else { return nil }
        return Date().timeIntervalSince(lastFed) / 3600.0
    }

    /// Hours since last interaction
    var hoursSinceLastInteraction: Double? {
        guard let lastInteraction = lastInteractionDate else { return nil }
        return Date().timeIntervalSince(lastInteraction) / 3600.0
    }
}
