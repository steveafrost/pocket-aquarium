# Pocket Aquarium — AGENTS.md

## Project Architecture

A complete iOS 17+ SwiftUI app: a virtual pet fish living in your Dynamic Island, Lock Screen, or Home Screen widget. Built with SwiftUI, SpriteKit (animation engine), ActivityKit (Dynamic Island), WidgetKit, Core Data/UserDefaults, Core Motion, and StoreKit 2.

## What's Built — File Inventory

### `App/`
- **`PocketAquariumApp.swift`** — App entry point. Sets up global environment objects (persistence, StoreKit, notifications, behavior engine, phone monitor). Starts monitoring on launch.
- **`ContentView.swift`** — Root tab view with 4 tabs (Aquarium, Hatchery, Breeding, Shop) + Settings sheet + Pro upgrade sheet.

### `Models/`
- **`Fish.swift`** — Core fish entity: all properties (id, name, species, morph, hue/sat/brightness, size, age, state, happiness, hunger, breeding, position). Computed properties for display values with morph color effects.
- **`FishSpecies.swift`** — 6 species: Goldfish (free), Betta, Clownfish, Angelfish, Seahorse, Jellyfish (Pro). Each with emoji, swim speed, fin style, color ranges, hunger interval.
- **`FishMorph.swift`** — 5 morphs: Normal, Albino (1%), Neon (2%), Galaxy (0.5%), Gold (3%). Each applies color transformations (hue shift, saturation/brightness override).
- **`FishState.swift`** — Enum: idle, eating, sleeping, excited, lonely. With display name, emoji, and behavior flags.
- **`Tank.swift`** — Tank environment with 6 backgrounds (Basic Blue + 5 Pro). Decoration slot system.
- **`TankDecoration.swift`** — 10 decorations (3 free, 7 Pro). Position/scale placement.
- **`ProUnlockManager.swift`** — UserDefaults-persisted Pro state. Feature access control.

### `Services/`
- **`FishBehaviorEngine.swift`** — Timer-driven state machine. Transitions: idle ↔ eating ↔ sleeping ↔ excited ↔ lonely. Reacts to time since fed, time of day (10pm-7am sleep), phone state. Updates hunger/happiness/growth continuously. Lonely notifications.
- **`BreedingEngine.swift`** — Pair selection → compatibility check → 8h egg timer → baby fish. Color inheritance with weighted random mutation (Albino 1%, Neon 2%, Galaxy 0.5%, Gold 3%). 24h breeding cooldown. Persistence via UserDefaults.
- **`AnimationEngine.swift`** — Per-fish animation timer (~30fps). Smooth target-seeking movement with random waypoints. Speed varies by species/state. Phone reactions: excited burst (3x speed), sleepy drift (0.3x), charge nap (near glass). Bubble particle generator.
- **`DynamicIslandManager.swift`** — Live Activity via ActivityKit (iOS 16.1+). Shows fish name, species, state, happiness, hunger in Dynamic Island. Updates on state change.
- **`WidgetDataProvider.swift`** — Shared data source for FishWidget. Timeline entry with fish state for WidgetKit refresh.
- **`NotificationService.swift`** — UNUserNotificationCenter wrapper. Scheduling for lonely reminders, hatching alerts, growth updates.
- **`PhoneStateMonitor.swift`** — Monitors: UIDevice batteryState (charging), CMMotionManager accelerometer (pickup detection, >1.8g threshold), NSCalendar time-of-day (night 10pm-7am). Publishes combined PhoneState enum.
- **`StoreKitManager.swift`** — StoreKit 2 purchase/restore for com.pocketaquarium.pro.unlock ($4.99). Transaction verification via `.currentEntitlements`.
- **`PersistenceService.swift`** — UserDefaults-backed JSON store for fish list, tanks, selected tank. Codable serialization. Free user limited to 1 fish.

### `Views/`
- **`AquariumMainView.swift`** — Full-screen tank with gradient background, decorations, bubbles, fish animation overlay. Tap to feed/pet nearest fish. Empty state adds starter Goldfish. Reacts to phone state changes. Status bars for happiness/hunger.
- **`FishDetailView.swift`** — Fish profile: species display, morph badge, stat bars (happiness/hunger/size/state), growth progress, feed/pet/rename actions, state description, release button.
- **`ShopView.swift`** — Tabbed shop (Fish/Decorations/Tanks) with LazyVGrid. Species cards, decoration cards, tank background cards. Purchase/add logic with Pro gating. Pro upgrade banner.
- **`BreedingView.swift`** — Parent selection via SwiftUI sheet picker. Compatibility check display. Active breeding timers with ProgressView. Hatched eggs list. Pro requirement banner. Breeding info section.
- **`FishReactionView.swift`** — Animated overlay showing phone state reactions: charging (bolt+nap), pickup (excited zoomies), night (sleepy moon), daytime (active sun).
- **`HatcheryView.swift`** — Egg incubation display with countdown timers. Recently hatched list. Baby fish tracking with growth progress. Full fish roster.
- **`SettingsView.swift`** — Pro status, restore purchases, notification toggles, sound toggles, tank config, data reset, app info.
- **`ProUpgradeView.swift`** — Feature list carousel, $4.99 price display, StoreKit purchase button with loading state, restore purchases, fine print.

