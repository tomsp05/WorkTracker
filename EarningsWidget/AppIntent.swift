//
//  AppIntent.swift
//  EarningsWidget
//
//  Created by Tom Speake on 8/2/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Work Earnings Widget" }
    static var description: IntentDescription { "Track your monthly earnings and work hours." }
}
