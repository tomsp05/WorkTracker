import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    // Theme selection
    @State private var selectedTheme: String = ""
    
    // Data management
    @State private var showExportSheet = false
    @State private var showImportSheet = false
    @State private var showResetConfirmation = false
    @State private var exportText = ""
    @State private var importText = ""
    
    // App Specific Settings
    @AppStorage("defaultTimeRange") private var defaultTimeRange = TimeRange.thisWeek.rawValue
    @AppStorage("includeWeekends") private var includeWeekends = true
    
    // Theme Color options
    private let themeOptions = ["Blue", "Green", "Orange", "Purple", "Red", "Teal"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with title and save button
                HStack {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: saveAllSettings) {
                        Text("Save All")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.themeColor)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal)
                
                // Appearance section
                settingsSection(title: "Appearance", icon: "paintbrush.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Theme Color")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            // Color preview row
                            HStack(spacing: 15) {
                                ForEach(themeOptions, id: \.self) { option in
                                    ThemeColorButton(
                                        colorName: option,
                                        isSelected: selectedTheme == option,
                                        onTap: { selectedTheme = option }
                                    )
                                }
                            }
                            
                            // Preview card with selected theme
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Preview")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(getThemeColor(name: selectedTheme))
                                    .frame(height: 60)
                                    .overlay(
                                        HStack {
                                            Image(systemName: "calendar.badge.clock")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .padding(.leading)
                                            
                                            Text("Theme Preview")
                                                .foregroundColor(.white)
                                                .fontWeight(.semibold)
                                            
                                            Spacer()
                                        }
                                    )
                            }
                        }
                    }
                }
                
                // Preferences section
                settingsSection(title: "Preferences", icon: "gearshape.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        // Default time range picker
                        HStack {
                            Text("Default Time Range")
                                .font(.headline)
                            
                            Spacer()
                            
                            Picker("", selection: $defaultTimeRange) {
                                ForEach(TimeRange.allCases, id: \.self) { range in
                                    Text(range.title).tag(range.rawValue)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        // Weekend inclusion toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Include Weekends")
                                    .font(.headline)
                                
                                Text("Count Saturday and Sunday in weekly statistics")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $includeWeekends)
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: viewModel.themeColor))
                        }
                        
                        // Jobs management button
                        NavigationLink(destination: JobsListView()) {
                            HStack {
                                Image(systemName: "briefcase.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(viewModel.themeColor)
                                    .cornerRadius(8)
                                
                                Text("Manage Jobs")
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Data Management section
                settingsSection(title: "Data Management", icon: "externaldrive.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: { showExportSheet = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                
                                Text("Export Data")
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { showImportSheet = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.green)
                                    .cornerRadius(8)
                                
                                Text("Import Data")
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { showResetConfirmation = true }) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.red)
                                    .cornerRadius(8)
                                
                                Text("Reset All Data")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // About section
                settingsSection(title: "About", icon: "info.circle.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Version")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("1.0.0")
                        }
                        
                        HStack {
                            Text("Developer")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Tom Speake")
                        }
                        
                        HStack {
                            Text("Last Updated")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("April 23, 2025")
                        }
                        
                        Button(action: {
                            // Open feedback link
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(viewModel.themeColor)
                                Text("Send Feedback")
                                    .fontWeight(.medium)
                                    .foregroundColor(viewModel.themeColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(viewModel.themeColor, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 8)
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedTheme = viewModel.themeColorName
        }
        .sheet(isPresented: $showExportSheet) {
            exportDataSheet
        }
        .sheet(isPresented: $showImportSheet) {
            importDataSheet
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
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(viewModel.themeColor)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            // Content
            content()
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
    
    private var exportDataSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title and instructions
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(viewModel.themeColor)
                    
                    Text("Export Your Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Copy the text below to save all your work shifts and jobs.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Data display
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Export Data")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        TextEditor(text: $exportText)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .frame(minHeight: 200)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Copy button
                Button(action: {
                    UIPasteboard.general.string = exportText
                }) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy to Clipboard")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.themeColor)
                    .cornerRadius(15)
                    .shadow(color: viewModel.themeColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Export Data")
            .navigationBarItems(trailing: Button("Done") {
                showExportSheet = false
            })
            .onAppear {
                exportText = DataService.shared.exportData()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
    
    private var importDataSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title and instructions
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Import Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Paste your previously exported data below to restore your work shifts and jobs.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Data input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste Data Here")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        TextEditor(text: $importText)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .frame(minHeight: 200)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Import button
                Button(action: {
                    if DataService.shared.importData(importText) {
                        viewModel.loadInitialData()
                        showImportSheet = false
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import Data")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(importText.isEmpty ? Color.gray : .green)
                    .cornerRadius(15)
                    .shadow(color: (importText.isEmpty ? Color.gray : .green).opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(importText.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Import Data")
            .navigationBarItems(trailing: Button("Cancel") {
                showImportSheet = false
            })
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveAllSettings() {
        // Save theme color
        viewModel.themeColorName = selectedTheme
        DataService.shared.saveThemeColor(selectedTheme)
        
        // Note: AppStorage settings automatically save
        
        // Show feedback (in a real app, you might add a toast here)
        // For now, just dismiss
        presentationMode.wrappedValue.dismiss()
    }
    
    private func getThemeColor(name: String) -> Color {
        switch name {
        case "Blue":
            return Color(red: 0.20, green: 0.40, blue: 0.70)
        case "Green":
            return Color(red: 0.20, green: 0.55, blue: 0.30)
        case "Orange":
            return Color(red: 0.80, green: 0.40, blue: 0.20)
        case "Purple":
            return Color(red: 0.50, green: 0.25, blue: 0.70)
        case "Red":
            return Color(red: 0.70, green: 0.20, blue: 0.20)
        case "Teal":
            return Color(red: 0.20, green: 0.50, blue: 0.60)
        default:
            return Color(red: 0.20, green: 0.40, blue: 0.70)
        }
    }
    
    // MARK: - Supporting Views
    
    struct ThemeColorButton: View {
        let colorName: String
        let isSelected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                ZStack {
                    Circle()
                        .fill(getThemeColorPreview(name: colorName))
                        .frame(width: 40, height: 40)
                        .shadow(color: getThemeColorPreview(name: colorName).opacity(0.4), radius: 3, x: 0, y: 2)
                    
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        
        private func getThemeColorPreview(name: String) -> Color {
            // Match the same color calculation as in the ViewModel
            switch name {
            case "Blue":
                return Color(red: 0.20, green: 0.40, blue: 0.70)
            case "Green":
                return Color(red: 0.20, green: 0.55, blue: 0.30)
            case "Orange":
                return Color(red: 0.80, green: 0.40, blue: 0.20)
            case "Purple":
                return Color(red: 0.50, green: 0.25, blue: 0.70)
            case "Red":
                return Color(red: 0.70, green: 0.20, blue: 0.20)
            case "Teal":
                return Color(red: 0.20, green: 0.50, blue: 0.60)
            default:
                return Color(red: 0.20, green: 0.40, blue: 0.70)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView().environmentObject(WorkHoursViewModel())
        }
    }
}
