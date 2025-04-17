//
//  EarningsDetailView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//

import SwiftUI
import Charts

struct EarningsDetailView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var timeRange: TimeRange
    
    // For the charts
    @State private var selectedChartTab: ChartType = .earnings
    
    // For the detail stats
    private var totalEarnings: Double {
        let (startDate, endDate) = timeRange.dateRange
        return viewModel.totalEarnings(from: startDate, to: endDate)
    }
    
    private var totalHours: Double {
        let (startDate, endDate) = timeRange.dateRange
        return viewModel.totalHours(from: startDate, to: endDate)
    }
    
    private var averageHourlyRate: Double {
        if totalHours > 0 {
            return totalEarnings / totalHours
        }
        return 0.0
    }
    
    private var totalShifts: Int {
        let (startDate, endDate) = timeRange.dateRange
        return viewModel.shifts.filter { $0.date >= startDate && $0.date <= endDate }.count
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
        let (startDate, endDate) = timeRange.dateRange
        var breakdown: [(job: Job, hours: Double, earnings: Double)] = []
        
        for job in viewModel.jobs where job.isActive {
            let jobShifts = viewModel.shifts.filter { $0.jobId == job.id && $0.date >= startDate && $0.date <= endDate }
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
                // Summary cards
                statisticCardsSection
                
                // Chart section
                chartSection
                
                // Job breakdown section
                jobBreakdownSection
                
                // Time period selector
                timeRangeSection
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationTitle("Earnings Detail")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
    }
    
    // MARK: - View Sections
    
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
    
    private var timeRangeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time Period")
                .font(.headline)
            
            Picker("Time Range", selection: $timeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
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
        let (startDate, endDate) = timeRange.dateRange
        
        switch timeRange {
        case .today:
            // Hourly breakdown for today
            return generateHourlyChartData(calculating: .earnings)
            
        case .thisWeek, .last30Days:
            // Daily breakdown
            return generateDailyChartData(from: startDate, to: endDate, calculating: .earnings)
            
        case .thisMonth:
            // Weekly breakdown for this month
            return generateWeeklyChartData(from: startDate, to: endDate, calculating: .earnings)
        }
    }
    
    private func generateHoursChartData() -> [ChartData] {
        let (startDate, endDate) = timeRange.dateRange
        
        switch timeRange {
        case .today:
            // Hourly breakdown for today
            return generateHourlyChartData(calculating: .hours)
            
        case .thisWeek, .last30Days:
            // Daily breakdown
            return generateDailyChartData(from: startDate, to: endDate, calculating: .hours)
            
        case .thisMonth:
            // Weekly breakdown for this month
            return generateWeeklyChartData(from: startDate, to: endDate, calculating: .hours)
        }
    }
    
    private func generateHourlyChartData(calculating type: ChartCalculationType) -> [ChartData] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        var chartData: [ChartData] = []
        
        // Group shifts by hour
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        
        // Create hour slots for the full day (0-23)
        for hour in 0..<24 {
            if let hourDate = calendar.date(byAdding: .hour, value: hour, to: startOfDay) {
                let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourDate)!
                
                // Filter shifts that were active during this hour
                let hourShifts = viewModel.shifts.filter { shift in
                    shift.startTime < hourEnd && shift.endTime > hourDate
                }
                
                // Calculate value based on type
                let value: Double
                if type == .earnings {
                    value = hourShifts.reduce(0) { sum, shift in
                        // Calculate proportional earnings for this hour
                        let totalShiftMinutes = shift.endTime.timeIntervalSince(shift.startTime) / 60
                        let hourStartOverlap = max(hourDate, shift.startTime)
                        let hourEndOverlap = min(hourEnd, shift.endTime)
                        let overlapMinutes = hourEndOverlap.timeIntervalSince(hourStartOverlap) / 60
                        let proportionOfShift = totalShiftMinutes > 0 ? overlapMinutes / totalShiftMinutes : 0
                        
                        // Use our correct earnings calculation
                        let fullShiftEarnings = calculateShiftEarnings(shift)
                        return sum + (fullShiftEarnings * proportionOfShift)
                    }
                } else {
                    // Hours calculation - add up overlapping time
                    value = hourShifts.reduce(0) { sum, shift in
                        let hourStartOverlap = max(hourDate, shift.startTime)
                        let hourEndOverlap = min(hourEnd, shift.endTime)
                        let overlapHours = hourEndOverlap.timeIntervalSince(hourStartOverlap) / 3600
                        return sum + overlapHours
                    }
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
        
        return chartData
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
    
    private func generateWeeklyChartData(from startDate: Date, to endDate: Date, calculating type: ChartCalculationType) -> [ChartData] {
        let calendar = Calendar.current
        var chartData: [ChartData] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "'Week' w"
        
        // Use dateComponents to get start of week properly - fixes the calendar warning
        let weekDateComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate)
        if let currentWeekStart = calendar.date(from: weekDateComponents) {
            var weekStart = currentWeekStart
            
            while weekStart <= endDate {
                let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
                
                // Get shifts for this week
                let weekShifts = viewModel.shifts.filter {
                    $0.date >= weekStart && $0.date < nextWeekStart
                }
                
                // Calculate value
                let value: Double
                if type == .earnings {
                    // Use our correct earnings calculation
                    value = weekShifts.reduce(0) { $0 + calculateShiftEarnings($1) }
                } else {
                    value = weekShifts.reduce(0) { $0 + $1.duration }
                }
                
                chartData.append(ChartData(
                    id: UUID(),
                    label: formatter.string(from: weekStart),
                    value: value
                ))
                
                weekStart = nextWeekStart
            }
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
