//
//  PayrollManagementView.swift
//  WorkTracker
//
//  Created by GitHub Copilot on 8/2/25.
//

import SwiftUI

struct PayrollManagementView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    let jobs: [Job]
    let shifts: [WorkShift]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Enhanced Header Section
                VStack(spacing: 16) {
                        // Icon and title
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.themeColor.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "banknote.fill")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(viewModel.themeColor)
                            }
                            
                            VStack(spacing: 6) {
                                Text("Payroll Management")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("Track pay schedules, record payslips, and compare expected vs actual earnings")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        // Navigation breadcrumb
                        HStack {
                            Image(systemName: "house.fill")
                                .font(.caption)
                                .foregroundColor(viewModel.themeColor)
                            
                            Text("WorkTracker")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("Payroll")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(viewModel.themeColor)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Enhanced Feature Cards
                    VStack(spacing: 16) {
                        // Pay Schedules Card
                        NavigationLink(destination: PayScheduleListView(jobs: jobs)) {
                            PayrollFeatureCard(
                                title: "Pay Schedules",
                                description: "Set up when you get paid for each job",
                                iconName: "calendar.badge.clock",
                                iconColor: .blue,
                                actionText: "Manage Schedules",
                                badge: getActiveSchedulesCount()
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Payslips Card
                        NavigationLink(destination: PayslipListView(jobs: jobs)) {
                            PayrollFeatureCard(
                                title: "Payslips",
                                description: "Track actual earnings from your paystubs",
                                iconName: "doc.text.fill",
                                iconColor: .green,
                                actionText: "View Payslips",
                                badge: getPayslipsCount()
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Comparison Card
                        NavigationLink(destination: PayComparisonView(jobs: jobs, shifts: shifts)) {
                            PayrollFeatureCard(
                                title: "Compare Earnings",
                                description: "See how your logged shifts match actual pay",
                                iconName: "chart.bar.xaxis",
                                iconColor: .orange,
                                actionText: "View Comparisons",
                                badge: nil
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    // Enhanced Quick Stats Section
                    if !jobs.isEmpty {
                        QuickPayrollStats(jobs: jobs, shifts: shifts)
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
        }
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .navigationTitle("Payroll")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getActiveSchedulesCount() -> String? {
        // This would typically fetch from PayScheduleViewModel, but for now return nil
        return nil
    }
    
    private func getPayslipsCount() -> String? {
        // This would typically fetch from PayslipViewModel, but for now return nil
        return nil
    }
}

struct PayrollFeatureCard: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let description: String
    let iconName: String
    let iconColor: Color
    let actionText: String
    let badge: String?
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 64, height: 64)
                
                Image(systemName: iconName)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(iconColor)
                
                // Badge indicator
                if let badge = badge {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(iconColor)
                                .clipShape(Capsule())
                                .offset(x: 8, y: -8)
                        }
                        Spacer()
                    }
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text(actionText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(iconColor)
                    .padding(.top, 2)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.3 : 0.07))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(viewModel.themeColor.opacity(0.15), lineWidth: 1)
        )
        .scaleEffect(0.98)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}

struct QuickPayrollStats: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    let jobs: [Job]
    let shifts: [WorkShift]
    @StateObject private var payslipViewModel = PayslipViewModel()
    @StateObject private var payScheduleViewModel = PayScheduleViewModel()
    
    var recentShiftsCount: Int {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return shifts.filter { $0.date >= thirtyDaysAgo }.count
    }
    
    var totalEarningsThisMonth: Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        return shifts.filter { $0.date >= startOfMonth }
                    .reduce(0) { total, shift in
                        if let job = jobs.first(where: { $0.id == shift.jobId }) {
                            return total + (shift.duration * job.hourlyRate)
                        }
                        return total
                    }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Quick Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("Last 30 days")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                EnhancedStatCard(
                    title: "Active Schedules",
                    value: "\(payScheduleViewModel.paySchedules.filter { $0.isActive }.count)",
                    subtitle: "Pay frequencies",
                    iconName: "calendar.badge.clock",
                    color: .blue,
                    trend: nil
                )
                
                EnhancedStatCard(
                    title: "Recorded Payslips",
                    value: "\(payslipViewModel.payslips.count)",
                    subtitle: "Total entries",
                    iconName: "doc.text.fill",
                    color: .green,
                    trend: nil
                )
                
                EnhancedStatCard(
                    title: "Recent Shifts",
                    value: "\(recentShiftsCount)",
                    subtitle: "This month",
                    iconName: "clock.fill",
                    color: .orange,
                    trend: recentShiftsCount > 0 ? .up : .neutral
                )
                
                EnhancedStatCard(
                    title: "Expected Earnings",
                    value: totalEarningsThisMonth.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")),
                    subtitle: "This month",
                    iconName: "dollarsign.circle.fill",
                    color: viewModel.themeColor,
                    trend: totalEarningsThisMonth > 0 ? .up : .neutral
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.15 : 0.06))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(viewModel.themeColor.opacity(0.15), lineWidth: 1)
        )
    }
}

struct EnhancedStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let iconName: String
    let color: Color
    let trend: TrendDirection?
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: WorkHoursViewModel
    
    enum TrendDirection {
        case up, down, neutral
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with icon and trend
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trendIcon(for: trend))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(trendColor(for: trend))
                }
            }
            
            // Value and subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Title
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.15 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(viewModel.themeColor.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func trendIcon(for trend: TrendDirection) -> String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }
    
    private func trendColor(for trend: TrendDirection) -> Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .neutral: return .secondary
        }
    }
}

