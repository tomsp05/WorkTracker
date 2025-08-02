//
//  EarningsWidget.swift
//  EarningsWidget
//
//  Created by Tom Speake on 8/2/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            totalEarnings: 150.50,
            totalHours: 12.5,
            todayShift: nil,
            upcomingShift: WorkShift(
                jobId: UUID(),
                date: Date().addingTimeInterval(3600),
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(7200),
                breakDuration: 0.5
            ),
            jobs: [Job(name: "Main Job", hourlyRate: 12.50, color: "Blue")]
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let data = loadWidgetData(for: configuration.timePeriod)
        return SimpleEntry(
            date: Date(),
            configuration: configuration,
            totalEarnings: data.earnings,
            totalHours: data.hours,
            todayShift: data.todayShift,
            upcomingShift: data.upcomingShift,
            jobs: data.jobs
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        
        // Generate entries for the next few hours
        for hourOffset in 0..<6 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let data = loadWidgetData(for: configuration.timePeriod)
            
            let entry = SimpleEntry(
                date: entryDate,
                configuration: configuration,
                totalEarnings: data.earnings,
                totalHours: data.hours,
                todayShift: data.todayShift,
                upcomingShift: data.upcomingShift,
                jobs: data.jobs
            )
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .hour, value: 6, to: currentDate)!))
    }
    
    private func loadWidgetData(for period: TimePeriodOption) -> (earnings: Double, hours: Double, todayShift: WorkShift?, upcomingShift: WorkShift?, jobs: [Job]) {
        let jobs = SharedDataService.shared.loadJobs()
        let shifts = SharedDataService.shared.loadWorkShifts()
        
        let calendar = Calendar.current
        let now = Date()
        
        // Filter shifts based on selected period
        let filteredShifts: [WorkShift]
        switch period {
        case .today:
            filteredShifts = shifts.filter { calendar.isDate($0.date, inSameDayAs: now) }
        case .thisWeek:
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let weekEnd = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
            filteredShifts = shifts.filter { $0.date >= weekStart && $0.date <= weekEnd }
        case .thisMonth:
            let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let monthEnd = calendar.dateInterval(of: .month, for: now)?.end ?? now
            filteredShifts = shifts.filter { $0.date >= monthStart && $0.date <= monthEnd }
        }
        
        // Calculate totals
        let totalEarnings = filteredShifts.reduce(0) { total, shift in
            let job = jobs.first { $0.id == shift.jobId }
            return total + shift.earnings(with: job)
        }
        
        let totalHours = filteredShifts.reduce(0) { $0 + $1.duration }
        
        // Find today's shift and upcoming shift
        let todayShift = shifts.first { calendar.isDate($0.date, inSameDayAs: now) }
        let upcomingShift = shifts
            .filter { $0.date > now }
            .sorted { $0.date < $1.date }
            .first
        
        return (totalEarnings, totalHours, todayShift, upcomingShift, jobs)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let totalEarnings: Double
    let totalHours: Double
    let todayShift: WorkShift?
    let upcomingShift: WorkShift?
    let jobs: [Job]
}

