import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @State private var currentPage = 0
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    // This flag determines if the onboarding is opened from settings
    var isFromSettings: Bool = false

    // Pages for the onboarding flow
    let pages = ["welcome", "jobs", "settings", "finish"]

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                OnboardingWelcomeView()
                    .tag(0)
                    .padding(.bottom, 100)

                OnboardingJobsView()
                    .tag(1)
                    .padding(.bottom, 100)

                OnboardingSettingsView()
                    .tag(2)
                    .padding(.bottom, 100)

                OnboardingFinishView()
                    .tag(3)
                    .padding(.bottom, 100)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Navigation controls
            VStack(spacing: 20) {
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? viewModel.themeColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                // Navigation buttons
                HStack {
                    // Back/Cancel Button
                    if currentPage > 0 || isFromSettings {
                        Button(action: {
                            if isFromSettings && currentPage == 0 {
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }
                        }) {
                            if isFromSettings && currentPage == 0 {
                                Text("Cancel")
                                    .foregroundColor(.secondary)
                            } else {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .foregroundColor(viewModel.themeColor)
                            }
                        }
                        .padding()
                    } else {
                        Spacer().frame(minWidth: 80) // Placeholder for balance
                    }


                    Spacer()

                    // Next/Finish button
                    Button(action: {
                        withAnimation {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                if isFromSettings {
                                    presentationMode.wrappedValue.dismiss()
                                } else {
                                    viewModel.completeOnboarding()
                                }
                            }
                        }
                    }) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Next" : (isFromSettings ? "Done" : "Get Started"))
                            if currentPage < pages.count - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(viewModel.themeColor)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color.black.opacity(0.7) : Color(.systemBackground).opacity(0.8),
                        colorScheme == .dark ? Color.black.opacity(0.9) : Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .padding(.bottom, 30)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
