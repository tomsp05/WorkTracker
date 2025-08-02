//
//  AppIntent.swift
//  EarningsWidget
//
//  Created by Tom Speake on 8/2/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Work Tracker Widget" }
    static var description: IntentDescription { "View your work shift information and earnings at a glance." }

    @Parameter(title: "Show Period", default: .thisWeek)
    var timePeriod: TimePeriodOption
}

enum TimePeriodOption: String, CaseIterable, AppEnum {
    case today = "today"
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Time Period"
    }
    
    static var caseDisplayRepresentations: [TimePeriodOption: DisplayRepresentation] {
        [
            .today: "Today",
            .thisWeek: "This Week", 
            .thisMonth: "This Month"
        ]
    }
}
