//
//  ShiftTimeFilter.swift
//  WorkTracker
//
//  Created by Tom Speake on 6/25/25.
//


import Foundation

// Enum for time-based filtering of shifts
enum ShiftTimeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case future = "Future"
    case past = "Past"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case custom = "Custom"

    var id: String { self.rawValue }

    var systemImage: String {
        switch self {
        case .all: return "infinity"
        case .future: return "arrow.right.square"
        case .past: return "arrow.left.square"
        case .today: return "sun.max"
        case .thisWeek: return "calendar.badge.clock"
        case .thisMonth: return "calendar"
        case .lastMonth: return "arrow.left.and.right.circle"
        case .custom: return "calendar.badge.plus"
        }
    }
}


// A struct to hold the state of the filters for the shifts list.
struct ShiftFilterState {
    var analytics = AnalyticsFilterState()
    var selectedJobIds: Set<UUID> = []
    var minEarnings: Double?
    var maxEarnings: Double?
    var shiftTypes: Set<ShiftType> = []
    var isPaid: Bool? = nil

    var hasActiveFilters: Bool {
        return analytics.timeFilter != .month || analytics.timeOffset != 0 ||
               !selectedJobIds.isEmpty ||
               minEarnings != nil ||
               maxEarnings != nil ||
               !shiftTypes.isEmpty ||
                isPaid != nil
    }
    
    var dateRange: (start: Date, end: Date) {
        var startDate: Date
        var endDate: Date
        let calendar = Calendar.current
        let now = Date()
        
        switch analytics.timeFilter {
        case .week:
            var weekCal = calendar
            weekCal.firstWeekday = 2 // Monday
            guard let thisWeekStart = weekCal.dateInterval(of: .weekOfYear, for: now)?.start else {
                endDate = now
                startDate = weekCal.date(byAdding: .day, value: -6, to: now)!
                break
            }
            startDate = weekCal.date(byAdding: .weekOfYear, value: analytics.timeOffset, to: thisWeekStart)!
            endDate = weekCal.date(byAdding: .day, value: 6, to: startDate)!
        case .month:
            guard let thisMonthStart = calendar.dateInterval(of: .month, for: now)?.start else {
                endDate = now
                startDate = calendar.date(byAdding: .day, value: -29, to: now)!
                break
            }
            startDate = calendar.date(byAdding: .month, value: analytics.timeOffset, to: thisMonthStart)!
            if analytics.timeOffset == 0 {
                endDate = now
            } else {
                let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: startDate)!
                endDate = nextMonthStart.addingTimeInterval(-1)
            }
        case .yearToDate:
            endDate = now.addingTimeInterval(Double(analytics.timeOffset) * (365 * 24 * 60 * 60))
            var comps = calendar.dateComponents([.year], from: endDate)
            comps.month = 1
            comps.day = 1
            startDate = calendar.date(from: comps)!
        case .year:
            endDate = now.addingTimeInterval(Double(analytics.timeOffset) * (365 * 24 * 60 * 60))
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
        }
        
        return (start: startDate, end: endDate)
    }
}
