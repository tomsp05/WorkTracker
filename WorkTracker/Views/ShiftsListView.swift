import SwiftUI

struct ShiftsListView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @State private var showFilterSheet = false
    @Environment(\.colorScheme) var colorScheme

    // Filter state
    @State private var filterState: ShiftFilterState

    // New initializer to accept a pre-configured filter state
    init(initialFilterState: ShiftFilterState? = nil) {
        _filterState = State(initialValue: initialFilterState ?? ShiftFilterState())
    }

    // Group shifts by week and sort by date (most recent first)
    private var groupedShifts: [(date: Date, shifts: [WorkShift])] {
        // Apply all filters
        let filteredShifts = viewModel.shifts.filter { shift in
            // Apply time filter
            let (startDate, endDate) = filterState.dateRange
            let passesTimeFilter = shift.date >= startDate && shift.date <= endDate

            // Apply job filter
            let passesJobFilter = filterState.selectedJobIds.isEmpty || filterState.selectedJobIds.contains(shift.jobId)
            
            // Apply shift type filter
            let passesShiftTypeFilter = filterState.shiftTypes.isEmpty || filterState.shiftTypes.contains(shift.shiftType)

            // Apply paid status filter
            let passesPaidStatusFilter: Bool
            if let isPaid = filterState.isPaid {
                passesPaidStatusFilter = shift.isPaid == isPaid
            } else {
                passesPaidStatusFilter = true
            }


            return passesTimeFilter && passesJobFilter && passesShiftTypeFilter && passesPaidStatusFilter
        }

        // Group by the start of the week for each shift date.
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredShifts) { shift in
            calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: shift.date))!
        }
        // Sort the groups by key (date) descending.
        let sortedGroups = groups.sorted { $0.key > $1.key }
        // Sort shifts within each group by date descending.
        return sortedGroups.map { (date: $0.key, shifts: $0.value.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Active filters display
            if filterState.hasActiveFilters {
                activeFiltersView
            }

            // Shifts list
            shiftsList
        }
        .navigationTitle("Shifts")
        .navigationBarItems(trailing: filterButton)
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .sheet(isPresented: $showFilterSheet) {
            NavigationView {
                ShiftFilterView(filterState: $filterState)
            }
        }
    }

    // Filter button for navigation bar
    private var filterButton: some View {
        Button(action: {
            showFilterSheet = true
        }) {
            HStack(spacing: 5) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text(filterState.hasActiveFilters ? "\(activeFilterCount)" : "")
            }
        }
    }

    // Active filters display
    private var activeFiltersView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Active Filters")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    filterState = ShiftFilterState()
                }) {
                    Text("Clear All")
                        .font(.subheadline)
                        .foregroundColor(viewModel.themeColor)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if filterState.hasActiveFilters {
                        filterTag(
                            icon: "calendar",
                            text: filterState.analytics.timeFilter.rawValue,
                            color: viewModel.themeColor
                        )
                    }

                    if !filterState.selectedJobIds.isEmpty {
                        filterTag(
                            icon: "briefcase",
                            text: "\(filterState.selectedJobIds.count) Jobs",
                            color: .blue
                        )
                    }

                    if !filterState.shiftTypes.isEmpty {
                        let typeText = filterState.shiftTypes.count == 1 ?
                            filterState.shiftTypes.first!.rawValue.capitalized :
                            "\(filterState.shiftTypes.count) Types"
                        
                        filterTag(
                            icon: "tag",
                            text: typeText,
                            color: .orange
                        )
                    }

                    if let isPaid = filterState.isPaid {
                        filterTag(
                            icon: isPaid ? "checkmark.circle.fill" : "xmark.circle.fill",
                            text: isPaid ? "Paid" : "Unpaid",
                            color: isPaid ? .green : .red
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }

            Divider()
        }
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
    }

    // Filter tag component
    private func filterTag(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(colorScheme == .dark ? 0.25 : 0.15))
        )
        .foregroundColor(color)
    }

    // Helper to count active filters
    private var activeFilterCount: Int {
        var count = 0
        if filterState.analytics.timeFilter != .month || filterState.analytics.timeOffset != 0 { count += 1 }
        if !filterState.selectedJobIds.isEmpty { count += 1 }
        if !filterState.shiftTypes.isEmpty { count += 1 }
        if filterState.isPaid != nil { count += 1 }
        return count
    }

    // Shifts list view
    private var shiftsList: some View {
        ScrollView {
            if groupedShifts.isEmpty {
                noShiftsView
            } else {
                LazyVStack(spacing: 12) {
                    // Iterate over grouped shifts
                    ForEach(groupedShifts, id: \.date) { group in
                        VStack(alignment: .leading, spacing: 4) {
                            // Date header for the group
                            Text(formattedWeek(group.date))
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)

                            Divider()

                            // List out each shift for this day.
                            ForEach(group.shifts) { shift in
                                NavigationLink(destination: EditShiftView(shift: shift)) {
                                    ShiftCardView(shift: shift)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }.padding(.vertical, 2)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding()
            }
        }
    }

    // No shifts view
    private var noShiftsView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 56))
                .foregroundColor(viewModel.themeColor.opacity(0.5))

            Text("No shifts match your filters")
                .font(.headline)
                .foregroundColor(.primary)

            if filterState.hasActiveFilters {
                Button(action: {
                    filterState = ShiftFilterState()
                }) {
                    Text("Clear all filters")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(viewModel.themeColor)
                        .cornerRadius(10)
                        .shadow(color: colorScheme == .dark ? Color.clear : viewModel.themeColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Helper to format the grouped date header.
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
}

struct ShiftsListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ShiftsListView().environmentObject(WorkHoursViewModel())
        }
    }
}
