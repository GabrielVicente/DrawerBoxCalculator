//
//  Models.swift
//  DrawerBoxCalculator
//
//  Created by Gabriel Vicente on 9/17/25.
//

import Foundation

// MARK: - Slide Type
enum SlideType: String, CaseIterable, Codable {
    case undermount = "Undermount"
    case sidemount = "Sidemount"
    
    var requiresMaterialThickness: Bool {
        self == .undermount
    }
}

// MARK: - Drawer Slide Model
struct DrawerSlide: Identifiable, Hashable, Codable {
    let id: UUID
    let line: String
    let partNumber: String
    let type: SlideType
    let manufacturer: String
    let standardDeductionMM: Double // in millimeters (will be applied on each side)
    let maxMaterialThicknessMM: Double // in millimeters
    let isCustom: Bool // Track if this is a user-created slide
    
    // Provide a default initializer for built-in slides
    init(line: String, partNumber: String, type: SlideType, manufacturer: String, 
         standardDeductionMM: Double, maxMaterialThicknessMM: Double, isCustom: Bool = false) {
        self.id = UUID()
        self.line = line
        self.partNumber = partNumber
        self.type = type
        self.manufacturer = manufacturer
        self.standardDeductionMM = standardDeductionMM
        self.maxMaterialThicknessMM = maxMaterialThicknessMM
        self.isCustom = isCustom
    }
    
