
//  ShiftType.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//


import Foundation

enum ShiftType: String, Codable, CaseIterable {
    case regular
    case overtime
    case holiday
}

struct WorkShift: Identifiable, Codable {
    var id = UUID()
    var jobId: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var breakDuration: Double // In hours
    var shiftType: ShiftType = .regular
    var notes: String = ""
    var isPaid: Bool = false
    var hourlyRateOverride: Double? // Optional override of job's rate
    
    // Computed properties
    var duration: Double {
        let totalMinutes = endTime.timeIntervalSince(startTime) / 60
        let breakMinutes = breakDuration * 60
        return (totalMinutes - breakMinutes) / 60 // Convert to hours
    }
    
    var earnings: Double {
        let rate = hourlyRateOverride ?? 0.0
        let multiplier: Double = {
            switch shiftType {
            case .regular: return 1.0
            case .overtime: return 1.5
            case .holiday: return 2.0
            }
        }()
        return duration * rate * multiplier
    }
    
    func earnings(with job: Job?) -> Double {
        let rate: Double
        if let override = hourlyRateOverride {
            rate = override
        } else if let job = job {
            rate = job.hourlyRate
        } else {
            rate = 0.0
        }
        
        let multiplier: Double = {
            switch shiftType {
            case .regular: return 1.0
            case .overtime: return 1.5
            case .holiday: return 2.0
            }
        }()
        
        return duration * rate * multiplier
    }
    
    // For recurring shifts
    var isRecurring: Bool = false
    var recurrenceInterval: RecurrenceInterval = .none
    var recurrenceEndDate: Date?
    var parentShiftId: UUID?
}

enum RecurrenceInterval: String, Codable, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-Weekly"
    case monthly = "Monthly"
}
