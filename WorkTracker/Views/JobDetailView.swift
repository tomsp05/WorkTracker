import SwiftUI
import Charts

struct JobDetailView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingEditSheet = false
    @State private var filterState = AnalyticsFilterState()
    @State private var selectedChartTab: ChartType = .earnings

    var job: Job

    // The actual job from the view model might be updated
    private var currentJob: Job {
        viewModel.jobs.first(where: { $0.id == job.id }) ?? job
    }

    // Job statistics
    private var dateRange: (start: Date, end: Date) {
        var startDate: Date
        var endDate: Date
        let calendar = Calendar.current
        let now = Date()

        switch filterState.timeFilter {
        case .week:
            var weekCal = calendar
            weekCal.firstWeekday = 2 // Monday
            guard let thisWeekStart = weekCal.dateInterval(of: .weekOfYear, for: now)?.start else {
                endDate = now
                startDate = weekCal.date(byAdding: .day, value: -6, to: now)!
                break
            }
            startDate = weekCal.date(byAdding: .weekOfYear, value: filterState.timeOffset, to: thisWeekStart)!
            endDate = weekCal.date(byAdding: .day, value: 6, to: startDate)!
        case .month:
            guard let thisMonthStart = calendar.dateInterval(of: .month, for: now)?.start else {
                endDate = now
                startDate = calendar.date(byAdding: .day, value: -29, to: now)!
                break
            }
            startDate = calendar.date(byAdding: .month, value: filterState.timeOffset, to: thisMonthStart)!
            if filterState.timeOffset == 0 {
                endDate = now
            } else {
                let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: startDate)!
                endDate = nextMonthStart.addingTimeInterval(-1)
            }
        case .yearToDate:
            endDate = now.addingTimeInterval(Double(filterState.timeOffset) * (365 * 24 * 60 * 60))
            var comps = calendar.dateComponents([.year], from: endDate)
            comps.month = 1
            comps.day = 1
            startDate = calendar.date(from: comps)!
        case .year:
            endDate = now.addingTimeInterval(Double(filterState.timeOffset) * (365 * 24 * 60 * 60))
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
        }

        return (start: startDate, end: endDate)
    }

    private var timePeriodTitle: String {
        let formatter = DateFormatter()

        switch filterState.timeFilter {
        case .week:
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: dateRange.start)
        case .yearToDate:
            formatter.dateFormat = "yyyy"
            let year = formatter.string(from: dateRange.end)
            return "\(year) YTD"
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: dateRange.start)
        }
    }

    private var jobShifts: [WorkShift] {
        let (startDate, endDate) = dateRange
        return viewModel.shifts
            .filter { $0.jobId == job.id && $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date > $1.date }
    }

    private func calculateShiftEarnings(_ shift: WorkShift) -> Double {
        // Get the appropriate rate (either override or job rate)
        let rate: Double
        if let override = shift.hourlyRateOverride {
            rate = override
        } else if let job = viewModel.jobs.first(where: { $0.id == shift.jobId }) {
            rate = job.hourlyRate
        } else {
            rate = 0.0
        }

        // Apply shift type multiplier
        let multiplier: Double = {
            switch shift.shiftType {
            case .regular: return 1.0
            case .overtime: return 1.5
            case .holiday: return 2.0
            }
        }()

        return shift.duration * rate * multiplier
    }

    private var totalShifts: Int {
        return jobShifts.count
    }

    private var totalHours: Double {
        return jobShifts.reduce(0) { $0 + $1.duration }
    }

    private var totalEarnings: Double {
        return jobShifts.reduce(0) { $0 + calculateShiftEarnings($1) }
    }

    private var averageHoursPerShift: Double {
        return totalShifts > 0 ? totalHours / Double(totalShifts) : 0
    }

    private var effectiveHourlyRate: Double {
        return totalHours > 0 ? totalEarnings / totalHours : 0
    }

    // Color for the job
    private var jobColor: Color {
        return getJobColor(currentJob.color ?? "Blue") // Add default color value
    }

    private var jobColorGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                jobColor.opacity(0.7),
                jobColor
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // All-time stats for this job
    private var allTimeJobShifts: Int {
        return viewModel.shifts.filter { $0.jobId == job.id }.count
    }

    private var allTimeJobHours: Double {
        return viewModel.shifts.filter { $0.jobId == job.id }.reduce(0) { $0 + $1.duration }
    }

    private var allTimeJobEarnings: Double {
        let allShifts = viewModel.shifts.filter { $0.jobId == job.id }
        return allShifts.reduce(0) { $0 + calculateShiftEarnings($1) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Job overview card
                jobOverviewCard

                // Time period selector
                timeNavigationView

                // Statistics cards
                statisticsCardsSection

                // Chart section
                chartSection

                // Recent shifts section
                recentShiftsSection
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationTitle(currentJob.name)
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingEditSheet = true
                }) {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                JobFormView(isPresented: $showingEditSheet, job: currentJob)
                    .environmentObject(viewModel)
                    .navigationTitle("Edit Job")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingEditSheet = false
                        }
                    )
            }
            .environmentObject(viewModel)
        }
    }

    // MARK: - View Sections

    private var jobOverviewCard: some View {
        VStack {
            HStack(alignment: .center) {
                // Color circle
                Circle()
                    .fill(jobColor)
                    .frame(width: 30, height: 30)

                Text(currentJob.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                if !currentJob.isActive {
                    Text("Inactive")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.secondary)
                        .cornerRadius(20)
                }
            }

            Divider()
                .padding(.vertical, 8)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hourly Rate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(formatCurrency(currentJob.hourlyRate) + "/hr")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("All-time Earnings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(formatCurrency(allTimeJobEarnings))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(jobColor)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All-time Hours")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(formatHours(allTimeJobHours))
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("All-time Shifts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("\(allTimeJobShifts)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private var timeNavigationView: some View {
        VStack(spacing: 12) {
            Picker("Time Filter", selection: $filterState.timeFilter) {
                ForEach(AnalyticsTimeFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            HStack {
                Button(action: { filterState.timeOffset -= 1 }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(viewModel.themeColor)
                        .font(.system(size: 16, weight: .medium))
                        .padding(8)
                        .background(Circle().fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1)))
                }

                Spacer()

                Text(timePeriodTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Button(action: { if filterState.timeOffset < 0 { filterState.timeOffset += 1 } }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(viewModel.themeColor)
                        .font(.system(size: 16, weight: .medium))
                        .padding(8)
                        .background(Circle().fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1)))
                }
                .disabled(filterState.timeOffset == 0).opacity(filterState.timeOffset == 0 ? 0.5 : 1.0)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private var statisticsCardsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatisticCardView(
                    title: "Total Earnings",
                    value: formatCurrency(totalEarnings),
                    iconName: "dollarsign.circle.fill"
                )
                .environmentObject(viewModel)

                StatisticCardView(
                    title: "Total Hours",
                    value: formatHours(totalHours),
                    iconName: "clock.fill"
                )
                .environmentObject(viewModel)
            }

            HStack(spacing: 16) {
                StatisticCardView(
                    title: "Avg. Hours/Shift",
                    value: formatHours(averageHoursPerShift),
                    iconName: "gauge.medium"
                )
                .environmentObject(viewModel)

                StatisticCardView(
                    title: "Effective Rate",
                    value: formatCurrency(effectiveHourlyRate) + "/h",
                    iconName: "chart.bar.fill"
                )
                .environmentObject(viewModel)
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview")
                .font(.headline)

            // Tab selector for chart type
            Picker("Chart Type", selection: $selectedChartTab) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            if chartData.isEmpty {
                VStack {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .padding()

                    Text("No data available for this period")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 250)
            } else {
                // Chart view
                Chart {
                    ForEach(chartData) { item in
                        BarMark(
                            x: .value("Date", item.label),
                            y: .value(selectedChartTab.rawValue, item.value)
                        )
                        .foregroundStyle(jobColorGradient)
                    }
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                if selectedChartTab == .earnings {
                                    Text(formatCurrency(doubleValue))
                                } else {
                                    Text(formatHours(doubleValue))
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private var recentShiftsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Shifts")
                .font(.headline)

            if jobShifts.isEmpty {
                VStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .padding()

                    Text("No shifts available for this period")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(jobShifts.prefix(5)) { shift in
                        NavigationLink(destination: EditShiftView(shift: shift).environmentObject(viewModel)) {
                            ShiftCardView(shift: shift)
                                .environmentObject(viewModel)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                if jobShifts.count > 5 {
                    // Create a filter state with the current job's ID pre-selected
                    let filterState = ShiftFilterState(selectedJobIds: [job.id])

                    NavigationLink(destination: ShiftsListView(initialFilterState: filterState).environmentObject(viewModel)) {
                        Text("See All Shifts")
                            .font(.headline)
                            .foregroundColor(jobColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(jobColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            .cornerRadius(15)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Helper Methods

    private var chartData: [ChartData] {
        switch selectedChartTab {
        case .earnings:
            return generateChartData(calculating: .earnings)
        case .hours:
            return generateChartData(calculating: .hours)
        }
    }

    private func generateChartData(calculating type: ChartCalculationType) -> [ChartData] {
        let (startDate, endDate) = dateRange
        let calendar = Calendar.current
        var chartData: [ChartData] = []

        switch filterState.timeFilter {
        case .week, .month:
            // Daily breakdown
            let formatter = DateFormatter()
            formatter.dateFormat = "E" // Short day name

            var currentDate = startDate
            while currentDate <= endDate {
                let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                let dailyShifts = jobShifts.filter { $0.date >= currentDate && $0.date < nextDate }

                let value: Double
                if type == .earnings {
                    value = dailyShifts.reduce(0) { $0 + calculateShiftEarnings($1) }
                } else {
                    value = dailyShifts.reduce(0) { $0 + $1.duration }
                }

                chartData.append(ChartData(
                    id: UUID(),
                    label: formatter.string(from: currentDate),
                    value: value
                ))

                currentDate = nextDate
            }

        case .yearToDate, .year:
            // For year to date view, monthly data
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM" // Month abbreviation (Jan, Feb, etc.)

            // Group by month
            var components = calendar.dateComponents([.year, .month], from: startDate)

            while let currentMonthStart = calendar.date(from: components), currentMonthStart <= endDate {
                // Get next month
                components.month! += 1
                let nextMonthStart = calendar.date(from: components) ?? endDate

                // Filter shifts for this month
                let monthlyShifts = jobShifts.filter {
                    $0.date >= currentMonthStart && $0.date < nextMonthStart
                }

                let value: Double
                if type == .earnings {
                    value = monthlyShifts.reduce(0) { $0 + calculateShiftEarnings($1) }
                } else {
                    value = monthlyShifts.reduce(0) { $0 + $1.duration }
                }

                chartData.append(ChartData(
                    id: UUID(),
                    label: monthFormatter.string(from: currentMonthStart),
                    value: value
                ))
            }
        }

        return chartData
    }

    // Calculate proportional value for shifts that span multiple segments
    private func calculateProportionalValue(shifts: [WorkShift], startTime: Date, endTime: Date, valueType: ChartCalculationType) -> Double {
        shifts.reduce(0) { sum, shift in
            let shiftDuration = shift.endTime.timeIntervalSince(shift.startTime)
            let periodStart = max(startTime, shift.startTime)
            let periodEnd = min(endTime, shift.endTime)

            if periodStart >= periodEnd {
                return sum
            }

            let periodDuration = periodEnd.timeIntervalSince(periodStart)
            let proportion = shiftDuration > 0 ? (periodDuration / shiftDuration) : 0

            if valueType == .earnings {
                return sum + (calculateShiftEarnings(shift) * proportion)
            } else {
                return sum + (periodDuration / 3600) // Convert to hours
            }
        }
    }

    // Format currency
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }

    // Format hours
    private func formatHours(_ hours: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1

        guard let formattedHours = formatter.string(from: NSNumber(value: hours)) else {
            return "\(hours)h"
        }

        return "\(formattedHours)h"
    }

    // Get job color
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
