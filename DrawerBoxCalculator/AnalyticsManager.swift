//
//  AnalyticsManager.swift
//  DrawerBoxCalculator
//
//  Created on 9/21/25.
//

import Foundation
import SwiftUI
import Mixpanel

class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    // TODO: Replace with your actual Mixpanel token
    private let mixpanelToken = "352e4ec007859bcf08f53d881bdc5a66"
    
    private init() {
        setupMixpanel()
    }
    
    private func setupMixpanel() {
        Mixpanel.initialize(token: mixpanelToken, trackAutomaticEvents: true)
        #if DEBUG
        Mixpanel.mainInstance().loggingEnabled = true // Enable for debugging
        #endif
        
        // Enable IP-based location tracking
        Mixpanel.mainInstance().useIPAddressForGeoLocation = true
        
        // Set super properties that will be sent with every event
        setSuperProperties()
        
        // Generate or retrieve anonymous user ID
        let anonymousID = getAnonymousUserID()
        Mixpanel.mainInstance().identify(distinctId: anonymousID)
        
        print("[Analytics] Initialized with ID: \(anonymousID) with location tracking enabled")
    }
    
    private func setSuperProperties() {
        let properties: [String: MixpanelType] = [
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "device_model": getDeviceModelName(),
            "ios_version": UIDevice.current.systemVersion,
            "device_type": UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        ]
        
        Mixpanel.mainInstance().registerSuperProperties(properties)
        print("[Analytics] Super properties set: \(properties)")
    }
    
    private func getDeviceModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
        
        guard let code = modelCode else { return "Unknown" }
        
        // Map device codes to readable names
        switch code {
        // iPhone models
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,6": return "iPhone SE (3rd generation)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        
        // iPad models (common ones)
        case "iPad13,1", "iPad13,2": return "iPad Air (4th generation)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th generation)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro 11-inch (5th generation)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro 12.9-inch (5th generation)"
        case "iPad14,3", "iPad14,4": return "iPad Air (5th generation)"
        case "iPad13,16", "iPad13,17": return "iPad Air (5th generation)"
        case "iPad14,5", "iPad14,6": return "iPad Pro 12.9-inch (6th generation)"
        case "iPad14,7", "iPad14,8": return "iPad Pro 11-inch (4th generation)"
        
        // Simulator
        case "x86_64", "arm64":
            if UIDevice.current.userInterfaceIdiom == .pad {
                return "iPad Simulator"
            } else {
                return "iPhone Simulator"
            }
        
        default:
            // For unknown models, return the raw code plus device type
            if UIDevice.current.userInterfaceIdiom == .pad {
                return "iPad (\(code))"
            } else {
                return "iPhone (\(code))"
            }
        }
    }
    
    private func getAnonymousUserID() -> String {
        let userDefaultsKey = "analytics_anonymous_id"
        if let existingID = UserDefaults.standard.string(forKey: userDefaultsKey) {
            return existingID
        } else {
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: userDefaultsKey)
            return newID
        }
    }
    
    // MARK: - App Lifecycle Events
    
    func trackAppLaunch() {
        track("App Launched")
    }
    
    func trackAppBackground() {
        track("App Backgrounded")
    }
    
    // MARK: - Calculator Events
    
    func trackCalculation(slideType: SlideType,
                         openingWidth: Double,
                         materialThickness: Double?,
                         calculatedWidth: Double,
                         slideName: String?,
                         slideManufacturer: String?,
                         isMetric: Bool) {
        
        var properties: [String: MixpanelType] = [
            "slide_type": slideType.rawValue,
            "opening_width_inches": openingWidth,
            "calculated_width_inches": calculatedWidth,
            "unit_system": isMetric ? "metric" : "imperial"
        ]
        
        if let thickness = materialThickness {
            properties["material_thickness_inches"] = thickness
        }
        
        if let name = slideName {
            properties["slide_name"] = name
        }
        
        if let manufacturer = slideManufacturer {
            properties["slide_manufacturer"] = manufacturer
        }
        
        track("Calculation Performed", properties: properties)
    }
    
    // MARK: - Hardware Management Events
    
    func trackHardwareSelection(slide: DrawerSlide) {
        let properties: [String: MixpanelType] = [
            "slide_type": slide.type.rawValue,
            "manufacturer": slide.manufacturer,
            "line": slide.line,
            "part_number": slide.partNumber,
            "is_custom": slide.isCustom,
            "deduction_mm": slide.standardDeductionMM,
            "max_thickness_mm": slide.maxMaterialThicknessMM
        ]
        
        track("Hardware Selected", properties: properties)
    }
    
    func trackCustomHardwareAdded(slide: DrawerSlide) {
        let properties: [String: MixpanelType] = [
            "slide_type": slide.type.rawValue,
            "manufacturer": slide.manufacturer,
            "line": slide.line,
            "part_number": slide.partNumber,
            "deduction_mm": slide.standardDeductionMM,
            "max_thickness_mm": slide.maxMaterialThicknessMM
        ]
        
        track("Custom Hardware Added", properties: properties)
        
        // Track unique manufacturers and product lines only if truly new
        trackUniqueManufacturerIfNew(slide.manufacturer)
        trackUniqueProductLineIfNew(slide.line)
    }
    
    func trackCustomHardwareDeleted(slide: DrawerSlide) {
        let properties: [String: MixpanelType] = [
            "slide_type": slide.type.rawValue,
            "manufacturer": slide.manufacturer,
            "line": slide.line
        ]
        
        track("Custom Hardware Deleted", properties: properties)
    }
    
    
    // MARK: - Filter Events
    
    func trackFilterApplied(filterType: String, value: Any) {
        let properties: [String: MixpanelType] = [
            "filter_type": filterType,
            "filter_value": String(describing: value)
        ]
        
        track("Filter Applied", properties: properties)
    }
    
    func trackFavoritesFilterToggled(enabled: Bool) {
        track("Favorites Filter Toggled", properties: ["enabled": enabled])
    }
    
    func trackUserAddedFilterToggled(enabled: Bool) {
        track("User Added Filter Toggled", properties: ["enabled": enabled])
    }
    
    // MARK: - Favorites Events
    
    func trackFavoriteToggled(slide: DrawerSlide, isFavorite: Bool) {
        let properties: [String: MixpanelType] = [
            "action": isFavorite ? "added" : "removed",
            "slide_type": slide.type.rawValue,
            "manufacturer": slide.manufacturer,
            "line": slide.line,
            "is_custom": slide.isCustom
        ]
        
        track("Favorite Toggled", properties: properties)
    }
    
    // MARK: - UI Interaction Events
    
    func trackScreenView(_ screenName: String) {
        track("Screen Viewed", properties: ["screen_name": screenName])
    }
    
    func trackHelpViewed() {
        track("Help Viewed")
    }
    
    func trackFeedbackInitiated() {
        track("Feedback Initiated")
    }
    
    func trackSlideDetailsViewed(slide: DrawerSlide) {
        let properties: [String: MixpanelType] = [
            "slide_type": slide.type.rawValue,
            "manufacturer": slide.manufacturer,
            "line": slide.line,
            "is_custom": slide.isCustom
        ]
        
        track("Slide Details Viewed", properties: properties)
    }
    
    func trackUnitSystemChanged(toMetric: Bool) {
        track("Unit System Changed", properties: ["to_metric": toMetric])
    }
    
    // MARK: - Search Events
    
    func trackManufacturerSearched(query: String, resultCount: Int) {
        let properties: [String: MixpanelType] = [
            "query": query,
            "result_count": resultCount
        ]
        
        track("Manufacturer Searched", properties: properties)
    }
    
    func trackProductLineSearched(query: String, resultCount: Int) {
        let properties: [String: MixpanelType] = [
            "query": query,
            "result_count": resultCount
        ]
        
        track("Product Line Searched", properties: properties)
    }
    
    // MARK: - Unique Value Tracking
    
    private func trackUniqueManufacturerIfNew(_ manufacturer: String) {
        // Get all existing manufacturers from built-in slides
        let builtInManufacturers = getBuiltInManufacturers()
        
        // Get previously tracked unique manufacturers from UserDefaults
        let trackedManufacturers = getTrackedUniqueManufacturers()
        
        let manufacturerTrimmed = manufacturer.trimmingCharacters(in: .whitespaces)
        
        // Only track if this manufacturer is truly new (not built-in and not previously tracked)
        if !builtInManufacturers.contains(where: { $0.lowercased() == manufacturerTrimmed.lowercased() }) &&
           !trackedManufacturers.contains(where: { $0.lowercased() == manufacturerTrimmed.lowercased() }) {
            
            // Add to tracked manufacturers
            var updated = trackedManufacturers
            updated.append(manufacturerTrimmed)
            saveTrackedUniqueManufacturers(updated)
            
            // Track the event
            trackUniqueValue("Unique Manufacturer Used", value: manufacturerTrimmed)
            
            print("[Analytics] Tracking new unique manufacturer: \(manufacturerTrimmed)")
        }
    }
    
    private func trackUniqueProductLineIfNew(_ productLine: String) {
        // Get all existing product lines from built-in slides
        let builtInProductLines = getBuiltInProductLines()
        
        // Get previously tracked unique product lines from UserDefaults
        let trackedProductLines = getTrackedUniqueProductLines()
        
        let productLineTrimmed = productLine.trimmingCharacters(in: .whitespaces)
        
        // Only track if this product line is truly new (not built-in and not previously tracked)
        if !builtInProductLines.contains(where: { $0.lowercased() == productLineTrimmed.lowercased() }) &&
           !trackedProductLines.contains(where: { $0.lowercased() == productLineTrimmed.lowercased() }) {
            
            // Add to tracked product lines
            var updated = trackedProductLines
            updated.append(productLineTrimmed)
            saveTrackedUniqueProductLines(updated)
            
            // Track the event
            trackUniqueValue("Unique Product Line Used", value: productLineTrimmed)
            
            print("[Analytics] Tracking new unique product line: \(productLineTrimmed)")
        }
    }
    
    // MARK: - Helper Methods for Built-in Data
    
    private func getBuiltInManufacturers() -> [String] {
        let allBuiltInSlides = DrawerSlide.undermountSlides + DrawerSlide.sidemountSlides
        return Array(Set(allBuiltInSlides.map { $0.manufacturer }))
    }
    
    private func getBuiltInProductLines() -> [String] {
        let allBuiltInSlides = DrawerSlide.undermountSlides + DrawerSlide.sidemountSlides
        return Array(Set(allBuiltInSlides.map { $0.line }))
    }
    
    // MARK: - UserDefaults for Tracking Previously Added Unique Values
    
    private func getTrackedUniqueManufacturers() -> [String] {
        return UserDefaults.standard.stringArray(forKey: "tracked_unique_manufacturers") ?? []
    }
    
    private func saveTrackedUniqueManufacturers(_ manufacturers: [String]) {
        UserDefaults.standard.set(manufacturers, forKey: "tracked_unique_manufacturers")
    }
    
    private func getTrackedUniqueProductLines() -> [String] {
        return UserDefaults.standard.stringArray(forKey: "tracked_unique_product_lines") ?? []
    }
    
    private func saveTrackedUniqueProductLines(_ productLines: [String]) {
        UserDefaults.standard.set(productLines, forKey: "tracked_unique_product_lines")
    }
    
    // MARK: - Core Tracking Methods
    
    private func track(_ eventName: String, properties: [String: MixpanelType] = [:]) {
        Mixpanel.mainInstance().track(event: eventName, properties: properties)
        
        #if DEBUG
        print("[Analytics] Event: \(eventName)")
        if !properties.isEmpty {
            print("[Analytics] Properties: \(properties)")
        }
        #endif
    }
    
    private func trackUniqueValue(_ eventName: String, value: String) {
        // This creates a unique user property that Mixpanel can use to track unique values
        let propertyKey = "unique_\(eventName.lowercased().replacingOccurrences(of: " ", with: "_"))"
        Mixpanel.mainInstance().people.union(properties: [propertyKey: [value]])
        
        track(eventName, properties: ["value": value])
    }
    
    func setUserProperty(_ property: String, value: MixpanelType) {
        Mixpanel.mainInstance().people.set(property: property, to: value)
        
        #if DEBUG
        print("[Analytics] User property set: \(property) = \(value)")
        #endif
    }
    
    func incrementUserProperty(_ property: String, by amount: Double = 1) {
        Mixpanel.mainInstance().people.increment(property: property, by: amount)
        
        #if DEBUG
        print("[Analytics] User property incremented: \(property) by \(amount)")
        #endif
    }
}




