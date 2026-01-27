//
//  OAuthWebView.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI
import WebKit

struct OAuthWebView: UIViewRepresentable {
    let url: URL
    let onCodeReceived: (String) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeReceived: onCodeReceived)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onCodeReceived: (String) -> Void

        init(onCodeReceived: @escaping (String) -> Void) {
            self.onCodeReceived = onCodeReceived
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                onCodeReceived(code)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
