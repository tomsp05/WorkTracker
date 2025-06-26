//
//  JobCardView.swift
//  WorkTracker
//
//  Created by Tom Speake on 6/26/25.
//


// WorkTracker/Views/JobCardView.swift

import SwiftUI

struct JobCardView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    
    let job: Job
    
    private var jobColor: Color {
        getJobColor(job.color)
    }

    var body: some View {
        HStack(spacing: 15) {
            // Color indicator
            Circle()
                .fill(jobColor)
                .frame(width: 15, height: 15)
                .padding(.leading)

            VStack(alignment: .leading, spacing: 5) {
                Text(job.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("£\(String(format: "%.2f", job.hourlyRate))/hr")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !job.isActive {
                Text("Inactive")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.8))
                    .cornerRadius(15)
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.1), radius: 5, x: 0, y: 2)
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