//
//  PaySchedule.swift
//  WorkTracker
//
//

import Foundation

enum PayFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Bi-Weekly"
    case monthly = "Monthly"
    case custom = "Custom"
    
    var displayName: String {
        return self.rawValue
    }
}

struct PaySchedule: Identifiable, Codable {
    var id = UUID()
    var jobId: UUID
    var frequency: PayFrequency
    var startDate: Date // First pay date or reference date
    var customDayInterval: Int? // For custom schedules (e.g., every 15 days)
    var isActive: Bool = true
    
    // Calculate next pay date based on frequency
    func nextPayDate(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        
        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: startDate) ?? startDate
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .custom:
            let interval = customDayInterval ?? 14
            return calendar.date(byAdding: .day, value: interval, to: startDate) ?? startDate
        }
    }
    
    // Get all pay periods for a date range
    func payPeriodsInRange(from startDate: Date, to endDate: Date) -> [PayPeriod] {
        var periods: [PayPeriod] = []
        var currentDate = self.startDate
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            let periodEndDate: Date
            
            switch frequency {
            case .weekly:
                periodEndDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
            case .biweekly:
                periodEndDate = calendar.date(byAdding: .weekOfYear, value: 2, to: currentDate) ?? currentDate
            case .monthly:
                periodEndDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            case .custom:
                let interval = customDayInterval ?? 14
                periodEndDate = calendar.date(byAdding: .day, value: interval, to: currentDate) ?? currentDate
            }
            
            if currentDate >= startDate {
                periods.append(PayPeriod(
                    id: UUID(),
                    payScheduleId: id,
                    startDate: currentDate,
                    endDate: calendar.date(byAdding: .day, value: -1, to: periodEndDate) ?? currentDate,
                    payDate: periodEndDate
                ))
            }
            
            currentDate = periodEndDate
        }
        
        return periods
    }
}

struct PayPeriod: Identifiable, Codable {
    var id = UUID()
    var payScheduleId: UUID
    var startDate: Date
    var endDate: Date
    var payDate: Date
    
    // Check if a date falls within this pay period
    func contains(date: Date) -> Bool {
        return date >= startDate && date <= endDate
    }
}
