import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var previousEarnings: Double = 0.0
    @State private var isAnimating: Bool = false
    @State private var animationScale: CGFloat = 1.0
    @State private var showChangeAmount: Bool = false
    @State private var viewDidAppear = false
    
    // Date range for the summary
    @State private var timeRange: TimeRange = .thisWeek
    
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
            .sorted { $0.date > $1.date }
            .prefix(5)
            .filter { $0.date <= Date() } // Only show past or today's shifts
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
    
    // Refresh earnings display
    func refreshEarningsDisplay() {
        let currentAmount = currentEarnings
        
        if previousEarnings != currentAmount {
            // Trigger animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                animationScale = 1.1
                isAnimating = true
                showChangeAmount = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    animationScale = 1.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    isAnimating = false
                    showChangeAmount = false
                }
                previousEarnings = currentAmount
            }
        } else {
            previousEarnings = currentAmount
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Earnings summary header - matching the Finance app's design
                    NavigationLink(destination: EarningsDetailView(timeRange: $timeRange)) {
                        VStack(spacing: 8) {
                            Text(timeRange.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ZStack(alignment: .center) {
                                // Main earnings with animation
                                CountingValueView(
                                    value: currentEarnings,
                                    fromValue: previousEarnings,
                                    isAnimating: isAnimating,
                                    fontSize: 42,
                                    positiveColor: .white,
                                    negativeColor: .white
                                )
                                .scaleEffect(animationScale)
                                .modifier(ShimmerEffect(
                                    isAnimating: isAnimating,
                                    isDarkMode: colorScheme == .dark
                                ))
                                
                                // Change amount badge
                                if showChangeAmount && previousEarnings != currentEarnings {
                                    let difference = currentEarnings - previousEarnings
                                    VStack {
                                        HStack(spacing: 4) {
                                            Image(systemName: difference >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                                .foregroundColor(difference >= 0 ? .green : .red)
                                                .font(.system(size: 16))
                                            
                                            Text(formatCurrency(abs(difference)))
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(difference >= 0 ? .green : .red)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color(UIColor.secondarySystemBackground))
                                                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                        )
                                        .offset(y: -50)
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            
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
                        .padding(.vertical, 24)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
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
                    }
                    
                    // Time range picker
                    Picker("Time Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: timeRange) { _, _ in
                        refreshEarningsDisplay()
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
                                    subtitle: "Customize",
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
                            VStack(spacing: 12) {
                                ForEach(recentShifts) { shift in
                                    NavigationLink(destination: EditShiftView(shift: shift)) {
                                        ShiftCardView(shift: shift)
                                            .environmentObject(viewModel)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            
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
            .navigationTitle("Work Hours")
            .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
            .onAppear {
                previousEarnings = currentEarnings
                viewDidAppear = true
                
                DispatchQueue.main.async {
                    self.refreshEarningsDisplay()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                if viewDidAppear {
                    DispatchQueue.main.async {
                        self.refreshEarningsDisplay()
                    }
                }
            }
            .onChange(of: viewModel.earningsDidChange) { _, _ in
                let newEarningsValue = currentEarnings
                
                // Trigger animation when earnings change
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    animationScale = 1.1
                    isAnimating = true
                    showChangeAmount = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        animationScale = 1.0
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isAnimating = false
                        showChangeAmount = false
                    }
                    previousEarnings = newEarningsValue
                }
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
        }
        
        return (startDate, endDate)
    }
}

// Reusing the Shimmer Effect from Finance app
struct ShimmerEffect: ViewModifier {
    var isAnimating: Bool
    var isDarkMode: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        if isAnimating {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.clear, location: 0),
                                .init(color: isDarkMode ? Color.white.opacity(0.3) : Color.white.opacity(0.5), location: 0.3),
                                .init(color: isDarkMode ? Color.white.opacity(0.3) : Color.white.opacity(0.5), location: 0.7),
                                .init(color: Color.clear, location: 1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .mask(content)
                        .frame(width: geo.size.width * 2)
                        .offset(x: -geo.size.width + (geo.size.width * 2) * phase)
                    }
                    .mask(content)
                )
                .onAppear {
                    withAnimation(Animation.linear(duration: 1.0).repeatCount(2)) {
                        self.phase = 1.0
                    }
                }
        } else {
            content
        }
    }
}
