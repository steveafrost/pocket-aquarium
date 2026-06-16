import Foundation
import Combine
import UIKit
import CoreMotion

/// Monitors phone state events: charging, pickup, time of day
class PhoneStateMonitor: ObservableObject {
    static let shared = PhoneStateMonitor()

    @Published var currentState: PhoneState = .stationary
    @Published var isCharging: Bool = false
    @Published var isPickedUp: Bool = false
    @Published var currentHour: Int = Calendar.current.component(.hour, from: Date())

    private var motionManager: CMMotionManager?
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?

    enum PhoneState: Equatable {
        case charging
        case pickedUp
        case night
        case daytime
        case stationary
    }

    private init() {
        motionManager = CMMotionManager()
        observeTimeOfDay()
    }

    // MARK: - Public API

    /// Start monitoring all phone state signals
    func startMonitoring() {
        monitorBatteryState()
        monitorMotion()
        updateTimeOfDay()
        startPeriodicTimeCheck()
    }

    /// Stop monitoring
    func stopMonitoring() {
        timer?.invalidate()
        motionManager?.stopAccelerometerUpdates()
        cancellables.removeAll()
    }

    // MARK: - Battery / Charging

    private func monitorBatteryState() {
        UIDevice.current.isBatteryMonitoringEnabled = true

        // Observe battery state changes via NotificationCenter
        NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryState()
            }
            .store(in: &cancellables)

        // Initial state
        updateBatteryState()
    }

    private func updateBatteryState() {
        let state = UIDevice.current.batteryState
        DispatchQueue.main.async {
            self.isCharging = (state == .charging || state == .full)
            if self.isCharging {
                self.currentState = .charging
            } else {
                self.updateStateBasedOnTime()
            }
        }
    }

    // MARK: - Motion / Pickup Detection

    private func monitorMotion() {
        guard let motionManager = motionManager, motionManager.isAccelerometerAvailable else {
            print("Accelerometer not available")
            return
        }

        motionManager.accelerometerUpdateInterval = 0.5
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }

            let acceleration = data.acceleration
            // Detect pickup: sudden increase in total acceleration magnitude
            let magnitude = sqrt(acceleration.x * acceleration.x +
                                 acceleration.y * acceleration.y +
                                 acceleration.z * acceleration.z)

            // Normal gravity is ~1.0. A pickup creates a spike > 1.5
            let wasPickedUp = magnitude > 1.8
            if wasPickedUp != self?.isPickedUp {
                DispatchQueue.main.async {
                    self?.isPickedUp = wasPickedUp
                    if wasPickedUp {
                        self?.currentState = .pickedUp
                        // Revert to stationary after short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            if self?.currentState == .pickedUp {
                                self?.updateStateBasedOnTime()
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Time of Day

    private func observeTimeOfDay() {
        NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)
            .sink { [weak self] _ in
                self?.updateTimeOfDay()
            }
            .store(in: &cancellables)
    }

    private func startPeriodicTimeCheck() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTimeOfDay()
        }
    }

    private func updateTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())
        DispatchQueue.main.async {
            self.currentHour = hour
            if !self.isCharging && !self.isPickedUp {
                self.updateStateBasedOnTime()
            }
        }
    }

    private func updateStateBasedOnTime() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 22 || hour < 7 {
            currentState = .night
        } else {
            currentState = .daytime
        }
    }

    deinit {
        stopMonitoring()
    }
}
