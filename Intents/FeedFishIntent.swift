import Foundation
import AppIntents
import WidgetKit

/// App Intent to feed the user's primary fish via Siri / Shortcuts / Widget
@available(iOS 16.0, *)
struct FeedFishIntent: AppIntent {
    static let title: LocalizedStringResource = "Feed My Fish"
    static let description = IntentDescription("Feeds your Pocket Aquarium fish.")

    static let openAppWhenRun = false

    /// No parameters — feeds all fish or the primary fish
    @Parameter(
        title: "All Fish",
        description: "Feed all fish instead of just the primary fish"
    )
    var feedAll: Bool?

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let fishList = PersistenceService.shared.fish

        guard !fishList.isEmpty else {
            return .result(value: "🐠 No fish to feed!")
        }

        if feedAll == true {
            // Feed every fish
            for fish in fishList {
                FishBehaviorEngine.shared.feed(fishID: fish.id)
            }
            WidgetDataProvider.shared.refreshWidgets()
            return .result(value: "🐠 All fish fed! (\(fishList.count) fish)")
        } else {
            // Feed the primary (first) fish
            guard let primary = fishList.first else {
                return .result(value: "🐠 No fish to feed!")
            }
            FishBehaviorEngine.shared.feed(fishID: primary.id)
            WidgetDataProvider.shared.refreshWidgets()
            return .result(value: "🐠 Fed!")
        }
    }
}
