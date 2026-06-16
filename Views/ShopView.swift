import SwiftUI

/// Shop view — buy fish species, decorations, and food using in-app purchase state
struct ShopView: View {
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var storeKit: StoreKitManager
    @EnvironmentObject var behaviorEngine: FishBehaviorEngine

    @State private var selectedCategory: ShopCategory = .fish
    @State private var showProUpgrade = false
    @State private var purchaseMessage: String?

    enum ShopCategory: String, CaseIterable {
        case fish = "Fish"
        case decorations = "Decorations"
        case tanks = "Tanks"

        var icon: String {
            switch self {
            case .fish: return "fish"
            case .decorations: return "paintbrush.fill"
            case .tanks: return "square.split.bottomrightquarter.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Category picker
            Picker("Category", selection: $selectedCategory) {
                ForEach(ShopCategory.allCases, id: \.self) { category in
                    Label(category.rawValue, systemImage: category.icon)
                        .tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Content
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    switch selectedCategory {
                    case .fish:
                        fishShopGrid
                    case .decorations:
                        decorationShopGrid
                    case .tanks:
                        tankShopGrid
                    }
                }
                .padding(.horizontal)
            }

            // Pro upgrade banner
            if !storeKit.isPro {
                proBanner
            }
        }
        .navigationTitle("Shop")
        .sheet(isPresented: $showProUpgrade) {
            ProUpgradeView()
        }
        .overlay(alignment: .top) {
            if let message = purchaseMessage {
                Text(message)
                    .font(.caption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { purchaseMessage = nil }
                        }
                    }
            }
        }
    }

    // MARK: - Fish Shop

    private var fishShopGrid: some View {
        ForEach(FishSpecies.all, id: \.id) { species in
            FishSpeciesCard(species: species, isOwned: isFishOwned(species), isPro: storeKit.isPro) {
                purchaseFish(species)
            }
        }
    }

    // MARK: - Decoration Shop

    private var decorationShopGrid: some View {
        ForEach(TankDecoration.all, id: \.id) { decoration in
            DecorationCard(decoration: decoration, isOwned: isDecorationOwned(decoration), isPro: storeKit.isPro) {
                purchaseDecoration(decoration)
            }
        }
    }

    // MARK: - Tank Shop

    private var tankShopGrid: some View {
        ForEach(Tank.TankBackground.allCases, id: \.rawValue) { background in
            TankBackgroundCard(background: background, isOwned: isTankOwned(background), isPro: storeKit.isPro) {
                purchaseTank(background)
            }
        }
    }

    // MARK: - Pro Banner

