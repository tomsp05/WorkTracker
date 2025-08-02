//
//  PayslipDetailView.swift
//  WorkTracker
//
//  Created by GitHub Copilot on 8/2/25.
//

import SwiftUI

struct PayslipDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    let payslip: Payslip
    let jobName: String
    
    var body: some View {
        NavigationView {
            Form {
                // Job & Period Section
                Section {
                    PayslipDetailRow(title: "Job", value: jobName)
                    PayslipDetailRow(title: "Pay Date", value: payslip.payDate, format: .date)
                    PayslipDetailRow(
                        title: "Pay Period",
                        value: "\(payslip.periodStartDate.formatted(date: .abbreviated, time: .omitted)) - \(payslip.periodEndDate.formatted(date: .abbreviated, time: .omitted))"
                    )
                } header: {
                    Text("Job & Period")
                }
                
                // Hours Section
                Section {
                    PayslipDetailRow(title: "Regular Hours", value: payslip.regularHours, format: .hours)
                    PayslipDetailRow(title: "Overtime Hours", value: payslip.overtimeHours, format: .hours)
                    PayslipDetailRow(title: "Holiday Hours", value: payslip.holidayHours, format: .hours)
                    
                    Divider()
                    
                    HStack {
                        Text("Total Hours")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(payslip.totalHours, format: .number.precision(.fractionLength(1)))
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.themeColor)
                        Text("hrs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Hours Breakdown")
                }
                
                // Earnings Section
                Section {
                    PayslipDetailRow(title: "Regular Pay", value: payslip.regularPay, format: .currency)
                    PayslipDetailRow(title: "Overtime Pay", value: payslip.overtimePay, format: .currency)
                    PayslipDetailRow(title: "Holiday Pay", value: payslip.holidayPay, format: .currency)
                    
                    if payslip.bonuses > 0 {
                        PayslipDetailRow(title: "Bonuses", value: payslip.bonuses, format: .currency)
                    }
                    
                    if payslip.otherEarnings > 0 {
                        PayslipDetailRow(title: "Other Earnings", value: payslip.otherEarnings, format: .currency)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Gross Pay")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(payslip.grossPay, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.themeColor)
                    }
                } header: {
                    Text("Earnings Breakdown")
                }
                
                // Deductions Section
                if payslip.totalDeductions > 0 {
                    Section {
                        if payslip.taxDeductions > 0 {
                            PayslipDetailRow(title: "Tax Deductions", value: payslip.taxDeductions, format: .currency, isDeduction: true)
                        }
                        
                        if payslip.insuranceDeductions > 0 {
                            PayslipDetailRow(title: "Insurance Deductions", value: payslip.insuranceDeductions, format: .currency, isDeduction: true)
                        }
                        
                        if payslip.retirementDeductions > 0 {
                            PayslipDetailRow(title: "Retirement Contributions", value: payslip.retirementDeductions, format: .currency, isDeduction: true)
                        }
                        
                        if payslip.otherDeductions > 0 {
                            PayslipDetailRow(title: "Other Deductions", value: payslip.otherDeductions, format: .currency, isDeduction: true)
                        }
                        
                        Divider()
                        
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
                }
                
                // Net Pay Section
                Section {
                    HStack {
                        Text("Net Pay")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        Text(payslip.netPay, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(viewModel.themeColor)
                    }
                    .padding(.vertical, 8)
                    
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
                if !payslip.notes.isEmpty {
                    Section {
                        Text(payslip.notes)
                            .foregroundColor(.primary)
                    } header: {
                        Text("Notes")
                    }
                }
            }
            .navigationTitle("Payslip Details")
            .navigationBarTitleDisplayMode(.inline)
            .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.1 : 0.05))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(viewModel.themeColor)
                }
            }
        }
    }
}

struct PayslipDetailRow: View {
    let title: String
    let value: Any
    let format: DetailFormat
    let isDeduction: Bool
    
    init(title: String, value: String) {
        self.title = title
        self.value = value
        self.format = .text
        self.isDeduction = false
    }
    
    init(title: String, value: Double, format: DetailFormat, isDeduction: Bool = false) {
        self.title = title
        self.value = value
        self.format = format
        self.isDeduction = isDeduction
    }
    
    init(title: String, value: Date, format: DetailFormat) {
        self.title = title
        self.value = value
        self.format = format
        self.isDeduction = false
    }
    
    enum DetailFormat {
        case currency
        case hours
        case date
        case text
    }
    
    var body: some View {
        HStack {
            Text(title)
            
            Spacer()
            
            Group {
                switch format {
                case .currency:
                    if let doubleValue = value as? Double {
                        Text(doubleValue, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                case .hours:
                    if let doubleValue = value as? Double {
                        HStack(spacing: 2) {
                            Text(doubleValue, format: .number.precision(.fractionLength(1)))
                            Text("hrs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                case .date:
                    if let dateValue = value as? Date {
                        Text(dateValue, style: .date)
                    }
                case .text:
                    if let stringValue = value as? String {
                        Text(stringValue)
                    }
                }
            }
            .foregroundColor(isDeduction ? .red : .primary)
        }
    }
}
