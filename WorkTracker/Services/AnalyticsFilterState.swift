//
//  AnalyticsFilterState.swift
//  WorkTracker
//
//  Created by Tom Speake on 6/25/25.
//


import Foundation

struct AnalyticsFilterState: Codable, Equatable {
    var timeFilter: AnalyticsTimeFilter = .month
    var timeOffset: Int = 0
}

enum AnalyticsTimeFilter: String, Codable, CaseIterable, Equatable {
    case week = "Week"
    case month = "Month"
    case yearToDate = "YTD"
    case year = "Year"
}