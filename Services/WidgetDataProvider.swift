import Foundation
import WidgetKit
import SwiftUI

/// Provides data to the Widget extension
class WidgetDataProvider: ObservableObject {
    static let shared = WidgetDataProvider()

    @Published var currentFish: Fish?

    private init() {
        loadCurrentFish()
    }

    /// Load the primary fish for widget display
    func loadCurrentFish() {
        let fishList = PersistenceService.shared.fish
        // Show the first fish (most recent interaction)
        currentFish = fishList.max(by: {
            ($0.lastInteractionDate ?? $0.creationDate) < ($1.lastInteractionDate ?? $1.creationDate)
        })
    }

    /// Refresh widget data and tell WidgetKit to update
    func refreshWidgets() {
        loadCurrentFish()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Fish data formatted for widget consumption
    func widgetEntry(for fish: Fish?) -> FishWidgetEntry {
        guard let fish = fish else {
            return FishWidgetEntry(
                date: Date(),
                fishName: "No fish yet",
                speciesID: "goldfish",
                fishState: .idle,
                happiness: 0.5,
                hungerLevel: 0,
                morph: .normal,
                tankBackground: "basicBlue"
            )
        }

        return FishWidgetEntry(
            date: Date(),
            fishName: fish.name,
            speciesID: fish.speciesID,
            fishState: fish.state,
            happiness: fish.happiness,
            hungerLevel: fish.hungerLevel,
            morph: fish.morph,
            tankBackground: "basicBlue"
        )
    }
}

/// Timeline entry for the widget
struct FishWidgetEntry: TimelineEntry {
    let date: Date
    let fishName: String
    let speciesID: String
    let fishState: FishState
    let happiness: Double
    let hungerLevel: Double
    let morph: FishMorph
    let tankBackground: String
}
