//
//  ShiftFilterView.swift
//  WorkTracker
//
//  Created by Tom Speake on 6/25/25.
//


import SwiftUI

struct ShiftFilterView: View {
    @Binding var filterState: ShiftFilterState
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            Form {
                // Time Filter Section
                Section(header: Text("Date Range")) {
                    timeNavigationView
                }

                // Job Filter Section
                Section(header: Text("Filter by Job")) {
                    ForEach(viewModel.jobs) { job in
                        Button(action: {
                            if filterState.selectedJobIds.contains(job.id) {
                                filterState.selectedJobIds.remove(job.id)
                            } else {
                                filterState.selectedJobIds.insert(job.id)
                            }
                        }) {
                            HStack {
                                Text(job.name)
                                Spacer()
                                if filterState.selectedJobIds.contains(job.id) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                // Earnings Filter
                Section(header: Text("Filter by Earnings")) {
                    TextField("Minimum Earnings", value: $filterState.minEarnings, format: .currency(code: "GBP"))
                        .keyboardType(.decimalPad)
                    TextField("Maximum Earnings", value: $filterState.maxEarnings, format: .currency(code: "GBP"))
                        .keyboardType(.decimalPad)
                }
                
                // Shift Type Filter
                Section(header: Text("Shift Type")) {
                    ForEach(ShiftType.allCases, id: \.self) { type in
                        Button(action: {
                            if filterState.shiftTypes.contains(type) {
                                filterState.shiftTypes.remove(type)
                            } else {
                                filterState.shiftTypes.insert(type)
                            }
                        }) {
                            HStack {
                                Text(type.rawValue.capitalized)
                                Spacer()
                                if filterState.shiftTypes.contains(type) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                // Paid Status Filter
                Section(header: Text("Payment Status")) {
                    Picker("Status", selection: Binding(
                        get: {
                            if let isPaid = filterState.isPaid {
                                return isPaid ? "Paid" : "Unpaid"
                            } else {
                                return "All"
                            }
                        },
                        set: {
                            if $0 == "Paid" {
                                filterState.isPaid = true
                            } else if $0 == "Unpaid" {
                                filterState.isPaid = false
                            } else {
                                filterState.isPaid = nil
                            }
                        }
                    )) {
                        Text("All").tag("All")
                        Text("Paid").tag("Paid")
                        Text("Unpaid").tag("Unpaid")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }


            }
            .navigationTitle("Filter Shifts")
            .navigationBarItems(leading: Button("Clear") {
                filterState = ShiftFilterState()
            }, trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    private var timeNavigationView: some View {
        VStack(spacing: 12) {
            Picker("Time Filter", selection: $filterState.analytics.timeFilter) {
                ForEach(AnalyticsTimeFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            HStack {
                Button(action: { filterState.analytics.timeOffset -= 1 }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(viewModel.themeColor)
                        .font(.system(size: 16, weight: .medium))
                        .padding(8)
                        .background(Circle().fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1)))
                }
                
                Spacer()
                
                Text(timePeriodTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Button(action: { if filterState.analytics.timeOffset < 0 { filterState.analytics.timeOffset += 1 } }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(viewModel.themeColor)
                        .font(.system(size: 16, weight: .medium))
                        .padding(8)
                        .background(Circle().fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1)))
                }
                .disabled(filterState.analytics.timeOffset == 0).opacity(filterState.analytics.timeOffset == 0 ? 0.5 : 1.0)
            }
        }
    }
    
    private var timePeriodTitle: String {
        let (start, end) = filterState.dateRange
        let formatter = DateFormatter()
        
        switch filterState.analytics.timeFilter {
        case .week:
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: start)
        case .yearToDate:
            formatter.dateFormat = "yyyy"
            let year = formatter.string(from: end)
            return "\(year) YTD"
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: start)
        }
    }
}
