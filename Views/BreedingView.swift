import SwiftUI

/// Breeding view — select two fish to pair, check compatibility, and start breeding
struct BreedingView: View {
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var breedingEngine: BreedingEngine
    @EnvironmentObject var storeKit: StoreKitManager

    @State private var selectedFish1: Fish?
    @State private var selectedFish2: Fish?
    @State private var showFishPicker1 = false
    @State private var showFishPicker2 = false
    @State private var showResult = false
    @State private var resultMessage = ""
    @State private var showProUpgrade = false

    private var breedableFish: [Fish] {
        persistence.fish.filter { $0.isAdult }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Pro check
                    if !storeKit.isPro {
                        proRequiredBanner
                    }

                    // Active breedings
                    if !breedingEngine.activeBreedings.isEmpty {
                        activeBreedingsSection
                    }

                    // Hatched eggs
                    if !breedingEngine.eggs.isEmpty {
                        hatchedEggsSection
                    }

                    // Fish selection
                    fishSelectionSection

                    // Compatibility & breed button
                    if let fish1 = selectedFish1, let fish2 = selectedFish2 {
                        compatibilitySection(fish1: fish1, fish2: fish2)
                    }

                    // Breeding info
                    breedingInfoSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Breeding")
            .sheet(isPresented: $showProUpgrade) {
                ProUpgradeView()
            }
            .sheet(isPresented: $showFishPicker1) {
                FishPickerView(fishList: breedableFish.filter { $0.id != selectedFish2?.id }, title: "Select Parent 1") { fish in
                    selectedFish1 = fish
                    showFishPicker1 = false
                }
            }
            .sheet(isPresented: $showFishPicker2) {
                FishPickerView(fishList: breedableFish.filter { $0.id != selectedFish1?.id }, title: "Select Parent 2") { fish in
                    selectedFish2 = fish
                    showFishPicker2 = false
                }
            }
            .alert("Breeding Result", isPresented: $showResult) {
                Button("OK") {}
            } message: {
                Text(resultMessage)
            }
        }
    }

    // MARK: - Pro Banner

    private var proRequiredBanner: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            Text("Breeding requires Pro")
                .font(.headline)
            Text("Unlock rare morphs like Albino, Neon, Galaxy & Gold!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Upgrade to Pro") {
                showProUpgrade = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Active Breedings

    private var activeBreedingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Active Breedings", systemImage: "heart.fill")
                .font(.headline)

            ForEach(breedingEngine.activeBreedings) { pair in
                HStack {
                    VStack(alignment: .leading) {
                        Text("Breeding in progress")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Hatches: \(hatchTimer(pair.hatchDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                .padding()
                .background(Color.pink.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Hatched Eggs

    private var hatchedEggsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Hatched!", systemImage: "sparkles")
                .font(.headline)

            ForEach(breedingEngine.eggs) { egg in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("New fish hatched!")
                            .font(.subheadline)
                        Text("Tap the Hatchery tab to see your new fish")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Fish Selection

    private var fishSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Select Parents", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)

            if breedableFish.isEmpty {
                Text("You need at least 2 adult fish to breed.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                // Fish 1 selection
                fishSelectionButton(
                    fish: selectedFish1,
                    placeholder: "Parent 1",
                    action: { showFishPicker1 = true }
                )

                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)

                // Fish 2 selection
                fishSelectionButton(
                    fish: selectedFish2,
                    placeholder: "Parent 2",
                    action: { showFishPicker2 = true }
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func fishSelectionButton(fish: Fish?, placeholder: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let fish = fish {
                    Text(fish.species?.emoji ?? "🐠")
                        .font(.title)
                    Text(fish.name)
                        .font(.caption)
                    Text(fish.morph.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "questionmark.circle")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text(placeholder)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - Compatibility

    private func compatibilitySection(fish1: Fish, fish2: Fish) -> some View {
        VStack(spacing: 12) {
            let compatibility = breedingEngine.canBreed(fish1, fish2)

            if compatibility.isCompatible {
                Label("Compatible! 🎉", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)

                Button(action: { performBreed(fish1, fish2) }) {
                    Label("Start Breeding", systemImage: "heart.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
            } else {
                Label(
                    compatibility.failureReason ?? "Cannot breed",
                    systemImage: "xmark.circle.fill"
                )
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Breeding Info

    private var breedingInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("About Breeding", systemImage: "info.circle.fill")
                .font(.headline)

            Text("• Two fish of the same species can breed")
                .font(.caption)
            Text("• Eggs take 8 hours to hatch")
                .font(.caption)
            Text("• Babies inherit colors from both parents")
                .font(.caption)
            Text("• Rare morphs: Albino (1%), Neon (2%), Galaxy (0.5%), Gold (3%)")
                .font(.caption)
            Text("• Breeding cooldown: 24 hours")
                .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func performBreed(_ fish1: Fish, _ fish2: Fish) {
        guard storeKit.isPro else {
            showProUpgrade = true
            return
        }

        if breedingEngine.startBreeding(fish1, fish2) {
            resultMessage = "Breeding started! Eggs will hatch in 8 hours. 🥚"
            selectedFish1 = nil
            selectedFish2 = nil
        } else {
            resultMessage = "Could not start breeding. Check compatibility."
        }
        showResult = true
    }

    // MARK: - Helpers

    private func hatchTimer(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        guard interval > 0 else { return "Now!" }
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Fish Picker View

struct FishPickerView: View {
    let fishList: [Fish]
    let title: String
    let onSelect: (Fish) -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(fishList) { fish in
                Button {
                    onSelect(fish)
                    dismiss()
                } label: {
                    HStack {
                        Text(fish.species?.emoji ?? "🐠")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(fish.name)
                                .fontWeight(.semibold)
                            HStack {
                                Text(fish.species?.displayName ?? "Fish")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(fish.morph.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if fish.canBreed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Text("Cooldown")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
