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
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate timeline entries for the next 8 hours, updating every hour
        let currentDate = Date()
        for hourOffset in 0 ..< 8 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct EarningsWidgetEntryView : View {
    var entry: Provider.Entry
    
    // Get theme color from shared preferences
    private var themeColorName: String {
        SharedDataService.shared.themeColor()
    }
    
    private var themeColor: Color {
        switch themeColorName {
        case "Blue":
            return Color(red: 0.20, green: 0.40, blue: 0.70)
        case "Green":
            return Color(red: 0.20, green: 0.55, blue: 0.30)
        case "Orange":
            return Color(red: 0.80, green: 0.40, blue: 0.20)
        case "Purple":
            return Color(red: 0.50, green: 0.25, blue: 0.70)
        case "Red":
            return Color(red: 0.70, green: 0.20, blue: 0.20)
        case "Teal":
            return Color(red: 0.20, green: 0.50, blue: 0.60)
        case "Pink":
            return Color(red: 0.90, green: 0.40, blue: 0.60)
        default:
            return Color(red: 0.20, green: 0.40, blue: 0.70)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with month
            HStack {
                Text(currentMonthTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.title3)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Spacer()
            
            // Main earnings display
            VStack(spacing: 4) {
                Text(formatCurrency(SharedDataService.shared.monthlyEarnings()))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(formatHours(SharedDataService.shared.monthlyHours())) this month")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            // Bottom stats row
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This Week")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(formatCurrency(SharedDataService.shared.weeklyEarnings()))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(formatHours(SharedDataService.shared.todayHours()))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    themeColor.opacity(0.8),
                    themeColor
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Helper Methods
    
    private var currentMonthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: entry.date)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "£0"
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
}

struct EarningsWidget: Widget {
    let kind: String = "EarningsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            EarningsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Work Earnings")
        .description("Track your monthly earnings and hours worked")
        .supportedFamilies([.systemSmall])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var standard: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        return intent
    }
}

#Preview(as: .systemSmall) {
    EarningsWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .standard)
    SimpleEntry(date: Date().addingTimeInterval(3600), configuration: .standard)
}
