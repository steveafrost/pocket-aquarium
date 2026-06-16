import SwiftUI

/// Main tank view — full-screen aquarium with animated fish, bubbles, and decorations
struct AquariumMainView: View {
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var behaviorEngine: FishBehaviorEngine
    @EnvironmentObject var animationEngine: AnimationEngine
    @EnvironmentObject var phoneMonitor: PhoneStateMonitor
    @EnvironmentObject var storeKit: StoreKitManager

    @State private var showFishDetail: Bool = false
    @State private var selectedFish: Fish?
    @State private var tankSize: CGSize = .zero
    @State private var showFeedAnimation: UUID?
    @State private var showPetAnimation: UUID?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Tank background
                tankBackground
                    .ignoresSafeArea()

                // Water overlay
                waterOverlay

                // Decorations
                decorationsLayer

                // Bubbles
                bubblesLayer

                // Fish layer
                fishLayer

                // Status overlay
                VStack {
                    Spacer()
                    statusBar
                }

                // Tap to feed prompt
                if persistence.fish.isEmpty {
                    emptyTankOverlay
                }
            }
            .onAppear {
                tankSize = geometry.size
                startAnimations(tankSize: geometry.size)
            }
            .onChange(of: persistence.fish) { _, _ in
                restartAnimations(tankSize: geometry.size)
            }
            .onChange(of: phoneMonitor.currentState) { _, newState in
                handlePhoneStateChange(newState)
            }
            .onTapGesture { location in
                handleTap(at: location)
            }
        }
    }

    // MARK: - Tank Background

    private var tankBackground: some View {
        let tank = persistence.selectedTank ?? Tank.defaultTank
        return Group {
            switch tank.background {
            case .basicBlue:
                LinearGradient(
                    gradient: Gradient(colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .reef:
                LinearGradient(
                    gradient: Gradient(colors: [Color.teal.opacity(0.5), Color.blue.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .darkWater:
                LinearGradient(
                    gradient: Gradient(colors: [Color.indigo.opacity(0.7), Color.black.opacity(0.9)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .planted:
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.4), Color.blue.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .castleRuins:
                LinearGradient(
                    gradient: Gradient(colors: [Color.brown.opacity(0.5), Color.gray.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .space:
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.black.opacity(0.9)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private var waterOverlay: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .ignoresSafeArea()
    }

    // MARK: - Decorations

    private var decorationsLayer: some View {
        let tank = persistence.selectedTank ?? Tank.defaultTank
        return ForEach(tank.decorations.filter { $0.isPlaced }, id: \.id) { decoration in
            Text(decoration.type.emoji)
                .font(.system(size: CGFloat(decoration.scale * 30)))
                .position(
                    x: decoration.positionX * tankSize.width,
                    y: decoration.positionY * tankSize.height
                )
        }
    }

    // MARK: - Bubbles

    private var bubblesLayer: some View {
        ForEach(animationEngine.bubbles, id: \.id) { bubble in
            Circle()
                .fill(Color.white.opacity(bubble.opacity))
                .frame(width: bubble.size, height: bubble.size)
                .position(bubble.position)
                .animation(.linear(duration: bubble.speed * 2), value: bubble.position)
        }
    }

    // MARK: - Fish Layer

    private var fishLayer: some View {
        ForEach(persistence.fish, id: \.id) { fish in
            fishView(for: fish)
        }
    }

    @ViewBuilder
    private func fishView(for fish: Fish) -> some View {
        let renderState = animationEngine.fishPositions[fish.id]

        ZStack {
            // Fish body (using emoji as placeholder)
            Text(fishSpeciesEmoji(fish.speciesID))
                .font(.system(size: 40 * CGFloat(fish.size)))
                .rotationEffect(.radians(renderState?.swimAngle ?? 0))
                .scaleEffect(x: abs(cos(renderState?.swimAngle ?? 0)) > 0 ? 1 : -1, y: 1)
                .overlay(
                    // Morph indicator
                    Text(fish.morph.emoji)
                        .font(.system(size: 12))
                        .offset(x: 15, y: -15)
                )

            // State indicator
            if fish.state == .sleeping {
                Text("💤")
                    .font(.system(size: 14))
                    .offset(y: -30)
            } else if fish.state == .lonely {
                Text("😢")
                    .font(.system(size: 14))
                    .offset(y: -30)
            }

            // Feed/pet animation
            if showFeedAnimation == fish.id {
                Text("🍕")
                    .font(.system(size: 20))
                    .offset(y: -25)
                    .transition(.scale.combined(with: .opacity))
            }
            if showPetAnimation == fish.id {
                Text("❤️")
                    .font(.system(size: 20))
                    .offset(y: -25)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .position(
            x: renderState?.position.x ?? fish.positionX * tankSize.width,
            y: renderState?.position.y ?? fish.positionY * tankSize.height
        )
        .onTapGesture {
            selectedFish = fish
            showFishDetail = true
        }
        .sheet(isPresented: $showFishDetail) {
            if let fish = selectedFish {
                FishDetailView(fish: fish)
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            if let fish = persistence.fish.first {
                VStack(alignment: .leading, spacing: 2) {
                    // Happiness bar
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.caption)
                        ProgressView(value: fish.happiness, total: 1.0)
                            .tint(.pink)
                            .frame(width: 60)
                    }

                    // Hunger bar
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        ProgressView(value: fish.hungerLevel, total: 1.0)
                            .tint(.orange)
                            .frame(width: 60)
                    }
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(10)

                Spacer()

                // Fish count / Pro indicator
                HStack(spacing: 4) {
                    Text("\(persistence.fish.count)")
                        .font(.caption)
                        .foregroundColor(.white)
                    Image(systemName: storeKit.isPro ? "crown.fill" : "fish")
                        .font(.caption)
                        .foregroundColor(storeKit.isPro ? .yellow : .white)
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Empty Tank

    private var emptyTankOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "fish")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))
            Text("Tap to add your first fish!")
                .foregroundColor(.white.opacity(0.7))
                .font(.headline)
            Text("Start with a free Goldfish")
                .foregroundColor(.white.opacity(0.5))
                .font(.subheadline)
        }
        .onTapGesture {
            addStarterFish()
        }
    }

    // MARK: - Actions

    private func addStarterFish() {
        let starterFish = Fish(
            name: "Goldie",
            speciesID: "goldfish",
            state: .idle,
            happiness: 0.8,
            positionX: 0.5,
            positionY: 0.5,
            targetX: 0.6,
            targetY: 0.4
        )
        persistence.addFish(starterFish)
        behaviorEngine.startMonitoring(fish: starterFish)
        animationEngine.startAnimating(fish: starterFish, tankSize: tankSize)
        WidgetDataProvider.shared.refreshWidgets()
    }

    private func handleTap(at location: CGPoint) {
        guard !persistence.fish.isEmpty else {
            addStarterFish()
            return
        }

        // Feed the nearest fish
        if let fish = persistence.fish.first {
            let fishX = animationEngine.fishPositions[fish.id]?.position.x ?? fish.positionX * tankSize.width
            let fishY = animationEngine.fishPositions[fish.id]?.position.y ?? fish.positionY * tankSize.height
            let distance = sqrt(pow(location.x - fishX, 2) + pow(location.y - fishY, 2))

            if distance < 60 {
                // Tap on fish — pet and feed
                behaviorEngine.pet(fishID: fish.id)
                behaviorEngine.feed(fishID: fish.id)

                withAnimation(.easeInOut(duration: 0.3)) {
                    showPetAnimation = fish.id
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showPetAnimation = nil
                }
            } else {
                // Tap elsewhere — feed
                behaviorEngine.feed(fishID: fish.id)
                withAnimation(.easeInOut(duration: 0.3)) {
                    showFeedAnimation = fish.id
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showFeedAnimation = nil
                }
            }
        }
    }

    private func handlePhoneStateChange(_ state: PhoneStateMonitor.PhoneState) {
        for fish in persistence.fish {
            switch state {
            case .charging:
                animationEngine.applyPhoneReaction(fishID: fish.id, reaction: .chargeNap)
            case .pickedUp:
                animationEngine.applyPhoneReaction(fishID: fish.id, reaction: .excitedBurst)
            case .night:
                animationEngine.applyPhoneReaction(fishID: fish.id, reaction: .sleepyDrift)
            case .daytime, .stationary:
                break
            }
        }
    }

    private func startAnimations(tankSize: CGSize) {
        for fish in persistence.fish {
            animationEngine.startAnimating(fish: fish, tankSize: tankSize)
        }
    }

    private func restartAnimations(tankSize: CGSize) {
        for fish in persistence.fish {
            animationEngine.stopAnimating(fishID: fish.id)
            animationEngine.startAnimating(fish: fish, tankSize: tankSize)
        }
    }

    // MARK: - Helpers

    private func fishSpeciesEmoji(_ speciesID: String) -> String {
        FishSpecies.all.first { $0.id == speciesID }?.emoji ?? "🐠"
    }
}