    private var proBanner: some View {
        Button {
            showProUpgrade = true
        } label: {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                Text("Unlock all species, tanks & decorations")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(LinearGradient(colors: [.purple.opacity(0.8), .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.white)
        }
    }

    // MARK: - Purchase Logic

    private func isFishOwned(_ species: FishSpecies) -> Bool {
        persistence.fish.contains { $0.speciesID == species.id }
    }

    private func isDecorationOwned(_ decoration: TankDecoration) -> Bool {
        guard let tank = persistence.selectedTank else { return false }
        return tank.decorations.contains { $0.id == decoration.id && $0.isPlaced }
    }

    private func isTankOwned(_ background: Tank.TankBackground) -> Bool {
        persistence.tanks.contains { $0.background == background }
    }

    private func purchaseFish(_ species: FishSpecies) {
        if species.isPro && !storeKit.isPro {
            showProUpgrade = true
            return
        }

        // Check if we already have this species
        if isFishOwned(species) {
            purchaseMessage = "You already have a \(species.displayName)!"
            return
        }

        let newFish = Fish(
            name: species.displayName,
            speciesID: species.id,
            state: .idle,
            happiness: 0.8,
            hungerLevel: 0,
            positionX: Double.random(in: 0.2...0.8),
            positionY: Double.random(in: 0.2...0.8)
        )
        persistence.addFish(newFish)
        behaviorEngine.startMonitoring(fish: newFish)
        purchaseMessage = "Added \(species.displayName) to your tank! 🐟"
        WidgetDataProvider.shared.refreshWidgets()
    }

    private func purchaseDecoration(_ decoration: TankDecoration) {
        if decoration.isPro && !storeKit.isPro {
            showProUpgrade = true
            return
        }

        guard var tank = persistence.selectedTank else { return }
        if tank.decorations.count >= tank.maxDecorations {
            purchaseMessage = "Tank is full! Remove some decorations."
            return
        }

        var newDecoration = decoration
        newDecoration.isPlaced = true
        newDecoration.positionX = Double.random(in: 0.1...0.9)
        newDecoration.positionY = Double.random(in: 0.3...0.8)
        tank.decorations.append(newDecoration)
        persistence.updateTank(tank)
        purchaseMessage = "Placed \(decoration.name)! 🎨"
    }

    private func purchaseTank(_ background: Tank.TankBackground) {
        if background != .basicBlue && !storeKit.isPro {
            showProUpgrade = true
            return
        }

        if isTankOwned(background) {
            // Switch to this tank
            if let tank = persistence.tanks.first(where: { $0.background == background }) {
                persistence.selectTank(id: tank.id)
                purchaseMessage = "Switched to \(background.displayName) tank!"
            }
            return
        }

        let newTank = Tank(
            name: "\(background.displayName) Tank",
            background: background
        )
        persistence.addTank(newTank)
        purchaseMessage = "Unlocked \(background.displayName) tank! 🎉"
    }
}

// MARK: - Shop Cards

struct FishSpeciesCard: View {
    let species: FishSpecies
    let isOwned: Bool
    let isPro: Bool
    let onPurchase: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(species.emoji)
                .font(.system(size: 40))

            Text(species.displayName)
                .font(.headline)

            Text(species.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if species.isPro {
                Label("Pro", systemImage: "crown.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }

            Button(action: onPurchase) {
                if isOwned {
                    Label("Owned", systemImage: "checkmark")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                } else if species.isPro && !isPro {
                    Label("Pro", systemImage: "lock.fill")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Add to Tank")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isOwned ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
            .cornerRadius(8)
            .disabled(isOwned)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }
}

struct DecorationCard: View {
    let decoration: TankDecoration
    let isOwned: Bool
    let isPro: Bool
    let onPurchase: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(decoration.type.emoji)
                .font(.system(size: 40))

            Text(decoration.name)
                .font(.headline)

            if decoration.isPro {
                Label("Pro", systemImage: "crown.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }

            Button(action: onPurchase) {
                if isOwned {
                    Label("Placed", systemImage: "checkmark")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                } else if decoration.isPro && !isPro {
                    Label("Pro", systemImage: "lock.fill")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Place")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isOwned ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
            .cornerRadius(8)
            .disabled(isOwned)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }
}

struct TankBackgroundCard: View {
    let background: Tank.TankBackground
    let isOwned: Bool
    let isPro: Bool
    let onPurchase: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(tankColor(background))
                .frame(width: 40, height: 40)

            Text(background.displayName)
                .font(.headline)

            if background != .basicBlue {
                Label("Pro", systemImage: "crown.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            } else {
                Text("Free")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            Button(action: onPurchase) {
                if isOwned {
                    Label("Owned", systemImage: "checkmark")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                } else if background != .basicBlue && !isPro {
                    Label("Pro", systemImage: "lock.fill")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Unlock")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isOwned ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
            .cornerRadius(8)
            .disabled(isOwned)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }

    private func tankColor(_ background: Tank.TankBackground) -> Color {
        switch background {
        case .basicBlue: return .cyan
        case .reef: return .teal
        case .darkWater: return .indigo
        case .planted: return .green
        case .castleRuins: return .brown
        case .space: return .purple
        }
    }
}
