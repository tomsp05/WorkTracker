//
//  WorkTrackerApp.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//

import SwiftUI

@main
struct WorkTrackerApp: App {
    // Create the view model at the app level
    @StateObject private var viewModel = WorkHoursViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
