import SwiftUI

struct OnboardingJobsView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @State private var jobs: [JobSetup] = []
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 25) {
                Text("Set Up Your Jobs")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.themeColor)
                    .padding(.top, 30)

                Text("Add the jobs you want to track. You can add more later.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .foregroundColor(.secondary)

                VStack(spacing: 15) {
                    ForEach(0..<jobs.count, id: \.self) { index in
                        JobRow(job: $jobs[index], viewModel: viewModel)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    withAnimation {
                        jobs.append(JobSetup(name: "New Job", hourlyRate: 10.0, color: "Green", isEnabled: true))
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Another Job")
                    }
                    .foregroundColor(viewModel.themeColor)
                    .padding()
                }
            }
        }
        .onAppear(perform: loadJobs)
        .onDisappear(perform: saveJobs)
    }

    private func loadJobs() {
        // If the user already has jobs, load them.
        if !viewModel.jobs.isEmpty {
            jobs = viewModel.jobs.map { job in
                JobSetup(id: job.id, name: job.name, hourlyRate: job.hourlyRate, color: job.color, isEnabled: job.isActive)
            }
        }
        // Otherwise, if it's a new user with no jobs, create a default one.
        else if jobs.isEmpty {
            jobs.append(JobSetup(name: "My First Job", hourlyRate: 10.0, color: "Blue", isEnabled: true))
        }
    }

    private func saveJobs() {
        let updatedJobs = jobs.filter(\.isEnabled).map { jobSetup in
            Job(id: jobSetup.id, name: jobSetup.name, hourlyRate: jobSetup.hourlyRate, color: jobSetup.color, isActive: jobSetup.isEnabled)
        }

        // Replace the old job list with the updated one, without deleting shifts.
        viewModel.jobs = updatedJobs
        DataService.shared.saveJobs(viewModel.jobs)
    }
}

struct JobSetup: Identifiable {
    var id = UUID()
    var name: String
    var hourlyRate: Double
    var color: String
    var isEnabled: Bool
}

struct JobRow: View {
    @Binding var job: JobSetup
    let viewModel: WorkHoursViewModel
    @State private var isExpanded: Bool = false
    @Environment(\.colorScheme) var colorScheme

    private let jobColors = ["Blue", "Green", "Orange", "Purple", "Red", "Teal", "Pink"]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Toggle("", isOn: $job.isEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: viewModel.themeColor))

                VStack(alignment: .leading, spacing: 2) {
                    Text(job.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("£\(job.hourlyRate, specifier: "%.2f")/hr")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: "chevron.\(isExpanded ? "up" : "down")")
                        .foregroundColor(.gray)
                }
            }
            .padding()

            if isExpanded && job.isEnabled {
                VStack(spacing: 15) {
                    Divider().padding(.horizontal)
                    TextField("Job Name", text: $job.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    HStack {
                        Text("Hourly Rate")
                        Spacer()
                        TextField("Rate", value: $job.hourlyRate, formatter: NumberFormatter.currencyFormatter)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                    }
                    .padding(.horizontal)

                    Picker("Color", selection: $job.color) {
                        ForEach(jobColors, id: \.self) { color in
                            Text(color).tag(color)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.08), radius: 5, x: 0, y: 3)
    }
}

// A helper for currency formatting, which you can place in a separate file if you wish.
extension NumberFormatter {
    static var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
}
