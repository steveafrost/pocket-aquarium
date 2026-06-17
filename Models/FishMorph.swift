import Foundation
import CoreGraphics

/// Rare color morphs a fish can inherit through breeding
enum FishMorph: String, Codable, CaseIterable {
    case normal = "Normal"
    case albino = "Albino"
    case neon = "Neon"
    case galaxy = "Galaxy"
    case gold = "Gold"

    var displayName: String {
        rawValue
    }

    var rarityDescription: String {
        switch self {
        case .normal: return "Common"
        case .albino: return "Rare (1%)"
        case .neon: return "Rare (2%)"
        case .galaxy: return "Legendary (0.5%)"
        case .gold: return "Uncommon (3%)"
        }
    }

    /// Mutation chance out of 1.0
    var mutationChance: Double {
        switch self {
        case .normal: return 0.935   // default (remainder after all chances)
        case .albino: return 0.01
        case .neon: return 0.02
        case .galaxy: return 0.005
        case .gold: return 0.03
        }
    }

    /// Color effect applied to the base hue
    func applyColorEffect(to baseHue: CGFloat) -> CGFloat {
        switch self {
        case .normal: return baseHue
        case .albino: return 0.0    // white/pale
        case .neon: return (baseHue + 0.5).truncatingRemainder(dividingBy: 1.0)
        case .galaxy: return (baseHue + 0.2).truncatingRemainder(dividingBy: 1.0)
        case .gold: return 0.12     // golden hue
        }
    }

    func applySaturation(_ base: CGFloat) -> CGFloat {
        switch self {
        case .normal: return base
        case .albino: return 0.05
        case .neon: return 1.0
        case .galaxy: return 0.9
        case .gold: return 0.85
        }
    }

    func applyBrightness(_ base: CGFloat) -> CGFloat {
        switch self {
        case .normal: return base
        case .albino: return 1.0
        case .neon: return 1.0
        case .galaxy: return 1.0
        case .gold: return 0.95
        }
    }

    var emoji: String {
        switch self {
        case .normal: return "🐟"
        case .albino: return "🐠"
        case .neon: return "🦐"
        case .galaxy: return "🌌"
        case .gold: return "⭐"
        }
    }

    /// All morphs with mutation weight for weighted random selection
    static var weightedMorphs: [(FishMorph, Double)] {
        FishMorph.allCases.map { ($0, $0.mutationChance) }
    }
}
