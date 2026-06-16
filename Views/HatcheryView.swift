import SwiftUI

/// Hatchery view — shows eggs incubating and baby fish hatching
struct HatcheryView: View {
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var breedingEngine: BreedingEngine
    @EnvironmentObject var behaviorEngine: FishBehaviorEngine
    @EnvironmentObject var animationEngine: AnimationEngine

    @State private var tankSize: CGSize = .zero
    @State private var showNewFishAlert = false
    @State private var newFishName = ""

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Hatchery background
                    hatcheryBackground
                        .frame(height: geometry.size.height * 0.4)
                        .overlay(alignment: .bottom) {
                            if breedingEngine.activeBreedings.isEmpty && breedingEngine.eggs.isEmpty {
                                emptyHatcheryOverlay
                            }
                        }

                    // Eggs and babies list
                    List {
                        // Active eggs
                        if !breedingEngine.activeBreedings.isEmpty {
                            Section("Incubating Eggs") {
                                ForEach(breedingEngine.activeBreedings) { pair in
                                    EggRow(pair: pair)
                                }
                            }
                        }

                        // Hatched eggs / babies
                        if !breedingEngine.eggs.isEmpty {
                            Section("Recent Hatches") {
                                ForEach(breedingEngine.eggs) { egg in
                                    HatchedEggRow(egg: egg, fishList: persistence.fish)
                                }
                            }
                        }

                        // Baby fish
                        let babies = persistence.fish.filter { !$0.isAdult }
                        if !babies.isEmpty {
                            Section("Baby Fish") {
                                ForEach(babies) { baby in
                                    BabyFishRow(fish: baby)
                                }
                            }
                        }

                        // All fish
                        if !persistence.fish.isEmpty {
                            Section("All Fish (\(persistence.fish.count))") {
                                ForEach(persistence.fish) { fish in
                                    FishRow(fish: fish)
                                }
                            }
                        }

                        if persistence.fish.isEmpty && breedingEngine.activeBreedings.isEmpty && breedingEngine.eggs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "egg.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No eggs or fish yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Buy fish from the Shop or breed them to get started!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Hatchery")
            .onAppear {
                breedingEngine.checkHatches()
            }
            .onReceive(breedingEngine.$activeBreedings) { _ in
                breedingEngine.checkHatches()
            }
        }
    }

    // MARK: - Hatchery Background

    private var hatcheryBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.pink.opacity(0.2), Color.orange.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )

            // Decorative eggs
            Image(systemName: "egg.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
                .offset(x: -60, y: -20)

            Image(systemName: "leaf.fill")
                .font(.system(size: 40))
                .foregroundColor(.green.opacity(0.3))
                .offset(x: 70, y: 20)
        }
        .overlay(alignment: .center) {
            if !breedingEngine.activeBreedings.isEmpty {
                VStack(spacing: 4) {
                    Text("\(breedingEngine.activeBreedings.count) eggs incubating")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Check back soon!")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
    }

    private var emptyHatcheryOverlay: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.circle")
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.5))
            Text("Breed fish to see eggs here")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Egg Row

struct EggRow: View {
    let pair: BreedingPair

    var body: some View {
        HStack {
            Image(systemName: "egg.fill")
                .font(.title2)
                .foregroundColor(.pink)
                .symbolEffect(.pulse)

            VStack(alignment: .leading) {
                Text("Eggs incubating")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Hatch time remaining: \(hatchTimer(pair.hatchDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            ProgressView(timerInterval: Date()...pair.hatchDate, countsDown: true)
                .frame(width: 80)
        }
        .padding(.vertical, 4)
    }

    private func hatchTimer(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        guard interval > 0 else { return "Now!" }
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Hatched Egg Row

struct HatchedEggRow: View {
    let egg: FishEgg
    let fishList: [Fish]

    var babyFish: Fish? {
        guard let babyID = egg.babyFishID else { return nil }
        return fishList.first { $0.id == babyID }
    }

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)

            VStack(alignment: .leading) {
                if let baby = babyFish {
                    Text("\(baby.name) hatched! 🎉")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(baby.species?.displayName ?? "Fish") • \(baby.morph.displayName) morph")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("A new fish hatched!")
                        .font(.subheadline)
                }
                Text("Hatched \(formattedDate(egg.hatchDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Baby Fish Row

struct BabyFishRow: View {
    let fish: Fish

    var body: some View {
        HStack {
            Text(fish.species?.emoji ?? "🐠")
                .font(.title2)

            VStack(alignment: .leading) {
                Text(fish.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                HStack {
                    Text("Baby • \(Int(fish.growthProgress))% grown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if fish.morph != .normal {
                        Text("• \(fish.morph.displayName)")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }

            Spacer()

            ProgressView(value: fish.size, total: 1.0)
                .tint(.blue)
                .frame(width: 60)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Fish Row

struct FishRow: View {
    let fish: Fish

    var body: some View {
        HStack {
            Text(fish.species?.emoji ?? "🐠")
                .font(.title2)

            VStack(alignment: .leading) {
                Text(fish.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("F\(fish.generation) • \(fish.state.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if fish.morph != .normal {
                Text(fish.morph.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(4)
            }

            Text(fish.isAdult ? "Adult" : "Baby")
                .font(.caption)
                .foregroundColor(fish.isAdult ? .green : .blue)
        }
        .padding(.vertical, 4)
    }
}
