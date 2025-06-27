// WorkTracker/Views/CalendarView.swift

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @State private var selectedDate = Date()
    @State private var selectedDay: Date?
    @State private var showingShiftDetail = false
    @State private var showFilterSheet = false
    @State private var filterState = ShiftFilterState()

    private var calendarHasActiveFilters: Bool {
        !filterState.selectedJobIds.isEmpty ||
        filterState.minEarnings != nil ||
        filterState.maxEarnings != nil ||
        !filterState.shiftTypes.isEmpty ||
        filterState.isPaid != nil
    }

    private var monthlyGroupedShifts: [(date: Date, shifts: [WorkShift])] {
        let monthShifts = viewModel.shifts.filter { shift in
            let isInMonth = Calendar.current.isDate(shift.date, equalTo: selectedDate, toGranularity: .month)
            if !isInMonth { return false }

            if !filterState.selectedJobIds.isEmpty && !filterState.selectedJobIds.contains(shift.jobId) {
                return false
            }

            if !filterState.shiftTypes.isEmpty && !filterState.shiftTypes.contains(shift.shiftType) {
                return false
            }

            if let isPaid = filterState.isPaid, shift.isPaid != isPaid {
                return false
            }

            return true
        }
        
        let calendar = Calendar.current
        let groups = Dictionary(grouping: monthShifts) { shift in
            calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: shift.date))!
        }
        
        let sortedGroups = groups.sorted { $0.key > $1.key }
        return sortedGroups.map { (date: $0.key, shifts: $0.value.sorted { $0.date > $1.date }) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CalendarHeaderView(selectedDate: $selectedDate)
                    .padding(.horizontal)
                    .padding(.top)
                
                DayOfWeekHeaderView()
                    .padding(.horizontal)
                
                CalendarGridView(
                    selectedDate: $selectedDate,
                    selectedDay: $selectedDay,
                    onDayTap: { date in
                        selectedDay = date
                        showingShiftDetail = true
                    }
                )
                .padding(.horizontal)

                if calendarHasActiveFilters {
                    activeFiltersView
                }

                if !monthlyGroupedShifts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        ForEach(monthlyGroupedShifts, id: \.date) { group in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formattedWeek(group.date))
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                Divider()
                                    .padding(.horizontal)
                                
                                ForEach(group.shifts) { shift in
                                    NavigationLink(destination: EditShiftView(shift: shift)) {
                                        ShiftCardView(shift: shift)
                                            .environmentObject(viewModel)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .navigationTitle("Shift Calendar")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showFilterSheet = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            CalendarFilterView(filterState: $filterState)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingShiftDetail) {
            if let selectedDay = selectedDay {
                ShiftDetailSheet(date: selectedDay)
                    .environmentObject(viewModel)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedDay)
    }

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
        }
    }
    
    private func formattedWeek(_ weekStartDate: Date) -> String {
        let calendar = Calendar.current
        let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate)!
        
        let startFormatter = DateFormatter()
        let endFormatter = DateFormatter()
        
        if calendar.isDate(weekStartDate, equalTo: weekEndDate, toGranularity: .month) {
            startFormatter.dateFormat = "d"
        } else {
            startFormatter.dateFormat = "d MMM"
        }
        endFormatter.dateFormat = "d MMM"
        
        return "Week of \(startFormatter.string(from: weekStartDate)) - \(endFormatter.string(from: weekEndDate))"
    }
}

struct CalendarFilterView: View {
    @Binding var filterState: ShiftFilterState
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
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

struct CalendarHeaderView: View {
    @Binding var selectedDate: Date
    @EnvironmentObject var viewModel: WorkHoursViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.themeColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(viewModel.themeColor.opacity(0.1))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(selectedDate, formatter: monthFormatter)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(selectedDate, formatter: yearFormatter)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.themeColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(viewModel.themeColor.opacity(0.1))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.vertical)
    }
}

