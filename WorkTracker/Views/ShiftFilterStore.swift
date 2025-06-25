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
    var timeFilter: ShiftTimeFilter = .all
    var customStartDate: Date?
    var customEndDate: Date?
    var selectedJobIds: Set<UUID> = []
    var minEarnings: Double?
    var maxEarnings: Double?
    var shiftTypes: Set<ShiftType> = []
    var isPaid: Bool? = nil

    var hasActiveFilters: Bool {
        return timeFilter != .all ||
               !selectedJobIds.isEmpty ||
               minEarnings != nil ||
               maxEarnings != nil ||
               !shiftTypes.isEmpty ||
                isPaid != nil
    }
}
