//
//  DataService.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//

import Foundation

class DataService {
    static let shared = DataService()
    
    private let fileCoordinator = NSFileCoordinator()
    
    private let jobsKey = "saved_jobs"
    private let shiftsKey = "saved_shifts"
    private let themeColorKey = "theme_color"
    private let templatesKey = "saved_templates"
    private let payslipsKey = "saved_payslips"
    private let paySchedulesKey = "saved_pay_schedules"
    
    private init() {}
    
    // MARK: - Jobs
    
    func saveJobs(_ jobs: [Job]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(jobs)
            UserDefaults.standard.set(data, forKey: jobsKey)
        } catch {
            print("Error saving jobs: \(error.localizedDescription)")
        }
    }
    
    func loadJobs() -> [Job]? {
        guard let data = UserDefaults.standard.data(forKey: jobsKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let jobs = try decoder.decode([Job].self, from: data)
            return jobs
        } catch {
            print("Error loading jobs: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Work Shifts
    
    func saveWorkShifts(_ shifts: [WorkShift]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(shifts)
            UserDefaults.standard.set(data, forKey: shiftsKey)
        } catch {
            print("Error saving work shifts: \(error.localizedDescription)")
        }
    }
    
    func loadWorkShifts() -> [WorkShift]? {
        guard let data = UserDefaults.standard.data(forKey: shiftsKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let shifts = try decoder.decode([WorkShift].self, from: data)
            return shifts
        } catch {
            print("Error loading work shifts: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Payslips
    
    func savePayslips(_ payslips: [Payslip]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(payslips)
            UserDefaults.standard.set(data, forKey: payslipsKey)
        } catch {
            print("Error saving payslips: \(error.localizedDescription)")
        }
    }
    
    func loadPayslips() -> [Payslip]? {
        guard let data = UserDefaults.standard.data(forKey: payslipsKey) else {
            return nil
        }
        do {
            let decoder = JSONDecoder()
            let payslips = try decoder.decode([Payslip].self, from: data)
            return payslips
        } catch {
            print("Error loading payslips: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Pay Schedules
    func savePaySchedules(_ schedules: [PaySchedule]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(schedules)
            UserDefaults.standard.set(data, forKey: paySchedulesKey)
        } catch {
            print("Error saving pay schedules: \(error.localizedDescription)")
        }
    }
    
    func loadPaySchedules() -> [PaySchedule]? {
        guard let data = UserDefaults.standard.data(forKey: paySchedulesKey) else {
            return nil
        }
        do {
            let decoder = JSONDecoder()
            let schedules = try decoder.decode([PaySchedule].self, from: data)
            return schedules
        } catch {
            print("Error loading pay schedules: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Theme Color
    
    func saveThemeColor(_ colorName: String) {
        UserDefaults.standard.set(colorName, forKey: themeColorKey)
    }
    
    func loadThemeColor() -> String? {
        return UserDefaults.standard.string(forKey: themeColorKey)
    }
    
    // MARK: - Data Import/Export
    
    func exportData() -> String {
        let exportData = ExportData(
            jobs: loadJobs() ?? [],
            shifts: loadWorkShifts() ?? [],
            themeColor: loadThemeColor() ?? "Blue",
            exportDate: Date()
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(exportData)
            if let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("Error exporting data: \(error.localizedDescription)")
        }
        
        return ""
    }
    
    func importData(_ jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else {
            print("Error converting string to data")
            return false
        }
        
        do {
            let decoder = JSONDecoder()
            let importData = try decoder.decode(ExportData.self, from: data)
            
            // Save the imported data
            saveJobs(importData.jobs)
            saveWorkShifts(importData.shifts)
            saveThemeColor(importData.themeColor)
            
            return true
        } catch {
            print("Error importing data: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Reset Data
    
    func resetAllData() {
        UserDefaults.standard.removeObject(forKey: jobsKey)
        UserDefaults.standard.removeObject(forKey: shiftsKey)
        // Don't reset theme color, just the data
    }
}

// Structure for data export/import
struct ExportData: Codable {
    let jobs: [Job]
    let shifts: [WorkShift]
    let themeColor: String
    let exportDate: Date
}

