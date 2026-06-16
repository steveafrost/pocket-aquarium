import SwiftUI
import StoreKit

/// Pro upgrade view — one-time $4.99 purchase to unlock all features
struct ProUpgradeView: View {
    @EnvironmentObject var storeKit: StoreKitManager
    @Environment(\.dismiss) var dismiss

    @State private var isPurchasing = false
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Feature list
                    featuresSection

                    // Price
                    priceSection

                    // Purchase button
                    purchaseButton

                    // Restore
                    restoreButton

                    // Fine print
                    finePrintSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Pocket Aquarium Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !isPurchasing {
                        Button("Not now") { dismiss() }
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(storeKit.purchaseError ?? "An error occurred.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .padding(.top, 20)

            Text("Unlock the Full Aquarium")
                .font(.title)
                .fontWeight(.bold)

            Text("One-time purchase. No subscriptions.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Included")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(ProUnlockManager.ProFeature.allCases, id: \.rawValue) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(feature.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Price

    private var priceSection: some View {
        VStack(spacing: 4) {
            Text("Just $4.99")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.purple)

            Text("One-time payment • Lifetime access")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task {
                isPurchasing = true
                await storeKit.purchasePro()
                isPurchasing = false
                if storeKit.isPro {
                    dismiss()
                } else if storeKit.purchaseError != nil {
                    showError = true
                }
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Pro")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isPurchasing || storeKit.isPro)
        .opacity(isPurchasing ? 0.7 : 1.0)
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            Task {
                await storeKit.restorePurchases()
                if storeKit.isPro {
                    dismiss()
                }
            }
        } label: {
            if storeKit.isRestoring {
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Fine Print

    private var finePrintSection: some View {
        VStack(spacing: 8) {
            Text("Payment will be charged to your Apple ID account at confirmation of purchase.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Pro is a one-time purchase that never expires. It is not a subscription.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
}
