//
//  HardwareDataManager.swift
//  DrawerBoxCalculator
//
//  Created by Gabriel Vicente on 9/22/25.
//

import Foundation
import Network

// MARK: - Hardware Data Response Models
struct HardwareDataResponse: Codable {
    let version: String
    let lastUpdated: String
    let undermount: [String: [String: [HardwareItem]]]
    let sidemount: [String: [String: [HardwareItem]]]
}

struct HardwareItem: Codable {
    let partNumber: String
    let standardDeductionMM: Double
    let maxMaterialThicknessMM: Double
}

// MARK: - Hardware Data Manager
@MainActor
class HardwareDataManager: ObservableObject {
    static let shared = HardwareDataManager()
    
    // MARK: - Configuration
    private let dataFileName = AppConfig.cacheFileName
    private let versionKey = AppConfig.versionKey
    private let lastUpdateKey = AppConfig.lastUpdateKey
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var lastUpdateDate: Date?
    @Published var currentVersion: String = "1.0"
    @Published var hasNetworkConnection = true
    
    // MARK: - Private Properties
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var cachedHardwareData: [SlideType: [DrawerSlide]]?
    
    private init() {
        setupNetworkMonitoring()
        loadVersionInfo()
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.hasNetworkConnection = path.status == .satisfied
            }
        }
        monitor.start(queue: monitorQueue)
    }
    
    // MARK: - Public API
    func loadHardwareData() async -> [SlideType: [DrawerSlide]] {
        // Try to load from cache first
        if let cached = cachedHardwareData {
            return cached
        }
        
        // Try to load cached data from disk
        if let diskCached = loadCachedData() {
            cachedHardwareData = diskCached
            return diskCached
        }
        
        // If no cached data and we have internet, try to download
        if hasNetworkConnection {
            await downloadLatestData()
            if let downloaded = cachedHardwareData {
                return downloaded
            }
        }
        
        // Fall back to bundled plist
        let fallbackData = loadFallbackData()
        cachedHardwareData = fallbackData
        return fallbackData
    }
    
    func checkForUpdates() async {
        guard hasNetworkConnection else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let versionURL = URL(string: AppConfig.versionCheckURL)!
            let (data, _) = try await URLSession.shared.data(from: versionURL)
            
            if let versionInfo = try? JSONDecoder().decode(ServerVersionResponse.self, from: data) {
                // Check if we need to update
                if shouldUpdate(remoteVersion: versionInfo.version, remoteDate: versionInfo.lastUpdated) {
                    await downloadLatestData()
                }
            }
        } catch {
            print("Failed to check for updates: \(error.localizedDescription)")
        }
    }
    
    func forceRefresh() async {
        cachedHardwareData = nil
        await downloadLatestData()
    }
    
    // MARK: - Private Methods
    private func downloadLatestData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let dataURL = URL(string: AppConfig.hardwareDataURL)!
            let (data, response) = try await URLSession.shared.data(from: dataURL)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let hardwareResponse = try JSONDecoder().decode(HardwareDataResponse.self, from: data)
            let processedData = processHardwareResponse(hardwareResponse)
            
            // Cache the data
            cachedHardwareData = processedData
            saveCachedData(data)
            saveVersionInfo(version: hardwareResponse.version, lastUpdated: hardwareResponse.lastUpdated)
            
            print("Successfully downloaded hardware data version \(hardwareResponse.version)")
            
        } catch {
            print("Failed to download hardware data: \(error.localizedDescription)")
        }
    }
    
    private func processHardwareResponse(_ response: HardwareDataResponse) -> [SlideType: [DrawerSlide]] {
        var result: [SlideType: [DrawerSlide]] = [:]
        
        // Process undermount slides
        var undermountSlides: [DrawerSlide] = []
        for (manufacturer, manufacturerDict) in response.undermount {
            for (line, itemsArray) in manufacturerDict {
                for item in itemsArray {
                    let slide = DrawerSlide(
                        line: line,
                        partNumber: item.partNumber,
                        type: .undermount,
                        manufacturer: manufacturer,
                        standardDeductionMM: item.standardDeductionMM,
                        maxMaterialThicknessMM: item.maxMaterialThicknessMM,
                        isCustom: false
                    )
                    undermountSlides.append(slide)
                }
            }
        }
        result[.undermount] = undermountSlides
        
        // Process sidemount slides
        var sidemountSlides: [DrawerSlide] = []
        for (manufacturer, manufacturerDict) in response.sidemount {
            for (line, itemsArray) in manufacturerDict {
                for item in itemsArray {
                    let slide = DrawerSlide(
                        line: line,
                        partNumber: item.partNumber,
                        type: .sidemount,
                        manufacturer: manufacturer,
                        standardDeductionMM: item.standardDeductionMM,
                        maxMaterialThicknessMM: item.maxMaterialThicknessMM,
                        isCustom: false
                    )
                    sidemountSlides.append(slide)
                }
            }
        }
        result[.sidemount] = sidemountSlides
        
        return result
    }
    
    private func loadCachedData() -> [SlideType: [DrawerSlide]]? {
        guard let url = getCacheFileURL(),
              let data = try? Data(contentsOf: url),
              let response = try? JSONDecoder().decode(HardwareDataResponse.self, from: data) else {
            return nil
        }
        
        return processHardwareResponse(response)
    }
    
    private func saveCachedData(_ data: Data) {
        guard let url = getCacheFileURL() else { return }
        
        do {
            try data.write(to: url)
        } catch {
            print("Failed to save cached data: \(error.localizedDescription)")
        }
    }
    
    private func getCacheFileURL() -> URL? {
        return FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(dataFileName)
    }
    
    private func loadFallbackData() -> [SlideType: [DrawerSlide]] {
        // This uses your existing plist loading logic as fallback
        return DrawerSlide.loadDefaultHardwareFromPlistFallback()
    }
    
    private func shouldUpdate(remoteVersion: String, remoteDate: String) -> Bool {
        let currentVersion = UserDefaults.standard.string(forKey: versionKey) ?? "0.0"
        let currentDate = UserDefaults.standard.string(forKey: lastUpdateKey) ?? ""
        
        // Simple version comparison (you might want to use semantic versioning)
        return remoteVersion != currentVersion || remoteDate != currentDate
    }
    
    private func saveVersionInfo(version: String, lastUpdated: String) {
        UserDefaults.standard.set(version, forKey: versionKey)
        UserDefaults.standard.set(lastUpdated, forKey: lastUpdateKey)
        
        currentVersion = version
        
        let formatter = ISO8601DateFormatter()
        lastUpdateDate = formatter.date(from: lastUpdated)
    }
    
    private func loadVersionInfo() {
        currentVersion = UserDefaults.standard.string(forKey: versionKey) ?? "1.0"
        
        if let lastUpdatedString = UserDefaults.standard.string(forKey: lastUpdateKey) {
            let formatter = ISO8601DateFormatter()
            lastUpdateDate = formatter.date(from: lastUpdatedString)
        }
    }
}

