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

    // AppStorage to track onboarding completion
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Computed property for future shifts
    var futureShifts: [WorkShift] {
        shifts.filter { $0.date > Date() }
    }

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
            case "Pink":
                return Color(red: 0.90, green: 0.40, blue: 0.60) // Pink
            default:
                return Color(red: 0.20, green: 0.40, blue: 0.70) // Default to Blue
            }
        }

    init() {
        loadInitialData()
    }

    // MARK: - Onboarding
    func completeOnboarding() {
        hasCompletedOnboarding = true
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
        if let _ = jobs.firstIndex(where: { $0.id == updatedJob.id }) {
            // Find the job by ID
            for i in 0..<jobs.count {
                if jobs[i].id == updatedJob.id {
                    jobs[i] = updatedJob
                    break
                }
            }
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
            for i in 0..<jobs.count {
                if jobs[i].id == job.id {
                    var updatedJob = job
                    updatedJob.isActive = false
                    jobs[i] = updatedJob
                    break
                }
            }
            DataService.shared.saveJobs(jobs)
        } else {
            // If no shifts, can safely delete
            jobs.removeAll { $0.id == job.id }
            DataService.shared.saveJobs(jobs)
        }
    }

    // MARK: - Shifts Management

    func addShift(_ shift: WorkShift) {
        shifts.append(shift)
        DataService.shared.saveWorkShifts(shifts)
        earningsDidChange.toggle() // Trigger animation
    }

    func addShifts(_ newShifts: [WorkShift]) {
        shifts.append(contentsOf: newShifts)
        DataService.shared.saveWorkShifts(shifts)
        earningsDidChange.toggle() // Trigger animation
    }

    func updateShift(_ updatedShift: WorkShift) {
        for i in 0..<shifts.count {
            if shifts[i].id == updatedShift.id {
                shifts[i] = updatedShift
                break
            }
        }
        DataService.shared.saveWorkShifts(shifts)
        earningsDidChange.toggle() // Trigger animation
    }

    // This is just the deleteShift method that should be in the WorkHoursViewModel.swift file

    func deleteShift(_ shift: WorkShift) {
        // First check if it's a recurring shift
        if shift.isRecurring || hasRecurringChildren(shift) {
            // Just remove this specific shift
            shifts.removeAll { $0.id == shift.id }
        } else {
            // For non-recurring shifts, simple removal
            shifts.removeAll { $0.id == shift.id }
        }

        // Save changes to persistent storage
        DataService.shared.saveWorkShifts(shifts)

        // Trigger animation for earnings update
        earningsDidChange.toggle()
    }

    func hasRecurringChildren(_ shift: WorkShift) -> Bool {
        return shifts.contains { $0.parentShiftId == shift.id }
    }

    func updateShiftAndFuture(_ updatedShift: WorkShift) {
        // Find the original shift date
        guard let originalShift = shifts.first(where: { $0.id == updatedShift.id }),
              let originalDate = shifts.first(where: { $0.id == updatedShift.id })?.date else { return }

        // Get all future recurrences
        let futureDependents = shifts.filter { shift in
            // If it's part of the same series and on or after this date
            return (shift.parentShiftId == originalShift.parentShiftId || shift.parentShiftId == updatedShift.id) &&
                shift.date >= originalDate
        }

        // Update this and all future shifts
        for shift in futureDependents {
            if shift.id == updatedShift.id {
                // This is the shift being directly edited
                for i in 0..<shifts.count {
                    if shifts[i].id == shift.id {
                        shifts[i] = updatedShift
                        break
                    }
                }
            } else {
                // Calculate the difference between original and updated shift
                let timeDifference = updatedShift.startTime.timeIntervalSince(originalShift.startTime)
                let durationDifference = updatedShift.duration - originalShift.duration

                // Find the shift to update
                for i in 0..<shifts.count {
                    if shifts[i].id == shift.id {
                        // Apply changes proportionally to this shift
                        var updatedFutureShift = shifts[i]
                        updatedFutureShift.jobId = updatedShift.jobId
                        updatedFutureShift.shiftType = updatedShift.shiftType
                        updatedFutureShift.hourlyRateOverride = updatedShift.hourlyRateOverride
                        updatedFutureShift.breakDuration = updatedShift.breakDuration
                        updatedFutureShift.isPaid = updatedShift.isPaid
                        updatedFutureShift.notes = updatedShift.notes

                        // Adjust start and end times based on the changes made to the original
                        updatedFutureShift.startTime = shift.startTime.addingTimeInterval(timeDifference)

                        // Adjust end time to maintain the new duration
                        let originalDuration = shift.endTime.timeIntervalSince(shift.startTime)
                        let newDuration = originalDuration + (durationDifference * 3600) // Convert hours to seconds
                        updatedFutureShift.endTime = updatedFutureShift.startTime.addingTimeInterval(newDuration)

                        // Update in the array
                        shifts[i] = updatedFutureShift
                        break
                    }
                }
            }
        }

        DataService.shared.saveWorkShifts(shifts)
        earningsDidChange.toggle() // Trigger animation
    }

    func updateAllRecurringShifts(_ updatedShift: WorkShift) {
        // Find the original shift
        guard let originalShift = shifts.first(where: { $0.id == updatedShift.id }) else { return }

        // Find parent ID (could be the shift itself or its parent)
        let seriesId = originalShift.parentShiftId ?? originalShift.id

        // Get all shifts in the same series
        let seriesShifts = shifts.filter { shift in
            return shift.id == seriesId || shift.parentShiftId == seriesId || shift.id == updatedShift.id
        }

        // Update all shifts in the series
        for shift in seriesShifts {
            if shift.id == updatedShift.id {
                // This is the shift being directly edited
                for i in 0..<shifts.count {
                    if shifts[i].id == shift.id {
                        shifts[i] = updatedShift
                        break
                    }
                }
            } else {
                // Update common properties
                for i in 0..<shifts.count {
                    if shifts[i].id == shift.id {
                        var updatedSeriesShift = shifts[i]
                        updatedSeriesShift.jobId = updatedShift.jobId
                        updatedSeriesShift.shiftType = updatedShift.shiftType
                        updatedSeriesShift.hourlyRateOverride = updatedShift.hourlyRateOverride
                        updatedSeriesShift.breakDuration = updatedShift.breakDuration
                        updatedSeriesShift.isPaid = updatedShift.isPaid
                        updatedSeriesShift.notes = updatedShift.notes

                        // Keep date and times as they were

                        // Update in the array
                        shifts[i] = updatedSeriesShift
                        break
                    }
                }
            }
        }

        DataService.shared.saveWorkShifts(shifts)
        earningsDidChange.toggle() // Trigger animation
    }

    // MARK: - Earnings Calculations

    func totalEarnings(from startDate: Date, to endDate: Date) -> Double {
        return shifts
            .filter { $0.date >= startDate && $0.date <= endDate }
            .reduce(0) { result, shift in
                // For each shift, calculate its earnings using either the override rate or the job's rate
                let rate: Double
                if let override = shift.hourlyRateOverride {
                    rate = override
                } else if let job = jobs.first(where: { $0.id == shift.jobId }) {
                    rate = job.hourlyRate
                } else {
                    rate = 0
                }

                // Apply shift type multiplier
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

    func totalHours(from startDate: Date, to endDate: Date) -> Double {
        return shifts
            .filter { $0.date >= startDate && $0.date <= endDate }
            .reduce(0) { $0 + $1.duration }
    }

    // Update shifts when a job is changed (e.g. hourly rate)
    func updateShiftsForJobChange(_ updatedJob: Job) {
        // Only update shifts that don't have custom hourly rate override
        for shift in shifts where shift.jobId == updatedJob.id && shift.hourlyRateOverride == nil {
            // The hourly rate is stored in the job, so we don't need to update the shift itself
            // But we'll trigger the animation to reflect any earnings changes
            earningsDidChange.toggle()
            break // Only need to trigger once
        }
    }
}
