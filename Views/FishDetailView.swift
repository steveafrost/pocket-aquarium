import SwiftUI

/// Detail view for a single fish — stats, interactions, growth progress
struct FishDetailView: View {
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var behaviorEngine: FishBehaviorEngine
    @Environment(\.dismiss) var dismiss

    @State private var fish: Fish
    @State private var showRelease = false

    init(fish: Fish) {
        self._fish = State(initialValue: fish)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Fish header
                    fishHeader

                    // Stats
                    statsSection

                    // Growth progress
                    growthSection

                    // Actions
                    actionsSection

                    // State timeline
                    stateSection

                    // Release button
                    if persistence.fish.count > 1 {
                        Button(role: .destructive) {
                            showRelease = true
                        } label: {
                            Label("Release \(fish.name)", systemImage: "xmark.circle")
                                .foregroundColor(.red)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(fish.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text(fish.name)
                        .font(.headline)
                }
            }
            .alert("Release \(fish.name)?", isPresented: $showRelease) {
                Button("Cancel", role: .cancel) {}
                Button("Release", role: .destructive) {
                    persistence.removeFish(id: fish.id)
                    dismiss()
                }
            } message: {
                Text("This cannot be undone. \(fish.name) will swim away forever.")
            }
        }
    }

    // MARK: - Fish Header

    private var fishHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        Color(
                            hue: fish.displayHue,
                            saturation: fish.displaySaturation,
                            brightness: fish.displayBrightness
                        )
                        .opacity(0.3)
                    )
                    .frame(width: 120, height: 120)

                Text(fishSpeciesEmoji(fish.speciesID))
                    .font(.system(size: 60 * CGFloat(fish.size)))
            }

            Text(fish.species?.displayName ?? "Fish")
                .font(.title3)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                MorphBadge(morph: fish.morph)
                if fish.species?.isPro == true {
                    ProBadge()
                }
            }

            Text("Generation F\(fish.generation)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Stats", systemImage: "chart.bar.fill")
                .font(.headline)

            StatRow(label: "Happiness", value: fish.happiness, color: .pink, icon: "heart.fill")
            StatRow(label: "Hunger", value: fish.hungerLevel, color: .orange, icon: "flame.fill")
            StatRow(label: "Size", value: fish.size, color: .blue, icon: "arrow.up.heart.fill")
            StatRow(label: "State", valueText: fish.state.emoji + " " + fish.state.displayName, color: .purple, icon: "circle.fill")

            Divider()

            HStack {
                Label("Age", systemImage: "clock.fill")
                    .foregroundColor(.secondary)
                Spacer()
                Text(formattedAge(fish.age))
                    .foregroundColor(.primary)
            }

            HStack {
                Label("Last Fed", systemImage: "fork.knife")
                    .foregroundColor(.secondary)
                Spacer()
                Text(formattedLastFed)
                    .foregroundColor(.primary)
            }

            HStack {
                Label("Last Pet", systemImage: "hand.raised.fill")
                    .foregroundColor(.secondary)
                Spacer()
                Text(formattedLastInteraction)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Growth

    private var growthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Growth", systemImage: "arrow.up.heart.fill")
                .font(.headline)

            ProgressView(value: fish.size, total: 1.0)
                .tint(.blue)

            HStack {
                Text(fish.isFullyGrown ? "Fully grown! 🎉" : "\(Int(fish.growthProgress))% grown")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if fish.canBreed {
                    Label("Can breed", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.pink)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        HStack(spacing: 20) {
            Button {
                behaviorEngine.feed(fishID: fish.id)
                refreshFish()
            } label: {
                VStack {
                    Image(systemName: "fish.fill")
                        .font(.title2)
                    Text("Feed")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }

            Button {
                behaviorEngine.pet(fishID: fish.id)
                refreshFish()
            } label: {
                VStack {
                    Image(systemName: "hand.raised.fill")
                        .font(.title2)
                    Text("Pet")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.pink.opacity(0.1))
                .cornerRadius(12)
            }

            // Rename
            Button {
                renameFish()
            } label: {
                VStack {
                    Image(systemName: "pencil")
                        .font(.title2)
                    Text("Rename")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - State

    private var stateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Current State", systemImage: "circle.fill")
                .font(.headline)

            HStack {
                Image(systemName: stateIcon(fish.state))
                    .foregroundColor(stateColor(fish.state))
                Text(fish.state.displayName)
                Spacer()
                Text(fish.state.emoji)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(stateColor(fish.state).opacity(0.1))
            )

            Text(stateDescription(fish.state))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func refreshFish() {
        if let updated = persistence.fish(with: fish.id) {
            fish = updated
        }
    }

    private func renameFish() {
        let alert = UIAlertController(title: "Rename \(fish.name)", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = fish.name
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                fish.name = newName
                persistence.updateFish(fish)
            }
        })

        // Present from root
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }

    private var formattedLastFed: String {
        guard let lastFed = fish.lastFedDate else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastFed, relativeTo: Date())
    }

    private var formattedLastInteraction: String {
        guard let last = fish.lastInteractionDate else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: last, relativeTo: Date())
    }

    private func formattedAge(_ age: TimeInterval) -> String {
        let days = Int(age / 86400)
        let hours = Int((age.truncatingRemainder(dividingBy: 86400)) / 3600)
        if days > 0 {
            return "\(days)d \(hours)h"
        }
        return "\(hours)h"
    }

    private func fishSpeciesEmoji(_ speciesID: String) -> String {
        FishSpecies.all.first { $0.id == speciesID }?.emoji ?? "🐠"
    }

    private func stateIcon(_ state: FishState) -> String {
        switch state {
        case .idle: return "pause.circle.fill"
        case .eating: return "fork.knife"
        case .sleeping: return "moon.zzz.fill"
        case .excited: return "bolt.fill"
        case .lonely: return "heart.slash.fill"
        }
    }

    private func stateColor(_ state: FishState) -> Color {
        switch state {
        case .idle: return .gray
        case .eating: return .orange
        case .sleeping: return .indigo
        case .excited: return .yellow
        case .lonely: return .red
        }
    }

    private func stateDescription(_ state: FishState) -> String {
        switch state {
        case .idle: return "Swimming gently, waiting for interaction."
        case .eating: return "Enjoying a meal! Keep the food coming."
        case .sleeping: return "Resting. Fish sleep with their eyes open."
        case .excited: return "Zooming around! Something exciting happened."
        case .lonely: return "Feeling neglected. Needs food and attention."
        }
    }
}

// MARK: - Supporting Views

struct StatRow: View {
    let label: String
    var value: Double? = nil
    var valueText: String? = nil
    let color: Color
    let icon: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundColor(.secondary)
            Spacer()
            if let value = value {
                ProgressView(value: value, total: 1.0)
                    .tint(color)
                    .frame(width: 100)
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .frame(width: 40, alignment: .trailing)
            } else if let text = valueText {
                Text(text)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct MorphBadge: View {
    let morph: FishMorph

    var body: some View {
        HStack(spacing: 4) {
            Text(morph.emoji)
                .font(.caption)
            Text(morph.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(morph == .normal ? Color.gray.opacity(0.2) : Color.yellow.opacity(0.3))
        .cornerRadius(8)
    }
}

struct ProBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: 10))
            Text("Pro")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.yellow.opacity(0.3))
        .foregroundColor(.yellow)
        .cornerRadius(8)
    }
}
