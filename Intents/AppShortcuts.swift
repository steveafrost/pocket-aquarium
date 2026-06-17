import Foundation
import AppIntents

/// Provides Pocket Aquarium intents to the Shortcuts app and Siri
@available(iOS 16.0, *)
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FeedFishIntent(),
            phrases: [
                "Feed my fish with \(.applicationName)",
                "Feed my fish",
                "Feed my aquarium with \(.applicationName)",
            ],
            shortTitle: "Feed Fish",
            systemImageName: "fish"
        )

        AppShortcut(
            intent: CheckFishIntent(),
            phrases: [
                "How's my fish on \(.applicationName)",
                "How's my fish?",
                "Check my aquarium",
                "Check my fish on \(.applicationName)",
            ],
            shortTitle: "Check Fish",
            systemImageName: "heart.fill"
        )
    }
}
