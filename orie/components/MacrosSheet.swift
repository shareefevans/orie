//
//  MacrosSheet.swift
//  orie
//
//  Created by Shareef Evans on 17/12/2025.
//

import SwiftUI

struct MacrosSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header with title and done button
            HStack {
                Text("Macros")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(
                        Color(
                            red: 69 / 255,
                            green: 69 / 255,
                            blue: 69 / 255
                        )
                    )

                Spacer()

                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.accentBlue)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 24)
            .padding(.bottom, 16)

            // Grid with 3 columns (Type, Total, Remaining)
            VStack(spacing: 12) {
                // Header row
                HStack(spacing: 0) {
                    Text("Type")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Total")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)

                    Text("Remaining")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 8)

                // Calories row
                HStack(spacing: 0) {
                    Text("Calories")
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("0g")
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)

                    Text("0g")
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 8)

                // Protein row
                HStack(spacing: 0) {
                    Text("Protein")
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("0g")
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)

                    Text("0g")
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 8)

                // Carbs row
                HStack(spacing: 0) {
                    Text("Carbs")
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("0g")
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)

                    Text("0g")
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 8)

                // Fats row
                HStack(spacing: 0) {
                    Text("Fats")
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("0g")
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)

                    Text("0g")
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 8)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .padding(.top, 32)
    }
}

#Preview {
    MacrosSheet()
}
