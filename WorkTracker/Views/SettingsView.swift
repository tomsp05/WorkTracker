//
//  SettingsView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//


//
//  SettingsView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedThemeColor = "Blue"
    @State private var showExportSheet = false
    @State private var showImportSheet = false
    @State private var showResetConfirmation = false
    @State private var exportText = ""
    @State private var importText = ""
    
    // App Specific Settings
    @AppStorage("defaultTimeRange") private var defaultTimeRange = TimeRange.thisWeek.rawValue
    @AppStorage("includeWeekends") private var includeWeekends = true
    
    // Theme Color options
    private let themeColors = ["Blue", "Green", "Orange", "Purple", "Red", "Teal"]
    
    var body: some View {
        Form {
            // Theme settings
            Section(header: Text("Appearance")) {
                Picker("Theme Color", selection: $selectedThemeColor) {
                    ForEach(themeColors, id: \.self) { colorName in
                        HStack {
                            Circle()
                                .fill(getThemeColor(colorName))
                                .frame(width: 20, height: 20)
                            Text(colorName)
                        }
                        .tag(colorName)
                    }
                }
                .onChange(of: selectedThemeColor) { _, newValue in
                    viewModel.themeColorName = newValue
                    DataService.shared.saveThemeColor(newValue)
                }
            }
            
            // App preferences
            Section(header: Text("Preferences")) {
                Picker("Default Time Range", selection: $defaultTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.title).tag(range.rawValue)
                    }
                }
                
                Toggle("Include Weekends in Statistics", isOn: $includeWeekends)
            }
            
            // Data Management
            Section(header: Text("Data Management")) {
                Button(action: {
                    showExportSheet = true
                    exportText = DataService.shared.exportData()
                }) {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
                
                Button(action: {
                    showImportSheet = true
                }) {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }
                
                Button(action: {
                    showResetConfirmation = true
                }) {
                    Label("Reset All Data", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
            
            // About section
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Developer")
                    Spacer()
                    Text("Tom Speake")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .onAppear {
            selectedThemeColor = viewModel.themeColorName
        }
        .sheet(isPresented: $showExportSheet) {
            NavigationView {
                VStack {
                    Text("Export Data")
                        .font(.headline)
                        .padding()
                    
                    Text("Copy the text below to save your data:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    TextEditor(text: $exportText)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding()
                    
                    Button(action: {
                        UIPasteboard.general.string = exportText
                    }) {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(viewModel.themeColor)
                            .cornerRadius(15)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .navigationBarItems(trailing: Button("Done") {
                    showExportSheet = false
                })
            }
        }
        .sheet(isPresented: $showImportSheet) {
            NavigationView {
                VStack {
                    Text("Import Data")
                        .font(.headline)
                        .padding()
                    
                    Text("Paste your data below:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    TextEditor(text: $importText)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding()
                    
                    Button(action: {
                        if DataService.shared.importData(importText) {
                            viewModel.loadInitialData()
                            showImportSheet = false
                        }
                    }) {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(viewModel.themeColor)
                            .cornerRadius(15)
                            .padding(.horizontal)
                    }
                    .disabled(importText.isEmpty)
                    
                    Spacer()
                }
                .navigationBarItems(trailing: Button("Cancel") {
                    showImportSheet = false
                })
            }
        }
        .alert(isPresented: $showResetConfirmation) {
            Alert(
                title: Text("Reset All Data"),
                message: Text("This will delete all your jobs and shifts. This cannot be undone."),
                primaryButton: .destructive(Text("Reset")) {
                    DataService.shared.resetAllData()
                    viewModel.loadInitialData()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func getThemeColor(_ colorName: String) -> Color {
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