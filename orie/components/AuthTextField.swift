//
//  AuthTextField.swift
//  orie
//
//  Created by Shareef Evans on 26/11/2025.
//

import SwiftUI

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var isDark: Bool = false
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    @State private var isPasswordVisible = false

    var body: some View {
        HStack {
            if isSecure && !isPasswordVisible {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color.primaryText(isDark))
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Color.primaryText(isDark))
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
            }

            if isSecure {
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(Color.secondaryText(isDark))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.appBackground(isDark))
        .cornerRadius(16)
    }
}
