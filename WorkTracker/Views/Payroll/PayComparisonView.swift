//
//  PayComparisonView.swift
//  WorkTracker
//
//  Created by GitHub Copilot on 8/2/25.
//

import SwiftUI

struct PayComparisonView: View {
    @StateObject private var payslipViewModel = PayslipViewModel()
    @StateObject private var payScheduleViewModel = PayScheduleViewModel()
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedJob: Job?
    @State private var selectedComparison: PayComparison?
    @State private var showingJobPicker = false
    
    let jobs: [Job]
    let shifts: [WorkShift]
    
    var filteredPayslips: [Payslip] {
        guard let selectedJob = selectedJob else { return [] }
        return payslipViewModel.getPayslips(for: selectedJob.id)
    }
    
    var comparisons: [PayComparison] {
        generateComparisons()
    }
    
    var overallAccuracy: Double {
        guard !comparisons.isEmpty else { return 0 }
        let totalAccuracy = comparisons.reduce(0) { $0 + $1.payAccuracy }
        return totalAccuracy / Double(comparisons.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Section
                VStack(spacing: 16) {
                        // Job Selector Card
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "briefcase.fill")
                                    .foregroundColor(viewModel.themeColor)
                                    .font(.title2)
                                
                                Text("Select Job")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if selectedJob != nil {
                                    Button("Change") {
                                        showingJobPicker = true
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(viewModel.themeColor.opacity(0.1))
                                    .foregroundColor(viewModel.themeColor)
                                    .cornerRadius(8)
                                }
                            }
                            
                            if let selectedJob = selectedJob {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(selectedJob.name)
                                            .font(.title3)
                                            .fontWeight(.medium)
                                        
                                        Text("\(filteredPayslips.count) payslips available")
                                            .font(.caption)
                                            .foregroundColor(viewModel.themeColor.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    if !comparisons.isEmpty {
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("Overall Accuracy")
                                                .font(.caption2)
                                                .foregroundColor(viewModel.themeColor.opacity(0.6))
                                            Text(String(format: "%.1f%%", overallAccuracy))
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(overallAccuracy >= 95 ? .green : overallAccuracy >= 85 ? .orange : .red)
                                        }
                                    }
                                }
                            } else {
                                Button {
                                    showingJobPicker = true
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Choose Job to Compare")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(viewModel.themeColor.opacity(0.7))
                                    }
                                    .foregroundColor(viewModel.themeColor)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(viewModel.themeColor.opacity(0.08))
                                .shadow(color: viewModel.themeColor.opacity(0.15), radius: 8, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(viewModel.themeColor.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Content Section
                    if let selectedJob = selectedJob {
                        if filteredPayslips.isEmpty {
                            EmptyComparisonView(jobName: selectedJob.name)
                                .padding(.horizontal)
                        } else {
                            // Quick Stats
                            if !comparisons.isEmpty {
                                ComparisonStatsView(comparisons: comparisons)
                                    .padding(.horizontal)
                            }
                            
                            // Comparisons List
                            LazyVStack(spacing: 12) {
                                ForEach(comparisons, id: \.id) { comparison in
                                    PayComparisonRowView(comparison: comparison)
                                        .onTapGesture {
                                            selectedComparison = comparison
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        SelectJobPromptView()
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
        }
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.05 : 0.02))
        .navigationTitle("Pay Comparison")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Select Job", isPresented: $showingJobPicker) {
            ForEach(jobs, id: \.id) { job in
                Button(job.name) {
                    selectedJob = job
                }
            }
        }
        .sheet(item: $selectedComparison) { comparison in
            PayComparisonDetailView(comparison: comparison, jobName: selectedJob?.name ?? "")
        }
    }
    
    private func generateComparisons() -> [PayComparison] {
        guard let selectedJob = selectedJob else { return [] }
        
        var comparisons: [PayComparison] = []
        
        for payslip in filteredPayslips.sorted(by: { $0.payDate > $1.payDate }) {
            // Create a synthetic pay period from the payslip dates
            let payPeriod = PayPeriod(
                id: UUID(),
                payScheduleId: UUID(),
                startDate: payslip.periodStartDate,
                endDate: payslip.periodEndDate,
                payDate: payslip.payDate
            )
            
            let comparison = payslipViewModel.createPayComparison(
                for: payslip,
                with: shifts,
                payPeriod: payPeriod,
                job: selectedJob
            )
            
            comparisons.append(comparison)
        }
        
        return comparisons
    }
    
}

// MARK: - Supporting Views

struct EmptyComparisonView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    let jobName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(viewModel.themeColor.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Payslips Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add payslips for \(jobName) to see comparisons with your logged shifts and expected earnings.")
                    .font(.subheadline)
                    .foregroundColor(viewModel.themeColor.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            NavigationLink(destination: PayslipListView(jobs: [Job(id: UUID(), name: jobName, hourlyRate: 0, color: "#000000")])) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Payslip")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(viewModel.themeColor)
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 40)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(viewModel.themeColor.opacity(0.08))
        )
    }
}

struct SelectJobPromptView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "briefcase")
                .font(.system(size: 48))
                .foregroundColor(viewModel.themeColor.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Select a Job")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Choose a job from above to compare your expected earnings with actual payslips.")
                    .font(.subheadline)
                    .foregroundColor(viewModel.themeColor.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 40)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(viewModel.themeColor.opacity(0.08))
        )
    }
}

