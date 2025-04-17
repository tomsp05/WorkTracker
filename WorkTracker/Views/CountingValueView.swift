//
//  CountingValueView.swift
//  WorkTracker
//
//  Created by Tom Speake on 4/17/25.
//

import SwiftUI

struct CountingValueView: View {
    var value: Double
    var fromValue: Double
    var isAnimating: Bool
    var fontSize: CGFloat = 36
    var positiveColor: Color = .green
    var negativeColor: Color = .red
    
    @State private var displayValue: Double
    @State private var timer: Timer?
    @State private var animationDuration: Double = 1.0
    @State private var animationStartTime: Date?
    
    init(value: Double, fromValue: Double, isAnimating: Bool, fontSize: CGFloat = 36, positiveColor: Color = .green, negativeColor: Color = .red) {
        self.value = value
        self.fromValue = fromValue
        self.isAnimating = isAnimating
        self.fontSize = fontSize
        self.positiveColor = positiveColor
        self.negativeColor = negativeColor
        self._displayValue = State(initialValue: fromValue)
    }
    
    var body: some View {
        Text(formattedValue)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(textColor)
            .onAppear {
                self.displayValue = value
            }
            .onChange(of: value) { _, newValue in
                startAnimation(from: fromValue, to: newValue)
            }
            .onChange(of: isAnimating) { _, newIsAnimating in
                if newIsAnimating {
                    startAnimation(from: fromValue, to: value)
                }
            }
            .onDisappear {
                stopAnimation()
            }
    }
    
    private var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: displayValue)) ?? "£0.00"
    }
    
    private var textColor: Color {
        if isAnimating {
            if value > fromValue {
                return positiveColor
            } else if value < fromValue {
                return negativeColor
            }
        }
        return positiveColor // Default to positive color
    }
    
    private func startAnimation(from startValue: Double, to endValue: Double) {
        // Skip animation if values are the same
        if abs(endValue - startValue) < 0.01 {
            displayValue = endValue
            return
        }
        
        // Stop any existing animation
        stopAnimation()
        
        // Store animation start time
        animationStartTime = Date()
        
        // Calculate appropriate duration based on the difference
        let difference = abs(endValue - startValue)
        animationDuration = min(max(difference / 100.0, 0.3), 1.0) // Between 0.3 and 1.0 seconds
        
        // Create a timer for smooth animation
        timer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { timer in
            guard let startTime = animationStartTime else {
                stopAnimation()
                return
            }
            
            let elapsedTime = Date().timeIntervalSince(startTime)
            let progress = min(elapsedTime / animationDuration, 1.0)
            
            // Use easeInOut curve for smoother animation
            let curvedProgress = easeInOut(progress)
            
            // Update displayed value
            displayValue = startValue + (endValue - startValue) * curvedProgress
            
            // Stop animation when complete
            if progress >= 1.0 {
                stopAnimation()
                displayValue = endValue
            }
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
        animationStartTime = nil
    }
    
    // Easing function for smoother animation
    private func easeInOut(_ t: Double) -> Double {
        return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
}
