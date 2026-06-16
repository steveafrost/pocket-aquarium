import Foundation

/// Represents the behavioral state of a fish in the state machine.
/// Transitions: idle ↔ eating ↔ sleeping ↔ excited ↔ lonely
enum FishState: String, Codable, CaseIterable {
    case idle
    case eating
    case sleeping
    case excited
    case lonely

    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .eating: return "Eating"
        case .sleeping: return "Sleeping"
        case .excited: return "Excited"
        case .lonely: return "Lonely"
        }
    }

    var emoji: String {
        switch self {
        case .idle: return "🐠"
        case .eating: return "🍕"
        case .sleeping: return "💤"
        case .excited: return "⚡"
        case .lonely: return "😢"
        }
    }

    /// Indicates if the fish is inactive/resting
    var isResting: Bool {
        self == .sleeping
    }

    /// Indicates if the fish needs user attention
    var needsAttention: Bool {
        self == .lonely
    }
}
