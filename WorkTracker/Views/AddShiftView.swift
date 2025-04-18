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
    @State private var hasEndDate = true
    
    // Error state
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // UI state
    @State private var currentStep: FormStep = .timing
    
    // Form steps enum
    enum FormStep {
        case timing, payment, review
        
        var title: String {
            switch self {
            case .timing: return "Timing"
            case .payment: return "Payment Details"
            case .review: return "Review"
            }
        }
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
        VStack(spacing: 0) {
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Dynamic content based on current step
                    switch currentStep {
                    case .timing:
                        timingSection
                    case .payment:
                        paymentSection
                    case .review:
                        reviewSection
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            
            // Bottom navigation area with progress bar and buttons
            bottomNavArea
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
    }
    
    // MARK: - Form Sections
    
    // Step 1: Timing
    private var timingSection: some View {
        VStack(spacing: 20) {
            // Date picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Date")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                    
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding()
                }
                .padding(.vertical, 4)
            }
            
            // Time picker section
            VStack(alignment: .leading, spacing: 10) {
                Text("Shift Times")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // Start time
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                    
                    HStack {
                        Text("Start Time")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    .padding()
                }
                .frame(height: 60)
                
                // End time
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                    
                    HStack {
                        Text("End Time")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .onChange(of: endTime) { _, newValue in
                                if newValue < startTime {
                                    // If end time is earlier than start time, assume it's the next day
                                    endTime = Calendar.current.date(byAdding: .day, value: 1, to: newValue)!
                                }
                            }
                    }
                    .padding()
                }
                .frame(height: 60)
                
                // Break duration
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                    
                    HStack {
                        Text("Break Duration")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Picker("", selection: $breakDuration) {
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
                    .padding()
                }
                .frame(height: 60)
            }
            
            // Summary for this step
            VStack(alignment: .leading, spacing: 8) {
                Text("Shift Duration")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Hours")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(formatDuration(shiftDuration))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(viewModel.themeColor)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "clock.fill")
                            .font(.system(size: 24))
                            .foregroundColor(viewModel.themeColor)
                    }
                    .padding()
                }
            }
            
            // Recurring toggle
            VStack(alignment: .leading, spacing: 10) {
                Text("Recurring")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Recurring Shift", isOn: $isRecurring)
                            .padding(.vertical, 5)
                        
                        if isRecurring {
                            Divider()
                            
                            HStack {
                                Text("Repeat")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $recurrenceInterval) {
                                    ForEach(RecurrenceInterval.allCases.filter { $0 != .none }, id: \.self) { interval in
                                        Text(interval.rawValue).tag(interval)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            .padding(.vertical, 5)
                            
                            Toggle("End Date", isOn: $hasEndDate)
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
                    .padding()
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // Step 2: Payment (now including all job info and shift type)
    private var paymentSection: some View {
        VStack(spacing: 20) {
            // Job selection
            VStack(alignment: .leading, spacing: 10) {
                Text("Select Job")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                if viewModel.jobs.isEmpty {
                    emptyStateView(message: "No jobs found. Add jobs in Settings.")
                } else {
                    ForEach(viewModel.jobs.filter(\.isActive)) { job in
                        JobSelectionRow(
                            job: job,
                            isSelected: selectedJobId == job.id,
                            onTap: {
                                selectedJobId = job.id
                                // Reset custom rate when job changes
                                if !useCustomRate {
                                    hourlyRateOverride = nil
                                }
                            }
                        )
                    }
                }
            }
            
            // MOVED FROM BASIC INFO: Shift type selection
            VStack(alignment: .leading, spacing: 10) {
                Text("Shift Type")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ForEach(ShiftType.allCases, id: \.self) { type in
                        TypeButton(
                            title: type.rawValue.capitalized,
                            isSelected: shiftType == type,
                            action: { shiftType = type }
                        )
                    }
                }
            }
            
            // Custom rate toggle
            VStack(alignment: .leading, spacing: 10) {
                Text("Payment Rate")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let jobId = selectedJobId, let job = viewModel.jobs.first(where: { $0.id == jobId }) {
                            HStack {
                                Text("Default Job Rate")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(formatCurrency(job.hourlyRate))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 5)
                        }
                        
                        Toggle("Use Custom Rate", isOn: $useCustomRate)
                            .padding(.vertical, 5)
                        
                        if useCustomRate {
                            Divider()
                            
                            HStack {
                                Text("Hourly Rate (£)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                TextField("Rate", value: $hourlyRateOverride, formatter: currencyFormatter)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding()
                }
                .padding(.vertical, 4)
            }
            
            // Shift payment multiplier info
            VStack(alignment: .leading, spacing: 10) {
                Text("Payment Multiplier")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(shiftType.rawValue.capitalized) Shift")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(getMultiplierText(for: shiftType))
                                .font(.subheadline)
                                .foregroundColor(viewModel.themeColor)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 5)
                        
                        Divider()
                        
                        HStack {
                            Text("Hourly Rate")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(formatCurrency(effectiveHourlyRate))
                                .font(.subheadline)
                        }
                        .padding(.vertical, 5)
                    }
                    .padding()
                }
                .padding(.vertical, 4)
            }
            
            // Earnings summary
            VStack(alignment: .leading, spacing: 10) {
                Text("Earnings Summary")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(viewModel.themeColor.opacity(0.1))
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                    
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Earnings")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(formatCurrency(shiftEarnings))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(viewModel.themeColor)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Hours")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(formatDuration(shiftDuration))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        // Calculate hourly earnings
                        HStack {
                            Text("Average Hourly Earnings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(formatCurrency(shiftDuration > 0 ? shiftEarnings / shiftDuration : 0))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                .padding(.vertical, 4)
            }
            
            // Payment status
            VStack(alignment: .leading, spacing: 10) {
                Text("Payment Status")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                    
                    HStack {
                        Toggle("Mark as Paid", isOn: $isPaid)
                        
                        Spacer()
                        
                        Image(systemName: isPaid ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isPaid ? .green : .secondary)
                    }
                    .padding()
                }
                .frame(height: 60)
            }
            
            // MOVED FROM BASIC INFO: Notes field
            VStack(alignment: .leading, spacing: 10) {
                Text("Notes (Optional)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                    
                    TextEditor(text: $notes)
                        .padding(8)
                        .frame(minHeight: 100)
                }
                .frame(height: 100)
            }
        }
    }
    
    // Step 3: Review
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Review Shift")
                .font(.title2)
                .fontWeight(.bold)
            
            // Card container with shift summary
            VStack(alignment: .leading, spacing: 16) {
                if let jobId = selectedJobId, let job = viewModel.jobs.first(where: { $0.id == jobId }) {
                    HStack {
                        Text("Job")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(job.name)
                            .fontWeight(.medium)
                    }
                    
                    Divider()
                }
                
                HStack {
                    Text("Date")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDate(date))
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Text("Time")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(formatTime(startTime)) - \(formatTime(endTime))")
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Text("Duration")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDuration(shiftDuration))
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Text("Break")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(breakDuration == 0 ? "No break" : formatDuration(breakDuration))
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Text("Shift Type")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(shiftType.rawValue.capitalized)
                        .fontWeight(.medium)
                }
                
                if useCustomRate {
                    Divider()
                    
                    HStack {
                        Text("Custom Rate")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatCurrency(hourlyRateOverride ?? 0))
                            .fontWeight(.medium)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Total Earnings")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatCurrency(shiftEarnings))
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.themeColor)
                }
                
                Divider()
                
                HStack {
                    Text("Payment Status")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(isPaid ? "Paid" : "Not Paid")
                        .fontWeight(.medium)
                        .foregroundColor(isPaid ? .green : .secondary)
                }
                
                if isRecurring {
                    Divider()
                    
                    HStack {
                        Text("Recurring")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(recurrenceInterval.rawValue)")
                            .fontWeight(.medium)
                    }
                    
                    if hasEndDate {
                        HStack {
                            Text("Ends on")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatDate(recurrenceEndDate))
                                .fontWeight(.medium)
                        }
                    }
                }
                
                if !notes.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .foregroundColor(.secondary)
                        
                        Text(notes)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
            
            // Add Shift Button
            Button(action: saveShift) {
                HStack {
                    Spacer()
                    Text("Add Shift")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(isFormValid() ? viewModel.themeColor : Color.gray)
                .cornerRadius(15)
                .shadow(color: (isFormValid() ? viewModel.themeColor : Color.gray).opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .disabled(!isFormValid())
            .padding(.top, 20)
        }
    }
    
    // Bottom navigation area with progress bar and buttons
    private var bottomNavArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            // Updated progress bar and navigation buttons
            HStack(spacing: 16) {
                // Back button
                if currentStep != .timing {
                    Button(action: goToPreviousStep) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(10)
                        .foregroundColor(viewModel.themeColor)
                    }
                } else {
                    // Placeholder for alignment
                    Spacer()
                        .frame(width: 85)
                }
                
                // Progress bar
                ProgressBar(currentStep: currentStep)
                    .frame(maxWidth: .infinity)
                
                // Next/Done button
                if currentStep != .review {
                    Button(action: goToNextStep) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(canMoveToNextStep() ? viewModel.themeColor.opacity(0.9) : Color.gray.opacity(0.3))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    }
                    .disabled(!canMoveToNextStep())
                } else {
                    // Button to add shift
                    Button(action: saveShift) {
                        HStack {
                            Text("Save")
                            Image(systemName: "checkmark")
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(isFormValid() ? viewModel.themeColor.opacity(0.9) : Color.gray.opacity(0.3))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    }
                    .disabled(!isFormValid())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        }
    }
    
    // MARK: - Helper Views
    
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Navigation Logic
    
    private func goToNextStep() {
        withAnimation {
            switch currentStep {
            case .timing:
                currentStep = .payment
            case .payment:
                currentStep = .review
            case .review:
                // Should never happen
                break
            }
        }
    }
    
    private func goToPreviousStep() {
        withAnimation {
            switch currentStep {
            case .timing:
                // Should never happen
                break
            case .payment:
                currentStep = .timing
            case .review:
                currentStep = .payment
            }
        }
    }
    
    private func canMoveToNextStep() -> Bool {
        switch currentStep {
        case .timing:
            return shiftDuration > 0
        case .payment:
            return selectedJobId != nil
        case .review:
            return isFormValid()
        }
    }
    
    private func isFormValid() -> Bool {
        guard let _ = selectedJobId, shiftDuration > 0 else {
            return false
        }
        
        // If custom rate is used, validate it
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
            
            // Stop if next date is beyond recurrence end date (if end date is set)
            if hasEndDate && nextDate > recurrenceEndDate { break }
            
            // Limit to a reasonable number of recurring shifts even if no end date
            if !hasEndDate && shiftsToAdd.count >= 51 { break } // Max 1 year of weekly shifts
            
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
    
    private func getMultiplierText(for shiftType: ShiftType) -> String {
        switch shiftType {
        case .regular: return "×1.0"
        case .overtime: return "×1.5"
        case .holiday: return "×2.0"
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

// MARK: - Supporting Views

// Progress bar for step-by-step form flow (3 steps)
struct ProgressBar: View {
    var currentStep: AddShiftView.FormStep
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                let stepCompleted = stepValue(for: currentStep) > index
                let isCurrentStep = stepValue(for: currentStep) == index
                
                Circle()
                    .fill(
                        stepCompleted || isCurrentStep
                            ? Color.blue
                            : Color.gray.opacity(0.3)
                    )
                    .frame(width: isCurrentStep ? 12 : 8, height: isCurrentStep ? 12 : 8)
                    .overlay(
                        Circle()
                            .stroke(isCurrentStep ? Color.blue : Color.clear, lineWidth: 2)
                            .scaleEffect(1.5)
                    )
            }
        }
    }
    
    private func stepValue(for step: AddShiftView.FormStep) -> Int {
        switch step {
        case .timing: return 0
        case .payment: return 1
        case .review: return 2
        }
    }
}

// Type button for selecting shift type
struct TypeButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    @EnvironmentObject var viewModel: WorkHoursViewModel
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? viewModel.themeColor : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Job selection row with details
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
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? viewModel.themeColor.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? viewModel.themeColor : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
