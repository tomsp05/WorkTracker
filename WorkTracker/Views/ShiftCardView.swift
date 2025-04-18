//
//  ShiftCardView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//

import SwiftUI

struct ShiftCardView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    
    // Animation state
    @State private var isAppearing: Bool = false
    
    var shift: WorkShift
    
    private var job: Job? {
        return viewModel.jobs.first(where: { $0.id == shift.jobId })
    }
    
    // Calculate the actual earnings including the job's hourly rate
    private var actualEarnings: Double {
        // Get the appropriate rate (either override or job rate)
        let rate: Double
        if let override = shift.hourlyRateOverride {
            rate = override
        } else if let job = self.job {
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
    
    private var jobColor: Color {
        if let colorName = job?.color {
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
        return .blue
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Job capsule indicator - maintaining the capsule look as requested
            Capsule()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            jobColor.opacity(colorScheme == .dark ? 0.8 : 0.7),
                            jobColor.opacity(colorScheme == .dark ? 0.6 : 0.5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 8, height: 42)
                .shadow(color: jobColor.opacity(colorScheme == .dark ? 0.2 : 0.3), radius: 3, x: 0, y: 2)
                .scaleEffect(isAppearing ? 1.0 : 0.8)
                .opacity(isAppearing ? 1.0 : 0.0)
            
            // Shift details with styling based on TransactionCardView
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Job name
                    Text(job?.name ?? "Unknown Job")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Earnings amount
                    Text(formatCurrency(actualEarnings))
                        .font(.system(size: 16, weight: .semibold))
                }
                
                HStack {
                    // Date and time details
                    Text("\(formatDate(shift.date)) • \(formatTime(shift.startTime)) - \(formatTime(shift.endTime))")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Duration
                    Text(formatDuration(shift.duration))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                // Shift type indicator (if not regular)
                if shift.shiftType != .regular {
                    HStack {
                        Text(shift.shiftType.rawValue.capitalized)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(jobColor.opacity(0.2))
                            .foregroundColor(jobColor)
                            .cornerRadius(4)
                        
                        Spacer()
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(
                    color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1),
                    radius: 5, x: 0, y: 2
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isAppearing = true
            }
        }
    }
}
