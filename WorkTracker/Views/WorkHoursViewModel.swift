//
//  WorkHoursViewModel.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//


import Foundation
import Combine
import SwiftUI

class WorkHoursViewModel: ObservableObject {
    @Published var jobs: [Job] = []
    @Published var shifts: [WorkShift] = []
    
    // Signal property for animations
    @Published var earningsDidChange: Bool = false
    
    // Theme color matching the finance app
    @Published var themeColorName: String = "Blue"
    
    /// Returns a SwiftUI Color based on the selected theme color name.
    var themeColor: Color {
        switch themeColorName {
        case "Blue":
             return Color(red: 0.20, green: 0.40, blue: 0.70) // Darker Blue
        case "Green":
             return Color(red: 0.20, green: 0.55, blue: 0.30) // Darker Green
        case "Orange":
             return Color(red: 0.80, green: 0.40, blue: 0.20) // Darker Orange
        case "Purple":
             return Color(red: 0.50, green: 0.25, blue: 0.70) // Darker Purple
        case "Red":
             return Color(red: 0.70, green: 0.20, blue: 0.20) // Darker Red
        case "Teal":
             return Color(red: 0.20, green: 0.50, blue: 0.60) // Darker Teal
        default:
             return Color(red: 0.20, green: 0.40, blue: 0.70) // Default to Blue
        }
    }
    
    init() {
        loadInitialData()
    }
    
    // MARK: - Data Loading & Initialization
    
    func loadInitialData() {
        // Load jobs
        if let loadedJobs = DataService.shared.loadJobs() {
            jobs = loadedJobs
        } else {
            // Create a default job if none exist
            jobs = [
                Job(name: "Main Job", hourlyRate: 10.0, color: "Blue")
            ]
            DataService.shared.saveJobs(jobs)
        }
        
        // Load shifts
        if let loadedShifts = DataService.shared.loadWorkShifts() {
            shifts = loadedShifts
        } else {
            shifts = []
        }
        
        // Load theme color
        if let loadedTheme = DataService.shared.loadThemeColor() {
            themeColorName = loadedTheme
        } else {
            themeColorName = "Blue"
        }
    }
    
    // MARK: - Jobs Management
    
    func addJob(_ job: Job) {
        jobs.append(job)
        DataService.shared.saveJobs(jobs)
    }
    
    func updateJob(_ updatedJob: Job) {
        if let index = jobs.firstIndex(where: { $0.id == updatedJob.id }) {
            jobs[index] = updatedJob
            DataService.shared.saveJobs(jobs)
            
            // Update hourly rate for all shifts using this job if rate changed
            updateShiftsForJobChange(updatedJob)
        }
    }
    
    func deleteJob(_ job: Job) {
        // Check if job has associated shifts
        let hasShifts = shifts.contains(where: { $0.jobId == job.id })
        
        if hasShifts {
            // If job has shifts, mark as inactive instead of deleting
            if let index = jobs.firstIndex(where: { $0.id == job.id }) {
                jobs[index].isActive = false
                DataService.shared.saveJobs(jobs)
            }
        } else {
            // If no shifts, can safely delete
            jobs.removeAll { $0.id == job.id }
            DataService.shared.saveJobs(jobs)
        }
    }
    
    private func updateShiftsForJobChange(_ job: Job) {
        var shiftsChanged = false
        
        // Update earnings calculations for shifts with this job
        for i in 0..<shifts.count {
            if shifts[i].jobId == job.id && shifts[i].hourlyRateOverride == nil {
                // Recalculate earnings based on job's new hourly rate
                shiftsChanged = true
            }
        }
        
        if shiftsChanged {
            DataService.shared.saveWorkShifts(shifts)
            signalEarningsChange()
        }
    }
    
    // MARK: - Shifts Management
    
    func addShift(_ shift: WorkShift) {
        shifts.append(shift)
        DataService.shared.saveWorkShifts(shifts)
        signalEarningsChange()
        
        // Generate recurring shifts if needed
        if shift.isRecurring {
            generateRecurringShifts(from: shift)
        }
    }
    
    func updateShift(_ updatedShift: WorkShift) {
        if let index = shifts.firstIndex(where: { $0.id == updatedShift.id }) {
            shifts[index] = updatedShift
            DataService.shared.saveWorkShifts(shifts)
            signalEarningsChange()
            
            // Update recurring series if this is a parent shift
            if updatedShift.isRecurring && updatedShift.parentShiftId == nil {
                updateRecurringShifts(updatedShift)
            }
        }
    }
    
    func deleteShift(_ shift: WorkShift, deleteFutureSeries: Bool = false) {
        if shift.isRecurring && shift.parentShiftId == nil && deleteFutureSeries {
            // Delete this shift and all in its series
            shifts.removeAll { $0.id == shift.id || $0.parentShiftId == shift.id }
        } else {
            // Delete just this shift
            shifts.removeAll { $0.id == shift.id }
        }
        
        DataService.shared.saveWorkShifts(shifts)
        signalEarningsChange()
    }
    
