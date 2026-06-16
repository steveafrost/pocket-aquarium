import Foundation
import ActivityKit
import SwiftUI

/// Manages Dynamic Island Live Activity to show the fish in the island
@available(iOS 16.1, *)
class DynamicIslandManager: ObservableObject {
    static let shared = DynamicIslandManager()

    @Published var isLiveActivityActive: Bool = false
    private var currentActivity: Activity<FishDynamicIslandAttributes>?

    private init() {}

    // MARK: - Public API

    /// Start a Live Activity showing the fish in the Dynamic Island
    func startFishActivity(fish: Fish) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }

        let attributes = FishDynamicIslandAttributes(fishName: fish.name, speciesID: fish.speciesID)

        let initialState = ActivityContent(
            state: FishDynamicIslandAttributes.ContentState(
                fishState: fish.state.rawValue,
                happiness: fish.happiness,
                hungerLevel: fish.hungerLevel,
                morph: fish.morph.rawValue,
                lastUpdated: Date()
            ),
            staleDate: Date().addingTimeInterval(60 * 5) // 5 min stale
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: initialState,
                pushType: nil
            )
            currentActivity = activity
            DispatchQueue.main.async {
                self.isLiveActivityActive = true
            }
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// Update the Dynamic Island with current fish state
    func updateFishState(fish: Fish) {
        guard let activity = currentActivity else { return }

        let updatedState = ActivityContent(
            state: FishDynamicIslandAttributes.ContentState(
                fishState: fish.state.rawValue,
                happiness: fish.happiness,
                hungerLevel: fish.hungerLevel,
                morph: fish.morph.rawValue,
                lastUpdated: Date()
            ),
            staleDate: Date().addingTimeInterval(60 * 5)
        )

        Task {
            await activity.update(updatedState)
        }
    }

    /// End the Dynamic Island Live Activity
    func stopFishActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(
                dismissalPolicy: .immediate
            )
        }
        currentActivity = nil
        DispatchQueue.main.async {
            self.isLiveActivityActive = false
        }
    }

    /// Check if we should start the activity when app goes to background
    func handleAppBackground(fish: Fish?) {
        guard let fish = fish else {
            if isLiveActivityActive { stopFishActivity() }
            return
        }
        startFishActivity(fish: fish)
    }
}

// MARK: - ActivityKit Attributes

struct FishDynamicIslandAttributes: ActivityAttributes {
    public typealias FishState = ContentState

    var fishName: String
    var speciesID: String

    public struct ContentState: Codable, Hashable {
        var fishState: String
        var happiness: Double
        var hungerLevel: Double
        var morph: String
        var lastUpdated: Date
    }
}
