import SwiftUI

struct ContentView: View {
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var storeKit: StoreKitManager

    @State private var selectedTab: Tab = .aquarium
    @State private var showProUpgrade = false
    @State private var showSettings = false

    enum Tab: String, CaseIterable {
        case aquarium = "Aquarium"
        case hatchery = "Hatchery"
        case shop = "Shop"
        case breeding = "Breeding"

        var icon: String {
            switch self {
            case .aquarium: return "fish"
            case .hatchery: return "egg"
            case .shop: return "cart"
            case .breeding: return "heart"
            }
        }
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                AquariumMainView()
                    .tabItem {
                        Label(Tab.aquarium.rawValue, systemImage: Tab.aquarium.icon)
                    }
                    .tag(Tab.aquarium)

                HatcheryView()
                    .tabItem {
                        Label(Tab.hatchery.rawValue, systemImage: Tab.hatchery.icon)
                    }
                    .tag(Tab.hatchery)

                BreedingView()
                    .tabItem {
                        Label(Tab.breeding.rawValue, systemImage: Tab.breeding.icon)
                    }
                    .tag(Tab.breeding)

                ShopView()
                    .tabItem {
                        Label(Tab.shop.rawValue, systemImage: Tab.shop.icon)
                    }
                    .tag(Tab.shop)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showProUpgrade) {
                ProUpgradeView()
            }
            .onChange(of: storeKit.isPro) { _, newValue in
                if !newValue && persistence.fish.count > 1 {
                    // Downgrade scenario — show pro upgrade
                    showProUpgrade = true
                }
            }
        }
    }
}
