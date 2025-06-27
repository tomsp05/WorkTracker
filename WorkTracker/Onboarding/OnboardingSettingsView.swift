//
//  OnboardingSettingsView.swift
//  WorkTracker
//
//  Created by Tom Speake on 6/27/25.
//


import SwiftUI

struct OnboardingSettingsView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @State private var selectedThemeColor: String

    let themeOptions = ["Blue", "Green", "Orange", "Purple", "Red", "Teal", "Pink"]

    init() {
        _selectedThemeColor = State(initialValue: "Blue")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                Text("Personalize Your App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.themeColor)
                    .padding(.top, 30)

                Text("Choose your favorite theme color.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 15) {
                    Text("App Theme")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 20) {
                        ForEach(themeOptions, id: \.self) { colorName in
                            ThemeColorButton(
                                colorName: colorName,
                                color: getThemeColor(name: colorName),
                                isSelected: selectedThemeColor == colorName,
                                onTap: {
                                    selectedThemeColor = colorName
                                    viewModel.themeColorName = colorName
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(15)
                .padding(.horizontal)
            }
        }
        .onAppear {
            selectedThemeColor = viewModel.themeColorName
        }
    }

    private func getThemeColor(name: String) -> Color {
        // This function should ideally be centralized
        switch name {
        case "Blue": return Color(red: 0.20, green: 0.40, blue: 0.70)
        case "Green": return Color(red: 0.20, green: 0.55, blue: 0.30)
        case "Orange": return Color(red: 0.80, green: 0.40, blue: 0.20)
        case "Purple": return Color(red: 0.50, green: 0.25, blue: 0.70)
        case "Red": return Color(red: 0.70, green: 0.20, blue: 0.20)
        case "Teal": return Color(red: 0.20, green: 0.50, blue: 0.60)
        case "Pink": return Color(red: 0.90, green: 0.40, blue: 0.60)
        default: return .blue
        }
    }
}
