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
    
    /// The main text title for the card
    var title: String
    /// An optional subtitle
    var subtitle: String
    /// Icon name to display (SF Symbols)
    var iconName: String
    /// The background colour for the card (defaults to theme color)
    var cardColor: Color?
    /// The horizontal alignment of the content
    var textAlignment: Alignment = .leading
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with circular background
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(subtitle.isEmpty ? .title2 : .headline)
                    .foregroundColor(.white)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity, alignment: textAlignment)
        }
        .padding(16)
        .background(
            ZStack {
                // Use theme color if no specific color is provided
                let backgroundColor = cardColor ?? viewModel.themeColor
                
                // Base color with slight adjustment for dark mode
                backgroundColor.opacity(colorScheme == .dark ? 0.9 : 1.0)
                
                // Gradient overlay for more depth - adjusted for dark mode
                LinearGradient(
                    gradient: Gradient(colors: [
                        backgroundColor.opacity(colorScheme == .dark ? 0.6 : 0.7),
                        backgroundColor.opacity(colorScheme == .dark ? 0.95 : 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .cornerRadius(20)
        .shadow(
            color: (cardColor ?? viewModel.themeColor).opacity(colorScheme == .dark ? 0.2 : 0.5),
            radius: colorScheme == .dark ? 7 : 10,
            x: 0,
            y: colorScheme == .dark ? 3 : 5
        )
    }
}

struct NavCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NavCardView(
                title: "Shifts",
                subtitle: "View All",
                iconName: "calendar.badge.clock"
            )
            .frame(maxWidth: 170)
            .environmentObject(WorkHoursViewModel())
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
}
