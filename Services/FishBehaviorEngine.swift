import Foundation
import Combine

/// State machine engine that drives fish behavior transitions.
/// Timer-driven, reacts to phone state and user interaction.
class FishBehaviorEngine: ObservableObject {
    static let shared = FishBehaviorEngine()

    @Published var fishStates: [UUID: FishState] = [:]

    private var timers: [UUID: Timer] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let engine = DispatchQueue(label: "com.pocketaquarium.behavior", qos: .utility)

    // Thresholds
    private let lonelyThreshold: TimeInterval = 4 * 3600  // 4 hours
    private let hungryThreshold: TimeInterval = 3 * 3600   // 3 hours
    private let sleepStartHour = 22  // 10 PM
    private let sleepEndHour = 7     // 7 AM
    private let stateCheckInterval: TimeInterval = 60      // check every 60 seconds

    private init() {
        observePhoneState()
    }

    // MARK: - Public API

    /// Start the behavior engine for a specific fish
    func startMonitoring(fish: Fish) {
        engine.async { [weak self] in
            guard let self = self else { return }
            self.stopTimer(for: fish.id)

            DispatchQueue.main.async {
                self.fishStates[fish.id] = fish.state
            }

            let timer = Timer.scheduledTimer(
                timeInterval: self.stateCheckInterval,
                target: self,
                selector: #selector(self.checkState(_:)),
                userInfo: fish.id,
                repeats: true
            )
            RunLoop.main.add(timer, forMode: .common)
            self.timers[fish.id] = timer
        }
    }

    /// Stop monitoring a fish
    func stopMonitoring(fishID: UUID) {
        stopTimer(for: fishID)
        DispatchQueue.main.async {
            self.fishStates.removeValue(forKey: fishID)
        }
    }

    /// Resume all fish on app start
    func resumeAllFish() {
        let fishList = PersistenceService.shared.fish
        for fish in fishList {
            startMonitoring(fish: fish)
        }
    }

    /// Feed a fish — resets hunger, transitions to eating state briefly
    func feed(fishID: UUID) {
        var fish = PersistenceService.shared.fish(with: fishID)
        fish?.lastFedDate = Date()
        fish?.hungerLevel = 0.0
        fish?.state = .eating
        fish?.happiness = min((fish?.happiness ?? 0.8) + 0.1, 1.0)
        if var updated = fish {
            PersistenceService.shared.updateFish(updated)
        }

        DispatchQueue.main.async {
            self.fishStates[fishID] = .eating
        }

        // After 30 seconds, return to idle
        DispatchQueue.global().asyncAfter(deadline: .now() + 30) { [weak self] in
            guard let self = self else { return }
            var fish = PersistenceService.shared.fish(with: fishID)
            if fish?.state == .eating {
                fish?.state = .idle
                if var updated = fish {
                    PersistenceService.shared.updateFish(updated)
                }
                DispatchQueue.main.async {
                    self.fishStates[fishID] = .idle
                }
            }
        }
    }

