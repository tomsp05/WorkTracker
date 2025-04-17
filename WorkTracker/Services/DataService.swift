//
//  DataService.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//


import Foundation

class DataService {
    static let shared = DataService()
    
    private init() {}
    
    private let jobsKey = "savedJobs"
    private let shiftsKey = "savedShifts"
    private let themeColorKey = "themeColor"
    
    // MARK: - Jobs Storage
    
    func saveJobs(_ jobs: [Job]) {
        if let encoded = try? JSONEncoder().encode(jobs) {
            UserDefaults.standard.set(encoded, forKey: jobsKey)
        }
    }
    
    func loadJobs() -> [Job]? {
        if let savedData = UserDefaults.standard.data(forKey: jobsKey),
           let jobs = try? JSONDecoder().decode([Job].self, from: savedData) {
            return jobs
        }
        return nil
    }
    
    // MARK: - Shifts Storage
    
    func saveWorkShifts(_ shifts: [WorkShift]) {
        if let encoded = try? JSONEncoder().encode(shifts) {
            UserDefaults.standard.set(encoded, forKey: shiftsKey)
        }
    }
    
    func loadWorkShifts() -> [WorkShift]? {
        if let savedData = UserDefaults.standard.data(forKey: shiftsKey),
           let shifts = try? JSONDecoder().decode([WorkShift].self, from: savedData) {
            return shifts
        }
        return nil
    }
    
    // MARK: - Theme Settings
    
    func saveThemeColor(_ colorName: String) {
        UserDefaults.standard.set(colorName, forKey: themeColorKey)
    }
    
    func loadThemeColor() -> String? {
        return UserDefaults.standard.string(forKey: themeColorKey)
    }
}