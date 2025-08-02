//
//  EarningsWidgetBundle.swift
//  EarningsWidget
//
//  Created by Tom Speake on 8/2/25.
//

import WidgetKit
import SwiftUI

@main
struct EarningsWidgetBundle: WidgetBundle {
    var body: some Widget {
        EarningsWidget()
        EarningsWidgetControl()
        EarningsWidgetLiveActivity()
    }
}
