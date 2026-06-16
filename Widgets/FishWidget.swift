import WidgetKit
import SwiftUI

/// Fish widget showing the fish in a small tank on the Lock Screen or Home Screen
struct FishWidget: Widget {
    let kind: String = "FishWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FishTimelineProvider()) { entry in
            FishWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Pocket Fish")
        .description("See your fish right on your Home or Lock Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Timeline Provider

struct FishTimelineProvider: TimelineProvider {
    let dataProvider = WidgetDataProvider.shared

    func placeholder(in context: Context) -> FishWidgetEntry {
        FishWidgetEntry(
            date: Date(),
            fishName: "Goldie",
            speciesID: "goldfish",
            fishState: .idle,
            happiness: 0.8,
            hungerLevel: 0.2,
            morph: .normal,
            tankBackground: "basicBlue"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FishWidgetEntry) -> Void) {
        let entry = dataProvider.widgetEntry(for: dataProvider.currentFish)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FishWidgetEntry>) -> Void) {
        let entry = dataProvider.widgetEntry(for: dataProvider.currentFish)

        // Refresh every 30 minutes
        let nextUpdate = Date().addingTimeInterval(30 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View

struct FishWidgetView: View {
    let entry: FishWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        case .accessoryCircular:
            circularWidgetView
        case .accessoryRectangular:
            rectangularWidgetView
        default:
            smallWidgetView
        }
    }

    // MARK: - Small Widget

    private var smallWidgetView: some View {
        ZStack {
            // Tank background
            tankColor
                .ignoresSafeArea()

            // Fish
            VStack(spacing: 4) {
                Text(fishEmoji)
                    .font(.system(size: 32))

                Text(entry.fishName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                // State indicator
                HStack(spacing: 2) {
                    Circle()
                        .fill(stateColor)
                        .frame(width: 6, height: 6)
                    Text(entry.fishState.displayName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }

    // MARK: - Medium Widget

    private var mediumWidgetView: some View {
        HStack {
            // Fish
            VStack {
                Text(fishEmoji)
                    .font(.system(size: 40))

                Text(entry.fishName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(width: 80)

            // Stats
            VStack(alignment: .leading, spacing: 8) {
                // Happiness
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                        .font(.caption)
                    ProgressView(value: entry.happiness, total: 1.0)
                        .tint(.pink)
                }

                // Hunger
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    ProgressView(value: entry.hungerLevel, total: 1.0)
                        .tint(.orange)
                }

                // Morph
                if entry.morph != .normal {
                    Text(entry.morph.displayName)
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }

                // State
                Text(entry.fishState.emoji + " " + entry.fishState.displayName)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.leading, 8)
        }
        .padding()
        .background(tankColor)
    }

    // MARK: - Circular Widget (Lock Screen)

    private var circularWidgetView: some View {
        ZStack {
            Circle()
                .fill(tankColor)

            VStack(spacing: 2) {
                Text(fishEmoji)
                    .font(.system(size: 24))
                Text(entry.fishState.emoji)
                    .font(.system(size: 10))
            }
        }
    }

    // MARK: - Rectangular Widget (Lock Screen)

    private var rectangularWidgetView: some View {
        HStack {
            Text(fishEmoji)
                .font(.system(size: 28))

            VStack(alignment: .leading) {
                Text(entry.fishName)
                    .font(.caption)
                    .fontWeight(.semibold)

                HStack {
                    Circle()
                        .fill(stateColor)
                        .frame(width: 6, height: 6)
                    Text(entry.fishState.displayName)
                        .font(.caption2)
                }
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private var fishEmoji: String {
        FishSpecies.all.first { $0.id == entry.speciesID }?.emoji ?? "🐠"
    }

    private var tankColor: Color {
        switch entry.tankBackground {
        case "basicBlue": return Color.blue.opacity(0.7)
        case "reef": return Color.teal.opacity(0.7)
        case "darkWater": return Color.indigo.opacity(0.7)
        case "planted": return Color.green.opacity(0.7)
        case "castleRuins": return Color.brown.opacity(0.7)
        case "space": return Color.purple.opacity(0.7)
        default: return Color.blue.opacity(0.7)
        }
    }

    private var stateColor: Color {
        switch entry.fishState {
        case .idle: return .gray
        case .eating: return .orange
        case .sleeping: return .indigo
        case .excited: return .yellow
        case .lonely: return .red
        }
    }
}
