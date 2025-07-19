// WorkTracker/Views/AddShiftView.swift

import SwiftUI

struct AddShiftView: View {
    @EnvironmentObject private var viewModel: WorkHoursViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Optional pre-selected values
    var preSelectedJobId: UUID?
    var preSelectedDate: Date?

    // Core shift data
    @State private var selectedJobId: UUID?
    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var breakDuration: Double = 0.5
    @State private var notes = ""
    @State private var isPaid = false
    
    // Payment settings
    @State private var hourlyRateOverride: Double?
    @State private var useCustomRate = false
    
    // Recurring shift settings
    @State private var isRecurring = false
    @State private var recurrenceInterval = RecurrenceInterval.weekly
    @State private var recurrenceEndDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())!
    @State private var hasEndDate = true
    
    // UI state
    @State private var currentStep: ShiftFormStep = .basics
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Break duration settings
    private let breakDurationRange: ClosedRange<Double> = 0.0...2.0
    private let breakDurationStep: Double = 0.25
    
    init(preSelectedJobId: UUID? = nil, preSelectedDate: Date? = nil) {
        self.preSelectedJobId = preSelectedJobId
        self.preSelectedDate = preSelectedDate
        
        let initialDate = preSelectedDate ?? Date()
        _date = State(initialValue: initialDate)
        _startTime = State(initialValue: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: initialDate)!)
        _endTime = State(initialValue: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: initialDate)!)
    }
    
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
        let duration = endTime.timeIntervalSince(startTime)
        let breakInSeconds = breakDuration * 3600
        return (duration - breakInSeconds) / 3600 // Convert to hours
    }
    
    private var shiftEarnings: Double {
        return shiftDuration * effectiveHourlyRate
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
        .alert(isPresented: $showingError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            // Set pre-selected job if provided
            if let jobId = preSelectedJobId {
                selectedJobId = jobId
            }
        }
        .onChange(of: date) { _, newDate in
            synchronizeTimeToDate(newDate)
        }
    }
    
    // MARK: - Form Sections
    
    // Step 1: Basic Information
    private var basicsSection: some View {
        VStack(spacing: 20) {
            // Job selection
            FormCard(title: "Job") {
                if viewModel.jobs.isEmpty {
                    EmptyStateView(message: "No jobs found. Add jobs first in the Settings.", systemImage: "briefcase")
                } else {
                    ForEach(viewModel.jobs.filter(\.isActive)) { job in
                        JobSelectionRow(
                            job: job,
                            isSelected: selectedJobId == job.id,
                            onTap: { selectedJobId = job.id }
                        )
                    }
                }
            }
            
            // Preset Shifts
            if let jobId = selectedJobId, let job = viewModel.jobs.first(where: { $0.id == jobId }), !job.presetShifts.isEmpty {
                FormCard(title: "Preset Shifts") {
                    ForEach(job.presetShifts) { preset in
                        PresetShiftRow(preset: preset) {
                            self.startTime = preset.startTime
                            self.endTime = preset.endTime
                            self.breakDuration = preset.breakDuration
                            synchronizeTimeToDate(self.date)
                        }
                    }
                }
            }
            
            // Date & Time
            FormCard(title: "Date & Time") {
                // Date picker
                VStack(alignment: .leading) {
                    Label("Date", systemImage: "calendar")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .padding(.vertical, 8)
                }
                
                Divider()
                
                // Time selection
                HStack {
                    VStack(alignment: .leading) {
                        Label("Start", systemImage: "clock")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    Spacer()
                    
                    Text("to")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Label("End", systemImage: "clock.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
                .padding(.vertical, 8)
                
                if endTime < startTime {
                    Text("Ends on the next day")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
                
                Divider()
                
                // Break duration slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Break Duration", systemImage: "cup.and.saucer")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(breakDurationText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.themeColor)
                    }
                    .padding(.bottom, 8)
                    
                    HStack {
                        Image(systemName: "tortoise")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Slider(
                            value: $breakDuration,
                            in: breakDurationRange,
                            step: breakDurationStep
                        )
                        .accentColor(viewModel.themeColor)
                        
                        Image(systemName: "hare")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    // Duration tick marks
                    HStack(spacing: 0) {
                        Text("0h")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .leading)
                        
                        Spacer()
                        
                        Text("1h")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("2h")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(width: 30, alignment: .trailing)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                }
                .padding(.vertical, 8)
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
    
    // Break duration formatted text
    private var breakDurationText: String {
        if breakDuration == 0 {
            return "No break"
        } else if breakDuration == 1 {
            return "1 hour"
        } else if breakDuration < 1 {
            return "\(Int(breakDuration * 60)) minutes"
        } else {
            let hours = Int(breakDuration)
            let minutes = Int((breakDuration - Double(hours)) * 60)
            if minutes == 0 {
                return "\(hours) hours"
            } else {
                return "\(hours)h \(minutes)m"
            }
        }
    }
    
    // Step 2: Payment Details
    private var paymentSection: some View {
        VStack(spacing: 20) {
            // Payment Rate
            FormCard(title: "Payment Rate") {
                if let jobId = selectedJobId, let job = viewModel.jobs.first(where: { $0.id == jobId }) {
                    HStack {
                        Text("Default Job Rate")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatCurrency(job.hourlyRate))
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 4)
                }
                
                Toggle("Use Custom Rate", isOn: $useCustomRate)
                    .padding(.vertical, 4)
                
                if useCustomRate {
                    Divider()
                    
                    HStack {
                        Text("Hourly Rate (£)")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        TextField("Rate", value: $hourlyRateOverride, formatter: currencyFormatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Payment Status
            FormCard(title: "Payment Status") {
                Toggle(isOn: $isPaid) {
                    HStack {
                        Text(isPaid ? "Marked as Paid" : "Mark as Paid")
                        
                        Spacer()
                        
                        if isPaid {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            // Recurring Options
            FormCard(title: "Recurring Shift") {
                Toggle("Create Recurring Shift", isOn: $isRecurring)
                    .padding(.vertical, 5)
                
                if isRecurring {
                    Divider()
                    
                    HStack {
                        Text("Repeat Every")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Picker("", selection: $recurrenceInterval) {
                            ForEach(RecurrenceInterval.allCases.filter { $0 != .none }, id: \.self) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.vertical, 5)
                    
                    Toggle("Set End Date", isOn: $hasEndDate)
                        .padding(.vertical, 5)
                    
                    if hasEndDate {
                        DatePicker(
                            "Ends On",
                            selection: $recurrenceEndDate,
                            in: date...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(CompactDatePickerStyle())
                    }
                }
            }
            
            // Earnings summary (updated)
            ShiftSummaryCard(
                duration: shiftDuration,
                hourlyRate: effectiveHourlyRate,
                earnings: shiftEarnings,
                themeColor: viewModel.themeColor
            )
        }
    }
    
    // Step 3: Review
    private var reviewSection: some View {
        VStack(spacing: 20) {
            // Card with all the details for review
            FormCard {
                VStack(alignment: .leading, spacing: 16) {
                    // Job info
                    if let jobId = selectedJobId, let job = viewModel.jobs.first(where: { $0.id == jobId }) {
                        ReviewRow(title: "Job", value: job.name, icon: "briefcase.fill")
                    }
                    
                    // Date & Time
                    ReviewRow(title: "Date", value: formatDate(date), icon: "calendar")
                    ReviewRow(title: "Time", value: "\(formatTime(startTime)) - \(formatTime(endTime))", icon: "clock")
                    ReviewRow(title: "Duration", value: formatDuration(shiftDuration), icon: "hourglass")
                    ReviewRow(title: "Break", value: breakDuration == 0 ? "No break" : formatDuration(breakDuration), icon: "cup.and.saucer")
                    
                    // Payment details
                    if useCustomRate {
                        ReviewRow(
                            title: "Custom Rate",
                            value: formatCurrency(hourlyRateOverride ?? 0),
                            icon: "dollarsign.square"
                        )
                    }
                    
                    ReviewRow(
                        title: "Total Earnings",
                        value: formatCurrency(shiftEarnings),
                        icon: "banknote",
                        valueColor: viewModel.themeColor
                    )
                    
                    // Payment status
                    ReviewRow(
                        title: "Payment Status",
                        value: isPaid ? "Paid" : "Not Paid",
                        icon: isPaid ? "checkmark.seal.fill" : "checkmark.seal",
                        valueColor: isPaid ? .green : .secondary
                    )
                    
                    // Recurring information
                    if isRecurring {
                        Divider().padding(.vertical, 4)
                        
                        Text("Recurring Details")
                            .font(.headline)
                            .padding(.top, 4)
                        
                        ReviewRow(
                            title: "Frequency",
                            value: recurrenceInterval.rawValue,
                            icon: "repeat"
                        )
                        
                        if hasEndDate {
                            ReviewRow(
                                title: "Ends On",
                                value: formatDate(recurrenceEndDate),
                                icon: "calendar.badge.clock"
                            )
                        } else {
                            ReviewRow(
                                title: "End Date",
                                value: "No end date",
                                icon: "infinity"
                            )
                        }
                    }
                }
            }
            
            // Notes section moved here
            FormCard(title: "Notes") {
                TextEditor(text: $notes)
                    .frame(height: 80)
                    .padding(4)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(8)
                    .placeholderOverlay(notes.isEmpty ? "Add any additional details about this shift (optional)" : nil)
            }
            
            // Save Button
            Button(action: saveShift) {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                    Text("Add Shift")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(isFormValid() ? viewModel.themeColor : Color.gray)
                .cornerRadius(15)
                .foregroundColor(.white)
                .shadow(color: (isFormValid() ? viewModel.themeColor : Color.gray).opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .disabled(!isFormValid())
            .padding(.vertical)
        }
    }
    
    // MARK: - Navigation Footer
    
    private var navigationFooter: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 20) {
                // Back button
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
                
                // Progress indicators
                HStack(spacing: 8) {
                    ForEach(ShiftFormStep.allCases, id: \.self) { step in
                        Circle()
                            .fill(step.rawValue <= currentStep.rawValue ? viewModel.themeColor : Color.gray.opacity(0.3))
                            .frame(width: step == currentStep ? 12 : 8, height: step == currentStep ? 12 : 8)
                    }
                }
                
                Spacer()
                
                // Next button
                if currentStep != .review {
                    Button(action: goToNextStep) {
                        Label("Next", systemImage: "chevron.right")
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(canMoveToNextStep() ? viewModel.themeColor : Color.gray.opacity(0.3))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    .disabled(!canMoveToNextStep())
                } else {
                    Button(action: saveShift) {
                        Label("Save", systemImage: "checkmark")
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(isFormValid() ? viewModel.themeColor : Color.gray.opacity(0.3))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    .disabled(!isFormValid())
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
            switch currentStep {
            case .basics:
                currentStep = .payment
            case .payment:
                currentStep = .review
            case .review:
                break // Should never happen
            }
        }
    }
    
    private func goToPreviousStep() {
        withAnimation {
            switch currentStep {
            case .basics:
                break // Should never happen
            case .payment:
                currentStep = .basics
            case .review:
                currentStep = .payment
            }
        }
    }
    
    private func canMoveToNextStep() -> Bool {
        switch currentStep {
        case .basics:
            return selectedJobId != nil && shiftDuration > 0
        case .payment:
            let customRateValid = !useCustomRate || (hourlyRateOverride ?? 0) > 0
            return selectedJobId != nil && customRateValid
        case .review:
            return isFormValid()
        }
    }
    
    private func isFormValid() -> Bool {
        guard let _ = selectedJobId, shiftDuration > 0 else {
            return false
        }
        
        // Validate custom rate if used
        if useCustomRate && (hourlyRateOverride == nil || hourlyRateOverride! <= 0) {
            return false
        }
        
        return true
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
        
        let finalEndTime = endTime < startTime ? Calendar.current.date(byAdding: .day, value: 1, to: endTime)! : endTime
        
        // Create shift
        let newShift = WorkShift(
            jobId: jobId,
            date: date,
            startTime: startTime,
            endTime: finalEndTime,
            breakDuration: breakDuration,
            shiftType: .regular,
            notes: notes,
            isPaid: isPaid,
            hourlyRateOverride: useCustomRate ? hourlyRateOverride : nil,
            isRecurring: isRecurring,
            recurrenceInterval: isRecurring ? recurrenceInterval : .none,
            recurrenceEndDate: isRecurring && hasEndDate ? recurrenceEndDate : nil
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
            case .daily: return DateComponents(day: 1)
            case .weekly: return DateComponents(day: 7)
            case .biweekly: return DateComponents(day: 14)
            case .monthly: return DateComponents(month: 1)
            case .none: return DateComponents()
            }
        }()
        
        // Continue creating shifts until we reach the end date
        while true {
            // Calculate next date based on recurrence
            guard let nextDate = calendar.date(byAdding: dateIncrement, to: currentDate) else { break }
            
            // Stop if next date is beyond recurrence end date (if end date is set)
            if hasEndDate && nextDate > recurrenceEndDate { break }
            
            // Limit to a reasonable number of recurring shifts even if no end date
            if !hasEndDate && shiftsToAdd.count >= 51 { break } // Max 1 year of weekly shifts
            
            // Create the recurring shift
            var newShift = baseShift
            newShift.id = UUID() // New unique ID
            newShift.date = nextDate
            newShift.startTime = newShift.startTime.addingTimeInterval(nextDate.timeIntervalSince(currentDate))
            newShift.endTime = newShift.endTime.addingTimeInterval(nextDate.timeIntervalSince(currentDate))
            newShift.parentShiftId = baseShift.id
            
            shiftsToAdd.append(newShift)
            currentDate = nextDate
        }
        
        // Add all recurring shifts
        viewModel.addShifts(shiftsToAdd)
    }
    
    // MARK: - Helper Methods
    
    private func synchronizeTimeToDate(_ newDate: Date) {
        let calendar = Calendar.current
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: newDate)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        
        if let newStartTime = calendar.date(from: dateComponents) {
            self.startTime = newStartTime
        }
        
        let endTimeComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        var endDateComponents = calendar.dateComponents([.year, .month, .day], from: newDate)
        endDateComponents.hour = endTimeComponents.hour
        endDateComponents.minute = endTimeComponents.minute
        
        if let newEndTime = calendar.date(from: endDateComponents) {
            self.endTime = newEndTime
        }
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

// MARK: - Supporting Views for AddShiftView

struct PresetShiftRow: View {
    let preset: PresetShift
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(preset.name).font(.headline)
                    Text("\(formatTime(preset.startTime)) - \(formatTime(preset.endTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(formatDuration(preset.duration))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    }
}


struct StepIndicator: View {
    var currentStep: ShiftFormStep
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ShiftFormStep.allCases, id: \.self) { step in
                VStack(spacing: 4) {
                    Image(systemName: step.systemImage)
                        .font(.system(size: step.rawValue == currentStep.rawValue ? 24 : 18))
                        .foregroundColor(step.rawValue <= currentStep.rawValue ? .blue : .gray)
                    
                    Text(step.title)
                        .font(.caption)
                        .fontWeight(step.rawValue == currentStep.rawValue ? .semibold : .regular)
                        .foregroundColor(step.rawValue <= currentStep.rawValue ? .blue : .gray)
                }
                .frame(maxWidth: .infinity)
                
                if step != ShiftFormStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, -10)
                }
            }
        }
    }
}

struct FormCard<Content: View>: View {
    var title: String?
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 0) {
                    content()
                }
                .padding()
            }
        }
    }
}

struct ShiftSummaryCard: View {
    let duration: Double
    let hourlyRate: Double
    let earnings: Double
    let themeColor: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(themeColor.opacity(0.1))
                .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        formatDurationView(duration)
                        
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Earnings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    formatEarningsView(earnings, themeColor: themeColor)
                }
            }
            .padding()
        }
    }
    
    private func formatDurationView(_ hours: Double) -> some View {
        let totalMinutes = Int(hours * 60)
        let hoursValue = totalMinutes / 60
        let minutesValue = totalMinutes % 60
        
        return (
            Text("\(hoursValue)")
                .font(.title3)
                .fontWeight(.bold) +
            Text("h ")
                .font(.subheadline) +
            Text("\(minutesValue)")
                .font(.title3)
                .fontWeight(.bold) +
            Text("m")
                .font(.subheadline)
        )
    }
    
    private func formatEarningsView(_ value: Double, themeColor: Color) -> some View {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        let formattedValue = formatter.string(from: NSNumber(value: value)) ?? "£0.00"
        
        return Text(formattedValue)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(themeColor)
    }
}

struct JobSelectionRow: View {
    let job: Job
    let isSelected: Bool
    let onTap: () -> Void
    
    @EnvironmentObject var viewModel: WorkHoursViewModel
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Job icon
                ZStack {
                    Circle()
                        .fill(viewModel.themeColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 18))
                        .foregroundColor(viewModel.themeColor)
                }
                
                // Job name and rate
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.name)
                        .font(.headline)
                    
                    Text("£\(String(format: "%.2f", job.hourlyRate))/hour")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(viewModel.themeColor)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? viewModel.themeColor.opacity(0.1) : Color(.systemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReviewRow: View {
    var title: String
    var value: String
    var icon: String
    var valueColor: Color? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 4)
    }
}

struct EmptyStateView: View {
    var message: String
    var systemImage: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Helper Extensions

extension View {
    func placeholderOverlay(_ text: String?) -> some View {
        ZStack(alignment: .topLeading) {
            self
            
            if let text = text {
                Text(text)
                    .font(.system(.body))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
        }
    }
}
