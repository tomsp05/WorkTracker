//
//  PayScheduleViewModel.swift
//  WorkTracker
//
//  Created by GitHub Copilot on 8/2/25.
//

import Foundation
import SwiftUI

class PayScheduleViewModel: ObservableObject {
    @Published var paySchedules: [PaySchedule] = []
    
    init() {
        loadPaySchedules()
    }
    
    func loadPaySchedules() {
        paySchedules = DataService.shared.loadPaySchedules() ?? []
    }
    
    func savePaySchedules() {
        DataService.shared.savePaySchedules(paySchedules)
    }
    
    func addPaySchedule(_ paySchedule: PaySchedule) {
        paySchedules.append(paySchedule)
        savePaySchedules()
    }
    
    func updatePaySchedule(_ paySchedule: PaySchedule) {
        if let index = paySchedules.firstIndex(where: { $0.id == paySchedule.id }) {
            paySchedules[index] = paySchedule
            savePaySchedules()
        }
    }
    
    func deletePaySchedule(_ paySchedule: PaySchedule) {
        paySchedules.removeAll { $0.id == paySchedule.id }
        savePaySchedules()
    }
    
    func getPaySchedule(for jobId: UUID) -> PaySchedule? {
        return paySchedules.first { $0.jobId == jobId && $0.isActive }
    }
    
    func getPayPeriods(for jobId: UUID, from startDate: Date, to endDate: Date) -> [PayPeriod] {
        guard let paySchedule = getPaySchedule(for: jobId) else { return [] }
        return paySchedule.payPeriodsInRange(from: startDate, to: endDate)
    }
}
