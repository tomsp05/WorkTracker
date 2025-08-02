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

struct PresetShift: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var startTime: Date
    var endTime: Date
    var breakDuration: Double
    
    init(id: UUID = UUID(), name: String, startTime: Date, endTime: Date, breakDuration: Double) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.breakDuration = breakDuration
    }
    
    // Computed property for duration
    var duration: Double {
        let totalMinutes = endTime.timeIntervalSince(startTime) / 60
        let breakMinutes = breakDuration * 60
        return (totalMinutes - breakMinutes) / 60 // Convert to hours
    }
}
