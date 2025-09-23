//
//  Constants.swift
//  DrawerBoxCalculator
//
//  Created by Gabriel Vicente on 9/17/25.
//

import SwiftUI

struct Constants {
    // MARK: - Measurements
    static let inchesToMM: Double = 25.4
    
    // MARK: - Colors
    static let backgroundColor = Color(red: 0x1E/255.0, green: 0x1E/255.0, blue: 0x1E/255.0)
    static let inputBackgroundColor = Color.gray.opacity(0.1)
    static let appTintColor = Color(red: 0xB3/255.0, green: 0x61/255.0, blue: 0x22/255.0)  // Burnt orange/terracotta #B36122
    static let lightGrayColor = Color(red: 0xE1/255.0, green: 0xE1/255.0, blue: 0xE1/255.0)  // Light gray #E1E1E1
    // MARK: - Layout
    static let cornerRadius: CGFloat = 8
    static let buttonCornerRadius: CGFloat = 25
    static let standardSpacing: CGFloat = 15
    static let smallSpacing: CGFloat = 8
    static let resultOverlayHorizontalPadding: CGFloat = 20
    static let resultOverlayVerticalPadding: CGFloat = 12
    static let inputFieldPadding: CGFloat = 5
    static let maxImageHeight: CGFloat = 250

    
    // MARK: - Typography
    static let resultFontSize: CGFloat = 16
    static let resultMetricFontSize: CGFloat = 12
}
