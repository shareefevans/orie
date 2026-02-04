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
    static func startOAuth(url: URL, onCodeReceived: @escaping (String) -> Void, onError: @escaping (Error?) -> Void) {
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

            guard let callbackURL = callbackURL,
                  let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                onError(nil)
                return
            }

            onCodeReceived(code)
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
