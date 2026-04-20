//
//  ProfileSheetComponents.swift
//  orie
//

import SwiftUI

enum ProfileTab {
    case profile, settings
}

// MARK: - ❇️ Macro Row Component
struct MacroRow: View {
    var icon: String? = nil
    var dotColor: Color? = nil
    let label: String
    @Binding var value: Int
    let unit: String
    let isDark: Bool
    var onSave: (() -> Void)?

    @State private var showPicker = false
    @State private var tempValue: Int

    init(icon: String? = nil, dotColor: Color? = nil, label: String, value: Binding<Int>, unit: String, isDark: Bool = false, onSave: (() -> Void)? = nil) {
        self.icon = icon
        self.dotColor = dotColor
        self.label = label
        self._value = value
        self.unit = unit
        self.isDark = isDark
        self.onSave = onSave
        _tempValue = State(initialValue: value.wrappedValue)
    }

    var body: some View {
        Button(action: {
            tempValue = value
            showPicker = true
        }) {
            HStack {
                if let dotColor {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 8, height: 8)
                        .frame(width: 20)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondaryText(isDark))
                        .frame(width: 20)
                }
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.primaryText(isDark))
                Spacer()
                HStack(spacing: 6) {
                    Text(value == 0 ? (unit == "yrs" ? "Add" : "Add \(unit.uppercased())") : "\(value) \(unit)")
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondaryText(isDark))
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundColor(Color.accessibleYellow(isDark))
                }
            }
            .padding(.vertical, 22)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            MacroPickerSheet(
                label: label,
                value: $tempValue,
                unit: unit,
                isDark: isDark,
                onDone: {
                    value = tempValue
                    showPicker = false
                    onSave?()
                }
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.cardBackground(isDark))
        }
    }
}

// MARK: - ❇️ Macro Picker Sheet
struct MacroPickerSheet: View {
    let label: String
    @Binding var value: Int
    let unit: String
    let isDark: Bool
    var onDone: () -> Void

    @State private var textValue: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { onDone() }
                    .foregroundColor(Color.secondaryText(isDark))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                Spacer()
                Text("Set \(label)")
                    .font(.headline)
                    .foregroundColor(Color.primaryText(isDark))
                Spacer()
                Button("Done") {
                    if let newValue = Int(textValue) { value = newValue }
                    onDone()
                }
                .foregroundColor(Color.accentBlue)
                .fontWeight(.semibold)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, 8)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()

            VStack(spacing: 16) {
                TextField("Enter value", text: $textValue)
                    .keyboardType(.numberPad)
                    .font(.system(size: 48, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.primaryText(isDark))
                    .focused($isTextFieldFocused)
                    .padding()
            }
            .padding(.top, 32)

            Spacer()
        }
        .background(Color.cardBackground(isDark))
        .onAppear {
            textValue = "\(value)"
            isTextFieldFocused = true
        }
    }
}

// MARK: - ❇️ Profile Sheet Skeleton
struct ProfileSheetSkeleton: View {
    let isDark: Bool
    var tab: ProfileTab = .profile
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 8) {
            if tab == .profile {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 60, height: 16)
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 200, height: 12)
                    }
                    .padding(.bottom, 8)
                    Divider(); SkeletonRow(isDark: isDark)
                    Divider(); SkeletonRow(isDark: isDark)
                    Divider(); SkeletonRow(isDark: isDark)
                    Divider(); SkeletonRow(isDark: isDark)
                }
                .padding(24).background(Color.cardBackground(isDark)).cornerRadius(24)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 80, height: 16)
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 220, height: 12)
                    }
                    .padding(.bottom, 8)
                    Divider(); SkeletonRow(isDark: isDark)
                    Divider(); SkeletonRow(isDark: isDark)
                    Divider(); SkeletonRow(isDark: isDark)
                    Divider(); SkeletonRow(isDark: isDark)
                    Divider(); SkeletonRow(isDark: isDark)
                    Divider(); SkeletonRow(isDark: isDark)
                    Divider(); SkeletonRow(isDark: isDark)
                }
                .padding(24).background(Color.cardBackground(isDark)).cornerRadius(24)
            }

            if tab == .settings {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 110, height: 16)
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 160, height: 12)
                    }
                    .padding(.bottom, 8)
                    Divider(); SkeletonRow(isDark: isDark)
                    Divider(); SkeletonRow(isDark: isDark)
                }
                .padding(24).background(Color.cardBackground(isDark)).cornerRadius(24)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 50, height: 16)
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 180, height: 12)
                    }
                    .padding(.bottom, 8)
                    Divider(); SkeletonRow(isDark: isDark)
                    Divider(); SkeletonRow(isDark: isDark)
                    Divider(); SkeletonRow(isDark: isDark)
                    Divider(); SkeletonRow(isDark: isDark)
                    Divider(); SkeletonRow(isDark: isDark)
                }
                .padding(24).background(Color.cardBackground(isDark)).cornerRadius(24)
            }
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - ❇️ Skeleton Row
struct SkeletonRow: View {
    let isDark: Bool

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 80, height: 14)
            Spacer()
            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 40, height: 14)
        }
    }
}
