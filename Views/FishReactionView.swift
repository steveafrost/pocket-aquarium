import SwiftUI

/// Overlay view showing the fish reacting to phone state changes
struct FishReactionView: View {
    @EnvironmentObject var phoneMonitor: PhoneStateMonitor

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()
                reactionContent
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                Spacer()
            }
            .padding(.bottom, 100)
        }
        .animation(.easeInOut(duration: 0.5), value: phoneMonitor.currentState)
    }

    @ViewBuilder
    private var reactionContent: some View {
        switch phoneMonitor.currentState {
        case .charging:
            chargingReaction
        case .pickedUp:
            pickupReaction
        case .night:
            nightReaction
        case .daytime:
            daytimeIndicator
        case .stationary:
            EmptyView()
        }
    }

    private var chargingReaction: some View {
        VStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            Text("Napping against the glass...")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
        }
    }

    private var pickupReaction: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("Excited zoomies! 🎉")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
        }
    }

    private var nightReaction: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .font(.largeTitle)
                .foregroundColor(.indigo)
            Text("Sleepy time... 💤")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
        }
    }

    private var daytimeIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "sun.max.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            Text("Active")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}
