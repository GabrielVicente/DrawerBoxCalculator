//
//  AppConfig.swift
//  DrawerBoxCalculator
//
//  Created by Gabriel Vicente on 9/22/25.
//

import Foundation

struct AppConfig {
    // MARK: - Server Configuration
    // Replace these URLs with your actual server endpoints
    
    #if DEBUG
    static let baseURL = "https://your-dev-server.com/api/hardware"
    #else
    static let baseURL = "https://your-production-server.com/api/hardware"
    #endif
    
    // MARK: - API Endpoints
    static let hardwareDataEndpoint = "/data"
    static let versionCheckEndpoint = "/version"
    
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