struct ComparisonStatsView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    let comparisons: [PayComparison]
    
    var averageHoursAccuracy: Double {
        guard !comparisons.isEmpty else { return 0 }
        return comparisons.reduce(0) { $0 + $1.hoursAccuracy } / Double(comparisons.count)
    }
    
    var averagePayAccuracy: Double {
        guard !comparisons.isEmpty else { return 0 }
        return comparisons.reduce(0) { $0 + $1.payAccuracy } / Double(comparisons.count)
    }
    
    var totalPayDifference: Double {
        comparisons.reduce(0) { $0 + $1.payDifference }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                StatPillView(
                    title: "Hours Match",
                    value: String(format: "%.0f%%", averageHoursAccuracy),
                    color: averageHoursAccuracy >= 95 ? .green : averageHoursAccuracy >= 85 ? .orange : .red,
                    icon: "clock.fill"
                )
                
                StatPillView(
                    title: "Pay Match",
                    value: String(format: "%.0f%%", averagePayAccuracy),
                    color: averagePayAccuracy >= 95 ? .green : averagePayAccuracy >= 85 ? .orange : .red,
                    icon: "dollarsign.circle.fill"
                )
                
                if abs(totalPayDifference) > 0.01 {
                    StatPillView(
                        title: "Total Diff",
                        value: totalPayDifference.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")),
                        color: totalPayDifference > 0 ? .green : .red,
                        icon: totalPayDifference > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(viewModel.themeColor.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(viewModel.themeColor.opacity(0.12))
        )
    }
}

struct StatPillView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(viewModel.themeColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(viewModel.themeColor.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(viewModel.themeColor.opacity(0.19), lineWidth: 1)
        )
    }
}

struct PayComparisonRowView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    let comparison: PayComparison
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pay Period")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(comparison.payPeriod.startDate.formatted(date: .abbreviated, time: .omitted)) - \(comparison.payPeriod.endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(viewModel.themeColor.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(comparison.payslip.payDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Pay Date")
                        .font(.caption2)
                        .foregroundColor(viewModel.themeColor.opacity(0.6))
                }
            }
            
            // Metrics Grid
            HStack(spacing: 16) {
                ComparisonMetricCard(
                    title: "Hours",
                    expected: comparison.expectedTotalHours,
                    actual: comparison.payslip.totalHours,
                    format: .hours,
                    accuracy: comparison.hoursAccuracy
                )
                
                ComparisonMetricCard(
                    title: "Gross Pay",
                    expected: comparison.expectedGrossPay,
                    actual: comparison.payslip.grossPay,
                    format: .currency,
                    accuracy: comparison.payAccuracy
                )
            }
            
            // Net Pay Banner
            HStack {
                Text("Net Pay")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.themeColor)
                
                Spacer()
                
                Text(comparison.payslip.netPay.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.themeColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(viewModel.themeColor.opacity(0.17))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(viewModel.themeColor.opacity(0.07))
                .shadow(color: viewModel.themeColor.opacity(0.12), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(viewModel.themeColor.opacity(0.10), lineWidth: 1)
        )
    }
}

struct ComparisonMetricCard: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    let title: String
    let expected: Double
    let actual: Double
    let format: MetricFormat
    let accuracy: Double
    
    enum MetricFormat {
        case currency
        case hours
    }
    
    var difference: Double {
        actual - expected
    }
    
    var isPositive: Bool {
        difference >= 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Title and accuracy
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.themeColor.opacity(0.8))
                
                Spacer()
                
                Text(String(format: "%.0f%%", accuracy))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accuracy >= 95 ? viewModel.themeColor.opacity(0.2) : accuracy >= 85 ? viewModel.themeColor.opacity(0.2) : viewModel.themeColor.opacity(0.2))
                    .foregroundColor(accuracy >= 95 ? .green : accuracy >= 85 ? .orange : .red)
                    .cornerRadius(4)
            }
            
            // Values comparison
            VStack(spacing: 6) {
                HStack {
                    Text("Expected:")
                        .font(.caption2)
                        .foregroundColor(viewModel.themeColor.opacity(0.7))
                    
                    Spacer()
                    
                    Group {
                        switch format {
                        case .currency:
                            Text(expected.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                        case .hours:
                            Text(String(format: "%.1f hrs", expected))
                        }
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                }
                
                HStack {
                    Text("Actual:")
                        .font(.caption2)
                        .foregroundColor(viewModel.themeColor.opacity(0.7))
                    
                    Spacer()
                    
                    Group {
                        switch format {
                        case .currency:
                            Text(actual.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                        case .hours:
                            Text(String(format: "%.1f hrs", actual))
                        }
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                }
                
                // Difference indicator
                if abs(difference) > (format == .currency ? 0.01 : 0.1) {
                    HStack {
                        Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                            .foregroundColor(isPositive ? .green : .red)
                        
                        Group {
                            switch format {
                            case .currency:
                                Text(abs(difference).formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                            case .hours:
                                Text(String(format: "%.1fh", abs(difference)))
                            }
                        }
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(isPositive ? .green : .red)
                        
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(viewModel.themeColor.opacity(0.08))
        )
    }
}

