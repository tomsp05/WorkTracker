import SwiftUI

@main
struct WorkTrackerApp: App {
    @StateObject private var viewModel = WorkHoursViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(viewModel)
            } else {
                OnboardingContainerView()
                    .environmentObject(viewModel)
            }
        }
    }
}
