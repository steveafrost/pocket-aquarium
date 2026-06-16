import Foundation
import SwiftUI

/// SpriteKit-based animation engine for fish movement, swimming patterns, and state reactions.
/// Uses per-fish animation state to drive smooth swimming behavior.
class AnimationEngine: ObservableObject {
    static let shared = AnimationEngine()

    @Published var fishPositions: [UUID: FishRenderState] = [:]
    @Published var bubbles: [Bubble] = []

    private var displayTimers: [UUID: Timer] = [:]
    private var bubbleTimer: Timer?

    private init() {
        startBubbleGenerator()
    }

    // MARK: - Fish Animation

    /// Start animating a fish with gentle swimming patterns
    func startAnimating(fish: Fish, tankSize: CGSize) {
        let renderState = FishRenderState(
            fishID: fish.id,
            position: CGPoint(x: fish.positionX * tankSize.width, y: fish.positionY * tankSize.height),
            targetPosition: CGPoint(x: fish.targetX * tankSize.width, y: fish.targetY * tankSize.height),
            swimAngle: fish.swimAngle,
            currentSpeed: speciesSpeed(fish.speciesID),
            opacity: 1.0,
            scale: CGFloat(fish.size * 0.8 + 0.2),
            finWavePhase: 0
        )

        DispatchQueue.main.async {
            self.fishPositions[fish.id] = renderState
        }

        let timer = Timer.scheduledTimer(
            timeInterval: 1.0 / 30, // ~30 fps
            target: self,
            selector: #selector(updateFishAnimation(_:)),
            userInfo: FishAnimationContext(fishID: fish.id, tankSize: tankSize),
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        displayTimers[fish.id] = timer
    }

    /// Stop animating a fish
    func stopAnimating(fishID: UUID) {
        displayTimers[fishID]?.invalidate()
        displayTimers.removeValue(forKey: fishID)
        DispatchQueue.main.async {
            self.fishPositions.removeValue(forKey: fishID)
        }
    }

    /// Update a fish's target position (called when fish changes behavior)
    func setTarget(fishID: UUID, targetX: Double, targetY: Double, tankSize: CGSize) {
        guard var state = fishPositions[fishID] else { return }
        state.targetPosition = CGPoint(x: targetX * tankSize.width, y: targetY * tankSize.height)
        DispatchQueue.main.async {
            self.fishPositions[fishID] = state
        }
    }

    /// React to phone state changes (charge, pickup, night)
    func applyPhoneReaction(fishID: UUID, reaction: FishReaction) {
        guard var state = fishPositions[fishID] else { return }

        switch reaction {
        case .excitedBurst:
            state.currentSpeed *= 3.0
            state.opacity = 1.0
            // Speed boost decays
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                guard var s = self.fishPositions[fishID] else { return }
                s.currentSpeed = self.speciesSpeed(nil) // reset to default
                self.fishPositions[fishID] = s
            }
        case .sleepyDrift:
            state.currentSpeed *= 0.3
            state.opacity = 0.7
        case .chargeNap:
            state.currentSpeed = 0.5
            state.targetPosition = CGPoint(x: 50, y: state.position.y) // near glass
            state.opacity = 0.8
        }

        DispatchQueue.main.async {
            self.fishPositions[fishID] = state
        }
    }

    // MARK: - Animation Update

    @objc private func updateFishAnimation(_ timer: Timer) {
        guard let context = timer.userInfo as? FishAnimationContext else { return }
        guard var state = fishPositions[context.fishID] else {
            timer.invalidate()
            return
        }

        // Move toward target
        let dx = state.targetPosition.x - state.position.x
        let dy = state.targetPosition.y - state.position.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance > 5 {
            let speed = state.currentSpeed * 0.016 // ~16ms per frame
            let step = min(speed, distance)
            let ratio = step / max(distance, 0.001)
            state.position.x += dx * ratio
            state.position.y += dy * ratio
            state.swimAngle = atan2(dy, dx)
        } else {
            // Pick a new random target within tank bounds
            let margin: CGFloat = 40
            let tankW = context.tankSize.width - margin * 2
            let tankH = context.tankSize.height - margin * 2
            state.targetPosition = CGPoint(
                x: margin + CGFloat.random(in: 0...tankW),
                y: margin + CGFloat.random(in: 0...tankH)
            )
        }

        // Update fin wave
        state.finWavePhase += 0.1
        if state.finWavePhase > .pi * 2 {
            state.finWavePhase -= .pi * 2
        }

        DispatchQueue.main.async {
            self.fishPositions[context.fishID] = state
        }
    }

    // MARK: - Bubbles

    private func startBubbleGenerator() {
        bubbleTimer = Timer.scheduledTimer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(generateBubble),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func generateBubble() {
        let bubble = Bubble(
            id: UUID(),
            position: CGPoint(
                x: CGFloat.random(in: 20...300),
                y: CGFloat.random(in: 100...300)
            ),
            size: CGFloat.random(in: 3...10),
            speed: Double.random(in: 0.3...1.0),
            opacity: Double.random(in: 0.2...0.5)
        )

        DispatchQueue.main.async {
            self.bubbles.append(bubble)
        }

        // Remove old bubbles
        if bubbles.count > 20 {
            DispatchQueue.main.async {
                self.bubbles.removeFirst(self.bubbles.count - 20)
            }
        }
    }

    // MARK: - Helpers

    private func speciesSpeed(_ speciesID: String?) -> CGFloat {
        guard let id = speciesID,
              let species = FishSpecies.all.first(where: { $0.id == id }) else {
            return 30
        }
        return CGFloat(species.baseSwimSpeed)
    }
}

// MARK: - Supporting Types

struct FishRenderState: Equatable {
    let fishID: UUID
    var position: CGPoint
    var targetPosition: CGPoint
    var swimAngle: Double
    var currentSpeed: CGFloat
    var opacity: Double
    var scale: CGFloat
    var finWavePhase: Double
}

struct Bubble: Identifiable, Equatable {
    let id: UUID
    var position: CGPoint
    let size: CGFloat
    let speed: Double
    let opacity: Double
}

struct FishAnimationContext {
    let fishID: UUID
    let tankSize: CGSize
}

enum FishReaction {
    case excitedBurst
    case sleepyDrift
    case chargeNap
}
