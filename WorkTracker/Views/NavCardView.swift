//
//  NavCardView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//


import SwiftUI

struct NavCardView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var title: String
    var subtitle: String
    var iconName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(viewModel.themeColor)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.themeColor)
            }
        }
        .padding()
        .frame(height: 80)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}