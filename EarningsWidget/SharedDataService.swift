//
//  SharedDataService.swift
//  EarningsWidget
//
//  Created by Tom Speake on 8/2/25.
//

import Foundation

/// Shared data service for accessing work data from the widget extension
class SharedDataService {
    static let shared = SharedDataService()
    
    private let appGroupIdentifier = "group.com.TomSpeake.WorkTracker"
    private let jobsKey = "saved_jobs"
    private let shiftsKey = "saved_shifts"
    private let themeColorKey = "theme_color"
    
    private var sharedUserDefaults: UserDefaults {
        return UserDefaults(suiteName: appGroupIdentifier) ?? UserDefaults.standard
    }
    
    private init() {}
    
    // MARK: - Jobs
    
    func loadJobs() -> [Job]? {
        guard let data = sharedUserDefaults.data(forKey: jobsKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let jobs = try decoder.decode([Job].self, from: data)
            return jobs
        } catch {
            print("Widget: Error loading jobs: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Work Shifts
    
    func loadWorkShifts() -> [WorkShift]? {
        guard let data = sharedUserDefaults.data(forKey: shiftsKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let shifts = try decoder.decode([WorkShift].self, from: data)
            return shifts
        } catch {
            print("Widget: Error loading work shifts: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Theme Color
    
    func loadThemeColor() -> String? {
        return sharedUserDefaults.string(forKey: themeColorKey)
    }
    
    // MARK: - Widget-specific data calculations
    
    func monthlyEarnings() -> Double {
        guard let shifts = loadWorkShifts(), let jobs = loadJobs() else {
            return 0.0
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        
        let monthlyShifts = shifts.filter { $0.date >= startOfMonth && $0.date <= now }
        
        return monthlyShifts.reduce(0) { result, shift in
            let rate: Double
            if let override = shift.hourlyRateOverride {
                rate = override
            } else if let job = jobs.first(where: { $0.id == shift.jobId }) {
                rate = job.hourlyRate
            } else {
                rate = 0
            }
            
            let multiplier: Double = {
                switch shift.shiftType {
                case .regular: return 1.0
                case .overtime: return 1.5
                case .holiday: return 2.0
                }
            }()
            
            return result + (shift.duration * rate * multiplier)
        }
    }
    
    func monthlyHours() -> Double {
        guard let shifts = loadWorkShifts() else {
            return 0.0
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        
        let monthlyShifts = shifts.filter { $0.date >= startOfMonth && $0.date <= now }
        
        return monthlyShifts.reduce(0) { $0 + $1.duration }
    }
    
    func weeklyEarnings() -> Double {
        guard let shifts = loadWorkShifts(), let jobs = loadJobs() else {
            return 0.0
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date ?? now.addingTimeInterval(-7*24*60*60)
        
        let weeklyShifts = shifts.filter { $0.date >= startOfWeek && $0.date <= now }
        
        return weeklyShifts.reduce(0) { result, shift in
            let rate: Double
            if let override = shift.hourlyRateOverride {
                rate = override
            } else if let job = jobs.first(where: { $0.id == shift.jobId }) {
                rate = job.hourlyRate
            } else {
                rate = 0
            }
            
            let multiplier: Double = {
                switch shift.shiftType {
                case .regular: return 1.0
                case .overtime: return 1.5
                case .holiday: return 2.0
                }
            }()
            
            return result + (shift.duration * rate * multiplier)
        }
    }
    
    func weeklyHours() -> Double {
        guard let shifts = loadWorkShifts() else {
            return 0.0
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date ?? now.addingTimeInterval(-7*24*60*60)
        
        let weeklyShifts = shifts.filter { $0.date >= startOfWeek && $0.date <= now }
        
        return weeklyShifts.reduce(0) { $0 + $1.duration }
    }
    
    func todayHours() -> Double {
        guard let shifts = loadWorkShifts() else {
            return 0.0
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let todayShifts = shifts.filter { $0.date >= startOfDay && $0.date < endOfDay }
        
        return todayShifts.reduce(0) { $0 + $1.duration }
    }
    
    func todayEarnings() -> Double {
        guard let shifts = loadWorkShifts(), let jobs = loadJobs() else {
            return 0.0
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let todayShifts = shifts.filter { $0.date >= startOfDay && $0.date < endOfDay }
        
        return todayShifts.reduce(0) { result, shift in
            let rate: Double
            if let override = shift.hourlyRateOverride {
                rate = override
            } else if let job = jobs.first(where: { $0.id == shift.jobId }) {
                rate = job.hourlyRate
            } else {
                rate = 0
            }
            
            let multiplier: Double = {
                switch shift.shiftType {
                case .regular: return 1.0
                case .overtime: return 1.5
                case .holiday: return 2.0
                }
            }()
            
            return result + (shift.duration * rate * multiplier)
        }
    }
    
    // Get theme color as SwiftUI Color
    func themeColor() -> String {
        return loadThemeColor() ?? "Blue"
    }
}