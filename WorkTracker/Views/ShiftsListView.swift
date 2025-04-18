//
//  ShiftsListView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//

import SwiftUI

struct ShiftsListView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingAddShiftSheet = false
    @State private var timeRange: TimeRange = .thisMonth
    @State private var selectedSort: SortOption = .dateDescending
    
    // Optional job ID for filtering shifts by job
    var filterJobId: UUID? = nil
    
    // Sort options
    enum SortOption: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case earningsDescending = "Highest Pay"
        case earningsAscending = "Lowest Pay"
        case durationDescending = "Longest First"
        case durationAscending = "Shortest First"
    }
    
    // Filtered shifts based on selected time range and job filter
    private var filteredShifts: [WorkShift] {
        let (startDate, endDate) = timeRange.dateRange
        
        return viewModel.shifts
            .filter { shift in
                // Filter by date range
                shift.date >= startDate && shift.date <= endDate &&
                // Optional filter by job
                (filterJobId == nil || shift.jobId == filterJobId)
            }
    }
    
    // Sorted shifts
    private var sortedShifts: [WorkShift] {
        switch selectedSort {
        case .dateDescending:
            return filteredShifts.sorted { $0.date > $1.date }
        case .dateAscending:
            return filteredShifts.sorted { $0.date < $1.date }
        case .earningsDescending:
            return filteredShifts.sorted { calculateShiftEarnings($0) > calculateShiftEarnings($1) }
        case .earningsAscending:
            return filteredShifts.sorted { calculateShiftEarnings($0) < calculateShiftEarnings($1) }
        case .durationDescending:
            return filteredShifts.sorted { $0.duration > $1.duration }
        case .durationAscending:
            return filteredShifts.sorted { $0.duration < $1.duration }
        }
    }
    
    // Group shifts by week
    private var groupedShifts: [(date: Date, shifts: [WorkShift])] {
        // Group by the start of week for each shift date
        let calendar = Calendar.current
        var groups = Dictionary<Date, [WorkShift]>()
        
        for shift in sortedShifts {
            // Get the start of the week containing this shift
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: shift.date))!
            
            if groups[weekStart] == nil {
                groups[weekStart] = []
            }
            
            groups[weekStart]!.append(shift)
        }
        
        // Sort the groups by key (date) based on selected sort order
        let sortedGroups: [(Date, [WorkShift])]
        
        switch selectedSort {
        case .dateAscending, .earningsAscending, .durationAscending:
            sortedGroups = groups.sorted { $0.0 < $1.0 }  // Fixed: Use tuple index instead of .key
        case .dateDescending, .earningsDescending, .durationDescending:
            sortedGroups = groups.sorted { $0.0 > $1.0 }  // Fixed: Use tuple index instead of .key
        }
        
        // Return the sorted groups
        return sortedGroups.map { (date: $0.0, shifts: $0.1) }  // Fixed: Use tuple indices
    }
    
    // Calculate correct earnings for a shift
    private func calculateShiftEarnings(_ shift: WorkShift) -> Double {
        // Get the appropriate rate (either override or job rate)
        let rate: Double
        if let override = shift.hourlyRateOverride {
            rate = override
        } else if let job = viewModel.jobs.first(where: { $0.id == shift.jobId }) {
            rate = job.hourlyRate
        } else {
            rate = 0.0
        }
        
        // Apply shift type multiplier
        let multiplier: Double = {
            switch shift.shiftType {
            case .regular: return 1.0
            case .overtime: return 1.5
            case .holiday: return 2.0
            }
        }()
        
        return shift.duration * rate * multiplier
    }
    
    // Summary stats for the period
    private var totalEarnings: Double {
        return filteredShifts.reduce(0) { sum, shift in
            return sum + calculateShiftEarnings(shift)
        }
    }
    
    private var totalHours: Double {
        return filteredShifts.reduce(0) { $0 + $1.duration }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Summary header
            summaryHeader
            
            // Filter options
            filterOptions
            
            // List of shifts
            if sortedShifts.isEmpty {
                emptyShiftsView
            } else {
                shiftsListView
            }
        }
        .navigationTitle(filterJobId != nil ? "Job Shifts" : "All Shifts")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddShiftSheet = true
                }) {
                    Label("Add Shift", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddShiftSheet) {
            NavigationView {
                AddShiftView(preSelectedJobId: filterJobId)
                    .navigationTitle("Add Shift")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingAddShiftSheet = false
                        }
                    )
            }
        }
    }
    
    // MARK: - View Components
    
    private var summaryHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Earnings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(totalEarnings))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.themeColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Hours")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatHours(totalHours))
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            
            // Period indicator
            Text(timeRangePeriodText)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var filterOptions: some View {
        VStack(spacing: 12) {
            // Time range picker
            Picker("Time Range", selection: $timeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Sort options
            HStack {
                Text("Sort by:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $selectedSort) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var emptyShiftsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
                .padding()
            
            Text("No shifts found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Try changing the date range or add a new shift.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingAddShiftSheet = true
            }) {
                Text("Add New Shift")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 250)
                    .background(viewModel.themeColor)
                    .cornerRadius(15)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
    
    private var shiftsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Iterate over grouped shifts by week
                ForEach(groupedShifts, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 4) {
                        // Week header with date and weekly stats
                        HStack {
                            // Show the week range
                            Text(formattedWeek(group.date))
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // Weekly summary
                            let weeklyHours = group.shifts.reduce(0) { $0 + $1.duration }
                            Text(formatHours(weeklyHours))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        
                        Divider()
                        
                        // Shifts for this week
                        ForEach(group.shifts) { shift in
                            NavigationLink(destination: EditShiftView(shift: shift)) {
                                ShiftCardView(shift: shift)
                                    .environmentObject(viewModel)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private var timeRangePeriodText: String {
        let (startDate, endDate) = timeRange.dateRange
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return "Period: \(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    private func formattedWeek(_ weekStartDate: Date) -> String {
        let calendar = Calendar.current
        let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate)!
        
        let startFormatter = DateFormatter()
        let endFormatter = DateFormatter()
        
        // If same month, only show day number for start date
        if calendar.component(.month, from: weekStartDate) == calendar.component(.month, from: weekEndDate) {
            startFormatter.dateFormat = "d"
            endFormatter.dateFormat = "d MMM yyyy"
            return "Week of \(startFormatter.string(from: weekStartDate))-\(endFormatter.string(from: weekEndDate))"
        } else {
            // Different months
            startFormatter.dateFormat = "d MMM"
            endFormatter.dateFormat = "d MMM yyyy"
            return "Week of \(startFormatter.string(from: weekStartDate))-\(endFormatter.string(from: weekEndDate))"
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
    
    private func formatHours(_ hours: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        
        guard let formattedHours = formatter.string(from: NSNumber(value: hours)) else {
            return "\(hours)h"
        }
        
        return "\(formattedHours)h"
    }
}
