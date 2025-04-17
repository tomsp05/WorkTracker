//
//  JobDetailView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//

import SwiftUI
import Charts

struct JobDetailView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingEditSheet = false
    @State private var timeRange: TimeRange = .thisMonth
    @State private var selectedChartTab: ChartType = .earnings
    
    var job: Job
    
    // The actual job from the view model might be updated
    private var currentJob: Job {
        viewModel.jobs.first(where: { $0.id == job.id }) ?? job
    }
    
    // Job statistics
    private var jobShifts: [WorkShift] {
        let (startDate, endDate) = timeRange.dateRange
        return viewModel.shifts
            .filter { $0.jobId == job.id && $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date > $1.date }
    }
    
    private var totalShifts: Int {
        return jobShifts.count
    }
    
    private var totalHours: Double {
        return jobShifts.reduce(0) { $0 + $1.duration }
    }
    
    private var totalEarnings: Double {
        return jobShifts.reduce(0) { $0 + $1.earnings }
    }
    
    private var averageHoursPerShift: Double {
        return totalShifts > 0 ? totalHours / Double(totalShifts) : 0
    }
    
    private var effectiveHourlyRate: Double {
        return totalHours > 0 ? totalEarnings / totalHours : 0
    }
    
    // Color for the job
    private var jobColor: Color {
        return getJobColor(currentJob.color ?? "Blue") // Add default color value
    }
    
    private var jobColorGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                jobColor.opacity(0.7),
                jobColor
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // All-time stats for this job
    private var allTimeJobShifts: Int {
        return viewModel.shifts.filter { $0.jobId == job.id }.count
    }
    
    private var allTimeJobHours: Double {
        return viewModel.shifts.filter { $0.jobId == job.id }.reduce(0) { $0 + $1.duration }
    }
    
    private var allTimeJobEarnings: Double {
        return viewModel.shifts.filter { $0.jobId == job.id }.reduce(0) { $0 + $1.earnings }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Job overview card
                jobOverviewCard
                
                // Time period selector
                timeRangeSelector
                
                // Statistics cards
                statisticsCardsSection
                
                // Chart section
                chartSection
                
                // Recent shifts section
                recentShiftsSection
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationTitle(currentJob.name)
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingEditSheet = true
                }) {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                JobFormView(isPresented: $showingEditSheet, job: currentJob)
                    .environmentObject(viewModel)
                    .navigationTitle("Edit Job")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingEditSheet = false
                        }
                    )
            }
            .environmentObject(viewModel)
        }
    }
    
    // MARK: - View Sections
    
    private var jobOverviewCard: some View {
        VStack {
            HStack(alignment: .center) {
                // Color circle
                Circle()
                    .fill(jobColor)
                    .frame(width: 30, height: 30)
                
                Text(currentJob.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !currentJob.isActive {
                    Text("Inactive")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.secondary)
                        .cornerRadius(20)
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hourly Rate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(currentJob.hourlyRate) + "/hr")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("All-time Earnings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(allTimeJobEarnings))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(jobColor)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All-time Hours")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatHours(allTimeJobHours))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("All-time Shifts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(allTimeJobShifts)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var timeRangeSelector: some View {
        Picker("Time Range", selection: $timeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    private var statisticsCardsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatisticCardView(
                    title: "Total Earnings",
                    value: formatCurrency(totalEarnings),
                    iconName: "dollarsign.circle.fill"
                )
                .environmentObject(viewModel)
                
                StatisticCardView(
                    title: "Total Hours",
                    value: formatHours(totalHours),
                    iconName: "clock.fill"
                )
                .environmentObject(viewModel)
            }
            
            HStack(spacing: 16) {
                StatisticCardView(
                    title: "Avg. Hours/Shift",
                    value: formatHours(averageHoursPerShift),
                    iconName: "gauge.medium"
                )
                .environmentObject(viewModel)
                
                StatisticCardView(
                    title: "Effective Rate",
                    value: formatCurrency(effectiveHourlyRate) + "/h",
                    iconName: "chart.bar.fill"
                )
                .environmentObject(viewModel)
            }
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview")
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
                        .foregroundStyle(jobColorGradient)
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
    
    private var recentShiftsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Shifts")
                .font(.headline)
            
            if jobShifts.isEmpty {
                VStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("No shifts available for this period")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(jobShifts.prefix(5)) { shift in
                        NavigationLink(destination: EditShiftView(shift: shift).environmentObject(viewModel)) {
                            ShiftCardView(shift: shift)
                                .environmentObject(viewModel)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if jobShifts.count > 5 {
                    NavigationLink(destination: ShiftsListView(filterJobId: job.id).environmentObject(viewModel)) {
                        Text("See All Shifts")
                            .font(.headline)
                            .foregroundColor(jobColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(jobColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            .cornerRadius(15)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private var chartData: [ChartData] {
        switch selectedChartTab {
        case .earnings:
            return generateChartData(calculating: .earnings)
        case .hours:
            return generateChartData(calculating: .hours)
        }
    }
    
    private func generateChartData(calculating type: ChartCalculationType) -> [ChartData] {
        let (startDate, endDate) = timeRange.dateRange
        let calendar = Calendar.current
        var chartData: [ChartData] = []
        
        switch timeRange {
        case .today:
            // For today, show hourly data
            for hour in 0..<24 {
                if let hourDate = calendar.date(byAdding: .hour, value: hour, to: calendar.startOfDay(for: Date())) {
                    let nextHour = calendar.date(byAdding: .hour, value: 1, to: hourDate)!
                    let hourShifts = jobShifts.filter { shift in
                        shift.startTime < nextHour && shift.endTime > hourDate
                    }
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "ha"
                    
                    let value: Double
                    if type == .earnings {
                        value = calculateProportionalValue(shifts: hourShifts, startTime: hourDate, endTime: nextHour, valueType: .earnings)
                    } else {
                        value = calculateProportionalValue(shifts: hourShifts, startTime: hourDate, endTime: nextHour, valueType: .hours)
                    }
                    
                    if value > 0 {
                        chartData.append(ChartData(
                            id: UUID(),
                            label: formatter.string(from: hourDate),
                            value: value
                        ))
                    }
                }
            }
            
        case .thisWeek:
            // For this week, daily data
            let formatter = DateFormatter()
            formatter.dateFormat = "E" // Short day name
            
            var currentDate = startDate
            while currentDate <= endDate {
                let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                let dailyShifts = jobShifts.filter { $0.date >= currentDate && $0.date < nextDate }
                
                let value: Double
                if type == .earnings {
                    value = dailyShifts.reduce(0) { $0 + $1.earnings }
                } else {
                    value = dailyShifts.reduce(0) { $0 + $1.duration }
                }
                
                chartData.append(ChartData(
                    id: UUID(),
                    label: formatter.string(from: currentDate),
                    value: value
                ))
                
                currentDate = nextDate
            }
            
        case .thisMonth, .last30Days:
            // For month view, weekly data
            let weekFormatter = DateFormatter()
            weekFormatter.dateFormat = "'W'w" // Week number
            
            // Get the start of the week properly
            let weekDateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate)
            if let currentWeekStart = calendar.date(from: weekDateComponents) {
                var weekStart = currentWeekStart
                
                while weekStart < endDate {
                    let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
                    let weeklyShifts = jobShifts.filter {
                        $0.date >= weekStart && $0.date < nextWeekStart
                    }
                    
                    let value: Double
                    if type == .earnings {
                        value = weeklyShifts.reduce(0) { $0 + $1.earnings }
                    } else {
                        value = weeklyShifts.reduce(0) { $0 + $1.duration }
                    }
                    
                    chartData.append(ChartData(
                        id: UUID(),
                        label: weekFormatter.string(from: weekStart),
                        value: value
                    ))
                    
                    weekStart = nextWeekStart
                }
            }
        }
        
        return chartData
    }
    
    // Calculate proportional value for shifts that span multiple segments
    private func calculateProportionalValue(shifts: [WorkShift], startTime: Date, endTime: Date, valueType: ChartCalculationType) -> Double {
        shifts.reduce(0) { sum, shift in
            let shiftDuration = shift.endTime.timeIntervalSince(shift.startTime)
            let periodStart = max(startTime, shift.startTime)
            let periodEnd = min(endTime, shift.endTime)
            
            if periodStart >= periodEnd {
                return sum
            }
            
            let periodDuration = periodEnd.timeIntervalSince(periodStart)
            let proportion = shiftDuration > 0 ? (periodDuration / shiftDuration) : 0
            
            if valueType == .earnings {
                return sum + (shift.earnings * proportion)
            } else {
                return sum + (periodDuration / 3600) // Convert to hours
            }
        }
    }
    
    // Format currency
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
    
    // Get job color
    private func getJobColor(_ colorName: String) -> Color {
        switch colorName {
        case "Blue": return Color(red: 0.20, green: 0.40, blue: 0.70)
        case "Green": return Color(red: 0.20, green: 0.55, blue: 0.30)
        case "Orange": return Color(red: 0.80, green: 0.40, blue: 0.20)
        case "Purple": return Color(red: 0.50, green: 0.25, blue: 0.70)
        case "Red": return Color(red: 0.70, green: 0.20, blue: 0.20)
        case "Teal": return Color(red: 0.20, green: 0.50, blue: 0.60)
        default: return .blue
        }
    }
}
