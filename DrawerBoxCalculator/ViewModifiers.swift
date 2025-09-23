//
//  ViewModifiers.swift
//  DrawerBoxCalculator
//
//  Created by Gabriel Vicente on 9/17/25.
//

import SwiftUI

// MARK: - Input Field Modifier
struct InputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(PlainTextFieldStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Constants.inputBackgroundColor)
            .cornerRadius(Constants.cornerRadius)
            .foregroundColor(.white)
            .keyboardType(.decimalPad)
            .font(.system(size: 15))
    }
}

// MARK: - View Extensions
extension View {
    func inputFieldStyle() -> some View {
        modifier(InputFieldModifier())
    }
}