struct EarningsWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    private var themeColor: Color {
        let colorName = SharedDataService.shared.loadThemeColor()
        return Color.themeColor(from: colorName)
    }
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry, themeColor: themeColor)
        case .systemMedium:
            MediumWidgetView(entry: entry, themeColor: themeColor)
        case .systemLarge:
            LargeWidgetView(entry: entry, themeColor: themeColor)
        default:
            SmallWidgetView(entry: entry, themeColor: themeColor)
        }
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: Provider.Entry
    let themeColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with period
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeColor)
                
                Text(periodTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Main earnings display
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.totalEarnings.formatAsCurrency())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("\(entry.totalHours.formatAsHours())")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Quick status
            if let todayShift = entry.todayShift {
                quickShiftStatus(todayShift)
            } else if let upcomingShift = entry.upcomingShift {
                quickUpcomingShift(upcomingShift)
            } else {
                Text("No shifts")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(widgetBackground)
    }
    
    private var periodTitle: String {
        switch entry.configuration.timePeriod {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        }
    }
    
    private func quickShiftStatus(_ shift: WorkShift) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let job = entry.jobs.first(where: { $0.id == shift.jobId }) {
                Text(job.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.themeColor(from: job.color))
                    .lineLimit(1)
            }
            
            Text("Today")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func quickUpcomingShift(_ shift: WorkShift) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let job = entry.jobs.first(where: { $0.id == shift.jobId }) {
                Text(job.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.themeColor(from: job.color))
                    .lineLimit(1)
            }
            
            Text("Next: \(shift.date, style: .relative)")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: Provider.Entry
    let themeColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Earnings summary
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(themeColor)
                    
                    Text(periodTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.totalEarnings.formatAsCurrency())
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(entry.totalHours.formatAsHours())")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right side - Shift information
            VStack(alignment: .leading, spacing: 12) {
                if let todayShift = entry.todayShift {
                    shiftCard(todayShift, title: "Today")
                } else {
                    Text("No shift today")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                if let upcomingShift = entry.upcomingShift {
                    shiftCard(upcomingShift, title: "Next Shift")
                } else {
                    Text("No upcoming shifts")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(widgetBackground)
    }
    
    private var periodTitle: String {
        switch entry.configuration.timePeriod {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        }
    }
    
    private func shiftCard(_ shift: WorkShift, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            if let job = entry.jobs.first(where: { $0.id == shift.jobId }) {
                Text(job.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.themeColor(from: job.color))
                    .lineLimit(1)
            }
            
            Text(shift.duration.formatAsHours())
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(colorScheme == .dark ? 0.1 : 0.05))
        )
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: Provider.Entry
    let themeColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    private var recentShifts: [WorkShift] {
        SharedDataService.shared.loadWorkShifts()
            .filter { $0.date <= Date() }
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with earnings summary
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(themeColor)
                        
                        Text(periodTitle)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Earnings")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(entry.totalEarnings.formatAsCurrency())
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hours")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(entry.totalHours.formatAsHours())
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // Recent shifts list
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Shifts")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                if recentShifts.isEmpty {
                    Text("No recent shifts")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(recentShifts) { shift in
                        shiftRow(shift)
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(widgetBackground)
    }
    
    private var periodTitle: String {
        switch entry.configuration.timePeriod {
        case .today: return "Today"
        case .thisWeek: return "This Week" 
        case .thisMonth: return "This Month"
        }
    }
    
    private func shiftRow(_ shift: WorkShift) -> some View {
        HStack(spacing: 8) {
            // Job color indicator
            if let job = entry.jobs.first(where: { $0.id == shift.jobId }) {
                Capsule()
                    .fill(Color.themeColor(from: job.color))
                    .frame(width: 3, height: 16)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(job.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(shift.date, style: .date)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 1) {
                Text(shift.earnings(with: entry.jobs.first { $0.id == shift.jobId }).formatAsCurrency())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(shift.duration.formatAsHours())
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Shared Components
extension View {
    var widgetBackground: some View {
        Rectangle()
            .fill(.regularMaterial)
            .background(Color(UIColor.systemBackground))
    }
}

struct EarningsWidget: Widget {
    let kind: String = "EarningsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            EarningsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Work Tracker")
        .description("View your work shift information and earnings at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var today: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.timePeriod = .today
        return intent
    }
    
    fileprivate static var thisWeek: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.timePeriod = .thisWeek
        return intent
    }
    
    fileprivate static var thisMonth: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.timePeriod = .thisMonth
        return intent
    }
}

#Preview(as: .systemSmall) {
    EarningsWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .today, totalEarnings: 85.50, totalHours: 6.5, todayShift: nil, upcomingShift: nil, jobs: [])
    SimpleEntry(date: .now, configuration: .thisWeek, totalEarnings: 420.75, totalHours: 32.5, todayShift: nil, upcomingShift: nil, jobs: [])
}

#Preview(as: .systemMedium) {
    EarningsWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .thisWeek, totalEarnings: 420.75, totalHours: 32.5, todayShift: nil, upcomingShift: nil, jobs: [])
}

#Preview(as: .systemLarge) {
    EarningsWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .thisMonth, totalEarnings: 1850.25, totalHours: 142.5, todayShift: nil, upcomingShift: nil, jobs: [])
}
