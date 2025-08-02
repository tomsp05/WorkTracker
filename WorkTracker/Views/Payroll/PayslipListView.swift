//
//  PayslipListView.swift
//  WorkTracker
//
//  Created by GitHub Copilot on 8/2/25.
//

import SwiftUI

struct PayslipListView: View {
    @StateObject private var payslipViewModel = PayslipViewModel()
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddPayslip = false
    @State private var editingPayslip: Payslip?
    @State private var selectedPayslip: Payslip?
    
    let jobs: [Job]
    
    var sortedPayslips: [Payslip] {
        payslipViewModel.payslips.sorted { $0.payDate > $1.payDate }
    }
    
    var body: some View {
        List {
            ForEach(sortedPayslips) { payslip in
                    PayslipRowView(
                        payslip: payslip,
                        jobName: getJobName(for: payslip.jobId)
                    )
                    .onTapGesture {
                        selectedPayslip = payslip
                    }
                    .contextMenu {
                        Button {
                            editingPayslip = payslip
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            payslipViewModel.deletePayslip(payslip)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: deletePayslips)
        }
        .navigationTitle("Payslips")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.1 : 0.05))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddPayslip = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(jobs.isEmpty)
                .foregroundColor(viewModel.themeColor)
            }
        }
        .sheet(isPresented: $showingAddPayslip) {
            PayslipFormView(
                payslipViewModel: payslipViewModel,
                jobs: jobs
            )
            .environmentObject(viewModel)
        }
        .sheet(item: $editingPayslip) { payslip in
            PayslipFormView(
                payslipViewModel: payslipViewModel,
                jobs: jobs,
                payslip: payslip
            )
            .environmentObject(viewModel)
        }
        .sheet(item: $selectedPayslip) { payslip in
            PayslipDetailView(payslip: payslip, jobName: getJobName(for: payslip.jobId))
                .environmentObject(viewModel)
        }
        .overlay {
            if payslipViewModel.payslips.isEmpty {
                ContentUnavailableView {
                    Label("No Payslips", systemImage: "doc.text")
                } description: {
                    Text("Add your payslips to track actual earnings and compare them with expected earnings from your logged shifts.")
                } actions: {
                    if !jobs.isEmpty {
                        Button("Add First Payslip") {
                            showingAddPayslip = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(viewModel.themeColor)
                    }
                }
            }
        }
    }
    
    private func getJobName(for jobId: UUID) -> String {
        return jobs.first { $0.id == jobId }?.name ?? "Unknown Job"
    }
    
    private func deletePayslips(offsets: IndexSet) {
        for index in offsets {
            payslipViewModel.deletePayslip(sortedPayslips[index])
        }
    }
}

struct PayslipRowView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    let payslip: Payslip
    let jobName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(jobName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Pay Period")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(payslip.payDate, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Pay Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Period and hours info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(payslip.periodStartDate.formatted(date: .abbreviated, time: .omitted)) - \(payslip.periodEndDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Label {
                            Text("\(payslip.totalHours, format: .number.precision(.fractionLength(1))) hrs")
                                .font(.caption)
                        } icon: {
                            Image(systemName: "clock")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        if payslip.totalDeductions > 0 {
                            Label {
                                Text(payslip.totalDeductions, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                    .font(.caption)
                            } icon: {
                                Image(systemName: "minus.circle")
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
                
                // Net pay highlight
                VStack(alignment: .trailing, spacing: 2) {
                    Text(payslip.netPay, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.themeColor)
                    Text("Net Pay")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Validation warning
            if !payslip.isValid {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Calculation mismatch")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // Makes entire row tappable
    }
}
