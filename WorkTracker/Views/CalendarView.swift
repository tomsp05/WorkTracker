//
//  CalendarView.swift
//  WorkTracker
//
//  Created by Tom Speake on 6/26/25.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @State private var selectedDate = Date()
    @State private var selectedDay: Date?
    @State private var showingShiftDetail = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced header with better styling
            CalendarHeaderView(selectedDate: $selectedDate)
                .padding(.horizontal)
                .padding(.top)
            
            // Day of week headers
            DayOfWeekHeaderView()
                .padding(.horizontal)
            
            // Calendar grid
            CalendarGridView(
                selectedDate: $selectedDate,
                selectedDay: $selectedDay,
                onDayTap: { date in
                    selectedDay = date
                    if hasShifts(for: date) {
                        showingShiftDetail = true
                    }
                }
            )
            .padding(.horizontal)
            
            Spacer()
            
            // Selected day info panel
            if let selectedDay = selectedDay {
                SelectedDayInfoView(date: selectedDay)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Shift Calendar")
        .navigationBarTitleDisplayMode(.large)
        .background(
            LinearGradient(
                colors: [viewModel.themeColor.opacity(0.05), viewModel.themeColor.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $showingShiftDetail) {
            if let selectedDay = selectedDay {
                ShiftDetailSheet(date: selectedDay)
                    .environmentObject(viewModel)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedDay)
    }
    
    private func hasShifts(for date: Date) -> Bool {
        !viewModel.shifts.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }.isEmpty
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
        
        // Fill remaining spaces to complete the last week
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
    
    private var totalHours: Double {
        shiftsForDate.reduce(0.0) { $0 + $1.duration }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(dayNumber)")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
                
                // Shift indicators
                HStack(spacing: 2) {
                    if !shiftsForDate.isEmpty {
                        if shiftsForDate.count == 1 {
                            Circle()
                                .fill(viewModel.themeColor)
                                .frame(width: 6, height: 6)
                        } else {
                            ForEach(0..<min(shiftsForDate.count, 3), id: \.self) { _ in
                                Circle()
                                    .fill(viewModel.themeColor)
                                    .frame(width: 4, height: 4)
                            }
                            if shiftsForDate.count > 3 {
                                Text("+")
                                    .font(.caption2)
                                    .foregroundColor(viewModel.themeColor)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
                .frame(height: 8)
                
                // Hours worked indicator
                if totalHours > 0 {
                    Text("\(totalHours, specifier: "%.1f")h")
                        .font(.caption2)
                        .foregroundColor(viewModel.themeColor)
                        .fontWeight(.medium)
                }
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
        } else if !shiftsForDate.isEmpty {
            return viewModel.themeColor.opacity(0.05)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        isSelected ? viewModel.themeColor : Color.clear
    }
}

struct SelectedDayInfoView: View {
    let date: Date
    @EnvironmentObject var viewModel: WorkHoursViewModel
    
    private var shiftsForDate: [WorkShift] {
        viewModel.shifts.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    private var totalHours: Double {
        shiftsForDate.reduce(0.0) { $0 + $1.duration }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(date, formatter: selectedDayFormatter)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !shiftsForDate.isEmpty {
                    Text("\(totalHours, specifier: "%.1f") hours")
                        .font(.subheadline)
                        .foregroundColor(viewModel.themeColor)
                        .fontWeight(.medium)
                }
            }
            
            if shiftsForDate.isEmpty {
                Text("No shifts scheduled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(shiftsForDate.prefix(3), id: \.id) { shift in
                        HStack {
                            Circle()
                                .fill(viewModel.themeColor)
                                .frame(width: 6, height: 6)
                            
                            Text("\(shift.startTime, formatter: timeFormatter) - \(shift.endTime, formatter: timeFormatter)")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(shift.duration, specifier: "%.1f")h")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if shiftsForDate.count > 3 {
                        Text("+ \(shiftsForDate.count - 3) more shifts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 12)
                    }
                }
            }
        }
    }
}

struct ShiftDetailSheet: View {
    let date: Date
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.dismiss) private var dismiss
    
    private var shiftsForDate: [WorkShift] {
        viewModel.shifts.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(shiftsForDate, id: \.id) { shift in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(shift.startTime, formatter: timeFormatter) - \(shift.endTime, formatter: timeFormatter)")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(shift.duration, specifier: "%.1f")h")
                                    .font(.subheadline)
                                    .foregroundColor(viewModel.themeColor)
                                    .fontWeight(.medium)
                            }
                            
                            if !shift.notes.isEmpty {
                                Text(shift.notes)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text(date, formatter: selectedDayFormatter)
                }
            }
            .navigationTitle("Shift Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Custom button style for scale effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Date formatters
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

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter
}()
