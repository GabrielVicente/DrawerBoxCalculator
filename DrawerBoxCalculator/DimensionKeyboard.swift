//
//  DimensionKeyboard.swift
//  DrawerBoxCalculator
//
//  Created by Gabriel Vicente on 9/18/25.
//

import SwiftUI

struct DimensionKeyboard: View {
    @Binding var text: String
    @Binding var isMetric: Bool
    @Binding var focusedField: Field?
    
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    private let buttonHeight: CGFloat = 55
    private let spacing: CGFloat = 0.5  // Thin separator width
    
    var body: some View {
        VStack(spacing: 0) {
            // Number pad with separators
            VStack(spacing: 0) {
                // Row 1: 1, 2, 3
                HStack(spacing: 0) {
                    numberButton("1")
                    Divider().background(Color.gray.opacity(0.3))
                    numberButton("2")
                    Divider().background(Color.gray.opacity(0.3))
                    numberButton("3")
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                // Row 2: 4, 5, 6
                HStack(spacing: 0) {
                    numberButton("4")
                    Divider().background(Color.gray.opacity(0.3))
                    numberButton("5")
                    Divider().background(Color.gray.opacity(0.3))
                    numberButton("6")
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                // Row 3: 7, 8, 9
                HStack(spacing: 0) {
                    numberButton("7")
                    Divider().background(Color.gray.opacity(0.3))
                    numberButton("8")
                    Divider().background(Color.gray.opacity(0.3))
                    numberButton("9")
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                // Row 4: -, 0, /
                HStack(spacing: 0) {
                    // Minus/dash button for fractions
                    fractionButton("-")
                    
                    Divider().background(Color.gray.opacity(0.3))
                    numberButton("0")
                    Divider().background(Color.gray.opacity(0.3))
                    
                    // Forward slash button for fractions
                    fractionButton("/")
                }
                
                Divider().background(Color.gray.opacity(0.3))
                
                // Row 5: Unit toggle, decimal, backspace
                HStack(spacing: 0) {
                    // Unit toggle button
                    Button(action: toggleUnit) {
                        Text(isMetric ? "mm" : "in")
                            .font(Typography.caption)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: buttonHeight)
//                            .background(Constants.inputBackgroundColor)
                    }
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    // Decimal button
                    Button(action: { addCharacter(".") }) {
                        Text(".")
                            .font(Typography.body)
                            .foregroundColor(canAddDecimal ? .white : .gray)
                            .frame(maxWidth: .infinity, maxHeight: buttonHeight)
//                            .background(Constants.inputBackgroundColor)
                    }
                    .disabled(!canAddDecimal)
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    // Backspace button
                    Button(action: backspace) {
                        Image(systemName: "delete.left")
                            .font(Typography.caption)
                            .foregroundColor(text.isEmpty ? .gray : .white)
                            .frame(maxWidth: .infinity, maxHeight: buttonHeight)
//                            .background(Constants.inputBackgroundColor)
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
        .padding(10)
        .clipShape(RoundedRectangle(cornerRadius: 10))  // Clip content with padding
        .padding(2)  // Small inner padding for border
        .background(
            Color(red: 0x2C/255.0, green: 0x2C/255.0, blue: 0x2E/255.0)
        )
        .clipShape(KeyboardShape())  // Clip entire panel to keyboard shape
        .overlay(
            KeyboardShape()
                .stroke(Constants.backgroundColor, lineWidth: 2)
        )
        .padding(.horizontal, 8) // Offset from screen edges
        .padding(.bottom, 8) // Matching offset from bottom
        .ignoresSafeArea(.keyboard) // Ignore keyboard safe area
        .ignoresSafeArea(.container, edges: .bottom) // Ignore bottom safe area\
        
    }
    
    // MARK: - Helper Views
    
    private func numberButton(_ number: String) -> some View {
        Button(action: { addCharacter(number) }) {
            Text(number)
                .font(Typography.buttonText)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: buttonHeight)
//                .background(Constants.inputBackgroundColor)
        }
    }
    
    private func fractionButton(_ symbol: String) -> some View {
        Button(action: { addCharacter(symbol) }) {
            Text(symbol)
                .font(Typography.body)
                .foregroundColor(isMetric ? .gray.opacity(0.3) : (canAddFractionSymbol(symbol) ? .white : .gray))
                .frame(maxWidth: .infinity, maxHeight: buttonHeight)
//                .background(Constants.inputBackgroundColor)
        }
        .disabled(isMetric || !canAddFractionSymbol(symbol))
    }
    
    // MARK: - Computed Properties
    
    private var canAddDecimal: Bool {
        if isMetric {
            return !text.contains(".")  // In metric, only prevent multiple decimals
        } else {
            // In imperial, prevent decimal if already has decimal, dash, or slash
            return !text.contains(".") && !text.contains("/") && !text.contains("-")
        }
    }
    
    private func canAddFractionSymbol(_ symbol: String) -> Bool {
        if isMetric { return false }
        if text.isEmpty { return false }
        if text.contains(".") { return false }
        
        if symbol == "-" {
            // Can add dash if no dash or slash exists yet
            return !text.contains("-") && !text.contains("/")
        } else if symbol == "/" {
            // Can add slash if:
            // 1. No slash exists yet AND
            // 2. Either has a dash (for mixed fractions like 1-1/2) OR no dash (for simple fractions like 1/2)
            return !text.contains("/")
        }
        
        return false
    }
    
    // MARK: - Actions
    
    private func addCharacter(_ char: String) {
        impactFeedback.impactOccurred()
        text.append(char)
        print("Added character '\(char)' to field: \(String(describing: focusedField)), new text: \(text)")
    }
    
    private func backspace() {
        impactFeedback.impactOccurred()
        if !text.isEmpty {
            text.removeLast()
        }
    }
    
    private func toggleUnit() {
        impactFeedback.impactOccurred()
        // The actual conversion is handled in ContentView via onChange of isMetric
        // This just toggles the unit and the ContentView will handle converting all fields
        isMetric.toggle()
    }
    
    private func dismissKeyboard() {
        impactFeedback.impactOccurred()
        // Keep the field focused, just a tap feedback
        // In an always-visible keyboard, Done doesn't actually dismiss
    }
}

// MARK: - View Extension for Custom Corner Radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct KeyboardShape: Shape {
    let topRadius: CGFloat = 20
    let bottomRadius: CGFloat = 58  // Matches device corner radius
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start from top-left corner
        path.move(to: CGPoint(x: rect.minX + topRadius, y: rect.minY))
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - topRadius, y: rect.minY))
        
        // Top-right corner
        path.addArc(center: CGPoint(x: rect.maxX - topRadius, y: rect.minY + topRadius),
                    radius: topRadius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(0),
                    clockwise: false)
        
        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRadius))
        
