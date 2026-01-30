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
    var isDark: Bool = false

    // Dot colors matching HealthTabView
    private let caloriesDotColor = Color(red: 75/255, green: 78/255, blue: 255/255)
    private let proteinDotColor = Color(red: 49/255, green: 209/255, blue: 149/255)
    private let carbsDotColor = Color(red: 135/255, green: 206/255, blue: 250/255)
    private let fatsDotColor = Color(red: 255/255, green: 180/255, blue: 50/255)

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - ❇️ Header with nutritional information and done button
            HStack {
                Text("nutritional information")
                    .font(.caption)
                    .foregroundColor(Color.secondaryText(isDark))

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
            .padding(.top, 16)
            .padding(.bottom, 24)

            VStack(spacing: 24) {
                // MARK: 👉Food name
                Text(entry.foodName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primaryText(isDark))
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)

                // MARK: 👉Sources row (buttons)
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
                                                .foregroundColor(Color.secondaryText(isDark))
                                        }
                                        .frame(width: 16, height: 16)

                                        Text(source.name)
                                            .font(.footnote)
                                            .foregroundColor(Color.primaryText(isDark))
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(height: 50)
                                    .background(Color.cardBackground(isDark))
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

                // MARK: 👉Two-column layout: Breakdown and Totals
                VStack(spacing: 12) {
                    // Header row
                    HStack(spacing: 0) {
                        Text("Breakdown")
                            .font(.footnote)
                            .foregroundColor(Color.secondaryText(isDark))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Totals")
                            .font(.footnote)
                            .foregroundColor(Color.secondaryText(isDark))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    Divider()

                    // MARK: - ❇️ Calories row
                    HStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(caloriesDotColor)
                                .frame(width: 8, height: 8)
                            Text("Calories")
                                .font(.subheadline)
                                .foregroundColor(Color.primaryText(isDark))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text("\(entry.calories ?? 0)")
                            .font(.subheadline)
                            .foregroundColor(Color.primaryText(isDark))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    // MARK: - ❇️ Protein row
                    HStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(proteinDotColor)
                                .frame(width: 8, height: 8)
                            Text("Protein")
                                .font(.subheadline)
                                .foregroundColor(Color.primaryText(isDark))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(String(format: "%.1fg", entry.protein ?? 0))
                            .font(.subheadline)
                            .foregroundColor(Color.primaryText(isDark))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    // MARK: - ❇️ Carbs row
                    HStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(carbsDotColor)
                                .frame(width: 8, height: 8)
                            Text("Carbs")
                                .font(.subheadline)
                                .foregroundColor(Color.primaryText(isDark))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(String(format: "%.1fg", entry.carbs ?? 0))
                            .font(.subheadline)
                            .foregroundColor(Color.primaryText(isDark))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    // MARK: ❇️ - Fat row
                    HStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(fatsDotColor)
                                .frame(width: 8, height: 8)
                            Text("Fat")
                                .font(.subheadline)
                                .foregroundColor(Color.primaryText(isDark))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(String(format: "%.1fg", entry.fats ?? 0))
                            .font(.subheadline)
                            .foregroundColor(Color.primaryText(isDark))
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
        .background(Color.cardBackground(isDark))
    }
}

#Preview {
    NutritionDetailSheet(
        entry: FoodEntry(foodName: "KFC Zinger Burger"),
        isDark: false
    )
}
