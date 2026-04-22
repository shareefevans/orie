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
    @State private var billingCycle: Int = 0  // 0 = monthly, 1 = annually
    @State private var isPremiumLoading = false
    @State private var isFreeLoading = false

    private var monthlyPriceDisplay: String {
        premiumProduct?.displayPrice ?? "$2.99"
    }

    private var annualPriceDisplay: String {
        guard let product = premiumProduct else { return "$35.88" }
        let annual = product.price * 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: annual as NSDecimalNumber) ?? "$35.88"
    }

    private var displayedPrice: String {
        billingCycle == 0 ? "\(monthlyPriceDisplay)usd per month" : "\(annualPriceDisplay)usd per year"
    }

    var body: some View {
        ZStack {
            Color.appBackground(isDark).ignoresSafeArea()

            // MARK: - Squiggle decoration (fixed)
            VStack {
                Image("squiggle_dark")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                Spacer()
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Billing toggle
                    NativeSegmentedControl(
                        options: ["Monthly", "Annually"],
                        selectedIndex: $billingCycle,
                        isDark: isDark
                    )
                    .frame(height: 50)
                    .padding(.horizontal, 16)
                    .padding(.top, 132)

                    // MARK: - Premium Card (first — it's the recommended option)
                    VStack(alignment: .leading, spacing: 16) {

                        // Header row
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Premium")
                                    .font(.footnote)
                                    .fontWeight(.regular)
                                    .foregroundColor(.yellow)
                                if loadingProduct {
                                    Text("...")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.secondaryText(isDark))
                                } else {
                                    Text(displayedPrice)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.primaryText(isDark))
                                        .contentTransition(.numericText())
                                        .animation(.easeInOut(duration: 0.2), value: billingCycle)
                                }
                            }
                            Spacer()
                            Text("Popular")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.yellow.opacity(0.55), in: Capsule())
                                .glassEffect(in: Capsule())
                        }

                        Rectangle()
                            .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                            .frame(height: 1)
                            .padding(.vertical, 8)

                        FeatureRow(icon: "checkmark.circle.fill", text: "15 Ai entries per day", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Orie natural language nutritional chatbot", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Voice to Text", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Image Scanning", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Unlimited manual entries", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Weekly Tracking & Overview Dashboard", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Predictive Entries", color: .yellow, isDark: isDark)

                        Rectangle()
                            .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                            .frame(height: 1)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        
                        Text(billingCycle == 0 ? "This is a monthly, recurring payment that can be canceled at any time" : "This is an annually recurring payment that can be canceled at any time")
                            .font(.system(size: 13))
                            .italic()
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 32)

                        Rectangle()
                            .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                            .frame(height: 1)
                            .padding(.vertical, 4)
                        
                        // CTA inside card
                        Button(action: {
                            Task {
                                isPremiumLoading = true
                                await subscriptionManager.purchase(authManager: authManager, userId: userId)
                                isPremiumLoading = false
                            }
                        }) {
                            ZStack {
                                Text(trialLabel)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .opacity(isPremiumLoading ? 0 : 1)

                                if isPremiumLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.accessibleYellow(isDark).opacity(0.55), in: .capsule)
                        }
                        .glassEffect(in: .capsule)
                        .disabled(isPremiumLoading || isFreeLoading)
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
                                    .font(.footnote)
                                    .fontWeight(.regular)
                                    .foregroundColor(Color.secondaryText(isDark))
                                Text(billingCycle == 0 ? "$0usd per month" : "$0usd per year")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.primaryText(isDark))
                                    .contentTransition(.numericText())
                                    .animation(.easeInOut(duration: 0.2), value: billingCycle)
                            }
                            Spacer()
                        }

                        Rectangle()
                            .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                            .frame(height: 1)
                            .padding(.vertical, 8)

                        FeatureRow(icon: "checkmark.circle.fill", text: "3 Ai entries per day", color: .gray, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Unlimited Manual food entry (unlimited)", color: .gray, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "AI nutrition lookup (3/day)", color: .gray, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Full dashboard & tracking", color: .gray, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Predictive Entries", color: .gray, isDark: isDark)

                        Rectangle()
                            .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                            .frame(height: 1)
                            .padding(.vertical, 8)
                        
                        // CTA inside card
                        Button(action: {
                            Task {
                                isFreeLoading = true
                                await subscriptionManager.selectFree(authManager: authManager, userId: userId)
                                isFreeLoading = false
                            }
                        }) {
                            ZStack {
                                Text("Continue for free")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(isDark ? .white : .black)
                                    .opacity(isFreeLoading ? 0 : 1)

                                if isFreeLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: isDark ? .white : .black))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                        }
                        .glassEffect(in: .capsule)
                        .disabled(isPremiumLoading || isFreeLoading)
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
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(isDark ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .glassEffect(in: .capsule)
                    .disabled(isPremiumLoading || isFreeLoading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            HStack(spacing: 8) {
                Button(action: {
                    Task { await authManager.logout() }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isDark ? .white : .black)
                        .frame(width: 44, height: 44)
                }
                .glassEffect(in: Circle())

                Text("Select Plan")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.primaryText(isDark))
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .glassEffect(.regular.interactive(), in: Capsule())
            }
            .padding(.leading, 16)
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
        return "Select Premium Plan"
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
                .font(.system(size: 14))
                .foregroundColor(Color.primaryText(isDark))
            Spacer()
        }
    }
}
