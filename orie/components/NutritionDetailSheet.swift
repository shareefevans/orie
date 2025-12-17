//
//  NutritionDetailSheet.swift
//  orie
//
//  Created by Shareef Evans on 18/12/2025.
//

import SwiftUI

struct NutritionDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let entry: FoodEntry

    var body: some View {
        VStack(spacing: 0) {
            // Header with nutritional information and done button
            HStack {
                Text("nutritional information")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 16)
            .padding(.bottom, 24)

            VStack(spacing: 24) {
                // Food name
                Text(entry.foodName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(
                        Color(
                            red: 69 / 255,
                            green: 69 / 255,
                            blue: 69 / 255
                        )
                    )
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)

                // Sources row (buttons)
                if let sources = entry.sources, !sources.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sources) { source in
                                Button(action: {
                                    if let url = URL(string: source.url) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        AsyncImage(url: URL(string: source.icon)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        } placeholder: {
                                            Image(systemName: "globe")
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(width: 16, height: 16)

                                        Text(source.name)
                                            .font(.footnote)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 100))
                                    .glassEffect(.regular.interactive())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .scrollClipDisabled(true)
                }

                // Two-column layout: Breakdown and Totals
                VStack(spacing: 12) {
                    // Header row
                    HStack(spacing: 0) {
                        Text("Breakdown")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Totals")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    Divider()

                    // Calories row
                    HStack(spacing: 0) {
                        Text("Calories")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("\(entry.calories ?? 0)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    // Protein row
                    HStack(spacing: 0) {
                        Text("Protein")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(String(format: "%.1fg", entry.protein ?? 0))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    // Carbs row
                    HStack(spacing: 0) {
                        Text("Carbs")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(String(format: "%.1fg", entry.carbs ?? 0))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    // Fat row
                    HStack(spacing: 0) {
                        Text("Fat")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(String(format: "%.1fg", entry.fats ?? 0))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)

                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .padding(.top, 32)
    }
}

#Preview {
    NutritionDetailSheet(
        entry: FoodEntry(foodName: "KFC Zinger Burger")
    )
}
