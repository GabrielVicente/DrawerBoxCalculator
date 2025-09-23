//
//  FractionText.swift
//  DrawerBoxCalculator
//
//  Created by Agent on 12/18/24.
//

import SwiftUI

struct FractionText: View {
    let fractionString: String
    
    // Convert digits to superscript Unicode
    private func toSuperscript(_ str: String) -> String {
        let superscriptMap: [Character: Character] = [
            "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
            "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹"
        ]
        return String(str.map { superscriptMap[$0] ?? $0 })
    }
    
    // Convert digits to subscript Unicode
    private func toSubscript(_ str: String) -> String {
        let subscriptMap: [Character: Character] = [
            "0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄",
            "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉"
        ]
        return String(str.map { subscriptMap[$0] ?? $0 })
    }
    
    // Try to use precomposed Unicode fractions first, fallback to super/subscript
    private func formatFraction(numerator: String, denominator: String) -> String {
        // First check for precomposed Unicode fractions
        switch (numerator, denominator) {
        case ("1", "2"): return "½"
        case ("1", "3"): return "⅓"
        case ("2", "3"): return "⅔"
        case ("1", "4"): return "¼"
        case ("3", "4"): return "¾"
        case ("1", "8"): return "⅛"
        case ("3", "8"): return "⅜"
        case ("5", "8"): return "⅝"
        case ("7", "8"): return "⅞"
        default:
            // For all others (including 16ths), use superscript/subscript with fraction slash
            return toSuperscript(numerator) + "⁄" + toSubscript(denominator)
        }
    }
    
    private var components: (whole: String?, fraction: String?, inches: Bool) {
        // Parse formats like "24-3/4"" or "3/4"" or "24""
        let cleanString = fractionString.replacingOccurrences(of: "\"", with: "")
        
        // Check if it's just a whole number
        if !cleanString.contains("/") {
            return (whole: cleanString, fraction: nil, inches: true)
        }
        
        // Check for mixed number (e.g., "24-3/4")
        if cleanString.contains("-") {
            let parts = cleanString.components(separatedBy: "-")
            if parts.count == 2 {
                let fractionParts = parts[1].components(separatedBy: "/")
                if fractionParts.count == 2 {
                    let formatted = formatFraction(numerator: fractionParts[0], denominator: fractionParts[1])
                    return (whole: parts[0], fraction: formatted, inches: true)
                }
            }
        }
        
        // Simple fraction (e.g., "3/4")
        let fractionParts = cleanString.components(separatedBy: "/")
        if fractionParts.count == 2 {
            let formatted = formatFraction(numerator: fractionParts[0], denominator: fractionParts[1])
            return (whole: nil, fraction: formatted, inches: true)
        }
        
        // Fallback - just return the original string
        return (whole: cleanString, fraction: nil, inches: true)
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            // Whole number part
            if let whole = components.whole, !whole.isEmpty {
                Text(whole)
                    .font(.system(size: 28, weight: .semibold, design: .default))
            }
            
            // Fraction part - already formatted as Unicode (either precomposed or super/subscript)
            if let fraction = components.fraction {
                Text(fraction)
                    .font(.system(size: 20, weight: .medium, design: .default))
                    .baselineOffset(6)
            }
            
            // Inches symbol - smaller and raised to match fractions
            if components.inches {
                Text("\"")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .baselineOffset(8)
            }
        }
        .foregroundColor(.white)
    }
}

// Preview with different fraction formats
#Preview("Fraction Formats") {
    VStack(spacing: 20) {
        FractionText(fractionString: "24-3/4\"")
        FractionText(fractionString: "3/4\"")
        FractionText(fractionString: "24\"")
        FractionText(fractionString: "1/2\"")
        FractionText(fractionString: "23-5/8\"")
        FractionText(fractionString: "15-15/16\"")
        FractionText(fractionString: "12-11/16\"")
        FractionText(fractionString: "7/16\"")
        FractionText(fractionString: "1/16\"")
    }
    .padding()
    .background(Constants.backgroundColor)
}
