//
//  PresetShiftFormView.swift
//  WorkTracker
//
//  Created by Tom Speake on 6/26/25.
//


//
//  PresetShiftFormView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/18/25.
//

import SwiftUI

struct PresetShiftFormView: View {
    @Binding var preset: PresetShift
    @Environment(\.dismiss) private var dismiss

    // Formatters
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var breakDurationProxy: Binding<Double> {
        Binding<Double>(
            get: { self.preset.breakDuration },
            set: { self.preset.breakDuration = $0 }
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Preset Details")) {
                    TextField("Preset Name", text: $preset.name)
                }

                Section(header: Text("Shift Times")) {
                    DatePicker("Start Time", selection: $preset.startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $preset.endTime, displayedComponents: .hourAndMinute)
                }

                Section(header: Text("Break Duration")) {
                    VStack(alignment: .leading) {
                        Text("Break: \(Int(preset.breakDuration * 60)) minutes")
                        Slider(value: breakDurationProxy, in: 0...2, step: 0.25) {
                            Text("Break Duration")
                        }
                    }
                }
                
                Section(header: Text("Summary")) {
                    HStack {
                        Text("Total Duration")
                        Spacer()
                        Text(String(format: "%.2f hours", preset.duration))
                    }
                }
            }
            .navigationTitle(preset.name.isEmpty ? "New Preset" : "Edit Preset")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    // Validation could be added here
                    dismiss()
                }
            )
        }
    }
}