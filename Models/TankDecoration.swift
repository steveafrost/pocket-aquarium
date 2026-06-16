import Foundation

/// Decorations placed in the tank
struct TankDecoration: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let type: DecorationType
    var positionX: Double       // 0.0-1.0 relative position
    var positionY: Double
    var scale: Double           // 0.5-2.0
    var isPro: Bool
    var isPlaced: Bool

    enum DecorationType: String, Codable, CaseIterable {
        case plant = "Plant"
        case rock = "Rock"
        case castle = "Castle"
        case cave = "Cave"
        case coral = "Coral"
        case shell = "Shell"
        case diver = "Diver"
        case treasure = "Treasure"
        case volcano = "Volcano"
        case archway = "Archway"

        var emoji: String {
            switch self {
            case .plant: return "🌿"
            case .rock: return "🪨"
            case .castle: return "🏰"
            case .cave: return "🕳️"
            case .coral: return "🪸"
            case .shell: return "🐚"
            case .diver: return "🤿"
            case .treasure: return "💎"
            case .volcano: return "🌋"
            case .archway: return "⛩️"
            }
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: DecorationType,
        positionX: Double = 0.5,
        positionY: Double = 0.5,
        scale: Double = 1.0,
        isPro: Bool = false,
        isPlaced: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.positionX = positionX
        self.positionY = positionY
        self.scale = scale
        self.isPro = isPro
        self.isPlaced = isPlaced
    }

    /// Free decorations available to all
    static let freeDecorations: [TankDecoration] = [
        TankDecoration(name: "Seaweed", type: .plant, isPro: false),
        TankDecoration(name: "Pebbles", type: .rock, isPro: false),
        TankDecoration(name: "Small Shell", type: .shell, isPro: false)
    ]

    /// Pro-only decorations
    static let proDecorations: [TankDecoration] = [
        TankDecoration(name: "Castle", type: .castle, isPro: true),
        TankDecoration(name: "Coral Reef", type: .coral, isPro: true),
        TankDecoration(name: "Treasure Chest", type: .treasure, isPro: true),
        TankDecoration(name: "Diver Statue", type: .diver, isPro: true),
        TankDecoration(name: "Underwater Volcano", type: .volcano, isPro: true),
        TankDecoration(name: "Mystic Archway", type: .archway, isPro: true),
        TankDecoration(name: "Crystal Cave", type: .cave, isPro: true)
    ]

    static var all: [TankDecoration] {
        freeDecorations + proDecorations
    }
}
