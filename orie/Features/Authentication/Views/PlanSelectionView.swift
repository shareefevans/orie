//
//  PlanSelectionView.swift
//  orie
//

import SwiftUI
import StoreKit

struct PlanSelectionView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    private var isDark: Bool { themeManager.isDarkMode }
    private var userId: String { authManager.currentUser?.id ?? "" }

    @State private var premiumProduct: Product? = nil
    @State private var loadingProduct = true

    var body: some View {
        ZStack {
            Color.appBackground(isDark).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Header
                    VStack(spacing: 0) {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.hexagonpath.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color.primaryText(isDark))
                                .padding(.top, 6)
                            Text("orie")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(Color.primaryText(isDark))
                        }
                        .frame(maxWidth: .infinity)


                        Text("Choose a plan")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(Color.secondaryText(isDark))
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 8)

                    // MARK: - Premium Card (first — it's the recommended option)
                    VStack(alignment: .leading, spacing: 16) {

                        // Header row
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("Premium")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.primaryText(isDark))
                                    Text("BEST")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.yellow)
                                        .cornerRadius(6)
                                }
                                Text("7-day free trial")
                                    .font(.footnote)
                                    .foregroundColor(.green)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                if loadingProduct {
                                    Text("...")
                                        .font(.footnote)
                                        .foregroundColor(Color.secondaryText(isDark))
                                } else if let product = premiumProduct {
                                    Text(product.displayPrice)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color.primaryText(isDark))
                                    Text("/ month")
                                        .font(.caption2)
                                        .foregroundColor(Color.secondaryText(isDark))
                                }
                            }
                        }

                        Divider()

                        FeatureRow(icon: "checkmark.circle.fill", text: "AI nutrition lookup (15/day)", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Image scanning", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Unlimited manual entry", color: .green, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Full dashboard & tracking", color: .green, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Cached entries never count toward limit", color: .green, isDark: isDark)

                        // CTA inside card
                        Button(action: {
                            Task {
                                await subscriptionManager.purchase(authManager: authManager, userId: userId)
                            }
                        }) {
                            ZStack {
                                Text(trialLabel)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .opacity(subscriptionManager.isLoading ? 0 : 1)

                                if subscriptionManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.accessibleYellow(isDark).opacity(0.55), in: .capsule)
                        }
                        .glassEffect(in: .capsule)
                        .disabled(subscriptionManager.isLoading)
                        .padding(.top, 4)
                    }
                    .padding(24)
                    .background(Color.cardBackground(isDark))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.yellow.opacity(0.5), lineWidth: 1.5)
                    )
                    .padding(.horizontal)

                    // MARK: - Free Card
                    VStack(alignment: .leading, spacing: 16) {

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Free")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.primaryText(isDark))
                                Text("Always free")
                                    .font(.footnote)
                                    .foregroundColor(Color.secondaryText(isDark))
                            }
                            Spacer()
                        }

                        Divider()

                        FeatureRow(icon: "checkmark.circle.fill", text: "Manual food entry (unlimited)", color: .green, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Full dashboard & tracking", color: .green, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Food history & achievements", color: .green, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "AI nutrition lookup (3/day)", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "xmark.circle.fill", text: "No image scanning", color: .gray, isDark: isDark)

                        // CTA inside card
                        Button(action: {
                            Task {
                                await subscriptionManager.selectFree(authManager: authManager, userId: userId)
                            }
                        }) {
                            Text("Continue for free")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(isDark ? .white : .black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .glassEffect(in: .capsule)
                        .disabled(subscriptionManager.isLoading)
                        .padding(.top, 4)
                    }
                    .padding(24)
                    .background(Color.cardBackground(isDark))
                    .cornerRadius(32)
                    .padding(.horizontal)

                    if let errorMessage = subscriptionManager.purchaseError {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Restore
                    Button(action: {
                        Task {
                            await subscriptionManager.restorePurchases(authManager: authManager, userId: userId)
                        }
                    }) {
                        Text("Restore purchases")
                            .font(.caption)
                            .foregroundColor(Color.secondaryText(isDark).opacity(0.6))
                    }
                    .disabled(subscriptionManager.isLoading)
                    .padding(.bottom, 40)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            Button(action: {
                Task { await authManager.logout() }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isDark ? .white : .black)
                    .frame(width: 44, height: 44)
            }
            .glassEffect(in: Circle())
            .padding(.leading)
            .padding(.top, 16)
        }
        .task {
            await loadProduct()
        }
    }

    private var trialLabel: String {
        if let product = premiumProduct,
           let offer = product.subscription?.introductoryOffer,
           offer.paymentMode == .freeTrial {
            return "Try Free for 7 Days — then \(product.displayPrice)/mo"
        }
        return "Start Premium"
    }

    private func loadProduct() async {
        loadingProduct = true
        if let products = try? await Product.products(for: [SubscriptionManager.premiumProductId]) {
            premiumProduct = products.first
        }
        loadingProduct = false
    }
}

#Preview {
    PlanSelectionView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .environmentObject(SubscriptionManager())
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    let isDark: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(.footnote)
                .foregroundColor(Color.primaryText(isDark))
            Spacer()
        }
    }
}
