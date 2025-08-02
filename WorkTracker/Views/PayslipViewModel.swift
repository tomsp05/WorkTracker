//
//  PayslipViewModel.swift
//  WorkTracker
//
//  Created by GitHub Copilot on 8/2/25.
//

import Foundation
import SwiftUI

class PayslipViewModel: ObservableObject {
    @Published var payslips: [Payslip] = []
    
    init() {
        loadPayslips()
    }
    
    func loadPayslips() {
        payslips = DataService.shared.loadPayslips() ?? []
    }
    
    func savePayslips() {
        DataService.shared.savePayslips(payslips)
    }
    
    func addPayslip(_ payslip: Payslip) {
        payslips.append(payslip)
        savePayslips()
    }
    
    func updatePayslip(_ payslip: Payslip) {
        if let index = payslips.firstIndex(where: { $0.id == payslip.id }) {
            payslips[index] = payslip
            savePayslips()
        }
    }
    
    func deletePayslip(_ payslip: Payslip) {
        payslips.removeAll { $0.id == payslip.id }
        savePayslips()
    }
    
    func getPayslips(for jobId: UUID) -> [Payslip] {
        return payslips.filter { $0.jobId == jobId }
    }
    
    func createPayComparison(for payslip: Payslip, with shifts: [WorkShift], payPeriod: PayPeriod, job: Job) -> PayComparison {
        let relevantShifts = shifts.filter { shift in
            payPeriod.contains(date: shift.date) && shift.jobId == payslip.jobId
        }
        
        return PayComparison(
            payslip: payslip,
            expectedShifts: relevantShifts,
            payPeriod: payPeriod,
            jobHourlyRate: job.hourlyRate,
            jobOvertimeRate: nil
        )
    }
}
