//
//  DrawerBoxCalculatorApp.swift
//  DrawerBoxCalculator
//
//  Created by Gabriel Vicente on 9/17/25.
//

import SwiftUI

@main
struct DrawerBoxCalculatorApp: App {
    init() {
        // Initialize analytics
        _ = AnalyticsManager.shared
        // Configure navigation bar title font globally
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Constants.backgroundColor)
        
        // Get the design system from Typography
        let designSystem = Typography.designSystem
        let fontDesign: UIFontDescriptor.SystemDesign = {
            switch designSystem {
            case .rounded: return .rounded
            case .monospaced: return .monospaced
            case .serif: return .serif
            default: return .default
            }
        }()
        
        // Set large title font with design system
        if let descriptor = UIFont.systemFont(ofSize: 34, weight: .bold)
            .fontDescriptor
            .withDesign(fontDesign) {
            appearance.largeTitleTextAttributes = [
                .font: UIFont(descriptor: descriptor, size: 34),
                .foregroundColor: UIColor.white
            ]
        }
        
        // Set inline title font with design system (matches Typography.headline)
        if let descriptor = UIFont.systemFont(ofSize: 17, weight: .semibold)
            .fontDescriptor
            .withDesign(fontDesign) {
            appearance.titleTextAttributes = [
                .font: UIFont(descriptor: descriptor, size: 17),
                .foregroundColor: UIColor.white
            ]
        }
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .tint(Constants.appTintColor)
                .font(Typography.body)  // Set global default font
                .environment(\.globalFont, Typography.body)  // Also set via environment
        }
    }
}
