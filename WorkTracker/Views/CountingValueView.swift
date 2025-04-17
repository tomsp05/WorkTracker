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
    @State private var animatedValue: Double
    
    init(value: Double, fromValue: Double, isAnimating: Bool, fontSize: CGFloat = 36, positiveColor: Color = .green, negativeColor: Color = .red) {
        self.value = value
        self.fromValue = fromValue
        self.isAnimating = isAnimating
        self.fontSize = fontSize
        self.positiveColor = positiveColor
        self.negativeColor = negativeColor
        self._animatedValue = State(initialValue: fromValue)
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
    
    var body: some View {
        Text(formatCurrency(animatedValue))
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundColor(value >= 0 ? positiveColor : negativeColor)
            .onChange(of: isAnimating) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        animatedValue = value
                    }
                }
            }
            .onChange(of: value) { _, newValue in
                if isAnimating {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        animatedValue = newValue
                    }
                } else {
                    animatedValue = newValue
                }
            }
            .onAppear {
                animatedValue = value
            }
    }
}