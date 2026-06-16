import Foundation

/// Represents a tank environment
struct Tank: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var background: TankBackground
    var decorations: [TankDecoration]
    var maxDecorations: Int
    var isDefault: Bool
    var isPro: Bool

    enum TankBackground: String, Codable, CaseIterable {
        case basicBlue = "Basic Blue"
        case reef = "Reef"
        case darkWater = "Dark Water"
        case planted = "Planted"
        case castleRuins = "Castle Ruins"
        case space = "Space"

        var displayName: String { rawValue }

        var color: String {
            switch self {
            case .basicBlue: return "cyan"
            case .reef: return "teal"
            case .darkWater: return "indigo"
            case .planted: return "green"
            case .castleRuins: return "brown"
            case .space: return "purple"
            }
        }
    }

    init(
        id: UUID = UUID(),
        name: String = "My Tank",
        background: TankBackground = .basicBlue,
        decorations: [TankDecoration] = [],
        maxDecorations: Int = 5,
        isDefault: Bool = false,
        isPro: Bool = false
    ) {
        self.id = id
        self.name = name
        self.background = background
        self.decorations = decorations
        self.maxDecorations = maxDecorations
        self.isDefault = isDefault
        self.isPro = isPro
    }

    static let defaultTank = Tank(
        name: "Starter Tank",
        background: .basicBlue,
        isDefault: true,
        isPro: false
    )

    /// Pro backgrounds
    static let proBackgrounds: [TankBackground] = [
        .reef, .darkWater, .planted, .castleRuins, .space
    ]
}
