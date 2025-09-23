//
//  EditCustomSlideFormView.swift
//  DrawerBoxCalculator
//
//  Created by Agent on 9/21/25.
//

import SwiftUI

struct EditCustomSlideFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var line: String
    @State private var partNumber: String
    @State private var manufacturer: String
    @State private var type: SlideType
    @State private var standardDeduction: String
    @State private var maxMaterialThickness: String
    @State private var deductionUnit: DimensionUnit = .millimeters
    @State private var thicknessUnit: DimensionUnit = .millimeters
    @State private var showManufacturerSuggestions = false
    @State private var showProductLineSuggestions = false
    @State private var selectedManufacturer: String? = nil
    @State private var selectedProductLine: String? = nil
    @FocusState private var focusedField: Field?
    
    let slideToEdit: DrawerSlide
    let onSave: (DrawerSlide) -> Void
    
    init(slideToEdit: DrawerSlide, onSave: @escaping (DrawerSlide) -> Void) {
        self.slideToEdit = slideToEdit
        self.onSave = onSave
        
        // Initialize state with existing slide data
        _line = State(initialValue: slideToEdit.line)
        _partNumber = State(initialValue: slideToEdit.partNumber)
        _manufacturer = State(initialValue: slideToEdit.manufacturer)
        _type = State(initialValue: slideToEdit.type)
        
        // Convert from MM to display values
        _standardDeduction = State(initialValue: String(slideToEdit.standardDeductionMM))
        _maxMaterialThickness = State(initialValue: String(slideToEdit.maxMaterialThicknessMM))
    }
    
    enum Field: Hashable {
        case productLine
        case manufacturer
        case partNumber
    }
    
    enum DimensionUnit: String, CaseIterable {
        case millimeters = "mm"
        case inches = "in"
        
        func toMM(_ value: Double) -> Double {
            switch self {
            case .millimeters: return value
            case .inches: return value * Constants.inchesToMM
            }
        }
    }
    
    private var isValid: Bool {
        !line.trimmingCharacters(in: .whitespaces).isEmpty &&
        !partNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(standardDeduction) != nil &&
        (type == .sidemount || Double(maxMaterialThickness) != nil)
    }
    
    private var deductionInMM: Double {
        guard let value = Double(standardDeduction) else { return slideToEdit.standardDeductionMM }
        return deductionUnit.toMM(value)
    }
    
    private var thicknessInMM: Double {
        guard let value = Double(maxMaterialThickness) else { return slideToEdit.maxMaterialThicknessMM }
        return thicknessUnit.toMM(value)
    }
    
    // Get unique manufacturers from existing slides
    private var existingManufacturers: [String] {
        let allSlides = DrawerSlide.undermountSlides + DrawerSlide.sidemountSlides + DrawerSlide.loadCustomSlides()
        let manufacturers = Set(allSlides.map { $0.manufacturer })
        return manufacturers.sorted()
    }
    
    // Get unique product lines for selected manufacturer
    private var existingProductLines: [String] {
        let allSlides = DrawerSlide.undermountSlides + DrawerSlide.sidemountSlides + DrawerSlide.loadCustomSlides()
        
        // If no manufacturer selected, show all product lines
        if manufacturer.trimmingCharacters(in: .whitespaces).isEmpty {
            let lines = Set(allSlides.map { $0.line })
            return lines.sorted()
        }
        
        // Show product lines for the selected/typed manufacturer
        let lines = Set(allSlides
            .filter { $0.manufacturer.lowercased() == manufacturer.lowercased().trimmingCharacters(in: .whitespaces) }
            .map { $0.line })
        return lines.sorted()
    }
    
    // Filter suggestions based on input
    private var filteredManufacturers: [String] {
        if manufacturer.isEmpty {
            return existingManufacturers
        }
        return existingManufacturers.filter { 
            $0.lowercased().contains(manufacturer.lowercased())
        }
    }
    
    private var filteredProductLines: [String] {
        if line.isEmpty {
            return existingProductLines
        }
        return existingProductLines.filter { 
            $0.lowercased().contains(line.lowercased())
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details").font(Typography.subheadline)) {
                    // Manufacturer field (first)
                    VStack {
                        HStack {
                            Text("Manufacturer")
                                .font(Typography.body)
                                .foregroundColor(Constants.lightGrayColor)
                            Spacer()
                            TextField("e.g. Blum, Hettich", text: $manufacturer, onEditingChanged: { isEditing in
                                if isEditing {
                                    // Only show suggestions if user has typed something and there are matches
                                    if !manufacturer.isEmpty && selectedManufacturer != manufacturer {
                                        selectedManufacturer = nil  // Reset selection when editing
                                        showManufacturerSuggestions = !filteredManufacturers.isEmpty
                                    } else {
                                        showManufacturerSuggestions = false
                                    }
                                } else {
                                    showManufacturerSuggestions = false
                                }
                            })
                            .font(Typography.body)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.white)
                            .focused($focusedField, equals: .manufacturer)
                            .onChange(of: manufacturer) {
                                // Only show suggestions if user has typed something and is actively editing
                                if focusedField == .manufacturer && !manufacturer.isEmpty && selectedManufacturer != manufacturer {
                                    showManufacturerSuggestions = !filteredManufacturers.isEmpty
                                    selectedManufacturer = nil  // Clear selection if user types something different
                                } else if manufacturer.isEmpty {
                                    showManufacturerSuggestions = false
                                }
                                
                                // Clear product line if manufacturer changes significantly
                                if selectedManufacturer != manufacturer {
                                    let matchingManufacturer = existingManufacturers.first {
                                        $0.lowercased() == manufacturer.lowercased()
                                    }
                                    if matchingManufacturer == nil {
                                        line = "" // Clear product line for new manufacturer
                                        selectedProductLine = nil
                                    }
                                }
                            }
                        }
                        
                        if showManufacturerSuggestions && !filteredManufacturers.isEmpty {
                            VStack(alignment: .trailing, spacing: 0) {
                                ForEach(filteredManufacturers.prefix(existingManufacturers.count), id: \.self) { suggestion in
                                    HStack {
                                        Spacer()
                                        Text(suggestion)
                                            .font(Typography.bodyBold)
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .onTapGesture {
                                        manufacturer = suggestion
                                        selectedManufacturer = suggestion  // Mark as selected
                                        showManufacturerSuggestions = false
                                        focusedField = nil  // Dismiss keyboard
                                    }
                                }
                            }
                            .cornerRadius(8)
                            .padding(.top, 4)
                        }
                    }
                    
                    // Product Line field (second, depends on manufacturer)
                    VStack {
                        HStack {
                            Text("Product Line")
                                .font(Typography.body)
                                .foregroundColor(Constants.lightGrayColor)
                            Spacer()
                            TextField("e.g. TANDEM plus BLUMOTION", text: $line, onEditingChanged: { isEditing in
                                if isEditing {
                                    // Only show suggestions if user has typed something and there are matches
                                    if !line.isEmpty && selectedProductLine != line {
                                        selectedProductLine = nil
                                        showProductLineSuggestions = !filteredProductLines.isEmpty
                                    } else {
                                        showProductLineSuggestions = false
                                    }
                                } else {
                                    showProductLineSuggestions = false
                                }
                            })
                            .font(Typography.body)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.white)
                            .focused($focusedField, equals: .productLine)
                            .onChange(of: line) {
                                // Only show suggestions if user has typed something and is actively editing
                                if focusedField == .productLine && !line.isEmpty && selectedProductLine != line {
                                    showProductLineSuggestions = !filteredProductLines.isEmpty
                                    selectedProductLine = nil
                                } else if line.isEmpty {
                                    showProductLineSuggestions = false
                                }
                            }
                        }
                        
                        if showProductLineSuggestions && !filteredProductLines.isEmpty {
                            VStack(alignment: .trailing, spacing: 0) {
                                ForEach(filteredProductLines.prefix(existingProductLines.count), id: \.self) { suggestion in
                                    HStack {
                                        Spacer()
                                        Text(suggestion)
                                            .font(Typography.bodyBold)
                                            .foregroundColor(Constants.lightGrayColor)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .onTapGesture {
                                        line = suggestion
                                        selectedProductLine = suggestion  // Mark as selected
                                        showProductLineSuggestions = false
                                        focusedField = nil  // Dismiss keyboard
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    // Part Number field (third)
                    HStack {
                        Text("Part Number")
                            .font(Typography.body)
                            .foregroundColor(Constants.lightGrayColor)
                        Spacer()
                        TextField("e.g. 563H", text: $partNumber)
                            .font(Typography.body)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.white)
                            .focused($focusedField, equals: .partNumber)
                            .textCase(.uppercase)
                            .onChange(of: partNumber) {
                                partNumber = partNumber.uppercased()
                            }
                    }
                    
                    // Type field
                    HStack {
                        Text("Type")
                            .font(Typography.body)
                            .foregroundColor(Constants.lightGrayColor)
                        Spacer()
                        Menu {
                            ForEach(SlideType.allCases, id: \.self) { slideType in
                                Button(action: {
                                    type = slideType
                                }) {
                                    Text(slideType.rawValue)
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(type.rawValue)
                                    .font(Typography.body)
                                    .foregroundColor(.white)
                                    .frame(minWidth: 80, alignment: .leading)
                                Image(systemName: "chevron.down")
                                    .font(Typography.caption2)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Constants.inputBackgroundColor)
                            .cornerRadius(8)
                        }
                        .fixedSize()
                    }
                }
                
                Section(header: Text("Specifications").font(Typography.subheadline)) {
                    HStack {
                        Text("Deduction per side")
                            .font(Typography.body)
                            .foregroundColor(Constants.lightGrayColor)
                        Spacer()
                        HStack(spacing: 8) {
                            TextField("Required", text: $standardDeduction)
                                .font(Typography.body)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.white)
                                .frame(width: 80)
                            
                            Picker("", selection: $deductionUnit) {
                                ForEach(DimensionUnit.allCases, id: \.self) { unit in
                                    Text(unit.rawValue)
                                        .tag(unit)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .font(Typography.footnote)
                            .frame(width: 80)
                        }
                    }
                    
                    // Only show max material thickness for undermount slides
                    if type == .undermount {
                        HStack {
                            Text("Max side material thickness")
                                .font(Typography.body)
                                .foregroundColor(Constants.lightGrayColor)
                            Spacer()
                            HStack(spacing: 8) {
                                TextField("Required", text: $maxMaterialThickness)
                                    .font(Typography.body)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(.white)
                                    .frame(width: 80)
                                
                                Picker("", selection: $thicknessUnit) {
                                    ForEach(DimensionUnit.allCases, id: \.self) { unit in
                                        Text(unit.rawValue)
                                            .tag(unit)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .font(Typography.footnote)
                                .frame(width: 80)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Hardware")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(Typography.body)
                        .foregroundColor(Constants.appTintColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // For sidemount slides, use a large default max thickness since it's not relevant
                        let maxThickness = type == .sidemount ? 25.4 : thicknessInMM  // 25.4mm = 1 inch default for sidemount
                        
                        let editedSlide = DrawerSlide(
                            line: line.trimmingCharacters(in: .whitespaces),
                            partNumber: partNumber.trimmingCharacters(in: .whitespaces),
                            type: type,
                            manufacturer: manufacturer.isEmpty ? "Custom" : manufacturer.trimmingCharacters(in: .whitespaces),
                            standardDeductionMM: deductionInMM,
                            maxMaterialThicknessMM: maxThickness,
                            isCustom: true
                        )
                        
                        // Create a new slide with the same ID as the original to maintain identity
                        let finalSlide = DrawerSlide(
                            id: slideToEdit.id,  // Keep the same ID
                            line: editedSlide.line,
                            partNumber: editedSlide.partNumber,
                            type: editedSlide.type,
                            manufacturer: editedSlide.manufacturer,
                            standardDeductionMM: editedSlide.standardDeductionMM,
                            maxMaterialThicknessMM: editedSlide.maxMaterialThicknessMM,
                            isCustom: true
                        )
                        
                        onSave(finalSlide)
                        dismiss()
                    }
                    .font(Typography.body)
                    .foregroundColor(isValid ? Constants.appTintColor : .gray)
                    .disabled(!isValid)
                }
            }
        }
    }
}

// Extension to support ID parameter in initializer
extension DrawerSlide {
    init(id: UUID, line: String, partNumber: String, type: SlideType, manufacturer: String, standardDeductionMM: Double, maxMaterialThicknessMM: Double, isCustom: Bool) {
        self.id = id
        self.line = line
        self.partNumber = partNumber
        self.type = type
        self.manufacturer = manufacturer
        self.standardDeductionMM = standardDeductionMM
        self.maxMaterialThicknessMM = maxMaterialThicknessMM
        self.isCustom = isCustom
    }
}