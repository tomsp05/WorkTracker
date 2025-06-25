import SwiftUI
import Charts

struct EarningsDetailView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    
    // New filter state
    @State private var filterState = AnalyticsFilterState()

    // For the charts
    @State private var selectedChartTab: ChartType = .earnings
    
    // MARK: - Computed Properties
    
    private var dateRange: (start: Date, end: Date) {
        var startDate: Date
        var endDate: Date
        let calendar = Calendar.current
        let now = Date()
        
        switch filterState.timeFilter {
        case .week:
            var weekCal = calendar
            weekCal.firstWeekday = 2 // Monday
            guard let thisWeekStart = weekCal.dateInterval(of: .weekOfYear, for: now)?.start else {
                endDate = now
                startDate = weekCal.date(byAdding: .day, value: -6, to: now)!
                break
            }
            startDate = weekCal.date(byAdding: .weekOfYear, value: filterState.timeOffset, to: thisWeekStart)!
            endDate = weekCal.date(byAdding: .day, value: 6, to: startDate)!
        case .month:
            guard let thisMonthStart = calendar.dateInterval(of: .month, for: now)?.start else {
                endDate = now
                startDate = calendar.date(byAdding: .day, value: -29, to: now)!
                break
            }
            startDate = calendar.date(byAdding: .month, value: filterState.timeOffset, to: thisMonthStart)!
            if filterState.timeOffset == 0 {
                endDate = now
            } else {
                let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: startDate)!
                endDate = nextMonthStart.addingTimeInterval(-1)
            }
        case .yearToDate:
            endDate = now.addingTimeInterval(Double(filterState.timeOffset) * (365 * 24 * 60 * 60))
            var comps = calendar.dateComponents([.year], from: endDate)
            comps.month = 1
            comps.day = 1
            startDate = calendar.date(from: comps)!
        case .year:
            endDate = now.addingTimeInterval(Double(filterState.timeOffset) * (365 * 24 * 60 * 60))
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
        }
        
        return (start: startDate, end: endDate)
    }
    
    private var timePeriodTitle: String {
        let formatter = DateFormatter()
        
        switch filterState.timeFilter {
        case .week:
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: dateRange.start)
        case .yearToDate:
            formatter.dateFormat = "yyyy"
            let year = formatter.string(from: dateRange.end)
            return "\(year) YTD"
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: dateRange.start)
        }
    }
    
    // For the detail stats
    private var totalEarnings: Double {
        viewModel.totalEarnings(from: dateRange.start, to: dateRange.end)
    }
    
    private var totalHours: Double {
        viewModel.totalHours(from: dateRange.start, to: dateRange.end)
    }
    
    private var averageHourlyRate: Double {
        if totalHours > 0 {
            return totalEarnings / totalHours
        }
        return 0.0
    }
    
    private var totalShifts: Int {
        viewModel.shifts.filter { $0.date >= dateRange.start && $0.date <= dateRange.end }.count
    }
    
    // Helper function to calculate earnings for a shift
    private func calculateShiftEarnings(_ shift: WorkShift) -> Double {
        // Get the appropriate rate (either override or job rate)
        let rate: Double
        if let override = shift.hourlyRateOverride {
            rate = override
        } else if let job = viewModel.jobs.first(where: { $0.id == shift.jobId }) {
            rate = job.hourlyRate
        } else {
            rate = 0.0
        }
        
        // Apply shift type multiplier
        let multiplier: Double = {
            switch shift.shiftType {
            case .regular: return 1.0
            case .overtime: return 1.5
            case .holiday: return 2.0
            }
        }()
        
        return shift.duration * rate * multiplier
    }
    
    // Job breakdown for the period
    private var jobBreakdown: [(job: Job, hours: Double, earnings: Double)] {
        var breakdown: [(job: Job, hours: Double, earnings: Double)] = []
        
        for job in viewModel.jobs where job.isActive {
            let jobShifts = viewModel.shifts.filter { $0.jobId == job.id && $0.date >= dateRange.start && $0.date <= dateRange.end }
            let hours = jobShifts.reduce(0) { $0 + $1.duration }
            
            // Calculate correct earnings for each shift
            let earnings = jobShifts.reduce(0) { $0 + calculateShiftEarnings($1) }
            
            if hours > 0 {
                breakdown.append((job: job, hours: hours, earnings: earnings))
            }
        }
        
        // Sort by earnings (highest first)
        return breakdown.sorted { $0.earnings > $1.earnings }
    }
    
    // Chart data for earnings/hours
    private var chartData: [ChartData] {
        switch selectedChartTab {
        case .earnings:
            return generateEarningsChartData()
        case .hours:
            return generateHoursChartData()
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Time navigation header
                timeNavigationView
                
                // Summary cards
                statisticCardsSection
                
                // Chart section
                chartSection
                
                // Job breakdown section
                jobBreakdownSection
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationTitle("Earnings Detail")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
    }
    
    // MARK: - View Sections
    
    private var timeNavigationView: some View {
        VStack(spacing: 12) {
            Picker("Time Filter", selection: $filterState.timeFilter) {
                ForEach(AnalyticsTimeFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            HStack {
                Button(action: { filterState.timeOffset -= 1 }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(viewModel.themeColor)
                        .font(.system(size: 16, weight: .medium))
                        .padding(8)
                        .background(Circle().fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1)))
                }
                
                Spacer()
                
                Text(timePeriodTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Button(action: { if filterState.timeOffset < 0 { filterState.timeOffset += 1 } }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(viewModel.themeColor)
                        .font(.system(size: 16, weight: .medium))
                        .padding(8)
                        .background(Circle().fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1)))
                }
                .disabled(filterState.timeOffset == 0).opacity(filterState.timeOffset == 0 ? 0.5 : 1.0)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var statisticCardsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatisticCardView(
                    title: "Total Earnings",
                    value: formatCurrency(totalEarnings),
                    iconName: "dollarsign.circle.fill"
                )
                
                StatisticCardView(
                    title: "Total Hours",
                    value: formatHours(totalHours),
                    iconName: "clock.fill"
                )
            }
            
            HStack(spacing: 16) {
                StatisticCardView(
                    title: "Average Rate",
                    value: formatCurrency(averageHourlyRate) + "/h",
                    iconName: "chart.bar.fill"
                )
                
                StatisticCardView(
                    title: "Total Shifts",
                    value: "\(totalShifts)",
                    iconName: "calendar.badge.clock"
                )
            }
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Earnings Overview")
                .font(.headline)
            
            // Tab selector for chart type
            Picker("Chart Type", selection: $selectedChartTab) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if chartData.isEmpty {
                VStack {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("No data available for this period")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 250)
            } else {
                // Chart view
                Chart {
                    ForEach(chartData) { item in
                        BarMark(
                            x: .value("Date", item.label),
                            y: .value(selectedChartTab.rawValue, item.value)
                        )
                        .foregroundStyle(viewModel.themeColor.gradient)
                    }
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                if selectedChartTab == .earnings {
                                    Text(formatCurrency(doubleValue))
                                } else {
                                    Text(formatHours(doubleValue))
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var jobBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Job Breakdown")
                .font(.headline)
            
            if jobBreakdown.isEmpty {
                VStack {
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("No job data available for this period")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(jobBreakdown, id: \.job.id) { item in
                    JobBreakdownRow(
                        job: item.job,
                        hours: item.hours,
                        earnings: item.earnings,
                        percentage: item.earnings / totalEarnings
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
    
    private func formatHours(_ hours: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        
        guard let formattedHours = formatter.string(from: NSNumber(value: hours)) else {
            return "\(hours)h"
        }
        
        return "\(formattedHours)h"
    }
    
    // Chart data generation based on time range
    private func generateEarningsChartData() -> [ChartData] {
        switch filterState.timeFilter {
        case .week, .month:
            // Daily breakdown
            return generateDailyChartData(from: dateRange.start, to: dateRange.end, calculating: .earnings)
            
        case .yearToDate, .year:
            // Monthly breakdown
            return generateMonthlyChartData(from: dateRange.start, to: dateRange.end, calculating: .earnings)
        }
    }
    
    private func generateHoursChartData() -> [ChartData] {
        switch filterState.timeFilter {
        case .week, .month:
            // Daily breakdown
            return generateDailyChartData(from: dateRange.start, to: dateRange.end, calculating: .hours)
            
        case .yearToDate, .year:
            // Monthly breakdown
            return generateMonthlyChartData(from: dateRange.start, to: dateRange.end, calculating: .hours)
        }
    }
    
    private func generateDailyChartData(from startDate: Date, to endDate: Date, calculating type: ChartCalculationType) -> [ChartData] {
        let calendar = Calendar.current
        var chartData: [ChartData] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Short day name like "Mon"
        
        var currentDate = startDate
        while currentDate <= endDate {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            
            // Get shifts for this day
            let dayShifts = viewModel.shifts.filter {
                $0.date >= currentDate && $0.date < nextDate
            }
            
            // Calculate value
            let value: Double
            if type == .earnings {
                // Use our correct earnings calculation
                value = dayShifts.reduce(0) { $0 + calculateShiftEarnings($1) }
            } else {
                value = dayShifts.reduce(0) { $0 + $1.duration }
            }
            
            chartData.append(ChartData(
                id: UUID(),
                label: formatter.string(from: currentDate),
                value: value
            ))
            
            currentDate = nextDate
        }
        
        return chartData
    }
    
    private func generateMonthlyChartData(from startDate: Date, to endDate: Date, calculating type: ChartCalculationType) -> [ChartData] {
        let calendar = Calendar.current
        var chartData: [ChartData] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM" // Month abbreviation (Jan, Feb, etc.)
        
        // Start with the first day of the month in the start date
        var components = calendar.dateComponents([.year, .month], from: startDate)
        
        // Create a date for each month from start to end
        while let monthStart = calendar.date(from: components), monthStart <= endDate {
            // Calculate the first day of the next month
            components.month! += 1
            let nextMonthStart = calendar.date(from: components)!
            
            // Get shifts for this month
            let monthShifts = viewModel.shifts.filter {
                $0.date >= monthStart && $0.date < nextMonthStart && $0.date <= endDate
            }
            
            // Calculate value
            let value: Double
            if type == .earnings {
                // Use our correct earnings calculation
                value = monthShifts.reduce(0) { $0 + calculateShiftEarnings($1) }
            } else {
                value = monthShifts.reduce(0) { $0 + $1.duration }
            }
            
            chartData.append(ChartData(
                id: UUID(),
                label: formatter.string(from: monthStart),
                value: value
            ))
        }
        
        return chartData
    }
}

// MARK: - Supporting Types

enum ChartType: String, CaseIterable {
    case earnings = "Earnings"
    case hours = "Hours"
}

enum ChartCalculationType {
    case earnings
    case hours
}

struct ChartData: Identifiable {
    var id: UUID
    var label: String
    var value: Double
}

// MARK: - Helper Views

struct StatisticCardView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var title: String
    var value: String
    var iconName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: iconName)
                    .foregroundColor(viewModel.themeColor)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct JobBreakdownRow: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    
    var job: Job
    var hours: Double
    var earnings: Double
    var percentage: Double
    
    private var jobColor: Color {
        switch job.color {
        case "Blue": return Color(red: 0.20, green: 0.40, blue: 0.70)
        case "Green": return Color(red: 0.20, green: 0.55, blue: 0.30)
        case "Orange": return Color(red: 0.80, green: 0.40, blue: 0.20)
        case "Purple": return Color(red: 0.50, green: 0.25, blue: 0.70)
        case "Red": return Color(red: 0.70, green: 0.20, blue: 0.20)
        case "Teal": return Color(red: 0.20, green: 0.50, blue: 0.60)
        default: return .blue
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
    
    private func formatHours(_ hours: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        
        guard let formattedHours = formatter.string(from: NSNumber(value: hours)) else {
            return "\(hours)h"
        }
        
        return "\(formattedHours)h"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Job color indicator
                Circle()
                    .fill(jobColor)
                    .frame(width: 12, height: 12)
                
                Text(job.name)
                    .font(.headline)
                
                Spacer()
                
                Text(formatCurrency(earnings))
                    .font(.headline)
                    .foregroundColor(jobColor)
            }
            
            HStack {
                Text("\(formatHours(hours)) • \(Int(percentage * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Progress bar showing percentage of total
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: geo.size.width, height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(jobColor)
                        .frame(width: max(4, geo.size.width * percentage), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 8)
    }
}
