//
//  PayrollIntegrationHelper.swift
//  WorkTracker
//
//  Created by GitHub Copilot on 8/2/25.
//

import Foundation

class PayrollIntegrationHelper {
    static let shared = PayrollIntegrationHelper()
    
    private init() {}
    
    // Get pay period for a specific date and job
    func getPayPeriod(for date: Date, jobId: UUID, paySchedules: [PaySchedule]) -> PayPeriod? {
        guard let paySchedule = paySchedules.first(where: { $0.jobId == jobId && $0.isActive }) else {
            return nil
        }
        
        let periods = paySchedule.payPeriodsInRange(
            from: Calendar.current.date(byAdding: .year, value: -1, to: date) ?? date,
            to: Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date
        )
        
        return periods.first { $0.contains(date: date) }
    }
    
    // Get all shifts for a pay period
    func getShifts(for payPeriod: PayPeriod, jobId: UUID, shifts: [WorkShift]) -> [WorkShift] {
        return shifts.filter { shift in
            shift.jobId == jobId && payPeriod.contains(date: shift.date)
        }
    }
    
    // Calculate expected earnings for a pay period
    func calculateExpectedEarnings(for payPeriod: PayPeriod, jobId: UUID, shifts: [WorkShift], jobs: [Job]) -> (regular: Double, overtime: Double, holiday: Double, total: Double) {
        let relevantShifts = getShifts(for: payPeriod, jobId: jobId, shifts: shifts)
        guard let job = jobs.first(where: { $0.id == jobId }) else {
            return (0, 0, 0, 0)
        }
        
        var regularEarnings: Double = 0
        var overtimeEarnings: Double = 0
        var holidayEarnings: Double = 0
        
        for shift in relevantShifts {
            let rate = shift.hourlyRateOverride ?? job.hourlyRate
            let multiplier: Double = {
                switch shift.shiftType {
                case .regular: return 1.0
                case .overtime: return 1.5
                case .holiday: return 2.0
                }
            }()
            let earnings = shift.duration * rate * multiplier
            
            switch shift.shiftType {
            case .regular:
                regularEarnings += earnings
            case .overtime:
                overtimeEarnings += earnings
            case .holiday:
                holidayEarnings += earnings
            }
        }
        
        let total = regularEarnings + overtimeEarnings + holidayEarnings
        return (regularEarnings, overtimeEarnings, holidayEarnings, total)
    }
    
    // Calculate expected hours for a pay period
    func calculateExpectedHours(for payPeriod: PayPeriod, jobId: UUID, shifts: [WorkShift]) -> (regular: Double, overtime: Double, holiday: Double, total: Double) {
        let relevantShifts = getShifts(for: payPeriod, jobId: jobId, shifts: shifts)
        
        var regularHours: Double = 0
        var overtimeHours: Double = 0
        var holidayHours: Double = 0
        
        for shift in relevantShifts {
            switch shift.shiftType {
            case .regular:
                regularHours += shift.duration
            case .overtime:
                overtimeHours += shift.duration
            case .holiday:
                holidayHours += shift.duration
            }
        }
        
        let total = regularHours + overtimeHours + holidayHours
        return (regularHours, overtimeHours, holidayHours, total)
    }
    
    // Auto-populate payslip from expected data
    func createPayslipFromExpected(payPeriod: PayPeriod, jobId: UUID, shifts: [WorkShift], jobs: [Job]) -> Payslip {
        let hours = calculateExpectedHours(for: payPeriod, jobId: jobId, shifts: shifts)
        let earnings = calculateExpectedEarnings(for: payPeriod, jobId: jobId, shifts: shifts, jobs: jobs)
        
        return Payslip(
            jobId: jobId,
            payPeriodId: payPeriod.id,
            payDate: payPeriod.payDate,
            periodStartDate: payPeriod.startDate,
            periodEndDate: payPeriod.endDate,
            regularHours: hours.regular,
            overtimeHours: hours.overtime,
            holidayHours: hours.holiday,
            regularPay: earnings.regular,
            overtimePay: earnings.overtime,
            holidayPay: earnings.holiday,
            netPay: earnings.total // This should be manually adjusted by user after adding deductions
        )
    }
    
    // Get upcoming pay dates
    func getUpcomingPayDates(for jobId: UUID, paySchedules: [PaySchedule], count: Int = 5) -> [Date] {
        guard let paySchedule = paySchedules.first(where: { $0.jobId == jobId && $0.isActive }) else {
            return []
        }
        
        let endDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
        let periods = paySchedule.payPeriodsInRange(from: Date(), to: endDate)
        
        return Array(periods.prefix(count).map { $0.payDate })
    }
}
