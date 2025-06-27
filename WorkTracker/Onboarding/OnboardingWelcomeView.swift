//
//  OnboardingWelcomeView.swift
//  WorkTracker
//
//  Created by Tom Speake on 6/27/25.
//


import SwiftUI

struct OnboardingWelcomeView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @State private var animateTitle = false
    @State private var animateText = false
    @State private var animateImage = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 25) {
                ZStack {
                    Circle()
                        .fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "briefcase.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(viewModel.themeColor)
                }
                .scaleEffect(animateImage ? 1.0 : 0.5)
                .opacity(animateImage ? 1.0 : 0.0)

                Text("Welcome to Shifts")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.themeColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(animateTitle ? 1.0 : 0.0)
                    .offset(y: animateTitle ? 0 : 20)

                Text("Let's get you set up to track your work hours and earnings.")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(animateText ? 1.0 : 0.0)
                    .offset(y: animateText ? 0 : 20)

                Spacer()
            }
            .padding(.top, 50)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    animateImage = true
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                    animateTitle = true
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
                    animateText = true
                }
            }
        }
    }
}