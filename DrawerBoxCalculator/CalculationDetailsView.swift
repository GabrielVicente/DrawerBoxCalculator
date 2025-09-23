//
//  CalculationDetailsView.swift
//  DrawerBoxCalculator
//
//  Created by Agent on 9/18/25.
//

import SwiftUI

struct CalculationDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    let slide: DrawerSlide
    let openingWidth: Double
    let materialThickness: Double
    let calculatedWidth: Double
    let isMetric: Bool
    
    // Format helpers
    private func formatInches(_ value: Double) -> String {
        return String(format: "%.3f\"", value)
    }
    
    private func formatMM(_ value: Double) -> String {
        return String(format: "%.1f mm", value * Constants.inchesToMM)
    }
    
    private func formatAsFraction(_ inches: Double) -> String {
        // Round to nearest 1/16th
        let sixteenths = round(inches * 16)
        let wholePart = Int(sixteenths / 16)
        let fractionPart = Int(sixteenths.truncatingRemainder(dividingBy: 16))
        
        if fractionPart == 0 {
            return "\(wholePart)\""
        }
        
        // Simplify fraction
        var numerator = fractionPart
        var denominator = 16
        
        // Find GCD and simplify
        if numerator % 8 == 0 {
            numerator /= 8
            denominator = 2
        } else if numerator % 4 == 0 {
            numerator /= 4
            denominator = 4
        } else if numerator % 2 == 0 {
            numerator /= 2
            denominator = 8
        }
        
        if wholePart > 0 {
            return "\(wholePart)-\(numerator)/\(denominator)\""
        } else {
            return "\(numerator)/\(denominator)\""
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Summary Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Calculation Summary")
                            .font(Typography.headline)
                            .foregroundColor(.white)
                        
                        Text(slide.type == .undermount ? 
                            "For undermount slides, the drawer box width is calculated by starting with your cabinet opening width and subtracting the deduction on each side. The deduction is based on manufacturer specifications and represents the required clearance - essentially the distance from the inside of the cabinet to the inside edge of the drawer box. For undermount slides, we then add back the material thickness on each side since the slides mount under the drawer bottom." :
                            "For sidemount slides, the drawer box width is calculated by subtracting the deduction from each side of the cabinet opening. The deduction is based on manufacturer specifications and represents the required clearance - essentially the distance from the inside of the cabinet to the outside edge of the drawer box. Material thickness is not added back because sidemount slides attach directly to the sides of the drawer box."
                        )
                        .font(Typography.body)
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                    }
                    .padding()
                    .background(Constants.appTintColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Constants.appTintColor.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    
                    // Hardware Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected Hardware")
                            .font(Typography.headline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Line:")
                                    .font(Typography.caption)
                                    .foregroundColor(.gray)
                                Text(slide.line)
                                    .font(Typography.body)
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("Part Number:")
                                    .font(Typography.caption)
                                    .foregroundColor(.gray)
                                Text("#\(slide.partNumber)")
                                    .font(Typography.body)
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("Manufacturer:")
                                    .font(Typography.caption)
                                    .foregroundColor(.gray)
                                Text(slide.manufacturer)
                                    .font(Typography.body)
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("Type:")
                                    .font(Typography.caption)
                                    .foregroundColor(.gray)
                                Text(slide.type.rawValue)
                                    .font(Typography.body)
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("Deduction per side:")
                                    .font(Typography.caption)
                                    .foregroundColor(.gray)
                                Text("\(formatInches(slide.standardDeductionInches)) | \(formatMM(slide.standardDeductionInches))")
                                    .font(Typography.body)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // Input Values Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Input Values")
                            .font(Typography.headline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Opening Width:")
                                    .font(Typography.caption)
                                    .foregroundColor(.gray)
                                Text("\(formatInches(openingWidth)) | \(formatMM(openingWidth))")
                                    .font(Typography.body)
                                    .foregroundColor(.white)
                            }
                            
                            if slide.type.requiresMaterialThickness {
                                HStack {
                                    Text("Material Thickness:")
                                        .font(Typography.caption)
                                        .foregroundColor(.gray)
                                    Text("\(formatInches(materialThickness)) | \(formatMM(materialThickness))")
                                        .font(Typography.body)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // Calculation Breakdown Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Calculation Breakdown")
                            .font(Typography.headline)
                            .foregroundColor(.white)
                        
                        if slide.type == .undermount {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Formula:")
                                    .font(Typography.subheadline)
                                    .foregroundColor(.gray)
                                
                                // Color-coded formula
                                HStack(spacing: 4) {
                                    Text("Drawer Width")
                                        .foregroundColor(Constants.appTintColor)
                                    Text("=")
                                        .foregroundColor(.white)
                                    Text("Opening Width")
                                        .foregroundColor(.cyan)
                                    Text("-")
                                        .foregroundColor(.white)
                                    Text("(2 × Deduction)")
                                        .foregroundColor(.orange)
                                    Text("+")
                                        .foregroundColor(.white)
                                    Text("(2 × Material)")
                                        .foregroundColor(.green)
                                }
                                .font(Typography.footnote)
                                .fontWeight(.medium)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                
                                Text("Step-by-step:")
                                    .font(Typography.subheadline)
                                    .foregroundColor(.gray)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 4) {
                                        Text("1. Start with opening:")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(formatInches(openingWidth))
                                            .foregroundColor(.cyan)
                                            .fontWeight(.medium)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Text("2. Subtract deductions:")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(formatInches(openingWidth))
                                            .foregroundColor(.cyan)
                                        Text("-")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text("(2 × \(formatInches(slide.standardDeductionInches)))")
                                            .foregroundColor(.orange)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Text("   =")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(formatInches(openingWidth - (2 * slide.standardDeductionInches)))
                                            .foregroundColor(.yellow)
                                            .fontWeight(.medium)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Text("3. Add material thickness:")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(formatInches(openingWidth - (2 * slide.standardDeductionInches)))
                                            .foregroundColor(.yellow)
                                        Text("+")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text("(2 × \(formatInches(materialThickness)))")
                                            .foregroundColor(.green)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Text("   =")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(formatInches(calculatedWidth))
                                            .foregroundColor(Constants.appTintColor)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .font(Typography.footnote)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Formula:")
                                    .font(Typography.subheadline)
                                    .foregroundColor(.gray)
                                
                                // Color-coded formula for sidemount
                                HStack(spacing: 4) {
                                    Text("Drawer Width")
                                        .foregroundColor(Constants.appTintColor)
                                    Text("=")
                                        .foregroundColor(.white)
                                    Text("Opening Width")
                                        .foregroundColor(.cyan)
                                    Text("-")
                                        .foregroundColor(.white)
                                    Text("(2 × Deduction)")
                                        .foregroundColor(.orange)
                                }
                                .font(Typography.footnote)
                                .fontWeight(.medium)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                
                                Text("Step-by-step:")
                                    .font(Typography.subheadline)
                                    .foregroundColor(.gray)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 4) {
                                        Text("1. Start with opening:")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(formatInches(openingWidth))
                                            .foregroundColor(.cyan)
                                            .fontWeight(.medium)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Text("2. Subtract deductions:")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(formatInches(openingWidth))
                                            .foregroundColor(.cyan)
                                        Text("-")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text("(2 × \(formatInches(slide.standardDeductionInches)))")
                                            .foregroundColor(.orange)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Text("   =")
                                            .foregroundColor(.white.opacity(0.9))
                                        Text(formatInches(calculatedWidth))
                                            .foregroundColor(Constants.appTintColor)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .font(Typography.footnote)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // Result Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Final Result")
                            .font(Typography.headline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Exact Value:")
                                    .font(Typography.caption)
                                    .foregroundColor(.gray)
                                Text(formatInches(calculatedWidth))
                                    .font(Typography.headline)
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("Metric:")
                                    .font(Typography.caption)
                                    .foregroundColor(.gray)
                                Text(formatMM(calculatedWidth))
                                    .font(Typography.headline)
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("Fractional (1/16\" precision):")
                                    .font(Typography.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                FractionText(fractionString: formatAsFraction(calculatedWidth))
                                    .scaleEffect(1.2)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        Text("Note: The fractional result is rounded to the nearest 1/16 of an inch for practical woodworking applications.")
                            .font(Typography.caption)
                            .foregroundColor(.gray)
                            .italic()
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Constants.backgroundColor)
            .navigationTitle("Calculation Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(Typography.body)
                    .foregroundColor(Constants.appTintColor)
                }
            }
        }
    }
}

#Preview {
    CalculationDetailsView(
        slide: DrawerSlide.undermountSlides.first!,
        openingWidth: 24.0,
        materialThickness: 0.5,
        calculatedWidth: 23.35,
        isMetric: false
    )
}