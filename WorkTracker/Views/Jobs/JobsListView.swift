// WorkTracker/Views/JobsListView.swift

import SwiftUI

struct JobsListView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddJobSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var jobToDelete: Job? = nil

    var body: some View {
        ScrollView {
            if viewModel.jobs.isEmpty {
                emptyJobsView
                    .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    // Active jobs section
                    if !viewModel.jobs.filter({ $0.isActive }).isEmpty {
                        Section(header: Text("Active Jobs").font(.headline).padding(.horizontal)) {
                            ForEach(viewModel.jobs.filter { $0.isActive }) { job in
                                jobRow(for: job)
                            }
                        }
                    }

                    // Inactive jobs section (if any)
                    if !viewModel.jobs.filter({ !$0.isActive }).isEmpty {
                        Section(header: Text("Inactive Jobs").font(.headline).padding(.horizontal)) {
                            ForEach(viewModel.jobs.filter { !$0.isActive }) { job in
                                jobRow(for: job)
                            }
                        }
                    }
                }
                .padding(.vertical)
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
            Spacer()
            Image(systemName: "briefcase.fill")
                .font(.system(size: 64))
                .foregroundColor(viewModel.themeColor.opacity(0.6))

            Text("No Jobs Added")
                .font(.title2)
                .fontWeight(.bold)

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
                    .shadow(color: viewModel.themeColor.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 10)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func jobRow(for job: Job) -> some View {
        NavigationLink(destination: JobDetailView(job: job).environmentObject(viewModel)) {
            JobCardView(job: job)
                .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
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
}