### `Widgets/`
- **`FishWidget.swift`** — StaticConfiguration widget supporting systemSmall (tank + fish + state), systemMedium (fish + stat bars), accessoryCircular (Lock Screen), accessoryRectangular (Lock Screen). 30-min refresh timeline.
- **`WidgetBundle.swift`** — @main entry point registering FishWidget.

### `Resources/`
- **`Assets.xcassets/`** — Placeholder asset catalog (needs app icon, accent color, custom fish sprites).
- **`PocketAquarium.entitlements`** — Code signing entitlements (App Groups for widget data sharing).
- **`Info.plist`** — App Info.plist used by the Xcode project.

### `APP_STORE_CONNECT.md`
- App Store Connect setup guide with pricing, IAP config, screenshots list, privacy notes, TestFlight reminders, and a distribution checklist.

## State Machine

```
Idle ──(4h unfed)──→ Lonely
Idle ──(night)──→ Sleeping
Idle ──(phone pickup)──→ Excited
Idle ──(feed)──→ Eating
Idle ──(charge)──→ Sleeping (nap)
Lonely ──(feed/pet)──→ Idle
Sleeping ──(daytime)──→ Idle
Excited ──(15s timeout)──→ Idle
Eating ──(30s timeout)──→ Idle
```

Timer checks every 60 seconds. Hunger increases continuously based on `baseHungerInterval`. Happiness decays after 2h without interaction. Growth occurs when fed + happy.

## What Needs Real Device / Entitlements

These features require real provisioning and can't be fully tested in the simulator:

1. **Dynamic Island** (ActivityKit) — Requires iOS 16.1+ physical device with Dynamic Island. Add `com.apple.developer.associated-domains` entitlement for Live Activities.
2. **Widgets** (WidgetKit) — Need a Widget Extension target in Xcode. The Swift files are ready but need proper target membership.
3. **In-App Purchase** (StoreKit 2) — Requires App Store Connect product setup (`com.pocketaquarium.pro.unlock`), paid applications agreement, and StoreKit configuration file or StoreKit Testing in Xcode.
4. **Notifications** (UserNotifications) — Requires capability entitlement and real device for push.
5. **Core Motion** (Accelerometer) — Works on real device; simulator returns no data.
6. **SpriteKit rendering** — The animation engine uses SwiftUI position-based rendering (emoji fish). For production, replace with SKScene/SKSpriteNode for proper fish sprites.

## Xcode Project Setup

The current code is a collection of Swift source files. To build:

1. Create a new Xcode project: iOS → App → SwiftUI, iOS 17.0+
2. Add files maintaining directory structure
3. Add Widget Extension target (check "Include Configuration Intent")
4. Capabilities:
   - App Groups (for widget data sharing)
   - In-App Purchase
   - Push Notifications
   - Background Modes (Core Motion)
5. Add StoreKit configuration file for local testing
6. Configure `Info.plist` with `NSCoreMotionUsageDescription`

## Next Steps to Ship

1. **Set up Xcode project** with proper bundle identifier `com.pocketaquarium`
2. **Create asset catalog** with app icon, accent colors, fish sprites (SVG/PDF)
3. **Replace emoji fish** with proper SpriteKit animation assets or SF Symbols
4. **Configure StoreKit** — Create product in App Store Connect, add StoreKit config for testing
5. **Test Dynamic Island** — Requires iOS 16.1+ device with island
6. **Add Core Data** — Replace UserDefaults persistence with Core Data for better performance with many fish
7. **Add sound effects** — AVFoundation ambient water loop, bubble sounds, notification sounds
8. **Add share cards** — Generate shareable images of rare morphs with UIActivityViewController
9. **Localize** — Add Localizable.strings for at least English
10. **UITest coverage** — Add XCUITest for core flows
11. **Submit to App Store** — Screenshots, app preview, privacy policy, terms

## Development Phases

| Phase | Scope | Dependencies |
|-------|-------|--------------|
| 1. Core | Fish model, state machine, tank view, persistence | None |
| 2. Engagement | Feeding, petting, notifications, phone state | Core Motion entitlement |
| 3. Monetization | StoreKit, Pro upgrade, feature gating | App Store Connect product |
| 4. Widgets | Lock Screen, Home Screen widget | App Groups entitlement |
| 5. Breeding | Genetics, egg timer, hatchery | Core complete |
| 6. Dynamic Island | Live Activity, compact/expanded views | iOS 16.1+ device |
| 7. Polish | Sprites, sounds, animations, share cards | Design assets |
| 8. Ship | Testing, localization, App Store submission | All of the above |

## Key Design Decisions

- **Emoji fish** during development — allows rapid iteration without art assets
- **UserDefaults + Codable** for persistence — simpler than Core Data for <50 fish
- **Timer-based behavior engine** — no SpriteKit physics needed for state machine
- **Per-fish animation timer** — lightweight, no SKScene overhead
- **Pro as one-time purchase** — better UX than subscription for a virtual pet
- **Free: 1 goldfish, 1 tank** — enough for users to try before buying

## Git

Repository: `git@github.com:steveafrost/pocket-aquarium.git`
Branch: `main`
Initial commit: "Initial build: full Pocket Aquarium iOS app"
