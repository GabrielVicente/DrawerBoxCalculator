//
//  AppConfig.swift
//  DrawerBoxCalculator
//
//  Created by Gabriel Vicente on 9/22/25.
//

import Foundation

struct AppConfig {
    // MARK: - Server Configuration
    // Using GitHub raw content URLs to serve JSON files directly
    
    #if DEBUG
    // For development, you can use a local server for testing
    // static let baseURL = "http://localhost:3000/api/hardware"
    static let baseURL = "https://raw.githubusercontent.com/GabrielVicente/DrawerBoxCalculator/main"
    #else
    static let baseURL = "https://raw.githubusercontent.com/GabrielVicente/DrawerBoxCalculator/main"
    #endif
    
    // MARK: - API Endpoints
    static let hardwareDataEndpoint = "/server_data.json"
    static let versionCheckEndpoint = "/version.json"
    
    // Full URLs
    static let hardwareDataURL = baseURL + hardwareDataEndpoint
    static let versionCheckURL = baseURL + versionCheckEndpoint
    
    // MARK: - Cache Configuration
    static let cacheFileName = "cached_hardware_data.json"
    static let cacheExpirationHours = 24 // Cache expires after 24 hours
    
    // MARK: - UserDefaults Keys
    static let versionKey = "hardware_data_version"
    static let lastUpdateKey = "hardware_data_last_update"
    static let lastCheckKey = "hardware_data_last_check"
    
    // MARK: - Network Configuration
    static let requestTimeoutInterval: TimeInterval = 30.0
    static let maxRetryAttempts = 3
    
    // MARK: - Feature Flags
    static let enableAutoUpdateCheck = true
    static let enableBackgroundRefresh = false // Set to true if you implement background app refresh
}

// MARK: - Server Response Models
struct ServerVersionResponse: Codable {
    let version: String
    let lastUpdated: String
    let minAppVersion: String? // Optional: minimum app version required
    let forceUpdate: Bool? // Optional: force update flag
}

struct ServerErrorResponse: Codable {
    let error: String
    let message: String
    let code: Int?
}