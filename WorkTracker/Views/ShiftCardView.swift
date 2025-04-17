//
//  ShiftCardView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//

import SwiftUI

struct ShiftCardView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    
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
        HStack(alignment: .center) {
            // Left color bar showing job
            Rectangle()
                .fill(jobColor)
                .frame(width: 8)
                .cornerRadius(4)
            
            // Shift details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(job?.name ?? "Unknown Job")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Use the properly calculated earnings
                    Text(formatCurrency(actualEarnings))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(jobColor)
                }
                
                HStack {
                    Text(formatDate(shift.date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(formatTime(shift.startTime)) - \(formatTime(shift.endTime))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(formatDuration(shift.duration))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if shift.shiftType != .regular {
                        Text(shift.shiftType.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(shift.shiftType == .overtime ? Color.orange.opacity(0.2) : Color.purple.opacity(0.2))
                            .foregroundColor(shift.shiftType == .overtime ? .orange : .purple)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    if shift.isPaid {
                        Text("Paid")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.leading, 8)
            .padding(.vertical, 4)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}
