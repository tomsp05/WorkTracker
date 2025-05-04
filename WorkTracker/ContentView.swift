import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var previousEarnings: Double = 0.0
    @State private var viewDidAppear = false
    
    // Date range for the summary
    @State private var timeRange: TimeRange = .thisWeek
    @State private var currentIndex = 1  // Default to "This Week" (index 1)
    
    // Time ranges for navigation
    private let timeRanges = TimeRange.allCases
    
    // Current earnings based on selected time range
    var currentEarnings: Double {
        let (startDate, endDate) = timeRange.dateRange
        return viewModel.totalEarnings(from: startDate, to: endDate)
    }
    
    // Current hours based on selected time range
    var currentHours: Double {
        let (startDate, endDate) = timeRange.dateRange
        return viewModel.totalHours(from: startDate, to: endDate)
    }
    
    // Recent work shifts (limit to 5)
    private var recentShifts: [WorkShift] {
        return viewModel.shifts
            .sorted { $0.date > $1.date } // Explicitly sort by date descending (newest first)
            .prefix(5)
            .filter { $0.date <= Date() } // Only show past or today's shifts
    }
    
    // Group recent shifts by week
    private var groupedRecentShifts: [(date: Date, shifts: [WorkShift])] {
        // Group by the start of week for each shift date
        let calendar = Calendar.current
        var groups = Dictionary<Date, [WorkShift]>()
        
        for shift in recentShifts {
            // Get the start of the week containing this shift
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: shift.date))!
            
            if groups[weekStart] == nil {
                groups[weekStart] = []
            }
            
            groups[weekStart]!.append(shift)
        }
        
        // Sort the groups by date (newest first)
        let sortedGroups = groups.sorted { $0.0 > $1.0 }
        
        // Return the sorted groups
        return sortedGroups.map { (date: $0.0, shifts: $0.1) }
    }
    
    // Format currency (£)
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
    
    // Format hours
    private func formatHours(_ hours: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        
        guard let formattedHours = formatter.string(from: NSNumber(value: hours)) else {
            return "\(hours)h"
        }
        
        return "\(formattedHours)h"
    }
    
    // Format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Format week heading
    private func formattedWeek(_ weekStartDate: Date) -> String {
        let calendar = Calendar.current
        let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate)!
        
        let startFormatter = DateFormatter()
        let endFormatter = DateFormatter()
        
        // If same month, only show day number for start date
        if calendar.component(.month, from: weekStartDate) == calendar.component(.month, from: weekEndDate) {
            startFormatter.dateFormat = "d"
            endFormatter.dateFormat = "d MMM yyyy"
            return "Week of \(startFormatter.string(from: weekStartDate))-\(endFormatter.string(from: weekEndDate))"
        } else {
            // Different months
            startFormatter.dateFormat = "d MMM"
            endFormatter.dateFormat = "d MMM yyyy"
            return "Week of \(startFormatter.string(from: weekStartDate))-\(endFormatter.string(from: weekEndDate))"
        }
    }
    
    // Update counter when earnings change
    func updateEarningsDisplay() {
        previousEarnings = currentEarnings
    }
    
    // Navigate to previous time period
    private func goToPreviousPeriod() {
        if currentIndex > 0 {
            withAnimation(.spring()) {
                currentIndex -= 1
                timeRange = timeRanges[currentIndex]
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
    
    // Navigate to next time period
    private func goToNextPeriod() {
        if currentIndex < timeRanges.count - 1 {
            withAnimation(.spring()) {
                currentIndex += 1
                timeRange = timeRanges[currentIndex]
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Earnings summary card with arrow navigation
                    VStack(spacing: 0) {
                        // Time period selector with arrow buttons
                        HStack {
                            // Left arrow button
                            Button(action: goToPreviousPeriod) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.25))
                                    )
                                    .opacity(currentIndex > 0 ? 1.0 : 0.3)
                            }
                            .disabled(currentIndex == 0)
                            
                            Spacer()
                            
                            // Time period title
                            Text(timeRange.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Right arrow button
                            Button(action: goToNextPeriod) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.25))
                                    )
                                    .opacity(currentIndex < timeRanges.count - 1 ? 1.0 : 0.3)
                            }
                            .disabled(currentIndex == timeRanges.count - 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Earnings details
                        NavigationLink(destination: EarningsDetailView(timeRange: $timeRange)) {
                            VStack(spacing: 8) {
                                // Earnings amount
                                CountingValueView(
                                    value: currentEarnings,
                                    fromValue: previousEarnings,
                                    isAnimating: currentEarnings != previousEarnings,
                                    fontSize: 36,
                                    positiveColor: .white,
                                    negativeColor: .white
                                )
                                
                                Text("\(formatHours(currentHours)) worked")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.top, 4)
                                
                                // Visual cue that this is tappable
                                HStack(spacing: 4) {
                                    Text("View Details")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .padding(.top, 2)
                            }
                            .padding(.bottom, 20)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                viewModel.themeColor.opacity(0.7),
                                viewModel.themeColor
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: viewModel.themeColor.opacity(0.5), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    .padding(.top)
                    .onChange(of: timeRange) { _, _ in
                        updateEarningsDisplay()
                    }
                    
                    // Navigation cards in a 2x2 grid - matching the Finance app's design
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            NavigationLink(destination: ShiftsListView()) {
                                NavCardView(
                                    title: "Shifts",
                                    subtitle: "View All",
                                    iconName: "calendar.badge.clock"
                                )
                            }
                            
                            NavigationLink(destination: JobsListView()) {
                                NavCardView(
                                    title: "Jobs",
                                    subtitle: "Manage",
                                    iconName: "briefcase.fill"
                                )
                            }
                        }
                        
                        HStack(spacing: 16) {
                            NavigationLink(destination: AddShiftView()) {
                                NavCardView(
                                    title: "Add",
                                    subtitle: "Work Shift",
                                    iconName: "plus.circle.fill"
                                )
                            }
                            
                            NavigationLink(destination: SettingsView()) {
                                NavCardView(
                                    title: "Settings",
                                    subtitle: "Customise",
                                    iconName: "gear"
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent shifts section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Shifts")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if recentShifts.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("No shifts recorded")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Tap 'Add Work Shift' to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    // Iterate over grouped shifts by week
                                    ForEach(groupedRecentShifts, id: \.date) { group in
                                        VStack(alignment: .leading, spacing: 4) {
                                            // Week header with date and weekly stats
                                            HStack {
                                                // Show the week range
                                                Text(formattedWeek(group.date))
                                                    .font(.headline)
                                                    .foregroundColor(.secondary)
                                                
                                                Spacer()
                                                
                                                // Weekly summary
                                                let weeklyHours = group.shifts.reduce(0) { $0 + $1.duration }
                                                Text(formatHours(weeklyHours))
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.vertical, 4)
                                            
                                            Divider()
                                            
                                            // Shifts for this week
                                            ForEach(group.shifts) { shift in
                                                NavigationLink(destination: EditShiftView(shift: shift)) {
                                                    ShiftCardView(shift: shift)
                                                        .environmentObject(viewModel)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .padding(.vertical, 2)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                                .padding()
                            }
                            
                            NavigationLink(destination: ShiftsListView()) {
                                Text("See All Shifts")
                                    .font(.headline)
                                    .foregroundColor(viewModel.themeColor)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                                    .cornerRadius(15)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Shifts")
            .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
            .onAppear {
                previousEarnings = currentEarnings
                viewDidAppear = true
                
                // Set initial index based on default timeRange
                if let index = timeRanges.firstIndex(of: timeRange) {
                    currentIndex = index
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                if viewDidAppear {
                    updateEarningsDisplay()
                }
            }
            .onChange(of: viewModel.earningsDidChange) { _, _ in
                // When earnings change, just update the previous value for the animation
                updateEarningsDisplay()
            }
        }
    }
}

// Time range enum for filtering data
enum TimeRange: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case last30Days = "Last 30 Days"
    case yearToDate = "Year to Date"
    
    var title: String {
        return self.rawValue
    }
    
    var dateRange: (Date, Date) {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        
        switch self {
        case .today:
            startDate = calendar.startOfDay(for: endDate)
        case .thisWeek:
            startDate = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: endDate).date ?? endDate.addingTimeInterval(-7*24*60*60)
        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: endDate)
            startDate = calendar.date(from: components) ?? endDate.addingTimeInterval(-30*24*60*60)
        case .last30Days:
            startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate.addingTimeInterval(-30*24*60*60)
        case .yearToDate:
            var components = calendar.dateComponents([.year], from: endDate)
            components.month = 1
            components.day = 1
            startDate = calendar.date(from: components) ?? endDate.addingTimeInterval(-365*24*60*60)
        }
        
        return (startDate, endDate)
    }
}