    // Custom decoder for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        line = try container.decode(String.self, forKey: .line)
        partNumber = try container.decode(String.self, forKey: .partNumber)
        type = try container.decode(SlideType.self, forKey: .type)
        manufacturer = try container.decode(String.self, forKey: .manufacturer)
        standardDeductionMM = try container.decode(Double.self, forKey: .standardDeductionMM)
        maxMaterialThicknessMM = try container.decode(Double.self, forKey: .maxMaterialThicknessMM)
        // Default to true for custom slides if the field doesn't exist (backward compatibility)
        isCustom = try container.decodeIfPresent(Bool.self, forKey: .isCustom) ?? true
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, line, partNumber, type, manufacturer
        case standardDeductionMM, maxMaterialThicknessMM, isCustom
    }
    
    // Convert mm to inches for calculations
    var standardDeductionInches: Double {
        standardDeductionMM / Constants.inchesToMM
    }
    
    var maxMaterialThicknessInches: Double {
        maxMaterialThicknessMM / Constants.inchesToMM
    }
    
    var formattedMaxThickness: String {
        let inches = maxMaterialThicknessInches
        // Convert to common fractions for display
        if abs(inches - 0.625) < 0.01 {
            return "5/8\""
        } else if abs(inches - 0.75) < 0.01 {
            return "3/4\""
        } else if abs(inches - 0.5) < 0.01 {
            return "1/2\""
        } else if abs(inches - 1.0) < 0.01 {
            return "1\""
        } else {
            return String(format: "%.3f\"", inches)
        }
    }
    
    var formattedMaxThicknessWithMM: String {
        return "\(formattedMaxThickness) (\(Int(maxMaterialThicknessMM))mm)"
    }
    
    var formattedDeduction: String {
        return "\(Int(standardDeductionMM))mm"
    }
    
    func isCompatible(with thicknessInches: Double) -> Bool {
        thicknessInches <= maxMaterialThicknessInches
    }
    
    // Calculate drawer width based on opening and material thickness (both in inches)
    func calculateDrawerWidth(openingWidth: Double, materialThickness: Double) -> Double {
        // Formula: opening width - (deduction * 2) + (material thickness * 2)
        return openingWidth - (standardDeductionInches * 2) + (materialThickness * 2)
    }
    
    // MARK: - Default Hardware Loading with Remote Support
    private static var _loadedDefaultHardware: [SlideType: [DrawerSlide]]?
    
    static var undermountSlides: [DrawerSlide] {
        get async {
            return await defaultHardware(for: .undermount)
        }
    }
    
    static var sidemountSlides: [DrawerSlide] {
        get async {
            return await defaultHardware(for: .sidemount)
        }
    }
    
    private static func defaultHardware(for type: SlideType) async -> [DrawerSlide] {
        if _loadedDefaultHardware == nil {
            _loadedDefaultHardware = await HardwareDataManager.shared.loadHardwareData()
        }
        return _loadedDefaultHardware?[type] ?? fallbackHardware(for: type)
    }
    
    private static func loadDefaultHardwareFromPlist() -> [SlideType: [DrawerSlide]] {
        guard let path = Bundle.main.path(forResource: "DefaultHardware", ofType: "plist"),
              let data = NSDictionary(contentsOfFile: path) else {
            print("Warning: Could not load DefaultHardware.plist, falling back to hardcoded data")
            return [:]
        }
        
        var result: [SlideType: [DrawerSlide]] = [:]
        
        // Load undermount slides from nested structure: undermount -> manufacturer -> line -> [items]
        if let undermountDict = data["undermount"] as? [String: [String: [[String: Any]]]] {
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
        
        // Load sidemount slides from nested structure: sidemount -> manufacturer -> line -> [items]
        if let sidemountDict = data["sidemount"] as? [String: [String: [[String: Any]]]] {
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
    
    // Fallback hardcoded data in case plist fails to load
    private static func fallbackHardware(for type: SlideType) -> [DrawerSlide] {
        switch type {
        case .undermount:
            return [
                // Blum slides
                DrawerSlide(line: "Tandem Plus", partNumber: "563", type: .undermount, manufacturer: "Blum", 
                           standardDeductionMM: 21, maxMaterialThicknessMM: 16),
                DrawerSlide(line: "Movento", partNumber: "769", type: .undermount, manufacturer: "Blum",
                           standardDeductionMM: 21, maxMaterialThicknessMM: 19.05)
            ]
        case .sidemount:
            return [
                DrawerSlide(line: "Standard Sidemount", partNumber: "STD", type: .sidemount, manufacturer: "Generic",
                           standardDeductionMM: 12.7, maxMaterialThicknessMM: 25.4)
            ]
        }
    }
    
    static func slides(for type: SlideType) async -> [DrawerSlide] {
        let builtIn: [DrawerSlide]
        switch type {
        case .undermount:
            builtIn = await undermountSlides
        case .sidemount:
            builtIn = await sidemountSlides
        }
        return builtIn + loadCustomSlides().filter { $0.type == type }
    }
    
    // MARK: - Custom Slides Persistence
    private static let customSlidesKey = "custom_drawer_slides"
    
    static func loadCustomSlides() -> [DrawerSlide] {
        guard let data = UserDefaults.standard.data(forKey: customSlidesKey) else { return [] }
        var slides = (try? JSONDecoder().decode([DrawerSlide].self, from: data)) ?? []
        // Ensure all loaded custom slides have isCustom set to true (migration for old data)
        slides = slides.map { slide in
            if !slide.isCustom {
                return DrawerSlide(
                    line: slide.line,
                    partNumber: slide.partNumber,
                    type: slide.type,
                    manufacturer: slide.manufacturer,
                    standardDeductionMM: slide.standardDeductionMM,
                    maxMaterialThicknessMM: slide.maxMaterialThicknessMM,
                    isCustom: true
                )
            }
            return slide
        }
        return slides
    }
    
    static func saveCustomSlide(_ slide: DrawerSlide) {
        var all = loadCustomSlides()
        all.append(slide)
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: customSlidesKey)
        }
    }
    
    static func deleteCustomSlide(_ slide: DrawerSlide) {
        var all = loadCustomSlides()
        all.removeAll { $0.id == slide.id }
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: customSlidesKey)
        }
    }
    
    static func updateCustomSlide(_ updatedSlide: DrawerSlide) {
        var all = loadCustomSlides()
        if let index = all.firstIndex(where: { $0.id == updatedSlide.id }) {
            all[index] = updatedSlide
            if let data = try? JSONEncoder().encode(all) {
                UserDefaults.standard.set(data, forKey: customSlidesKey)
            }
        }
    }
    
    static func isCustomSlide(_ slide: DrawerSlide) -> Bool {
        // Simply check the isCustom flag
        return slide.isCustom
    }
    
    // MARK: - Favorites Management
    private static let favoriteSlidesKey = "favorite_drawer_slides"
    
    static func loadFavoriteIDs() -> Set<UUID> {
        guard let data = UserDefaults.standard.data(forKey: favoriteSlidesKey) else { return [] }
        return (try? JSONDecoder().decode(Set<UUID>.self, from: data)) ?? []
    }
    
    static func saveFavoriteIDs(_ ids: Set<UUID>) {
        if let data = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(data, forKey: favoriteSlidesKey)
        }
    }
    
    static func toggleFavorite(for slide: DrawerSlide) {
        var favorites = loadFavoriteIDs()
        if favorites.contains(slide.id) {
            favorites.remove(slide.id)
        } else {
            favorites.insert(slide.id)
        }
        saveFavoriteIDs(favorites)
    }
    
    static func isFavorite(_ slide: DrawerSlide) -> Bool {
        loadFavoriteIDs().contains(slide.id)
    }
}

// MARK: - Image Assets
enum ImageAsset: String {
    case undermountSlides = "Undermount Slides"
    case sidemountSlides = "Sidemount Slides"
    case openingWidthUndermount = "Opening Width - Undermount"
    case openingWidthSidemount = "Opening Width - Sidemount"
    case materialThicknessSidemount = "Material Thickness - Sidemount"
    case materialThicknessUndermount = "Material Thickness - Undermount"
    case drawerWidthSidemount = "Drawer Width - Sidemount"
    case drawerWidthUndermount = "Drawer Width - Undermount"
    
    static func slideImage(for type: SlideType) -> ImageAsset {
        type == .undermount ? .undermountSlides : .sidemountSlides
    }
    
    static func openingImage(for type: SlideType) -> ImageAsset {
        type == .undermount ? .openingWidthUndermount : .openingWidthSidemount
    }
    
    
    static func sideThicknessImage(for type: SlideType) -> ImageAsset {
        type == .undermount ? .materialThicknessUndermount : .materialThicknessSidemount
    }
    
    static func drawerWidthImage(for type: SlideType) -> ImageAsset {
        type == .undermount ? .drawerWidthUndermount : .drawerWidthSidemount
    }
}

// MARK: - Input Fields
enum Field {
    case openingWidth
    case materialThickness
}
