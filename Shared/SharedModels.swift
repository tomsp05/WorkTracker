//
//  SharedModels.swift
//  WorkTracker
//
//  Created by Tom Speake on 8/2/25.
//

import Foundation
import SwiftUI

// MARK: - Shared Models for Widget Support

enum ShiftType: String, Codable, CaseIterable {
    case regular
    case overtime
    case holiday
}

struct Job: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var hourlyRate: Double
    var color: String // For visual identification
    var isActive: Bool = true
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
}

// MARK: - Shared Data Service

class SharedDataService {
    static let shared = SharedDataService()
    
    private let jobsKey = "saved_jobs"
    private let shiftsKey = "saved_shifts"
    private let themeColorKey = "theme_color"
    
    private init() {}
    
    // MARK: - Jobs
    
    func loadJobs() -> [Job] {
        guard let data = UserDefaults(suiteName: "group.com.TomSpeake.WorkTracker")?.data(forKey: jobsKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let jobs = try decoder.decode([Job].self, from: data)
            return jobs
        } catch {
            print("Error loading jobs: \(error.localizedDescription)")
            return []
        }
    }
    
    func saveJobs(_ jobs: [Job]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(jobs)
            UserDefaults(suiteName: "group.com.TomSpeake.WorkTracker")?.set(data, forKey: jobsKey)
        } catch {
            print("Error saving jobs: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Work Shifts
    
    func loadWorkShifts() -> [WorkShift] {
        guard let data = UserDefaults(suiteName: "group.com.TomSpeake.WorkTracker")?.data(forKey: shiftsKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let shifts = try decoder.decode([WorkShift].self, from: data)
            return shifts
        } catch {
            print("Error loading shifts: \(error.localizedDescription)")
            return []
        }
    }
    
    func saveWorkShifts(_ shifts: [WorkShift]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(shifts)
            UserDefaults(suiteName: "group.com.TomSpeake.WorkTracker")?.set(data, forKey: shiftsKey)
        } catch {
            print("Error saving shifts: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Theme Color
    
    func loadThemeColor() -> String {
        return UserDefaults(suiteName: "group.com.TomSpeake.WorkTracker")?.string(forKey: themeColorKey) ?? "Blue"
    }
    
    func saveThemeColor(_ color: String) {
        UserDefaults(suiteName: "group.com.TomSpeake.WorkTracker")?.set(color, forKey: themeColorKey)
    }
}

// MARK: - Helper Extensions

extension Color {
    static func themeColor(from colorName: String) -> Color {
        switch colorName {
        case "Blue": return Color(red: 0.20, green: 0.40, blue: 0.70)
        case "Green": return Color(red: 0.20, green: 0.55, blue: 0.30)
        case "Orange": return Color(red: 0.80, green: 0.40, blue: 0.20)
        case "Purple": return Color(red: 0.50, green: 0.25, blue: 0.70)
        case "Red": return Color(red: 0.70, green: 0.20, blue: 0.20)
        case "Teal": return Color(red: 0.20, green: 0.50, blue: 0.60)
        case "Pink": return Color(red: 0.90, green: 0.40, blue: 0.60)
        default: return Color(red: 0.20, green: 0.40, blue: 0.70)
        }
    }
}

extension Double {
    func formatAsCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "£0.00"
    }
    
    func formatAsHours() -> String {
        let totalMinutes = Int(self * 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    }
}
