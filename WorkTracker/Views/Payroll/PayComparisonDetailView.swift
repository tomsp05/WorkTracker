//
//  PayComparisonDetailView.swift
//  WorkTracker
//
//  Created by GitHub Copilot on 8/2/25.
//

import SwiftUI

fileprivate func currencyString(for value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
    return formatter.string(from: NSNumber(value: value)) ?? "$\(String(format: "%.2f", value))"
}

struct PayComparisonDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    let comparison: PayComparison
    let jobName: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    HeaderComparisonCard(comparison: comparison, jobName: jobName)
                        .padding(.horizontal)
                    
                    // Overall Accuracy Summary
                    AccuracySummaryCard(comparison: comparison)
                        .padding(.horizontal)
                    
                    // Detailed Breakdowns
                    VStack(spacing: 16) {
                        HoursBreakdownCard(comparison: comparison)
                        PayBreakdownCard(comparison: comparison)
                        ShiftsBreakdownCard(comparison: comparison)
                    }
                    .padding(.horizontal)
                    
                    // Analysis Insights
                    if abs(comparison.hoursDifference) > 0.1 || abs(comparison.payDifference) > 0.01 {
                        AnalysisInsightsCard(comparison: comparison)
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.05 : 0.02))
            .navigationTitle("Pay Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(viewModel.themeColor)
                    .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - Header Components

struct HeaderComparisonCard: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    let comparison: PayComparison
    let jobName: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Job and Period Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(jobName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Pay Period Analysis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(comparison.payslip.payDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Pay Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Period Duration
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(viewModel.themeColor)
                
                Text("\(comparison.payPeriod.startDate.formatted(date: .abbreviated, time: .omitted)) - \(comparison.payPeriod.endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            // Net Pay Highlight
            HStack {
                Text("Net Pay Received")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(currencyString(for: comparison.payslip.netPay))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.themeColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(viewModel.themeColor.opacity(0.1))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct AccuracySummaryCard: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    let comparison: PayComparison
    
    var overallAccuracy: Double {
        (comparison.hoursAccuracy + comparison.payAccuracy) / 2
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Accuracy Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(String(format: "%.1f", overallAccuracy))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(overallAccuracy >= 95 ? .green : overallAccuracy >= 85 ? .orange : .red)
            }
            
            HStack(spacing: 20) {
                AccuracyMetric(
                    title: "Hours Match",
                    value: comparison.hoursAccuracy,
                    icon: "clock.fill",
                    color: comparison.hoursAccuracy >= 95 ? .green : comparison.hoursAccuracy >= 85 ? .orange : .red
                )
                
                AccuracyMetric(
                    title: "Pay Match",
                    value: comparison.payAccuracy,
                    icon: "dollarsign.circle.fill",
                    color: comparison.payAccuracy >= 95 ? .green : comparison.payAccuracy >= 85 ? .orange : .red
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

struct AccuracyMetric: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text("\(String(format: "%.1f", value))%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}

// MARK: - Breakdown Cards

struct HoursBreakdownCard: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    let comparison: PayComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(viewModel.themeColor)
                    .font(.title3)
                
                Text("Hours Breakdown")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(String(format: "%.1f", comparison.hoursAccuracy))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(comparison.hoursAccuracy >= 95 ? Color.green.opacity(0.2) : comparison.hoursAccuracy >= 85 ? Color.orange.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(comparison.hoursAccuracy >= 95 ? .green : comparison.hoursAccuracy >= 85 ? .orange : .red)
                    .cornerRadius(6)
            }
            
            VStack(spacing: 12) {
                DetailComparisonRow(
                    title: "Regular Hours",
                    expected: comparison.expectedRegularHours,
                    actual: comparison.payslip.regularHours,
                    format: .hours
                )
                
                DetailComparisonRow(
                    title: "Overtime Hours",
                    expected: comparison.expectedOvertimeHours,
                    actual: comparison.payslip.overtimeHours,
                    format: .hours
                )
                
                DetailComparisonRow(
                    title: "Holiday Hours",
                    expected: comparison.expectedHolidayHours,
                    actual: comparison.payslip.holidayHours,
                    format: .hours
                )
                
                Divider()
                
                DetailComparisonRow(
                    title: "Total Hours",
                    expected: comparison.expectedTotalHours,
                    actual: comparison.payslip.totalHours,
                    format: .hours,
                    isTotal: true
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct PayBreakdownCard: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    let comparison: PayComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(viewModel.themeColor)
                    .font(.title3)
                
                Text("Pay Breakdown")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(String(format: "%.1f", comparison.payAccuracy))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(comparison.payAccuracy >= 95 ? Color.green.opacity(0.2) : comparison.payAccuracy >= 85 ? Color.orange.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(comparison.payAccuracy >= 95 ? .green : comparison.payAccuracy >= 85 ? .orange : .red)
                    .cornerRadius(6)
            }
            
            VStack(spacing: 12) {
                DetailComparisonRow(
                    title: "Expected Gross Pay",
                    expected: comparison.expectedGrossPay,
                    actual: comparison.payslip.grossPay,
                    format: .currency,
                    isTotal: true
                )
                
                HStack {
                    Text("Total Deductions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(currencyString(for: comparison.payslip.totalDeductions))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.systemGray6))
                )
                
                HStack {
                    Text("Net Pay")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text(currencyString(for: comparison.payslip.netPay))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.themeColor)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(viewModel.themeColor.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct ShiftsBreakdownCard: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    let comparison: PayComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundColor(viewModel.themeColor)
                    .font(.title3)
                
                Text("Logged Shifts")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(comparison.expectedShifts.count) shifts")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .foregroundColor(.secondary)
                    .cornerRadius(6)
            }
            
            if comparison.expectedShifts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No shifts logged for this period")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(comparison.expectedShifts.sorted(by: { $0.date < $1.date })) { shift in
                        ShiftSummaryRow(shift: shift)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct AnalysisInsightsCard: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    let comparison: PayComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(viewModel.themeColor)
                    .font(.title3)
                
                Text("Analysis Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                if abs(comparison.hoursDifference) > 0.1 {
                    InsightRow(
                        icon: comparison.hoursDifference > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                        color: comparison.hoursDifference > 0 ? .green : .red,
                        title: "Hours Difference",
                        description: "Your payslip shows \(String(format: "%.1f", abs(comparison.hoursDifference))) \(comparison.hoursDifference > 0 ? "more" : "fewer") hours than logged",
                        value: "\(comparison.hoursDifference > 0 ? "+" : "")\(String(format: "%.1f", comparison.hoursDifference)) hrs"
                    )
                }
                
                if abs(comparison.payDifference) > 0.01 {
                    InsightRow(
                        icon: comparison.payDifference > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                        color: comparison.payDifference > 0 ? .green : .red,
                        title: "Pay Difference",
                        description: "Your payslip shows \(comparison.payDifference > 0 ? "more" : "less") gross pay than expected",
                        value: "\(comparison.payDifference > 0 ? "+" : "")\(currencyString(for: comparison.payDifference))"
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct InsightRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

struct DetailComparisonRow: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    let title: String
    let expected: Double
    let actual: Double
    let format: ComparisonFormat
    let isTotal: Bool
    let accuracy: Double?
    
    init(title: String, expected: Double, actual: Double, format: ComparisonFormat, isTotal: Bool = false, accuracy: Double? = nil) {
        self.title = title
        self.expected = expected
        self.actual = actual
        self.format = format
        self.isTotal = isTotal
        self.accuracy = accuracy
    }
    
    enum ComparisonFormat {
        case currency
        case hours
    }
    
    var difference: Double {
        actual - expected
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(isTotal ? .headline : .subheadline)
                    .fontWeight(isTotal ? .semibold : .regular)
                
                Spacer()
                
                if let accuracy = accuracy {
                    Text("\(String(format: "%.1f", accuracy))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accuracy >= 95 ? Color.green.opacity(0.2) : accuracy >= 85 ? Color.orange.opacity(0.2) : Color.red.opacity(0.2))
                        .foregroundColor(accuracy >= 95 ? .green : accuracy >= 85 ? .orange : .red)
                        .cornerRadius(4)
                }
            }
            
            HStack(spacing: 16) {
                // Expected value
                VStack(alignment: .leading, spacing: 2) {
                    Text("Expected")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Group {
                        switch format {
                        case .currency:
                            Text(currencyString(for: expected))
                        case .hours:
                            Text(String(format: "%.2f", expected)) + Text(" hrs")
                        }
                    }
                    .font(isTotal ? .subheadline : .caption)
                    .fontWeight(isTotal ? .semibold : .medium)
                }
                
                // Difference indicator
                VStack(alignment: .center, spacing: 2) {
                    Text("Difference")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if abs(difference) > (format == .currency ? 0.01 : 0.01) {
                        HStack(spacing: 4) {
                            Image(systemName: difference >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .font(.caption)
                                .foregroundColor(difference >= 0 ? .green : .red)
                            
                            Group {
                                switch format {
                                case .currency:
                                    Text(currencyString(for: abs(difference)))
                                case .hours:
                                    Text(String(format: "%.2f", abs(difference))) + Text("h")
                                }
                            }
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(difference >= 0 ? .green : .red)
                        }
                    } else {
                        Text("Match")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                // Actual value
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Actual")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Group {
                        switch format {
                        case .currency:
                            Text(currencyString(for: actual))
                        case .hours:
                            Text(String(format: "%.2f", actual)) + Text(" hrs")
                        }
                    }
                    .font(isTotal ? .subheadline : .caption)
                    .fontWeight(isTotal ? .semibold : .medium)
                    .foregroundColor(isTotal ? viewModel.themeColor : .primary)
                }
            }
        }
        .padding(.vertical, isTotal ? 8 : 4)
        .padding(.horizontal, isTotal ? 12 : 8)
        .background(
            RoundedRectangle(cornerRadius: isTotal ? 12 : 8, style: .continuous)
                .fill(isTotal ? viewModel.themeColor.opacity(0.1) : Color(.systemGray6))
        )
    }
}

struct ShiftSummaryRow: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    let shift: WorkShift
    
    var body: some View {
        HStack(spacing: 12) {
            // Date and type indicator
            VStack(alignment: .leading, spacing: 2) {
                Text(shift.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .fontWeight(.semibold)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(shiftTypeColor)
                        .frame(width: 6, height: 6)
                    
                    Text(shift.shiftType.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Time range
            VStack(alignment: .center, spacing: 2) {
                Text("Time")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(shift.startTime.formatted(date: .omitted, time: .shortened)) - \(shift.endTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // Duration
            VStack(alignment: .trailing, spacing: 2) {
                Text("Duration")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.1f", shift.duration)) + Text(" hrs")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.themeColor)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
    
    private var shiftTypeColor: Color {
        switch shift.shiftType {
        case .regular:
            return .blue
        case .overtime:
            return .orange
        case .holiday:
            return .purple
        }
    }
}

struct AnalysisRow: View {
    let title: String
    let value: Double
    let format: AnalysisFormat
    
    enum AnalysisFormat {
        case percentage
        case currency
        case hours
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Group {
                switch format {
                case .percentage:
                    Text(String(format: "%.1f", value)) + Text("%")
                case .currency:
                    Text(currencyString(for: value))
                case .hours:
                    Text(String(format: "%.2f", value)) + Text(" hrs")
                }
            }
            .foregroundColor(
                format == .percentage ? 
                (value >= 95 ? .green : value >= 85 ? .orange : .red) : 
                .primary
            )
        }
    }
}