    // MARK: - Recurring Shifts
    
    private func generateRecurringShifts(from shift: WorkShift, upToDate: Date = Date().addingTimeInterval(60*60*24*90)) {
        guard shift.isRecurring, shift.recurrenceInterval != .none else { return }
        
        let endDate = shift.recurrenceEndDate ?? upToDate
        var currentDate = shift.date
        
        while currentDate <= endDate {
            if let nextDate = calculateNextRecurrenceDate(from: currentDate, interval: shift.recurrenceInterval) {
                if nextDate > endDate { break }
                
                let timeDifference = nextDate.timeIntervalSince(shift.date)
                
                var newShift = shift
                newShift.id = UUID()
                newShift.date = nextDate
                newShift.startTime = shift.startTime.addingTimeInterval(timeDifference)
                newShift.endTime = shift.endTime.addingTimeInterval(timeDifference)
                newShift.parentShiftId = shift.id
                
                shifts.append(newShift)
                currentDate = nextDate
            } else {
                break
            }
        }
        
        DataService.shared.saveWorkShifts(shifts)
    }
    
    private func updateRecurringShifts(_ updatedShift: WorkShift) {
        // Find all shifts in this series
        let childShifts = shifts.filter { $0.parentShiftId == updatedShift.id }
        
        for child in childShifts {
            if let childIndex = shifts.firstIndex(where: { $0.id == child.id }) {
                // Only update certain properties, preserving date/times
                var updatedChild = child
                updatedChild.jobId = updatedShift.jobId
                updatedChild.breakDuration = updatedShift.breakDuration
                updatedChild.shiftType = updatedShift.shiftType
                updatedChild.hourlyRateOverride = updatedShift.hourlyRateOverride
                updatedChild.notes = updatedShift.notes
                
                shifts[childIndex] = updatedChild
            }
        }
        
        DataService.shared.saveWorkShifts(shifts)
        signalEarningsChange()
    }
    
    private func calculateNextRecurrenceDate(from date: Date, interval: RecurrenceInterval) -> Date? {
        let calendar = Calendar.current
        
        switch interval {
        case .none:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        }
    }
    
    // MARK: - Reporting Functions
    
    /// Get total earnings for a specific period
    func totalEarnings(from startDate: Date, to endDate: Date) -> Double {
        let filteredShifts = shifts.filter { 
            let shiftDate = Calendar.current.startOfDay(for: $0.date)
            return shiftDate >= startDate && shiftDate <= endDate
        }
        
        return filteredShifts.reduce(0) { sum, shift in
            let jobRate = jobs.first(where: { $0.id == shift.jobId })?.hourlyRate ?? 0
            let rate = shift.hourlyRateOverride ?? jobRate
            
            let multiplier: Double = {
                switch shift.shiftType {
                case .regular: return 1.0
                case .overtime: return 1.5
                case .holiday: return 2.0
                }
            }()
            
            return sum + (shift.duration * rate * multiplier)
        }
    }
    
    /// Get total hours worked for a specific period
    func totalHours(from startDate: Date, to endDate: Date) -> Double {
        let filteredShifts = shifts.filter { 
            let shiftDate = Calendar.current.startOfDay(for: $0.date)
            return shiftDate >= startDate && shiftDate <= endDate
        }
        
        return filteredShifts.reduce(0) { sum, shift in
            return sum + shift.duration
        }
    }
    
    /// Get earnings grouped by job for a specific period
    func earningsByJob(from startDate: Date, to endDate: Date) -> [(job: Job, earnings: Double, hours: Double)] {
        var result: [(job: Job, earnings: Double, hours: Double)] = []
        
        for job in jobs {
            let jobShifts = shifts.filter {
                $0.jobId == job.id && 
                $0.date >= startDate && 
                $0.date <= endDate
            }
            
            let jobHours = jobShifts.reduce(0) { sum, shift in sum + shift.duration }
            let jobEarnings = jobShifts.reduce(0) { sum, shift in
                let rate = shift.hourlyRateOverride ?? job.hourlyRate
                
                let multiplier: Double = {
                    switch shift.shiftType {
                    case .regular: return 1.0
                    case .overtime: return 1.5
                    case .holiday: return 2.0
                    }
                }()
                
                return sum + (shift.duration * rate * multiplier)
            }
            
            if jobHours > 0 {
                result.append((job: job, earnings: jobEarnings, hours: jobHours))
            }
        }
        
        return result.sorted(by: { $0.earnings > $1.earnings })
    }
    
    // MARK: - Helpers
    
    func getJob(for shift: WorkShift) -> Job? {
        return jobs.first { $0.id == shift.jobId }
    }
    
    func activeJobs() -> [Job] {
        return jobs.filter { $0.isActive }
    }
    
    // MARK: - Settings & Animation
    
    func updateThemeColor(newColorName: String) {
        themeColorName = newColorName
        DataService.shared.saveThemeColor(newColorName)
    }
    
    private func signalEarningsChange() {
        earningsDidChange.toggle()
    }
}