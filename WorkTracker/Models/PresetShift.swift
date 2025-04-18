//
//  PresetShift.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/18/25.
//


//
//  PresetShift.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/18/25.
//

import Foundation

struct PresetShift: Identifiable, Codable {
    var id = UUID()
    var name: String
    var startTime: Date
    var endTime: Date
    var breakDuration: Double
    
    // Computed property for duration
    var duration: Double {
        let totalMinutes = endTime.timeIntervalSince(startTime) / 60
        let breakMinutes = breakDuration * 60
        return (totalMinutes - breakMinutes) / 60 // Convert to hours
    }
}