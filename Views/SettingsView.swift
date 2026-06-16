import SwiftUI

/// Settings view — app configuration, sounds, notifications, about
struct SettingsView: View {
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var storeKit: StoreKitManager
    @EnvironmentObject var notificationService: NotificationService
    @Environment(\.dismiss) var dismiss

    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var showProUpgrade = false

    var body: some View {
        NavigationStack {
            Form {
                // Pro section
                Section {
                    if storeKit.isPro {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("Pro Unlocked")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                        }
                    } else {
                        Button {
                            showProUpgrade = true
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                VStack(alignment: .leading) {
                                    Text("Upgrade to Pro")
                                        .fontWeight(.semibold)
                                    Text("$4.99 — one time")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Label("Pocket Aquarium Pro", systemImage: "crown.fill")
                }

                // Purchase management
                Section("Purchase") {
                    Button("Restore Purchases") {
                        Task {
                            await storeKit.restorePurchases()
                            restoreMessage = storeKit.isPro ? "Purchases restored! 🎉" : "No purchases found."
                            showRestoreAlert = true
                        }
                    }

                    Button("Manage Subscriptions") {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(.blue)
                }

                // Notifications
                Section("Notifications") {
                    Toggle("Lonely Fish Reminders", isOn: .constant(notificationService.authorizationGranted))
                        .onChange(of: notificationService.authorizationGranted) { _, newValue in
                            if newValue {
                                notificationService.requestAuthorization()
                            }
                        }

                    Toggle("Hatching Alerts", isOn: .constant(true))

                    Toggle("Growth Updates", isOn: .constant(true))
                }

                // Sounds
                Section("Sounds") {
                    Toggle("Ambient Water Sounds", isOn: .constant(true))
                        .disabled(!storeKit.isPro)

                    Toggle("Bubble Effects", isOn: .constant(true))

                    Toggle("Notification Sounds", isOn: .constant(true))
                }

                // Tank
                Section("Tank") {
                    Picker("Default Background", selection: .constant("basicBlue")) {
                        ForEach(Tank.TankBackground.allCases, id: \.rawValue) { bg in
                            Text(bg.displayName).tag(bg.rawValue)
                        }
                    }

                    Stepper("Max Decorations: \(5)", value: .constant(5), in: 1...10)
                }

                // Fish
                Section("Fish") {
                    Button("Release All Fish") {
                        for fish in persistence.fish {
                            persistence.removeFish(id: fish.id)
                        }
                    }
                    .foregroundColor(.red)

                    Button("Reset All Data") {
                        // Clear everything
                        let domain = Bundle.main.bundleIdentifier ?? "com.pocketaquarium"
                        UserDefaults.standard.removePersistentDomain(forName: domain)
                        // Force reload
                        persistence.fish = []
                        persistence.tanks = [Tank.defaultTank]
                    }
                    .foregroundColor(.red)
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link("Privacy Policy", destination: URL(string: "https://pocketaquarium.app/privacy")!)

                    Link("Terms of Service", destination: URL(string: "https://pocketaquarium.app/terms")!)

                    Link("Support", destination: URL(string: "https://pocketaquarium.app/support")!)
                }

                Section {
                    Text("Made with 🐠 by Pocket Aquarium")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK") {}
            } message: {
                Text(restoreMessage)
            }
            .sheet(isPresented: $showProUpgrade) {
                ProUpgradeView()
            }
        }
    }
}