struct DayOfWeekHeaderView: View {
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        HStack {
            ForEach(dayNames, id: \.self) { dayName in
                Text(dayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }
}

struct CalendarGridView: View {
    @Binding var selectedDate: Date
    @Binding var selectedDay: Date?
    let onDayTap: (Date) -> Void
    @EnvironmentObject var viewModel: WorkHoursViewModel
    
    private var days: [Date?] {
        let range = Calendar.current.range(of: .day, in: .month, for: selectedDate)!
        let monthFirstDay = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: selectedDate))!
        let startDayOfWeek = Calendar.current.component(.weekday, from: monthFirstDay)
        
        var days = [Date?](repeating: nil, count: startDayOfWeek - 1)
        days += (1...range.count).map { day in
            Calendar.current.date(byAdding: .day, value: day - 1, to: monthFirstDay)
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<days.count, id: \.self) { index in
                if let date = days[index] {
                    CalendarDayView(
                        date: date,
                        isSelected: selectedDay != nil && Calendar.current.isDate(date, inSameDayAs: selectedDay!),
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDay = date
                            }
                            onDayTap(date)
                        }
                    )
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 50)
                }
            }
        }
        .padding(.vertical)
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let onTap: () -> Void
    @EnvironmentObject var viewModel: WorkHoursViewModel
    
    private var shiftsForDate: [WorkShift] {
        viewModel.shifts.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(dayNumber)")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
                
                HStack(spacing: 3) {
                    if !shiftsForDate.isEmpty {
                        ForEach(shiftsForDate.prefix(3), id: \.id) { shift in
                            Circle()
                                .fill(getJobColor(for: shift.jobId))
                                .frame(width: 6, height: 6)
                        }
                        if shiftsForDate.count > 3 {
                            Image(systemName: "plus")
                                .font(.caption2)
                                .foregroundColor(viewModel.themeColor)
                        }
                    }
                }
                .frame(height: 8)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private func getJobColor(for jobId: UUID) -> Color {
        if let job = viewModel.jobs.first(where: { $0.id == jobId }) {
            switch job.color {
            case "Blue": return Color(red: 0.20, green: 0.40, blue: 0.70)
            case "Green": return Color(red: 0.20, green: 0.55, blue: 0.30)
            case "Orange": return Color(red: 0.80, green: 0.40, blue: 0.20)
            case "Purple": return Color(red: 0.50, green: 0.25, blue: 0.70)
            case "Red": return Color(red: 0.70, green: 0.20, blue: 0.20)
            case "Teal": return Color(red: 0.20, green: 0.50, blue: 0.60)
            default: return .gray
            }
        }
        return .gray
    }
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var textColor: Color {
        if isToday {
            return .white
        } else if isSelected {
            return viewModel.themeColor
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return viewModel.themeColor
        } else if isSelected {
            return viewModel.themeColor.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        isSelected ? viewModel.themeColor : Color.clear
    }
}

struct ShiftDetailSheet: View {
    let date: Date
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.dismiss) private var dismiss
    
    private var shiftsForDate: [WorkShift] {
        viewModel.shifts
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.startTime < $1.startTime }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if shiftsForDate.isEmpty {
                    emptyStateView
                } else {
                    shiftListView
                }
            }
            .navigationTitle(selectedDayFormatter.string(from: date))
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !shiftsForDate.isEmpty {
                        NavigationLink(destination: AddShiftView(preSelectedDate: date)) {
                            Image(systemName: "plus")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var shiftListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(shiftsForDate) { shift in
                    NavigationLink(destination: EditShiftView(shift: shift)) {
                        ShiftCardView(shift: shift)
                            .environmentObject(viewModel)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(viewModel.themeColor.opacity(0.6))
            
            Text("No Shifts Scheduled")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Tap the button below to add a new shift for this day.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            NavigationLink(destination: AddShiftView(preSelectedDate: date)) {
                Text("Add Shift")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.themeColor)
                    .cornerRadius(15)
                    .shadow(color: viewModel.themeColor.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Helper Components

// Custom button style for scale effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Date formatters used across the Calendar views
private let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM"
    return formatter
}()

private let yearFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy"
    return formatter
}()

private let selectedDayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d"
    return formatter
}()
