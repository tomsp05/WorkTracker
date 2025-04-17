//
//  AddShiftView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//

import SwiftUI

struct AddShiftView: View {
    @EnvironmentObject private var viewModel: WorkHoursViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Optional pre-selected job ID
    var preSelectedJobId: UUID? = nil
    
    // Form states
    @State private var selectedJobId: UUID? = nil
    @State private var date = Date()
    @State private var startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
    @State private var endTime = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())!
    @State private var breakDuration: Double = 0.5
    @State private var shiftType = ShiftType.regular
    @State private var notes = ""
    @State private var isPaid = false
    @State private var hourlyRateOverride: Double? = nil
    @State private var useCustomRate = false
    
    // Recurring shift settings
    @State private var isRecurring = false
    @State private var recurrenceInterval = RecurrenceInterval.weekly
    @State private var recurrenceEndDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())!
    
    // Error state
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Computed properties
    private var effectiveHourlyRate: Double {
        if useCustomRate, let override = hourlyRateOverride {
            return override
        } else if let jobId = selectedJobId, let job = viewModel.jobs.first(where: { $0.id == jobId }) {
            return job.hourlyRate
        }
        return 0.0
    }
    
    private var shiftDuration: Double {
        let totalMinutes = endTime.timeIntervalSince(startTime) / 60
        let breakMinutes = breakDuration * 60
        return (totalMinutes - breakMinutes) / 60 // Convert to hours
    }
    
    private var shiftEarnings: Double {
        let multiplier: Double = {
            switch shiftType {
            case .regular: return 1.0
            case .overtime: return 1.5
            case .holiday: return 2.0
            }
        }()
        return shiftDuration * effectiveHourlyRate * multiplier
    }
    
    var body: some View {
        Form {
            Section(header: Text("Job Information")) {
                // Job picker
                Picker("Select Job", selection: $selectedJobId) {
                    Text("Select a job")
                        .foregroundColor(.secondary)
                        .tag(nil as UUID?)
                    
                    ForEach(viewModel.jobs.filter(\.isActive)) { job in
                        Text(job.name).tag(job.id as UUID?)
                    }
                }
                .onChange(of: selectedJobId) { _, _ in
                    // Reset custom rate when job changes
                    if !useCustomRate {
                        hourlyRateOverride = nil
                    }
                }
                
                // Pay rate
                if selectedJobId != nil {
                    Toggle("Custom Pay Rate", isOn: $useCustomRate)
                    
                    if useCustomRate {
                        HStack {
                            Text("Hourly Rate (£)")
                            Spacer()
                            TextField("Rate", value: $hourlyRateOverride, formatter: currencyFormatter)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    // Shift type selection (regular, overtime, holiday)
                    Picker("Shift Type", selection: $shiftType) {
                        ForEach(ShiftType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                }
            }
            
            Section(header: Text("Date and Time")) {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    .onChange(of: endTime) { _, newValue in
                        if newValue < startTime {
                            // If end time is earlier than start time, assume it's the next day
                            endTime = Calendar.current.date(byAdding: .day, value: 1, to: newValue)!
                        }
                    }
                
                // Break duration in hours
                HStack {
                    Text("Break")
                    Spacer()
                    Picker("Break Duration", selection: $breakDuration) {
                        Text("No break").tag(0.0)
                        Text("15 min").tag(0.25)
                        Text("30 min").tag(0.5)
                        Text("45 min").tag(0.75)
                        Text("1 hour").tag(1.0)
                        Text("1.5 hours").tag(1.5)
                        Text("2 hours").tag(2.0)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            // Summary of hours and earnings
            if selectedJobId != nil {
                Section(header: Text("Summary")) {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(formatDuration(shiftDuration))
                            .bold()
                    }
                    
                    HStack {
                        Text("Earnings")
                        Spacer()
                        Text(formatCurrency(shiftEarnings))
                            .bold()
                    }
                    
                    Toggle("Marked as Paid", isOn: $isPaid)
                }
            }
            
            // Optional notes
            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
            
            // Recurring shift settings
            Section(header: Text("Recurrence")) {
                Toggle("Recurring Shift", isOn: $isRecurring)
                
                if isRecurring {
                    Picker("Repeat", selection: $recurrenceInterval) {
                        ForEach(RecurrenceInterval.allCases.filter { $0 != .none }, id: \.self) { interval in
                            Text(interval.rawValue).tag(interval)
                        }
                    }
                    
                    DatePicker("Until", selection: $recurrenceEndDate, displayedComponents: .date)
                }
            }
            
            // Save button
            Section {
                Button(action: saveShift) {
                    HStack {
                        Spacer()
                        Text("Save Shift")
                            .bold()
                        Spacer()
                    }
                }
                .disabled(selectedJobId == nil)
            }
        }
        .alert(isPresented: $showingError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .onAppear {
            // Set pre-selected job if provided
            if let jobId = preSelectedJobId {
                selectedJobId = jobId
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveShift() {
        // Validate input
        guard let jobId = selectedJobId else {
            errorMessage = "Please select a job"
            showingError = true
            return
        }
        
        guard shiftDuration > 0 else {
            errorMessage = "Shift duration must be greater than 0"
            showingError = true
            return
        }
        
        // Create initial shift
        let newShift = WorkShift(
            jobId: jobId,
            date: date,
            startTime: combineDateTime(date: date, time: startTime),
            endTime: combineDateTime(date: endTime < startTime ? Calendar.current.date(byAdding: .day, value: 1, to: date)! : date, time: endTime),
            breakDuration: breakDuration,
            shiftType: shiftType,
            notes: notes,
            isPaid: isPaid,
            hourlyRateOverride: useCustomRate ? hourlyRateOverride : nil,
            isRecurring: isRecurring,
            recurrenceInterval: isRecurring ? recurrenceInterval : .none,
            recurrenceEndDate: isRecurring ? recurrenceEndDate : nil
        )
        
        // Add the shift(s)
        if isRecurring {
            createRecurringShifts(baseShift: newShift)
        } else {
            viewModel.addShift(newShift)
        }
        
        // Dismiss the view
        dismiss()
    }
    
    private func createRecurringShifts(baseShift: WorkShift) {
        // Add the base shift
        viewModel.addShift(baseShift)
        
        // Create recurring shifts
        var shiftsToAdd: [WorkShift] = []
        
        var currentDate = baseShift.date
        let calendar = Calendar.current
        
        // Logic for different recurrence intervals
        let dateIncrement: DateComponents = {
            switch recurrenceInterval {
            case .daily:
                return DateComponents(day: 1)
            case .weekly:
                return DateComponents(day: 7)
            case .biweekly:
                return DateComponents(day: 14)
            case .monthly:
                return DateComponents(month: 1)
            case .none:
                return DateComponents()
            }
        }()
        
        // Continue creating shifts until we reach the end date
        while true {
            // Calculate next date based on recurrence
            guard let nextDate = calendar.date(byAdding: dateIncrement, to: currentDate) else { break }
            
            // Stop if next date is beyond recurrence end date
            if nextDate > recurrenceEndDate { break }
            
            // Calculate time difference between dates
            let timeDifference = nextDate.timeIntervalSince(currentDate)
            
            // Create the recurring shift
            var newShift = baseShift
            newShift.id = UUID() // New unique ID
            newShift.date = nextDate
            newShift.startTime = baseShift.startTime.addingTimeInterval(timeDifference)
            newShift.endTime = baseShift.endTime.addingTimeInterval(timeDifference)
            newShift.parentShiftId = baseShift.id
            
            shiftsToAdd.append(newShift)
            currentDate = nextDate
        }
        
        // Add all recurring shifts
        viewModel.addShifts(shiftsToAdd)
    }
    
    // MARK: - Helper Methods
    
    private func combineDateTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        return calendar.date(from: combinedComponents)!
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
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
    
    private func formatDuration(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    }
}
