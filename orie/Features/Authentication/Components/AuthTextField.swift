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
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    @State private var isPasswordVisible = false

    private var placeholderColor: Color {
        Color.secondaryText(isDark).opacity(0.8)
    }

    var body: some View {
        HStack {
            if isSecure && !isPasswordVisible {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(placeholderColor))
                    .font(.system(size: 16))
                    .foregroundColor(Color.primaryText(isDark))
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(placeholderColor))
                    .font(.system(size: 16))
                    .foregroundColor(Color.primaryText(isDark))
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
            }

            if isSecure {
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondaryText(isDark))
                }
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color.secondaryText(isDark))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 14)
    }
}
