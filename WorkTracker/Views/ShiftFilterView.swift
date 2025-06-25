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

    var body: some View {
        NavigationView {
            Form {
                // Time Filter Section
                Section(header: Text("Date Range")) {
                    Picker("Time Frame", selection: $filterState.timeFilter) {
                        ForEach(ShiftTimeFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    if filterState.timeFilter == .custom {
                        DatePicker("Start Date", selection: Binding(get: { filterState.customStartDate ?? Date() }, set: { filterState.customStartDate = $0 }), displayedComponents: .date)
                        DatePicker("End Date", selection: Binding(get: { filterState.customEndDate ?? Date() }, set: { filterState.customEndDate = $0 }), displayedComponents: .date)
                    }
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
}