//
//  JobFormView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//


//
//  JobFormView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//

import SwiftUI

struct JobFormView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var isPresented: Bool
    
    @State private var jobName: String = ""
    @State private var hourlyRate: Double = 10.0
    @State private var selectedColor: String = "Blue"
    @State private var isActive: Bool = true
    @State private var presetShifts: [PresetShift] = [] // Add state for presets
    
    // For managing the preset form sheet
    @State private var showingPresetForm = false
    @State private var selectedPreset: PresetShift?
    
    // For edit mode
    var job: Job? = nil
    
    private var isEditMode: Bool {
        return job != nil
    }
    
    private var formTitle: String {
        return isEditMode ? "Edit Job" : "Add Job"
    }
    
    // Available job colors
    private let jobColors = [
        "Blue",
        "Green",
        "Orange",
        "Purple",
        "Red",
        "Teal"
    ]
    
    init(isPresented: Binding<Bool>, job: Job? = nil) {
        self._isPresented = isPresented
        self.job = job
        
        // Initialize state if editing
        if let job = job {
            _jobName = State(initialValue: job.name)
            _hourlyRate = State(initialValue: job.hourlyRate)
            _selectedColor = State(initialValue: job.color)
            _isActive = State(initialValue: job.isActive)
            _presetShifts = State(initialValue: job.presetShifts) // Initialize presets
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Job Details")) {
                TextField("Job Name", text: $jobName)
                
                HStack {
                    Text("Hourly Rate (£)")
                    Spacer()
                    TextField("Rate", value: $hourlyRate, formatter: currencyFormatter)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section(header: Text("Color")) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 15) {
                    ForEach(jobColors, id: \.self) { color in
                        ColorSelectionButton(
                            color: getJobColor(color),
                            isSelected: color == selectedColor,
                            action: { selectedColor = color }
                        )
                    }
                }
                .padding(.vertical, 8)
            }

            // Preset Shifts Management Section
            Section(header: Text("Preset Shifts")) {
                ForEach(presetShifts) { preset in
                    Button(action: {
                        self.selectedPreset = preset
                        self.showingPresetForm = true
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preset.name).foregroundColor(.primary)
                                Text("\(formatTime(preset.startTime)) - \(formatTime(preset.endTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "pencil").foregroundColor(.accentColor)
                        }
                    }
                }
                .onDelete(perform: deletePreset)
                
                Button(action: {
                    self.selectedPreset = nil // Ensure we are creating a new one
                    self.showingPresetForm = true
                }) {
                    Label("Add Preset Shift", systemImage: "plus.circle.fill")
                }
            }
            
            if isEditMode {
                Section(header: Text("Status")) {
                    Toggle("Active", isOn: $isActive)
                }
            }
            
            Section {
                Button(action: saveJob) {
                    HStack {
                        Spacer()
                        Text(isEditMode ? "Update Job" : "Add Job")
                            .bold()
                        Spacer()
                    }
                }
                .disabled(jobName.isEmpty)
            }
        }
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .sheet(isPresented: $showingPresetForm) {
            let presetBinding = Binding<PresetShift>(
                get: {
                    // If selectedPreset is nil, create a new empty one for the form
                    self.selectedPreset ?? PresetShift(name: "", startTime: Date(), endTime: Date(), breakDuration: 0.5)
                },
                set: { updatedPreset in
                    if let index = self.presetShifts.firstIndex(where: { $0.id == updatedPreset.id }) {
                        // Update existing preset
                        self.presetShifts[index] = updatedPreset
                    } else if self.selectedPreset == nil {
                        // Add new preset
                        self.presetShifts.append(updatedPreset)
                    }
                    self.selectedPreset = updatedPreset // keep it selected
                }
            )
            PresetShiftFormView(preset: presetBinding)
        }
    }
    
    private func saveJob() {
        if isEditMode {
            if var updatedJob = job {
                updatedJob.name = jobName
                updatedJob.hourlyRate = hourlyRate
                updatedJob.color = selectedColor
                updatedJob.isActive = isActive
                updatedJob.presetShifts = presetShifts // Save presets
                
                viewModel.updateJob(updatedJob)
            }
        } else {
            let newJob = Job(
                name: jobName,
                hourlyRate: hourlyRate,
                color: selectedColor,
                presetShifts: presetShifts // Save presets
            )
            
            viewModel.addJob(newJob)
        }
        
        isPresented = false
    }

    private func deletePreset(at offsets: IndexSet) {
        presetShifts.remove(atOffsets: offsets)
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getJobColor(_ colorName: String) -> Color {
        switch colorName {
        case "Blue": return Color(red: 0.20, green: 0.40, blue: 0.70)
        case "Green": return Color(red: 0.20, green: 0.55, blue: 0.30)
        case "Orange": return Color(red: 0.80, green: 0.40, blue: 0.20)
        case "Purple": return Color(red: 0.50, green: 0.25, blue: 0.70)
        case "Red": return Color(red: 0.70, green: 0.20, blue: 0.20)
        case "Teal": return Color(red: 0.20, green: 0.50, blue: 0.60)
        default: return .blue
        }
    }
}

// Color selection button component
struct ColorSelectionButton: View {
    var color: Color
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
                
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
