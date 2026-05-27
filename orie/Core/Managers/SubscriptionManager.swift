//
//  SubscriptionManager.swift
//  orie
//

import Combine
import StoreKit
import SwiftUI
import UIKit

enum SubscriptionTier: String {
    case free = "free"
    case premium = "premium"
}

@MainActor
final class SubscriptionManager: ObservableObject {

    static let premiumProductId = "orie.premium.monthly"
    static let premiumAnnualProductId = "orie.premium.annually"

    @Published var tier: SubscriptionTier = .free
    @Published var aiUsedToday: Int = 0
    @Published var aiLimit: Int = 0
    @Published var isLoading: Bool = false
    /// True while the initial subscription status is being fetched on launch.
    /// Gates are ignored during this window so premium users aren't shown the paywall mid-load.
    @Published var isLoadingStatus: Bool = true
    @Published var purchaseError: String? = nil
    @Published var showUpgradePaywall: Bool = false
    @Published var paywallMessage: String = ""

    private var transactionListener: Task<Void, Never>?
    private weak var authManager: AuthManager?
    private var purchaseInProgress = false

    init() {
        transactionListener = listenForTransactions()
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Plan selection tracking

    func hasSelectedPlan(userId: String) -> Bool {
        UserDefaults.standard.bool(forKey: "planSelected_\(userId)")
    }

    private func markPlanSelected(userId: String) {
        UserDefaults.standard.set(true, forKey: "planSelected_\(userId)")
    }

    // MARK: - Load status from backend

    func loadStatus(authManager: AuthManager) async {
        self.authManager = authManager
        isLoading = true

        // Check StoreKit entitlements first — this is the source of truth for
        // whether the user has paid, regardless of backend sync state.
        var hasValidEntitlement = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.premiumProductId,
               transaction.revocationDate == nil {
                hasValidEntitlement = true
                break
            }
        }

        do {
            let status = try await authManager.withAuthRetry { accessToken in
                try await APIService.getSubscriptionStatus(accessToken: accessToken)
            }
            // If StoreKit says they have a valid purchase, don't let the backend downgrade them.
            // This handles cases where backend verification was delayed or failed.
            if hasValidEntitlement {
                tier = .premium
                aiLimit = 15
            } else {
                tier = SubscriptionTier(rawValue: status.tier) ?? .free
                aiLimit = status.aiLimit
            }
            aiUsedToday = status.aiUsedToday
        } catch {
            if hasValidEntitlement {
                tier = .premium
                aiLimit = 15
            }
            print("Failed to load subscription status: \(error)")
        }
        isLoading = false
        isLoadingStatus = false
    }

    // MARK: - Select free tier

    func selectFree(authManager: AuthManager, userId: String) async {
        isLoading = true
        do {
            try await authManager.withAuthRetry { accessToken in
                try await APIService.selectFreeTier(accessToken: accessToken)
            }
            tier = .free
            aiUsedToday = 0
            aiLimit = 3
            markPlanSelected(userId: userId)
        } catch {
            print("Failed to select free tier: \(error)")
        }
        isLoading = false
    }

    // MARK: - Purchase premium

    func purchase(authManager: AuthManager, userId: String, productId: String = premiumProductId) async {
        isLoading = true
        purchaseError = nil

        do {
            let products = try await Product.products(for: [productId])
            guard let product = products.first else {
                purchaseError = "Product not found. Please try again."
                isLoading = false
                return
            }

            purchaseInProgress = true
            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                switch verificationResult {
                case .verified(let transaction):
                    // Always finish and grant access — StoreKit has already verified payment
                    await transaction.finish()
                    tier = .premium
                    aiLimit = 15
                    purchaseError = nil
                    markPlanSelected(userId: userId)
                    // Best-effort backend sync — don't block or fail the purchase if this errors
                    try? await authManager.withAuthRetry { accessToken in
                        try await APIService.verifyAppleTransaction(
                            accessToken: accessToken,
                            jwsRepresentation: verificationResult.jwsRepresentation
                        )
                    }
                case .unverified:
                    purchaseError = "Purchase could not be verified. Please contact support."
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = "Purchase failed. Please try again."
            print("Purchase error: \(error)")
        }
        purchaseInProgress = false
        isLoading = false
    }

    // MARK: - Restore purchases

    func restorePurchases(authManager: AuthManager, userId: String) async {
        isLoading = true
        do {
            try await AppStore.sync()
            for await verificationResult in Transaction.currentEntitlements {
                if case .verified(let transaction) = verificationResult,
                   transaction.productID == Self.premiumProductId {
                    try? await authManager.withAuthRetry { accessToken in
                        try await APIService.verifyAppleTransaction(
                            accessToken: accessToken,
                            jwsRepresentation: verificationResult.jwsRepresentation
                        )
                    }
                    await transaction.finish()
                    tier = .premium
                    aiLimit = 15
                    markPlanSelected(userId: userId)
                }
            }
        } catch {
            print("Restore error: \(error)")
        }
        isLoading = false
    }

    // MARK: - Manage subscription (opens Apple's UI)

    func manageSubscription() {
        Task {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            try? await AppStore.showManageSubscriptions(in: windowScene)
        }
    }

    // MARK: - Listen for transaction updates (renewals, cancellations from Apple)

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await verificationResult in Transaction.updates {
                if case .verified(let transaction) = verificationResult {
                    await transaction.finish()
                    // Always re-fetch from backend so Supabase is the source of truth
                    await self?.refreshFromBackend()
                }
            }
        }
    }

    private func refreshFromBackend() async {
        guard let authManager = authManager, !purchaseInProgress else { return }
        await loadStatus(authManager: authManager)
    }
}
