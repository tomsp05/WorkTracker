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
    }
    
    private func saveJob() {
        if isEditMode {
            if var updatedJob = job {
                updatedJob.name = jobName
                updatedJob.hourlyRate = hourlyRate
                updatedJob.color = selectedColor
                updatedJob.isActive = isActive
                
                viewModel.updateJob(updatedJob)
            }
        } else {
            let newJob = Job(
                name: jobName,
                hourlyRate: hourlyRate,
                color: selectedColor
            )
            
            viewModel.addJob(newJob)
        }
        
        isPresented = false
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
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