// MARK: - DrawerSlide Extension for Fallback
extension DrawerSlide {
    static func loadDefaultHardwareFromPlistFallback() -> [SlideType: [DrawerSlide]] {
        guard let path = Bundle.main.path(forResource: "DefaultHardware", ofType: "plist"),
              let data = NSDictionary(contentsOfFile: path) else {
            print("Warning: Could not load DefaultHardware.plist, using hardcoded fallback")
            return [
                .undermount: [
                    DrawerSlide(line: "Tandem Plus", partNumber: "563", type: .undermount, 
                               manufacturer: "Blum", standardDeductionMM: 21, maxMaterialThicknessMM: 16)
                ],
                .sidemount: [
                    DrawerSlide(line: "Standard Sidemount", partNumber: "STD", type: .sidemount,
                               manufacturer: "Generic", standardDeductionMM: 12.7, maxMaterialThicknessMM: 25.4)
                ]
            ]
        }
        
        var result: [SlideType: [DrawerSlide]] = [:]
        
        // Load undermount slides from nested structure
        if let undermountDict = data["undermount"] as? [String: [String: [String: [[String: Any]]]]] {
            var undermountSlides: [DrawerSlide] = []
            
            for (manufacturer, manufacturerDict) in undermountDict {
                for (line, itemsArray) in manufacturerDict {
                    for itemDict in itemsArray {
                        guard let partNumber = itemDict["partNumber"] as? String,
                              let standardDeductionMM = itemDict["standardDeductionMM"] as? Double,
                              let maxMaterialThicknessMM = itemDict["maxMaterialThicknessMM"] as? Double else {
                            continue
                        }
                        
                        let slide = DrawerSlide(
                            line: line,
                            partNumber: partNumber,
                            type: .undermount,
                            manufacturer: manufacturer,
                            standardDeductionMM: standardDeductionMM,
                            maxMaterialThicknessMM: maxMaterialThicknessMM,
                            isCustom: false
                        )
                        undermountSlides.append(slide)
                    }
                }
            }
            result[.undermount] = undermountSlides
        }
        
        // Load sidemount slides from nested structure
        if let sidemountDict = data["sidemount"] as? [String: [String: [String: [[String: Any]]]]] {
            var sidemountSlides: [DrawerSlide] = []
            
            for (manufacturer, manufacturerDict) in sidemountDict {
                for (line, itemsArray) in manufacturerDict {
                    for itemDict in itemsArray {
                        guard let partNumber = itemDict["partNumber"] as? String,
                              let standardDeductionMM = itemDict["standardDeductionMM"] as? Double,
                              let maxMaterialThicknessMM = itemDict["maxMaterialThicknessMM"] as? Double else {
                            continue
                        }
                        
                        let slide = DrawerSlide(
                            line: line,
                            partNumber: partNumber,
                            type: .sidemount,
                            manufacturer: manufacturer,
                            standardDeductionMM: standardDeductionMM,
                            maxMaterialThicknessMM: maxMaterialThicknessMM,
                            isCustom: false
                        )
                        sidemountSlides.append(slide)
                    }
                }
            }
            result[.sidemount] = sidemountSlides
        }
        
        return result
    }
}