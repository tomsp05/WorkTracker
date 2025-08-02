//
//  Payslip.swift
//  WorkTracker
//
//  Created by GitHub Copilot on 8/2/25.
//

import Foundation

struct Payslip: Identifiable, Codable {
    var id = UUID()
    var jobId: UUID
    var payPeriodId: UUID?
    var payDate: Date
    var periodStartDate: Date
    var periodEndDate: Date
    
    // Hours and earnings
    var regularHours: Double
    var overtimeHours: Double
    var holidayHours: Double
    var totalHours: Double {
        return regularHours + overtimeHours + holidayHours
    }
    
    // Gross pay breakdown
    var regularPay: Double
    var overtimePay: Double
    var holidayPay: Double
    var bonuses: Double = 0.0
    var otherEarnings: Double = 0.0
    var grossPay: Double {
        return regularPay + overtimePay + holidayPay + bonuses + otherEarnings
    }
    
    // Deductions
    var taxDeductions: Double = 0.0
    var insuranceDeductions: Double = 0.0
    var retirementDeductions: Double = 0.0
    var otherDeductions: Double = 0.0
    var totalDeductions: Double {
        return taxDeductions + insuranceDeductions + retirementDeductions + otherDeductions
    }
    
    // Net pay
    var netPay: Double
    
    // Notes
    var notes: String = ""
    
    // Validation
    var isValid: Bool {
        return abs(netPay - (grossPay - totalDeductions)) < 0.01
    }
}

// For comparing expected vs actual earnings
struct PayComparison: Identifiable {
    var id = UUID()
    var payslip: Payslip
    var expectedShifts: [WorkShift]
    var payPeriod: PayPeriod
    var jobHourlyRate: Double // Add job hourly rate
    var jobOvertimeRate: Double? // Add job overtime rate
    
    // Expected calculations
    var expectedRegularHours: Double {
        return expectedShifts.filter { $0.shiftType == .regular }.reduce(0) { $0 + $1.duration }
    }
    
    var expectedOvertimeHours: Double {
        return expectedShifts.filter { $0.shiftType == .overtime }.reduce(0) { $0 + $1.duration }
    }
    
    var expectedHolidayHours: Double {
        return expectedShifts.filter { $0.shiftType == .holiday }.reduce(0) { $0 + $1.duration }
    }
    
    var expectedTotalHours: Double {
        return expectedRegularHours + expectedOvertimeHours + expectedHolidayHours
    }
    
    var expectedGrossPay: Double {
        var total: Double = 0.0
        
        for shift in expectedShifts {
            let baseRate = shift.hourlyRateOverride ?? jobHourlyRate
            let rate: Double = {
                switch shift.shiftType {
                case .regular: 
                    return baseRate
                case .overtime: 
                    return jobOvertimeRate ?? (baseRate * 1.5)
                case .holiday: 
                    return baseRate * 2.0
                }
            }()
            total += shift.duration * rate
        }
        
        return total
    }
    
    // Comparison results
    var hoursDifference: Double {
        return payslip.totalHours - expectedTotalHours
    }
    
    var payDifference: Double {
        return payslip.grossPay - expectedGrossPay
    }
    
    var regularHoursDifference: Double {
        return payslip.regularHours - expectedRegularHours
    }
    
    var overtimeHoursDifference: Double {
        return payslip.overtimeHours - expectedOvertimeHours
    }
    
    var holidayHoursDifference: Double {
        return payslip.holidayHours - expectedHolidayHours
    }
    
    // Accuracy percentages
    var hoursAccuracy: Double {
        guard expectedTotalHours > 0 else { return 0 }
        return (1 - abs(hoursDifference) / expectedTotalHours) * 100
    }
    
    var payAccuracy: Double {
        guard expectedGrossPay > 0 else { return 0 }
        return (1 - abs(payDifference) / expectedGrossPay) * 100
    }
}
