//
//  JobsListView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//


//
//  JobsListView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//

import SwiftUI

struct JobsListView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddJobSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var jobToDelete: Job? = nil
    
    var body: some View {
        List {
            if viewModel.jobs.isEmpty {
                emptyJobsView
            } else {
                // Active jobs section
                Section(header: Text("Active Jobs")) {
                    ForEach(viewModel.jobs.filter { $0.isActive }, id: \.id) { job in
                        jobRow(for: job)
                    }
                }
                
                // Inactive jobs section (if any)
                if viewModel.jobs.contains(where: { !$0.isActive }) {
                    Section(header: Text("Inactive Jobs")) {
                        ForEach(viewModel.jobs.filter { !$0.isActive }, id: \.id) { job in
                            jobRow(for: job)
                        }
                    }
                }
            }
        }
        .navigationTitle("Jobs")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddJobSheet = true
                }) {
                    Label("Add Job", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddJobSheet) {
            NavigationView {
                JobFormView(isPresented: $showingAddJobSheet)
                    .environmentObject(viewModel)
                    .navigationTitle("Add Job")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingAddJobSheet = false
                        }
                    )
            }
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Job"),
                message: Text("Are you sure you want to delete this job? This will not delete associated work shifts but they will show as unknown job."),
                primaryButton: .destructive(Text("Delete")) {
                    if let job = jobToDelete {
                        viewModel.deleteJob(job)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var emptyJobsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "briefcase.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Jobs Added")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Add a job to start tracking your work hours and earnings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingAddJobSheet = true
            }) {
                Text("Add Your First Job")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.themeColor)
                    .cornerRadius(15)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    private func jobRow(for job: Job) -> some View {
        NavigationLink(destination: JobDetailView(job: job)) {
            HStack(spacing: 12) {
                // Color indicator
                Circle()
                    .fill(getJobColor(job.color))
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.name)
                        .font(.headline)
                    
                    Text("£\(String(format: "%.2f", job.hourlyRate))/hr")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !job.isActive {
                    Text("Inactive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 4)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                jobToDelete = job
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                toggleJobActiveStatus(job)
            } label: {
                if job.isActive {
                    Label("Deactivate", systemImage: "eye.slash")
                } else {
                    Label("Activate", systemImage: "eye")
                }
            }
            .tint(.orange)
        }
    }
    
    private func toggleJobActiveStatus(_ job: Job) {
        var updatedJob = job
        updatedJob.isActive.toggle()
        viewModel.updateJob(updatedJob)
    }
    
    private func getJobColor(_ colorName: String) -> Color {
        switch colorName {
        case "Blue": return Color(red: 0.20, green: 0.40, blue: 0.70)
        case "Green": return Color(red: 0.20, green: 0.55, blue: 0.30)
        case "Orange": return Color(red: 0.80, green: 0.40, blue: 0.20)
        case "Purple": return Color(red: 0.50, green: 0.25, blue: 0.70)
        case "Red": return Color(red: 0.70, green: 0.20, blue: 0.20)
        case "Teal": return Color(red: 0.20, green: 0.50, blue: 0.60)
        default: return .blue
        }
    }
}