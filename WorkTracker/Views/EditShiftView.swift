//
//  EditShiftView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//

import SwiftUI

struct EditShiftView: View {
    @EnvironmentObject private var viewModel: WorkHoursViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var shift: WorkShift
    
    // Form states
    @State private var selectedJobId: UUID
    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var breakDuration: Double
    @State private var shiftType: ShiftType
    @State private var notes: String
    @State private var isPaid: Bool
    @State private var hourlyRateOverride: Double?
    @State private var useCustomRate: Bool
    
    // Confirm delete alert
    @State private var showingDeleteConfirmation = false
    
    // Show error alert
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Update recurring shifts confirmation
    @State private var showingRecurringUpdateAlert = false
    @State private var updateOption: RecurringUpdateOption = .thisOnly
    
    enum RecurringUpdateOption {
        case thisOnly
        case thisAndFuture
        case all
    }
    
    // Computed properties
    private var effectiveHourlyRate: Double {
        if useCustomRate, let override = hourlyRateOverride {
            return override
        } else if let job = viewModel.jobs.first(where: { $0.id == selectedJobId }) {
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
    
    private var isRecurring: Bool {
        return shift.isRecurring || shift.parentShiftId != nil || viewModel.hasRecurringChildren(shift)
    }
    
    init(shift: WorkShift) {
        self.shift = shift
        
        // Initialize state variables
        self._selectedJobId = State(initialValue: shift.jobId)
        self._date = State(initialValue: shift.date)
        self._startTime = State(initialValue: shift.startTime)
        self._endTime = State(initialValue: shift.endTime)
        self._breakDuration = State(initialValue: shift.breakDuration)
        self._shiftType = State(initialValue: shift.shiftType)
        self._notes = State(initialValue: shift.notes)
        self._isPaid = State(initialValue: shift.isPaid)
        self._hourlyRateOverride = State(initialValue: shift.hourlyRateOverride)
        self._useCustomRate = State(initialValue: shift.hourlyRateOverride != nil)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Job Information")) {
                // Job picker
                Picker("Select Job", selection: $selectedJobId) {
                    ForEach(viewModel.jobs) { job in
                        Text(job.name).tag(job.id)
                    }
                }
                .onChange(of: selectedJobId) { _, _ in
                    // Reset custom rate when job changes
                    if !useCustomRate {
                        hourlyRateOverride = nil
                    }
                }
                
                // Pay rate
                Toggle("Custom Pay Rate", isOn: $useCustomRate)
                    .onChange(of: useCustomRate) { _, newValue in
                        if !newValue {
                            hourlyRateOverride = nil
                        }
                    }
                
                if useCustomRate {
                    HStack {
                        Text("Hourly Rate (£)")
                        Spacer()
                        TextField("Rate", value: $hourlyRateOverride, formatter: currencyFormatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Shift type selection
                Picker("Shift Type", selection: $shiftType) {
                    ForEach(ShiftType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
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
            
            // Optional notes
            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
            
            // Recurring shift note (if applicable)
            if isRecurring {
                Section {
                    Text("This is part of a recurring shift series.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Save and Delete buttons
            Section {
                Button(action: updateShift) {
                    HStack {
                        Spacer()
                        Text("Save Changes")
                            .bold()
                        Spacer()
                    }
                }
                
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Spacer()
                        Text("Delete Shift")
                            .bold()
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Edit Shift")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Shift"),
                message: Text("Are you sure you want to delete this shift?"),
                primaryButton: .destructive(Text("Delete")) {
                    deleteShift()
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Update Recurring Shifts", isPresented: $showingRecurringUpdateAlert) {
            Button("This shift only", role: .cancel) {
                updateOption = .thisOnly
                saveShiftChanges(updateOption: .thisOnly)
            }
            Button("This and future shifts") {
                updateOption = .thisAndFuture
                saveShiftChanges(updateOption: .thisAndFuture)
            }
            Button("All shifts in series") {
                updateOption = .all
                saveShiftChanges(updateOption: .all)
            }
        } message: {
            Text("This shift is part of a recurring series. Which shifts would you like to update?")
        }
        .alert(isPresented: $showingError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Actions
    
    private func updateShift() {
        // Validate input
        guard shiftDuration > 0 else {
            errorMessage = "Shift duration must be greater than 0"
            showingError = true
            return
        }
        
        // Check if shift is part of a recurring series
        if isRecurring {
            showingRecurringUpdateAlert = true
        } else {
            saveShiftChanges(updateOption: .thisOnly)
        }
    }
    
    private func saveShiftChanges(updateOption: RecurringUpdateOption) {
        // Create updated shift with changes
        var updatedShift = shift
        updatedShift.jobId = selectedJobId
        updatedShift.date = date
        updatedShift.startTime = combineDateTime(date: date, time: startTime)
        updatedShift.endTime = combineDateTime(date: endTime < startTime ? Calendar.current.date(byAdding: .day, value: 1, to: date)! : date, time: endTime)
        updatedShift.breakDuration = breakDuration
        updatedShift.shiftType = shiftType
        updatedShift.notes = notes
        updatedShift.isPaid = isPaid
        updatedShift.hourlyRateOverride = useCustomRate ? hourlyRateOverride : nil
        
        // Update shifts based on selected option
        switch updateOption {
        case .thisOnly:
            viewModel.updateShift(updatedShift)
        case .thisAndFuture:
            viewModel.updateShiftAndFuture(updatedShift)
        case .all:
            viewModel.updateAllRecurringShifts(updatedShift)
        }
        
        dismiss()
    }
    
    private func deleteShift() {
        viewModel.deleteShift(shift)
        dismiss()
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
