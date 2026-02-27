//
//  OAuthWebView.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI
import UIKit
import AuthenticationServices

struct OAuthHelper {
    static func startOAuth(
        url: URL,
        onCodeReceived: @escaping (String) -> Void,
        onTokensReceived: @escaping (String, String) -> Void,
        onError: @escaping (Error?) -> Void
    ) {
        let callbackScheme = "orie"

        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackScheme
        ) { callbackURL, error in
            if let error = error as? ASWebAuthenticationSessionError {
                if error.code == .canceledLogin {
                    // User cancelled
                    onError(nil)
                    return
                }
                onError(error)
                return
            }

            guard let callbackURL = callbackURL else {
                onError(nil)
                return
            }

            // Try to get code from query params (authorization code flow)
            if let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
               let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                onCodeReceived(code)
                return
            }

            // Try to get tokens from fragment (implicit flow)
            // Fragment looks like: #access_token=...&refresh_token=...
            if let fragment = callbackURL.fragment {
                let fragmentParams = fragment.split(separator: "&").reduce(into: [String: String]()) { result, param in
                    let parts = param.split(separator: "=", maxSplits: 1)
                    if parts.count == 2 {
                        result[String(parts[0])] = String(parts[1])
                    }
                }

                if let accessToken = fragmentParams["access_token"],
                   let refreshToken = fragmentParams["refresh_token"] {
                    onTokensReceived(accessToken, refreshToken)
                    return
                }
            }

            // Try query params for tokens (in case backend redirected with tokens)
            if let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true) {
                let accessToken = components.queryItems?.first(where: { $0.name == "access_token" })?.value
                let refreshToken = components.queryItems?.first(where: { $0.name == "refresh_token" })?.value

                if let accessToken = accessToken, let refreshToken = refreshToken {
                    onTokensReceived(accessToken, refreshToken)
                    return
                }
            }

            onError(nil)
        }

        session.presentationContextProvider = OAuthPresentationContext.shared
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }
}

class OAuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthPresentationContext()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
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
