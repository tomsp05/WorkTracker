//
//  PayslipFormView.swift
//  WorkTracker
//
//  Created by GitHub Copilot on 8/2/25.
//

import SwiftUI

struct PayslipFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var payslipViewModel: PayslipViewModel
    @State private var payslip: Payslip
    @State private var selectedJob: Job?
    
    let jobs: [Job]
    let isEditing: Bool
    
    init(payslipViewModel: PayslipViewModel, jobs: [Job], payslip: Payslip? = nil) {
        self.payslipViewModel = payslipViewModel
        self.jobs = jobs
        self.isEditing = payslip != nil
        
        if let existingPayslip = payslip {
            self._payslip = State(initialValue: existingPayslip)
            self._selectedJob = State(initialValue: jobs.first { $0.id == existingPayslip.jobId })
        } else {
            let newPayslip = Payslip(
                jobId: jobs.first?.id ?? UUID(),
                payDate: Date(),
                periodStartDate: Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date()) ?? Date(),
                periodEndDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                regularHours: 0,
                overtimeHours: 0,
                holidayHours: 0,
                regularPay: 0,
                overtimePay: 0,
                holidayPay: 0,
                netPay: 0
            )
            self._payslip = State(initialValue: newPayslip)
            self._selectedJob = State(initialValue: jobs.first)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Job & Period Section
                Section {
                    Picker("Job", selection: $selectedJob) {
                        ForEach(jobs, id: \.id) { job in
                            Text(job.name)
                                .tag(job as Job?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    DatePicker("Pay Date", selection: $payslip.payDate, displayedComponents: .date)
                    DatePicker("Period Start", selection: $payslip.periodStartDate, displayedComponents: .date)
                    DatePicker("Period End", selection: $payslip.periodEndDate, displayedComponents: .date)
                } header: {
                    Text("Job & Period")
                }
                
                // Hours Section
                Section {
                    PayslipInputRow(
                        title: "Regular Hours",
                        value: $payslip.regularHours,
                        format: .hours
                    )
                    
                    PayslipInputRow(
                        title: "Overtime Hours",
                        value: $payslip.overtimeHours,
                        format: .hours
                    )
                    
                    PayslipInputRow(
                        title: "Holiday Hours",
                        value: $payslip.holidayHours,
                        format: .hours
                    )
                    
                    HStack {
                        Text("Total Hours")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(payslip.totalHours, format: .number.precision(.fractionLength(2)))
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.themeColor)
                    }
                } header: {
                    Text("Hours Worked")
                }
                
                // Earnings Section
                Section {
                    PayslipInputRow(
                        title: "Regular Pay",
                        value: $payslip.regularPay,
                        format: .currency
                    )
                    
                    PayslipInputRow(
                        title: "Overtime Pay",
                        value: $payslip.overtimePay,
                        format: .currency
                    )
                    
                    PayslipInputRow(
                        title: "Holiday Pay",
                        value: $payslip.holidayPay,
                        format: .currency
                    )
                    
                    PayslipInputRow(
                        title: "Bonuses",
                        value: $payslip.bonuses,
                        format: .currency,
                        isOptional: true
                    )
                    
                    PayslipInputRow(
                        title: "Other Earnings",
                        value: $payslip.otherEarnings,
                        format: .currency,
                        isOptional: true
                    )
                    
                    HStack {
                        Text("Gross Pay")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(payslip.grossPay, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.themeColor)
                    }
                } header: {
                    Text("Earnings")
                }
                
                // Deductions Section
                Section {
                    PayslipInputRow(
                        title: "Tax Deductions",
                        value: $payslip.taxDeductions,
                        format: .currency,
                        isOptional: true
                    )
                    
                    PayslipInputRow(
                        title: "Insurance Deductions",
                        value: $payslip.insuranceDeductions,
                        format: .currency,
                        isOptional: true
                    )
                    
                    PayslipInputRow(
                        title: "Retirement Contributions",
                        value: $payslip.retirementDeductions,
                        format: .currency,
                        isOptional: true
                    )
                    
                    PayslipInputRow(
                        title: "Other Deductions",
                        value: $payslip.otherDeductions,
                        format: .currency,
                        isOptional: true
                    )
                    
                    HStack {
                        Text("Total Deductions")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(payslip.totalDeductions, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Deductions")
                }
                
                // Net Pay Section
                Section {
                    PayslipInputRow(
                        title: "Net Pay",
                        value: $payslip.netPay,
                        format: .currency
                    )
                    
                    if !payslip.isValid {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Calculation Mismatch")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("Expected: \((payslip.grossPay - payslip.totalDeductions), format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Net Pay")
                }
                
                // Notes Section
                if isEditing || !payslip.notes.isEmpty {
                    Section {
                        TextField("Optional notes about this payslip", text: $payslip.notes, axis: .vertical)
                            .lineLimit(3...6)
                    } header: {
                        Text("Notes")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Payslip" : "New Payslip")
            .navigationBarTitleDisplayMode(.inline)
            .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.1 : 0.05))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePayslip()
                    }
                    .disabled(selectedJob == nil)
                    .foregroundColor(viewModel.themeColor)
                }
            }
        }
        .onChange(of: selectedJob) { job in
            if let job = job {
                payslip.jobId = job.id
            }
        }
    }
    
    private func savePayslip() {
        if isEditing {
            payslipViewModel.updatePayslip(payslip)
        } else {
            payslipViewModel.addPayslip(payslip)
        }
        dismiss()
    }
}

struct PayslipInputRow: View {
    let title: String
    @Binding var value: Double
    let format: InputFormat
    let isOptional: Bool
    
    init(title: String, value: Binding<Double>, format: InputFormat, isOptional: Bool = false) {
        self.title = title
        self._value = value
        self.format = format
        self.isOptional = isOptional
    }
    
    enum InputFormat {
        case currency
        case hours
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Group {
                switch format {
                case .currency:
                    TextField(
                        isOptional ? "0.00" : "Required",
                        value: $value,
                        format: .currency(code: Locale.current.currency?.identifier ?? "USD")
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                case .hours:
                    HStack(spacing: 4) {
                        TextField(
                            isOptional ? "0.0" : "Required",
                            value: $value,
                            format: .number.precision(.fractionLength(2))
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        Text("hrs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