    /// Pet/interact with fish — boosts happiness
    func pet(fishID: UUID) {
        var fish = PersistenceService.shared.fish(with: fishID)
        fish?.lastInteractionDate = Date()
        fish?.happiness = min((fish?.happiness ?? 0.8) + 0.15, 1.0)

        // Brief excited state
        let previousState = fish?.state ?? .idle
        fish?.state = .excited
        if var updated = fish {
            PersistenceService.shared.updateFish(updated)
        }

        DispatchQueue.main.async {
            self.fishStates[fishID] = .excited
        }

        // Return to idle after 10 seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [weak self] in
            var fish = PersistenceService.shared.fish(with: fishID)
            if fish?.state == .excited {
                fish?.state = previousState == .excited ? .idle : previousState
                if var updated = fish {
                    PersistenceService.shared.updateFish(updated)
                }
                DispatchQueue.main.async {
                    self.fishStates[fishID] = updated?.state ?? .idle
                }
            }
        }
    }

    /// Force a state transition (e.g., from phone pick-up)
    func transition(fishID: UUID, to state: FishState, duration: TimeInterval = 15) {
        var fish = PersistenceService.shared.fish(with: fishID)
        fish?.state = state
        if var updated = fish {
            PersistenceService.shared.updateFish(updated)
        }

        DispatchQueue.main.async {
            self.fishStates[fishID] = state
        }

        // Auto-revert after duration
        DispatchQueue.global().asyncAfter(deadline: .now() + duration) { [weak self] in
            var fish = PersistenceService.shared.fish(with: fishID)
            if fish?.state == state {
                fish?.state = .idle
                if var updated = fish {
                    PersistenceService.shared.updateFish(updated)
                }
                DispatchQueue.main.async {
                    self.fishStates[fishID] = .idle
                }
            }
        }
    }

    // MARK: - Timer Callback

    @objc private func checkState(_ timer: Timer) {
        guard let fishID = timer.userInfo as? UUID else { return }
        guard var fish = PersistenceService.shared.fish(with: fishID) else {
            stopTimer(for: fishID)
            return
        }

        let newState = computeNextState(for: &fish)
        if newState != fish.state {
            fish.state = newState
            PersistenceService.shared.updateFish(fish)
            DispatchQueue.main.async {
                self.fishStates[fishID] = newState
            }
            notifyIfNeeded(fishID: fishID, state: newState)
        }

        // Update hunger and happiness continuously
        updateHungerAndHappiness(for: &fish)
        PersistenceService.shared.updateFish(fish)
    }

    // MARK: - State Machine Logic

    private func computeNextState(for fish: inout Fish) -> FishState {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        // 1. Night time → sleeping
        if hour >= sleepStartHour || hour < sleepEndHour {
            return .sleeping
        }

        // 2. Check if lonely (unfed > 4h or un-interacted > 8h)
        if let hoursSinceFed = fish.hoursSinceLastFed, hoursSinceFed >= 4 {
            return .lonely
        }
        if let hoursSinceInteraction = fish.hoursSinceLastInteraction, hoursSinceInteraction >= 8 {
            return .lonely
        }

        // 3. If currently eating or excited, maintain state
        if fish.state == .eating || fish.state == .excited {
            return fish.state
        }

        // 4. Default to idle
        return .idle
    }

    private func updateHungerAndHappiness(for fish: inout Fish) {
        // Hunger increases over time
        if let lastFed = fish.lastFedDate {
            let elapsed = Date().timeIntervalSince(lastFed)
            fish.hungerLevel = min(elapsed / (fish.species?.baseHungerInterval ?? 4) / 3600.0, 1.0)
        } else {
            // Never fed — get hungry
            fish.hungerLevel = min(fish.hungerLevel + 0.01, 1.0)
        }

        // Happiness decays slowly
        if let lastInteraction = fish.lastInteractionDate {
            let hoursSinceInteraction = Date().timeIntervalSince(lastInteraction) / 3600.0
            if hoursSinceInteraction > 2 {
                fish.happiness = max(fish.happiness - 0.005, 0.0)
            }
        }

        // Very hungry fish lose happiness
        if fish.hungerLevel > 0.8 {
            fish.happiness = max(fish.happiness - 0.01, 0.0)
        }

        // Growth based on feeding and happiness
        if fish.hungerLevel < 0.3 && fish.happiness > 0.5 {
            fish.size = min(fish.size + 0.001, 1.0)
        }

        fish.age += stateCheckInterval
    }

    // MARK: - Phone State Reactions

    private func observePhoneState() {
        PhoneStateMonitor.shared.$currentState
            .sink { [weak self] phoneState in
                self?.handlePhoneStateChange(phoneState)
            }
            .store(in: &cancellables)
    }

    private func handlePhoneStateChange(_ phoneState: PhoneStateMonitor.PhoneState) {
        let fishList = PersistenceService.shared.fish
        for fish in fishList {
            switch phoneState {
            case .charging:
                // Nap against glass
                transition(fishID: fish.id, to: .sleeping, duration: 120)
            case .pickedUp:
                // Excited burst
                transition(fishID: fish.id, to: .excited, duration: 20)
            case .night:
                // Sleep
                if fish.state != .sleeping {
                    transition(fishID: fish.id, to: .sleeping)
                }
            case .daytime, .stationary:
                // No forced transition, let state machine handle it
                break
            }
        }
    }

    // MARK: - Notifications

    private func notifyIfNeeded(fishID: UUID, state: FishState) {
        let fish = PersistenceService.shared.fish(with: fishID)
        guard let fishName = fish?.name else { return }

        switch state {
        case .lonely:
            NotificationService.shared.scheduleNotification(
                title: "\(fishName) is lonely! 🐠",
                body: "Your fish hasn't been fed in a while. Tap to feed!",
                identifier: "lonely-\(fishID)"
            )
        case .sleeping:
            // Only notify if transitioning to sleep (not already sleeping)
            break
        default:
            break
        }
    }

    // MARK: - Helpers

    private func stopTimer(for fishID: UUID) {
        timers[fishID]?.invalidate()
        timers.removeValue(forKey: fishID)
    }

    deinit {
        timers.values.forEach { $0.invalidate() }
        cancellables.removeAll()
    }
}
