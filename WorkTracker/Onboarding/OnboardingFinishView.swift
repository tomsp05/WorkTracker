//
//  OnboardingFinishView.swift
//  WorkTracker
//
//  Created by Tom Speake on 6/27/25.
//


import SwiftUI

struct OnboardingFinishView: View {
    @EnvironmentObject var viewModel: WorkHoursViewModel
    @State private var animateElements = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(viewModel.themeColor)
                    .padding(.top, 50)
                    .scaleEffect(animateElements ? 1.0 : 0.5)
                    .opacity(animateElements ? 1.0 : 0.0)

                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.themeColor)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)

                Text("Your shift tracker is ready to go.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut.delay(0.2), value: animateElements)

                Spacer()
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    animateElements = true
                }
            }
        }
    }
}