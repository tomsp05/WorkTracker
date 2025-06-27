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
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(dayNumber)")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
                
                // Shift indicators with job colors
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
        } else if !shiftsForDate.isEmpty {
            return Color.clear
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
    
    private var formattedDate: String {
        selectedDayFormatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if shiftsForDate.isEmpty {
                        Text("No shifts for this day.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(shiftsForDate) { shift in
                            ShiftCardView(shift: shift)
                                .environmentObject(viewModel)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
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

