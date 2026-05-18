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

    @State private var monthlyProduct: Product? = nil
    @State private var annualProduct: Product? = nil
    @State private var loadingProduct = true
    @State private var billingCycle: Int = 0  // 0 = monthly, 1 = annually
    @State private var isPremiumLoading = false
    @State private var isFreeLoading = false

    private var selectedProduct: Product? {
        billingCycle == 0 ? monthlyProduct : annualProduct
    }

    private var monthlyPriceDisplay: String {
        monthlyProduct?.displayPrice ?? "$2.99"
    }

    private var annualPriceDisplay: String {
        annualProduct?.displayPrice ?? "--"
    }

    private var annualPerMonthDisplay: String {
        guard let product = annualProduct else { return "" }
        let perMonth = product.price / 12
        return perMonth.formatted(product.priceFormatStyle)
    }

    private var displayedPrice: String {
        billingCycle == 0 ? "\(monthlyPriceDisplay) per month" : "\(annualPriceDisplay) per year"
    }

    private var disclaimerText: String {
        let hasTrial = selectedProduct?.subscription?.introductoryOffer?.paymentMode == .freeTrial
        if billingCycle == 0 {
            if hasTrial {
                return "After your 7-day free trial, \(monthlyPriceDisplay)/month. Cancel anytime. Payment will be charged to your Apple ID at confirmation of purchase."
            } else {
                return "This is a monthly, recurring payment that can be canceled at any time. Payment will be charged to your Apple ID at confirmation of purchase."
            }
        } else {
            if hasTrial {
                return "After your 7-day free trial, \(annualPriceDisplay)/year. Cancel anytime. Payment will be charged to your Apple ID at confirmation of purchase."
            } else {
                return "This is an annual, recurring payment that can be canceled at any time. Payment will be charged to your Apple ID at confirmation of purchase."
            }
        }
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
                                    if billingCycle == 1 {
                                        Text("\(annualPerMonthDisplay)/month")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .contentTransition(.numericText())
                                            .animation(.easeInOut(duration: 0.2), value: billingCycle)
                                    }
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

                        FeatureRow(icon: "checkmark.circle.fill", text: "15 AI entries per day", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "AI nutrition assistant", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Voice logging", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Image Scanning", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Unlimited manual entries", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Weekly Tracking & Overview Dashboard", color: .yellow, isDark: isDark)
                        FeatureRow(icon: "checkmark.circle.fill", text: "Predictive Entries", color: .yellow, isDark: isDark)

                        Rectangle()
                            .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                            .frame(height: 1)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        
                        Text(disclaimerText)
                            .font(.system(size: 13))
                            .italic()
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 0)

                        Rectangle()
                            .fill(Color(red: 24/255, green: 24/255, blue: 24/255))
                            .frame(height: 1)
                            .padding(.vertical, 4)

                        // CTA inside card
                        Button(action: {
                            Task {
                                isPremiumLoading = true
                                let productId = billingCycle == 0
                                    ? SubscriptionManager.premiumProductId
                                    : SubscriptionManager.premiumAnnualProductId
                                await subscriptionManager.purchase(authManager: authManager, userId: userId, productId: productId)
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

                        HStack(spacing: 4) {
                            Link("Terms of Use", destination: URL(string: "https://www.orieapp.com/pages/terms")!)
                                .underline()
                            Text("&")
                            Link("Privacy Policy", destination: URL(string: "https://www.orieapp.com/pages/privacy")!)
                                .underline()
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
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
                                Text(billingCycle == 0 ? "$0 per month" : "$0 per year")
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

                        FeatureRow(icon: "checkmark.circle.fill", text: "3 AI entries per day", color: .gray, isDark: isDark)
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
        if let product = selectedProduct,
           let offer = product.subscription?.introductoryOffer,
           offer.paymentMode == .freeTrial {
            return "Try Free for 7 Days"
        }
        return "Select Premium Plan"
    }

    private func loadProduct() async {
        loadingProduct = true
        if let products = try? await Product.products(for: [
            SubscriptionManager.premiumProductId,
            SubscriptionManager.premiumAnnualProductId
        ]) {
            monthlyProduct = products.first(where: { $0.id == SubscriptionManager.premiumProductId })
            annualProduct = products.first(where: { $0.id == SubscriptionManager.premiumAnnualProductId })
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
