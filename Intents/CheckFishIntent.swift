import Foundation
import AppIntents

/// App Intent to check on the user's fish via Siri / Shortcuts
@available(iOS 16.0, *)
struct CheckFishIntent: AppIntent {
    static let title: LocalizedStringResource = "How's My Fish?"
    static let description = IntentDescription("Returns the current status of your Pocket Aquarium fish.")

    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard let fish = WidgetDataProvider.shared.currentFish else {
            return .result(value: "🐠 No fish in your aquarium yet!")
        }

        let species = fish.species?.displayName ?? "Unknown"
        let stateEmoji = fish.state.emoji
        let stateName = fish.state.displayName

        let hungerPercent = Int(fish.hungerLevel * 100)
        let happinessPercent = Int(fish.happiness * 100)
        let growthPercent = Int(fish.growthProgress)

        // Build a friendly status message
        var status = "🐟 \(fish.name) the \(species) is \(stateName) \(stateEmoji). "
        status += "Happiness: \(happinessPercent)%, Hunger: \(hungerPercent)%, Growth: \(growthPercent)%. "

        if fish.isStarving {
            status += "⚠️ \(fish.name) is starving! Feed them soon!"
        } else if fish.isHungry {
            status += "🍕 \(fish.name) is getting hungry."
        }

        if fish.state.needsAttention {
            status += "💔 \(fish.name) feels lonely — give them some attention!"
        }

        return .result(value: status)
    }
}
