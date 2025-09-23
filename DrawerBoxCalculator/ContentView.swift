//
//  ContentView.swift
//  DrawerBoxCalculator
//
//  Created by Gabriel Vicente on 9/17/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedSlideType = SlideType.undermount
    @State private var selectedSlide: DrawerSlide? = nil  // No default selection
    
    private let analytics = AnalyticsManager.shared
    @State private var cabinetOpeningWidth = ""  // No default value
    @State private var drawerSideMaterialThickness = ""  // No default value
    @State private var currentImage = ImageAsset.undermountSlides
    @State private var calculatedWidth: Double? = nil
    @State private var showResult = false
    @State private var showSlideSelection = false
    @State private var showHelp = false
    @State private var showCalculationDetails = false
    @State private var focusedField: Field? = nil
    
    // Filter states for persistence
    @State private var slideFilterManufacturer: [String] = []
    @State private var slideFilterMaxThickness: Double? = nil
    
    // Unit state for keyboard
    @State private var isMetric = false
    
    // MARK: - Computed Properties
    var canCalculate: Bool {
        guard let slide = selectedSlide,
              !cabinetOpeningWidth.isEmpty else { return false }
        
        let openingWidth = parseValue(cabinetOpeningWidth, isMetric: isMetric)
        guard openingWidth > 0 else { return false }
        
        if selectedSlideType.requiresMaterialThickness {
            guard !drawerSideMaterialThickness.isEmpty else { return false }
            let thickness = parseValue(drawerSideMaterialThickness, isMetric: isMetric)
            guard thickness > 0 else { return false }
            return slide.isCompatible(with: thickness)
        }
        return true
    }
    
    var thicknessValidationMessage: String? {
        guard let slide = selectedSlide,
              selectedSlideType.requiresMaterialThickness,
              !drawerSideMaterialThickness.isEmpty else { return nil }
        
        let thickness = parseValue(drawerSideMaterialThickness, isMetric: isMetric)
        guard thickness > 0 else { return nil }
        
        if !slide.isCompatible(with: thickness) {
            return "Material too thick. Max: \(slide.formattedMaxThickness)"
        }
        return nil
    }
    
    var appropriateImage: ImageAsset {
        switch focusedField {
        case .openingWidth:
            return ImageAsset.openingImage(for: selectedSlideType)
        case .materialThickness:
            return ImageAsset.sideThicknessImage(for: selectedSlideType)
        case nil:
            return showResult ? ImageAsset.drawerWidthImage(for: selectedSlideType) : ImageAsset.slideImage(for: selectedSlideType)
        }
    }
    
    // MARK: - Methods
    func calculateDrawerWidth() {
        guard let slide = selectedSlide else { return }
        
        // Parse the opening width (handle fractions if in imperial)
        let openingWidth = parseValue(cabinetOpeningWidth, isMetric: isMetric)
        guard openingWidth > 0 else { return }
        
        if selectedSlideType.requiresMaterialThickness {
            let thickness = parseValue(drawerSideMaterialThickness, isMetric: isMetric)
            guard thickness > 0 else { return }
            calculatedWidth = slide.calculateDrawerWidth(openingWidth: openingWidth, materialThickness: thickness)
        } else {
            // For sidemount, use 0 for material thickness since it doesn't affect the calculation
            calculatedWidth = slide.calculateDrawerWidth(openingWidth: openingWidth, materialThickness: 0)
        }
        
        showResult = true
        
        // Track calculation event
        analytics.trackCalculation(
            slideType: selectedSlideType,
            openingWidth: openingWidth,
            materialThickness: selectedSlideType.requiresMaterialThickness ? parseValue(drawerSideMaterialThickness, isMetric: isMetric) : nil,
            calculatedWidth: calculatedWidth!,
            slideName: slide.line,
            slideManufacturer: slide.manufacturer,
            isMetric: isMetric
        )
    }
    
    func parseValue(_ text: String, isMetric: Bool) -> Double {
        if isMetric {
            // Parse metric value and convert to inches
            if let mm = Double(text) {
                return mm / Constants.inchesToMM
            }
        } else {
            // Parse imperial (decimal or fraction)
            if text.contains("/") {
                // Parse fraction like "1-1/2" or "1/2"
                let components = text.components(separatedBy: "-")
                var total: Double = 0
                
                if components.count == 2 {
                    // Mixed fraction like "1-1/2"
                    total = Double(components[0]) ?? 0
                    let fractionParts = components[1].components(separatedBy: "/")
                    if fractionParts.count == 2,
                       let numerator = Double(fractionParts[0]),
                       let denominator = Double(fractionParts[1]),
                       denominator != 0 {
                        total += numerator / denominator
                    }
                } else if components.count == 1 {
                    // Simple fraction like "1/2"
                    let fractionParts = text.components(separatedBy: "/")
                    if fractionParts.count == 2,
                       let numerator = Double(fractionParts[0]),
                       let denominator = Double(fractionParts[1]),
                       denominator != 0 {
                        total = numerator / denominator
                    }
                }
                return total
            } else {
                // Decimal
                return Double(text) ?? 0
            }
        }
        return 0
    }
    
    func updateImageForFieldChange() {
        currentImage = appropriateImage
    }
    
    func resetResult() {
        showResult = false
    }
    
    func formatAsFraction(_ inches: Double) -> String {
        // Round to nearest 1/16th
        let sixteenths = round(inches * 16)
        let wholePart = Int(sixteenths / 16)
        let fractionPart = Int(sixteenths.truncatingRemainder(dividingBy: 16))
        
        if fractionPart == 0 {
            // Whole number
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
    
    func convertAllFieldsToNewUnit(toMetric: Bool) {
        // Convert cabinet opening width
        if !cabinetOpeningWidth.isEmpty {
            let currentValueInches = parseValue(cabinetOpeningWidth, isMetric: !toMetric)
            if currentValueInches > 0 {
                if toMetric {
                    // Convert to mm
                    let mmValue = round(currentValueInches * Constants.inchesToMM)
                    cabinetOpeningWidth = String(format: "%.0f", mmValue)
                } else {
                    // Convert to inches (as fraction if needed)
                    cabinetOpeningWidth = formatInchesForDisplay(currentValueInches)
                }
            }
        }
        
        // Convert material thickness
        if !drawerSideMaterialThickness.isEmpty {
            let currentValueInches = parseValue(drawerSideMaterialThickness, isMetric: !toMetric)
            if currentValueInches > 0 {
                if toMetric {
                    // Convert to mm
                    let mmValue = round(currentValueInches * Constants.inchesToMM)
                    drawerSideMaterialThickness = String(format: "%.0f", mmValue)
                } else {
                    // Convert to inches (as fraction if needed)
                    drawerSideMaterialThickness = formatInchesForDisplay(currentValueInches)
                }
            }
        }
    }
    
    func formatInchesForDisplay(_ inches: Double) -> String {
        // If it's a whole number, return as is
        if inches == floor(inches) {
            return String(format: "%.0f", inches)
        }
        
        // Try to convert to a nice fraction
        let sixteenths = round(inches * 16)
        let wholePart = Int(sixteenths / 16)
        let fractionPart = Int(sixteenths.truncatingRemainder(dividingBy: 16))
        
        if fractionPart == 0 {
            return "\(wholePart)"
        }
        
        // Simplify fraction
        var numerator = fractionPart
        var denominator = 16
        
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
            return "\(wholePart)-\(numerator)/\(denominator)"
        } else {
            return "\(numerator)/\(denominator)"
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            
            VStack {
                ScrollView {
                    
                    VStack{
                        
                        HStack {
                            
                            Text("DRAWER BOX CALCULATOR").foregroundColor(.white).font(Typography.bodyBold)
                            Spacer()
            Button(action: { showHelp = true }) {
                Image(systemName: "questionmark.circle")
                    .font(Typography.body)
                    .foregroundColor(.gray)
            }
                        }
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                        .padding(.vertical, 10)
//                        .padding(.top, -20)
//                        .background(Constants.backgroundColor)
                        
                        Divider()
                            .background(Color.gray.opacity(0.6)).padding(.horizontal)
                            .padding(.bottom, 10)
                        
                        headerImageView
                            .frame(height: 320)
                            .padding(.top, -60)
                            .padding(.bottom, -40)
                            .padding(.horizontal, 35)
                        
                        VStack(spacing: 10) {
                            slideSelector
                            Divider()
                                .background(Color.gray.opacity(0.6)).padding(.horizontal)
                            openingWidthInput
                            Divider()
                                .background(Color.gray.opacity(0.6)).padding(.horizontal)
                            
                            if selectedSlideType.requiresMaterialThickness {
                                VStack(alignment: .leading, spacing: 0) {
                                    materialThicknessInput
                                    
                                    if let validationMessage = thicknessValidationMessage {
                                        Text(validationMessage)
                                            .font(Typography.caption)
                                            .foregroundColor(.red)
                                            .padding(.horizontal)
                                    } else if let slide = selectedSlide {
                                        HStack(spacing: 8) {
                                            Text("Max: \(slide.formattedMaxThickness)")
                                                .font(Typography.caption)
                                                .foregroundColor(.gray)
                                            //
                                            //                                Text("•")
                                            //                                    .font(.caption)
                                            //                                    .foregroundColor(.gray.opacity(0.5))
                                            //
                                            //                                Text("Deduction: \(slide.formattedDeduction) per side")
                                            //                                    .font(.caption)
                                            //                                    .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.leading, 8)
                        
                        // Calculate/Reset button with result display
                        HStack(spacing: 12) {
                            // Result display (only visible when showResult is true)
                            if showResult, let width = calculatedWidth {
                // Info button
                Button(action: { showCalculationDetails = true }) {
                    Image(systemName: "info.circle")
                        .font(Typography.title3)
                        .foregroundColor(Constants.appTintColor)
                }
                                .transition(.scale.combined(with: .opacity))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    // Primary result based on input unit
                                    Text("Drawer Box Width:")
                                        .font(Typography.caption)
                                        .foregroundColor(.gray)
                                    
                                    if isMetric {
                                        Text(String(format: "%.0f mm", round(width * Constants.inchesToMM)))
                                            .font(Typography.headline)
                                            .foregroundColor(.white)
                                    } else {
                                        // Use FractionText for imperial measurements
                                        FractionText(fractionString: formatAsFraction(width))
                                            .scaleEffect(1.2)
                                            .padding(.leading, 5)// Make it slightly larger
                                    }
                                    
//                                    // Both units and exact value
//                                    Text(String(format: "%.3f\" | %.1f mm", width, width * Constants.inchesToMM))
//                                        .font(Typography.caption)
//                                        .foregroundColor(.gray)
                                }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                            
                            if showResult {
                                Spacer()
                            }
                            
                            // Animated Calculate/Reset button
                            animatedButton
                        }
                        .padding(.horizontal)
                        .padding(.vertical)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showResult)
                        
                    }
                    .padding(.top)
                    .background(Color(red: 0x1E/255.0, green: 0x1E/255.0, blue: 0x1E/255.0))
                    .cornerRadius(20)
                    .padding(.horizontal, 9)
                }
                
                // Push keyboard to bottom
//                Spacer()
                
                
                // Keyboard fills remaining space with minimum height
                DimensionKeyboard(
                    text: Binding(
                        get: {
                            if focusedField == .openingWidth {
                                return cabinetOpeningWidth
                            } else if focusedField == .materialThickness {
                                return drawerSideMaterialThickness
                            } else {
                                // Default to opening width
                                return cabinetOpeningWidth
                            }
                        },
                        set: { newValue in
                            resetResult()  // Clear result on any keyboard input
                            if focusedField == .openingWidth {
                                cabinetOpeningWidth = newValue
                            } else if focusedField == .materialThickness {
                                drawerSideMaterialThickness = newValue
                            } else {
                                // Default to opening width
                                cabinetOpeningWidth = newValue
                            }
                        }
                    ),
                    isMetric: $isMetric,
                    focusedField: $focusedField
                )
                .frame(height: 230)  // Minimum height for smaller screens
                .id(focusedField) // Force keyboard refresh when field changes
            }


        }
        .background(Constants.backgroundColor.ignoresSafeArea())
//        .shadow(radius: 20)

        .onChange(of: focusedField) { oldValue, newValue in
            print("Focus changed from \(String(describing: oldValue)) to \(String(describing: newValue))")
            updateImageForFieldChange()
        }
        .onChange(of: isMetric) { oldValue, newValue in
            // Convert all field values when unit changes
            convertAllFieldsToNewUnit(toMetric: newValue)
            resetResult()  // Clear any calculated result
        }
        .sheet(isPresented: $showSlideSelection) {
            SlideSelectionViewWithFilters(
                selectedSlide: $selectedSlide,
                selectedSlideType: $selectedSlideType,
                filterManufacturer: $slideFilterManufacturer,
                filterMaxThickness: $slideFilterMaxThickness
            )
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .sheet(isPresented: $showCalculationDetails) {
            if let width = calculatedWidth, let slide = selectedSlide {
                CalculationDetailsView(
                    slide: slide,
                    openingWidth: parseValue(cabinetOpeningWidth, isMetric: isMetric),
                    materialThickness: selectedSlideType.requiresMaterialThickness ? parseValue(drawerSideMaterialThickness, isMetric: isMetric) : 0,
                    calculatedWidth: width,
                    isMetric: isMetric
                )
            }
        }
    }
    
    // MARK: - View Components
    private var headerImageView: some View {
        ZStack {
            Image(currentImage.rawValue)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: Constants.maxImageHeight)
                .animation(.easeInOut(duration: 0.3), value: currentImage)
            
            if let width = calculatedWidth, showResult {
                resultOverlay(width: width).padding(.bottom, 20)
            }
        }
        .padding([.leading, .trailing], -20)
//        .padding(.top)
    }
    
    private func resultOverlay(width: Double) -> some View {
        Group {
            if isMetric {
                // Show metric result rounded to nearest mm
                let mmValue = round(width * Constants.inchesToMM)
                Text(String(format: "%.0f mm", mmValue))
                    .font(Typography.resultText)
                    .foregroundColor(.white)
            } else {
                // Show imperial result with natural fraction formatting
                FractionText(fractionString: formatAsFraction(width))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, Constants.resultOverlayVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(Color(red: 0x1E/255.0, green: 0x1E/255.0, blue: 0x1E/255.0))

        )
        .padding(.top, -14)
    }
    
    private var slideSelector: some View {
        HStack {
            Text("HARDWARE:")
                .font(Typography.body)
                .foregroundColor(Constants.lightGrayColor)
            
            Spacer()
            
            Button(action: {
                resetResult()  // Clear result when opening hardware selection
                showSlideSelection = true
            }) {
                HStack {
                    if let slide = selectedSlide {
                        Text("\(slide.line) #\(slide.partNumber)")
                            .foregroundColor(.white)
                            .font(Typography.body)
                    } else {
                        Text("Select")
                            .foregroundColor(.gray)
                            .font(Typography.body)
                    }
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(Typography.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Constants.inputBackgroundColor)
                .cornerRadius(Constants.cornerRadius)
            }
        }
        .padding(.horizontal)
//        .padding(.trailing, 10)
        .onChange(of: selectedSlideType) { _, _ in
            resetResult()
            updateImageForFieldChange()
        }
        .onChange(of: selectedSlide) { _, _ in
            resetResult()
        }
    }
    
    private var openingWidthInput: some View {
        inputFieldRow(
            title: "OPENING WIDTH:",
            text: $cabinetOpeningWidth,
            field: .openingWidth,
            placeholder: "0.0",
            isValid: true,
            onSubmit: { }
        )
    }
    
    private var materialThicknessInput: some View {
        inputFieldRow(
            title: "SIDES THICKNESS:",
            text: $drawerSideMaterialThickness,
            field: .materialThickness,
            placeholder: "0.0",
            isValid: thicknessValidationMessage == nil,
            onSubmit: { }
        )
    }
    
    private func inputFieldRow(
        title: String,
        text: Binding<String>,
        field: Field,
        placeholder: String,
        isValid: Bool,
        onSubmit: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
                .font(Typography.body)
                .foregroundColor(Constants.lightGrayColor)
                .lineLimit(1)
                .minimumScaleFactor(1)
            
            Spacer()
            
            HStack(spacing: 2) {
                Text(text.wrappedValue.isEmpty ? placeholder : text.wrappedValue)
                
                Text(isMetric ? "mm" : "\"")
                    .foregroundColor(isValid ? .gray : .red.opacity(0.7))
                    .font(Typography.footnote)
                    .padding(.top, isMetric ? 4 : -2)
            }
            .font(Typography.body)
            .foregroundColor(isValid ? (focusedField == field ? Constants.appTintColor : .white) : .red.opacity(0.7))
            .frame(width: 80, alignment: .trailing)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
//            .background(Constants.inputBackgroundColor)
            .cornerRadius(Constants.cornerRadius)
//            .overlay(
//                RoundedRectangle(cornerRadius: Constants.cornerRadius)
//                    .stroke(focusedField == field ? Constants.appTintColor : (isValid ? Color.clear : Color.red.opacity(0.5)), lineWidth: focusedField == field ? 2 : 1)
//            )
            .onTapGesture {
                print("Field tapped: \(field)")
                resetResult()  // Clear result when field is tapped
                focusedField = field
                print("Focused field is now: \(String(describing: focusedField))")
            }
        }
        .padding(.horizontal)
        .onChange(of: text.wrappedValue) {
            resetResult()
            onSubmit()
        }
    }
    
    private var animatedButton: some View {
        Button(action: {
            if showResult {
                // Reset action
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showResult = false
                    calculatedWidth = nil
                    currentImage = appropriateImage
                }
            } else {
                // Calculate action
                focusedField = nil
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentImage = ImageAsset.drawerWidthImage(for: selectedSlideType)
                    calculateDrawerWidth()
                }
            }
        }) {
            Group {
                if showResult {
                    // Reset button icon
                    Image(systemName: "arrow.counterclockwise")
                        .font(Typography.body)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                } else {
                    // Calculate text
                    Text("Calculate")
                        .font(Typography.headline)
                        .foregroundColor(canCalculate ? Constants.lightGrayColor : Color.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showResult)
        }
        .frame(width: showResult ? 50 : nil)
        .frame(height: 50)
        .background(showResult || canCalculate ? Constants.appTintColor : Color.gray.opacity(0.5))
        .cornerRadius(showResult ? 25 : 10)
        .disabled(!showResult && !canCalculate)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showResult)
    }
}

#Preview("iPhone 17 Pro", traits: .fixedLayout(width: 393, height: 852)) {
    ContentView()
}

