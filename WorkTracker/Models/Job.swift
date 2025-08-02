//
//  Job.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//


import Foundation

struct Job: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var hourlyRate: Double
    var color: String // For visual identification
    var isActive: Bool
    var presetShifts: [PresetShift]
    
    init(id: UUID = UUID(), name: String, hourlyRate: Double, color: String, isActive: Bool = true, presetShifts: [PresetShift] = []) {
        self.id = id
        self.name = name
        self.hourlyRate = hourlyRate
        self.color = color
        self.isActive = isActive
        self.presetShifts = presetShifts
    }
}
