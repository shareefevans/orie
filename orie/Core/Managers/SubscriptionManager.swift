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

    @Published var tier: SubscriptionTier = .free
    @Published var aiUsedToday: Int = 0
    @Published var aiLimit: Int = 0
    @Published var isLoading: Bool = false
    @Published var purchaseError: String? = nil

    private var transactionListener: Task<Void, Never>?
    private weak var authManager: AuthManager?

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
        do {
            let status = try await authManager.withAuthRetry { accessToken in
                try await APIService.getSubscriptionStatus(accessToken: accessToken)
            }
            tier = SubscriptionTier(rawValue: status.tier) ?? .free
            aiUsedToday = status.aiUsedToday
            aiLimit = status.aiLimit
        } catch {
            print("Failed to load subscription status: \(error)")
        }
        isLoading = false
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

    // MARK: - Select premium tier directly

    func selectPremium(authManager: AuthManager, userId: String) async {
        isLoading = true
        do {
            try await authManager.withAuthRetry { accessToken in
                try await APIService.selectPremiumTier(accessToken: accessToken)
            }
            tier = .premium
            aiLimit = 15
            markPlanSelected(userId: userId)
        } catch {
            print("Failed to select premium tier: \(error)")
        }
        isLoading = false
    }

    // MARK: - Purchase premium

    func purchase(authManager: AuthManager, userId: String) async {
        isLoading = true
        purchaseError = nil

        do {
            let products = try await Product.products(for: [Self.premiumProductId])
            guard let product = products.first else {
                purchaseError = "Product not found. Please try again."
                isLoading = false
                return
            }

            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                switch verificationResult {
                case .verified(let transaction):
                    try await authManager.withAuthRetry { accessToken in
                        try await APIService.verifyAppleTransaction(
                            accessToken: accessToken,
                            jwsRepresentation: verificationResult.jwsRepresentation
                        )
                    }
                    await transaction.finish()
                    tier = .premium
                    aiLimit = 15
                    markPlanSelected(userId: userId)
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
        guard let authManager = authManager else { return }
        await loadStatus(authManager: authManager)
    }
}
