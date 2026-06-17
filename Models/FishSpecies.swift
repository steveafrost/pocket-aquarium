import Foundation
import CoreGraphics

/// Defines a fish species with base properties
struct FishSpecies: Identifiable, Codable, Hashable {
    let id: String
    let displayName: String
    let description: String
    let emoji: String
    let baseSwimSpeed: Double       // pixels per second
    let finStyle: FinStyle
    let colorRanges: [ColorRange]   // possible color ranges for this species
    let isPro: Bool                 // requires Pro unlock
    let baseHungerInterval: TimeInterval  // hours before hunger starts

    enum FinStyle: String, Codable, CaseIterable {
        case standard
        case flowing
        case spiky
        case rounded
        case ribbon
        case tentacle

        var displayName: String {
            switch self {
            case .standard: return "Standard"
            case .flowing: return "Flowing"
            case .spiky: return "Spiky"
            case .rounded: return "Rounded"
            case .ribbon: return "Ribbon"
            case .tentacle: return "Tentacle"
            }
        }
    }

    struct ColorRange: Codable, Hashable {
        let baseHue: CGFloat
        let hueVariation: CGFloat    // ± range
        let saturation: CGFloat
        let brightness: CGFloat
    }

    /// 6 species definitions
    static let goldfish = FishSpecies(
        id: "goldfish",
        displayName: "Goldfish",
        description: "A friendly, hardy fish. Perfect starter pet!",
        emoji: "🐠",
        baseSwimSpeed: 30,
        finStyle: .standard,
        colorRanges: [
            ColorRange(baseHue: 0.08, hueVariation: 0.05, saturation: 0.8, brightness: 0.9),
            ColorRange(baseHue: 0.0, hueVariation: 0.03, saturation: 0.7, brightness: 0.85)
        ],
        isPro: false,
        baseHungerInterval: 4
    )

    static let betta = FishSpecies(
        id: "betta",
        displayName: "Betta",
        description: "A majestic fish with flowing, vibrant fins.",
        emoji: "🦚",
        baseSwimSpeed: 25,
        finStyle: .flowing,
        colorRanges: [
            ColorRange(baseHue: 0.85, hueVariation: 0.1, saturation: 0.9, brightness: 0.9),
            ColorRange(baseHue: 0.6, hueVariation: 0.05, saturation: 0.8, brightness: 0.8)
        ],
        isPro: true,
        baseHungerInterval: 5
    )

    static let clownfish = FishSpecies(
        id: "clownfish",
        displayName: "Clownfish",
        description: "Playful and energetic. Loves darting around!",
        emoji: "🐟",
        baseSwimSpeed: 45,
        finStyle: .rounded,
        colorRanges: [
            ColorRange(baseHue: 0.05, hueVariation: 0.02, saturation: 0.9, brightness: 1.0),
            ColorRange(baseHue: 0.0, hueVariation: 0.02, saturation: 0.9, brightness: 0.9)
        ],
        isPro: true,
        baseHungerInterval: 3.5
    )

    static let angelfish = FishSpecies(
        id: "angelfish",
        displayName: "Angelfish",
        description: "Graceful and elegant. Glides through the water.",
        emoji: "🧿",
        baseSwimSpeed: 20,
        finStyle: .ribbon,
        colorRanges: [
            ColorRange(baseHue: 0.55, hueVariation: 0.08, saturation: 0.6, brightness: 0.9),
            ColorRange(baseHue: 0.5, hueVariation: 0.05, saturation: 0.5, brightness: 1.0)
        ],
        isPro: true,
        baseHungerInterval: 6
    )

    static let seahorse = FishSpecies(
        id: "seahorse",
        displayName: "Seahorse",
        description: "Slow and hypnotic. Sways gently in the current.",
        emoji: "🐴",
        baseSwimSpeed: 10,
        finStyle: .spiky,
        colorRanges: [
            ColorRange(baseHue: 0.15, hueVariation: 0.1, saturation: 0.7, brightness: 0.8),
            ColorRange(baseHue: 0.0, hueVariation: 0.02, saturation: 0.6, brightness: 0.9)
        ],
        isPro: true,
        baseHungerInterval: 8
    )

    static let jellyfish = FishSpecies(
        id: "jellyfish",
        displayName: "Jellyfish",
        description: "Ethereal and mesmerizing. Pulses through the deep.",
        emoji: "🪼",
        baseSwimSpeed: 15,
        finStyle: .tentacle,
        colorRanges: [
            ColorRange(baseHue: 0.8, hueVariation: 0.1, saturation: 0.7, brightness: 1.0),
            ColorRange(baseHue: 0.3, hueVariation: 0.05, saturation: 0.6, brightness: 0.9)
        ],
        isPro: true,
        baseHungerInterval: 7
    )

    static var all: [FishSpecies] {
        [goldfish, betta, clownfish, angelfish, seahorse, jellyfish]
    }

    /// Species available for free users
    static var freeSpecies: [FishSpecies] {
        [goldfish]
    }

    /// Species requiring Pro
    static var proSpecies: [FishSpecies] {
        [betta, clownfish, angelfish, seahorse, jellyfish]
    }
}
