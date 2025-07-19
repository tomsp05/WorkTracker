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
    
    // UI state
    @State private var currentStep: ShiftFormStep = .basics
    
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
        VStack(spacing: 0) {
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Step indicator
                    StepIndicator(currentStep: currentStep)
                        .padding(.top)
                    
                    // Dynamic content based on current step
                    switch currentStep {
                    case .basics:
                        basicsSection
                    case .payment:
                        paymentSection
                    case .review:
                        reviewSection
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100) // Space for navigation bar
            }
            
            // Navigation area
            navigationFooter
        }
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .navigationTitle(currentStep.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Shift", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteShift()
            }
        } message: {
            Text("Are you sure you want to delete this shift?")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
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
    }
    
    // MARK: - Form Sections
    
    private var basicsSection: some View {
        VStack(spacing: 20) {
            // Job selection
            FormCard(title: "Job") {
                Picker("Select Job", selection: $selectedJobId) {
                    ForEach(viewModel.jobs) { job in
                        Text(job.name).tag(job.id)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedJobId) { _, _ in
                    if !useCustomRate {
                        hourlyRateOverride = nil
                    }
                }
            }
            
            // Date & Time
            FormCard(title: "Date & Time") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Divider()
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                Divider()
                DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    .onChange(of: endTime) { _, newValue in
                        if newValue < startTime {
                            endTime = Calendar.current.date(byAdding: .day, value: 1, to: newValue)!
                        }
                    }
                Divider()
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
            
            // Shift Type
            FormCard(title: "Shift Type") {
                Picker("Shift Type", selection: $shiftType) {
                    ForEach(ShiftType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Summary card
            ShiftSummaryCard(
                duration: shiftDuration,
                hourlyRate: effectiveHourlyRate,
                earnings: shiftEarnings,
                themeColor: viewModel.themeColor
            )
        }
    }
    
    private var paymentSection: some View {
        VStack(spacing: 20) {
            // Payment Rate
            FormCard(title: "Payment Rate") {
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
            }
            
            // Payment Status
            FormCard(title: "Payment Status") {
                Toggle("Marked as Paid", isOn: $isPaid)
            }
        }
    }
    
    private var reviewSection: some View {
        VStack(spacing: 20) {
            // Card with all the details for review
            FormCard {
                VStack(alignment: .leading, spacing: 16) {
                    if let job = viewModel.jobs.first(where: { $0.id == selectedJobId }) {
                        ReviewRow(title: "Job", value: job.name, icon: "briefcase.fill")
                    }
                    ReviewRow(title: "Date", value: formatDate(date), icon: "calendar")
                    ReviewRow(title: "Time", value: "\(formatTime(startTime)) - \(formatTime(endTime))", icon: "clock")
                    ReviewRow(title: "Duration", value: formatDuration(shiftDuration), icon: "hourglass")
                    ReviewRow(title: "Break", value: breakDuration == 0 ? "No break" : formatDuration(breakDuration), icon: "cup.and.saucer")
                    
                    if useCustomRate {
                        ReviewRow(title: "Custom Rate", value: formatCurrency(hourlyRateOverride ?? 0), icon: "dollarsign.square")
                    }
                    
                    ReviewRow(title: "Total Earnings", value: formatCurrency(shiftEarnings), icon: "banknote", valueColor: viewModel.themeColor)
                    ReviewRow(title: "Payment Status", value: isPaid ? "Paid" : "Not Paid", icon: isPaid ? "checkmark.seal.fill" : "checkmark.seal", valueColor: isPaid ? .green : .secondary)
                }
            }
            
            // Notes section
            FormCard(title: "Notes") {
                TextEditor(text: $notes)
                    .frame(height: 80)
                    .padding(4)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                    .placeholderOverlay(notes.isEmpty ? "Add any additional details..." : nil)
            }
            
            // Delete button
            Button(action: { showingDeleteConfirmation = true }) {
                HStack {
                    Spacer()
                    Image(systemName: "trash.fill")
                    Text("Delete Shift")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.8))
                .cornerRadius(15)
                .foregroundColor(.white)
                .shadow(color: .red.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Navigation Footer
    
    private var navigationFooter: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 20) {
                if currentStep != .basics {
                    Button(action: goToPreviousStep) {
                        Label("Back", systemImage: "chevron.left")
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGray5))
                            .cornerRadius(10)
                            .foregroundColor(viewModel.themeColor)
                    }
                } else {
                    Spacer().frame(width: 85)
                }
                
                Spacer()
                
                if currentStep != .review {
                    Button(action: goToNextStep) {
                        Label("Next", systemImage: "chevron.right")
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(viewModel.themeColor)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                } else {
                    Button(action: updateShift) {
                        Label("Save", systemImage: "checkmark")
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(viewModel.themeColor)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Navigation Logic
    
    private func goToNextStep() {
        withAnimation {
            if currentStep.rawValue < ShiftFormStep.allCases.count - 1 {
                currentStep = ShiftFormStep(rawValue: currentStep.rawValue + 1)!
            }
        }
    }
    
    private func goToPreviousStep() {
        withAnimation {
            if currentStep.rawValue > 0 {
                currentStep = ShiftFormStep(rawValue: currentStep.rawValue - 1)!
            }
        }
    }
    
    // MARK: - Actions
    
    private func updateShift() {
        guard shiftDuration > 0 else {
            errorMessage = "Shift duration must be greater than 0"
            showingError = true
            return
        }
        
        if isRecurring {
            showingRecurringUpdateAlert = true
        } else {
            saveShiftChanges(updateOption: .thisOnly)
        }
    }
    
    private func saveShiftChanges(updateOption: RecurringUpdateOption) {
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
