//
//  PayScheduleListView.swift
//  WorkTracker
//
//  Created by GitHub Copilot on 8/2/25.
//

import SwiftUI

struct PayScheduleListView: View {
    @StateObject private var payScheduleViewModel = PayScheduleViewModel()
    @State private var showingAddSchedule = false
    @State private var editingSchedule: PaySchedule?
    
    let jobs: [Job]
    
    var body: some View {
        List {
            ForEach(payScheduleViewModel.paySchedules) { schedule in
                    PayScheduleRowView(
                        paySchedule: schedule,
                        jobName: getJobName(for: schedule.jobId)
                    )
                    .onTapGesture {
                        editingSchedule = schedule
                    }
                }
                .onDelete(perform: deleteSchedules)
        }
        .navigationTitle("Pay Schedules")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSchedule = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(jobs.isEmpty)
            }
        }
        .sheet(isPresented: $showingAddSchedule) {
            PayScheduleFormView(
                payScheduleViewModel: payScheduleViewModel,
                jobs: jobs
            )
        }
        .sheet(item: $editingSchedule) { schedule in
            PayScheduleFormView(
                payScheduleViewModel: payScheduleViewModel,
                jobs: jobs,
                paySchedule: schedule
            )
        }
        .overlay {
            if payScheduleViewModel.paySchedules.isEmpty {
                ContentUnavailableView(
                    "No Pay Schedules",
                    systemImage: "calendar.badge.clock",
                    description: Text("Add a pay schedule to track when you get paid and compare expected vs actual earnings.")
                )
            }
        }
    }
    
    private func getJobName(for jobId: UUID) -> String {
        return jobs.first { $0.id == jobId }?.name ?? "Unknown Job"
    }
    
    private func deleteSchedules(offsets: IndexSet) {
        for index in offsets {
            payScheduleViewModel.deletePaySchedule(payScheduleViewModel.paySchedules[index])
        }
    }
}

struct PayScheduleRowView: View {
    let paySchedule: PaySchedule
    let jobName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(jobName)
                    .font(.headline)
                Spacer()
                if !paySchedule.isActive {
                    Text("Inactive")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            HStack {
                Label(paySchedule.frequency.displayName, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if paySchedule.frequency == .custom, let interval = paySchedule.customDayInterval {
                    Text("Every \(interval) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Next pay: \(paySchedule.nextPayDate(), style: .date)")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}
