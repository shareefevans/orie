//
//  AppleSignInHelper.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import AuthenticationServices
import SwiftUI
import UIKit

class AppleSignInHelper: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    private var onSuccess: ((String, String?, String?) -> Void)?
    private var onError: ((Error?) -> Void)?

    func startSignIn(
        onSuccess: @escaping (String, String?, String?) -> Void,
        onError: @escaping (Error?) -> Void
    ) {
        self.onSuccess = onSuccess
        self.onError = onError

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            onError?(nil)
            return
        }

        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        onSuccess?(tokenString, credential.email, fullName.isEmpty ? nil : fullName)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            onError?(nil) // User cancelled
        } else {
            onError?(error)
        }
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        let window = windowScene?.windows.first { $0.isKeyWindow }
            ?? windowScene?.windows.first
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }

        return window!
    }
}