        // Bottom-right corner
        path.addArc(center: CGPoint(x: rect.maxX - bottomRadius, y: rect.maxY - bottomRadius),
                    radius: bottomRadius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false)
        
        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY))
        
        // Bottom-left corner
        path.addArc(center: CGPoint(x: rect.minX + bottomRadius, y: rect.maxY - bottomRadius),
                    radius: bottomRadius,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false)
        
        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topRadius))
        
        // Top-left corner
        path.addArc(center: CGPoint(x: rect.minX + topRadius, y: rect.minY + topRadius),
                    radius: topRadius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)
        
        path.closeSubpath()
        return path
    }
}

#Preview("DimensionKeyboard - Imperial") {
    struct PreviewWrapper: View {
        @State private var text = "24"
        @State private var isMetric = false
        @State private var focusedField: Field? = .openingWidth
        
        var body: some View {
            DimensionKeyboard(
                text: $text,
                isMetric: $isMetric,
                focusedField: $focusedField
            )
        }
    }
    
    return PreviewWrapper()
}

#Preview("DimensionKeyboard - Metric") {
    struct PreviewWrapper: View {
        @State private var text = "610"
        @State private var isMetric = true
        @State private var focusedField: Field? = .materialThickness
        
        var body: some View {
            VStack {
                // Display current value
                Text("Current value: \(text) mm")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                
                Spacer()
                
                // Keyboard
                DimensionKeyboard(
                    text: $text,
                    isMetric: $isMetric,
                    focusedField: $focusedField
                )
            }
            .background(Constants.backgroundColor)
        }
    }
    
    return PreviewWrapper()
}

// MARK: - Custom TextField with Dimension Keyboard
struct DimensionTextField: View {
    @Binding var text: String
    @Binding var isMetric: Bool
    let field: Field
    @Binding var focusedField: Field?
    let placeholder: String
    let isValid: Bool
    let onSubmit: () -> Void
    
    @State private var showKeyboard = false
    
    var body: some View {
        TextField(placeholder, text: $text)
            .multilineTextAlignment(.trailing)
            .frame(width: 80)
            .inputFieldStyle()
            .overlay(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .stroke(isValid ? Color.clear : Color.red.opacity(0.5), lineWidth: 1)
            )
            .onTapGesture {
                focusedField = field
                showKeyboard = true
            }
            .onChange(of: text) { _ in
                onSubmit()
            }
            .disabled(true) // Disable system keyboard
            .allowsHitTesting(true)
    }
}
