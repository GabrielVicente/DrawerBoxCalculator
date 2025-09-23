//
//  Typography.swift
//  DrawerBoxCalculator
//
//  Created by Agent on 9/18/25.
//

import SwiftUI

// MARK: - Typography System
struct Typography {
    // Define your global font family here
    static let fontFamily = "System" // Change to "Helvetica Neue", "SF Pro", etc.
    static let designSystem: Font.Design = .monospaced // .rounded, .monospaced, or .serif
    
    // Define semantic font styles
    static let largeTitle = Font.system(size: 34, weight: .bold, design: designSystem)
    static let title = Font.system(size: 28, weight: .bold, design: designSystem)
    static let title2 = Font.system(size: 22, weight: .bold, design: designSystem)
    static let title3 = Font.system(size: 20, weight: .semibold, design: designSystem)
    static let headline = Font.system(size: 17, weight: .semibold, design: designSystem)
    static let body = Font.system(size: 15, weight: .regular, design: designSystem)
    static let bodyBold = Font.system(size: 15, weight: .bold, design: designSystem)
    static let callout = Font.system(size: 16, weight: .regular, design: designSystem)
    static let subheadline = Font.system(size: 15, weight: .regular, design: designSystem)
    static let footnote = Font.system(size: 13, weight: .regular, design: designSystem)
    static let caption = Font.system(size: 12, weight: .regular, design: designSystem)
    static let caption2 = Font.system(size: 11, weight: .regular, design: designSystem)
    
    // Custom semantic styles for your app
    static let inputText = Font.system(size: 18, weight: .regular, design: designSystem)
    static let buttonText = Font.system(size: 17, weight: .medium, design: designSystem)
    static let labelText = Font.system(size: 15, weight: .regular, design: designSystem)
    static let resultText = Font.system(size: 18, weight: .bold, design: designSystem)
}

// MARK: - Custom Font Modifier
extension View {
    func appFont(_ style: Font = Typography.body) -> some View {
        self.font(style)
    }
}

// MARK: - Global Font Environment Key
struct GlobalFontKey: EnvironmentKey {
    static let defaultValue: Font = Typography.body
}

extension EnvironmentValues {
    var globalFont: Font {
        get { self[GlobalFontKey.self] }
        set { self[GlobalFontKey.self] = newValue }
    }
}

// MARK: - Custom Font Styles for Specific Use Cases
extension Font {
    static func appFont(_ textStyle: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        return .system(textStyle, design: Typography.designSystem, weight: weight)
    }
    
    static func customAppFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if Typography.fontFamily == "System" {
            return .system(size: size, weight: weight, design: Typography.designSystem)
        } else {
            return .custom(Typography.fontFamily, size: size)
                .weight(weight)
        }
    }
}
