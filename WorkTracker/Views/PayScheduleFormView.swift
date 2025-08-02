//
//  PayScheduleFormView.swift
//  WorkTracker
//
//  Created by GitHub Copilot on 8/2/25.
//

import SwiftUI

struct PayScheduleFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var payScheduleViewModel: PayScheduleViewModel
    @State private var paySchedule: PaySchedule
    @State private var selectedJob: Job?
    
    let jobs: [Job]
    let isEditing: Bool
    
    init(payScheduleViewModel: PayScheduleViewModel, jobs: [Job], paySchedule: PaySchedule? = nil) {
        self.payScheduleViewModel = payScheduleViewModel
        self.jobs = jobs
        self.isEditing = paySchedule != nil
        
        if let existingPaySchedule = paySchedule {
            self._paySchedule = State(initialValue: existingPaySchedule)
            self._selectedJob = State(initialValue: jobs.first { $0.id == existingPaySchedule.jobId })
        } else {
            self._paySchedule = State(initialValue: PaySchedule(
                jobId: jobs.first?.id ?? UUID(),
                frequency: .biweekly,
                startDate: Date()
            ))
            self._selectedJob = State(initialValue: jobs.first)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Job") {
                    Picker("Select Job", selection: $selectedJob) {
                        ForEach(jobs, id: \.id) { job in
                            Text(job.name)
                                .tag(job as Job?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Pay Schedule") {
                    Picker("Frequency", selection: $paySchedule.frequency) {
                        ForEach(PayFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName)
                                .tag(frequency)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    DatePicker("Start Date", selection: $paySchedule.startDate, displayedComponents: .date)
                    
                    if paySchedule.frequency == .custom {
                        HStack {
                            Text("Every")
                            TextField("Days", value: Binding(
                                get: { paySchedule.customDayInterval ?? 14 },
                                set: { paySchedule.customDayInterval = $0 }
                            ), format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            Text("days")
                        }
                    }
                }
                
                Section("Settings") {
                    Toggle("Active", isOn: $paySchedule.isActive)
                }
                
                if !isEditing {
                    Section("Preview") {
                        if let job = selectedJob {
                            let samplePeriods = paySchedule.payPeriodsInRange(
                                from: Date(),
                                to: Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
                            ).prefix(4)
                            
                            ForEach(Array(samplePeriods), id: \.id) { period in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Pay Period: \(period.startDate, style: .date) - \(period.endDate, style: .date)")
                                        .font(.caption)
                                    Text("Pay Date: \(period.payDate, style: .date)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Pay Schedule" : "New Pay Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePaySchedule()
                    }
                    .disabled(selectedJob == nil)
                }
            }
        }
        .onChange(of: selectedJob) { job in
            if let job = job {
                paySchedule.jobId = job.id
            }
        }
    }
    
    private func savePaySchedule() {
        if isEditing {
            payScheduleViewModel.updatePaySchedule(paySchedule)
        } else {
            payScheduleViewModel.addPaySchedule(paySchedule)
        }
        dismiss()
    }
}
