//
//  SlideSelectionView.swift
//  DrawerBoxCalculator
//
//  Created by Gabriel Vicente on 9/17/25.
//

import SwiftUI

// MARK: - Wrapper View with Persistent Filters
struct SlideSelectionViewWithFilters: View {
    @Binding var selectedSlide: DrawerSlide?
    @Binding var selectedSlideType: SlideType
    @Binding var filterManufacturer: [String]
    @Binding var filterMaxThickness: Double?
    
    var body: some View {
        SlideSelectionViewInternal(
            selectedSlide: $selectedSlide,
            selectedSlideType: $selectedSlideType,
            filterManufacturers: $filterManufacturer,
            filterMaxThickness: $filterMaxThickness
        )
    }
}

// MARK: - Internal View with Filter Logic
struct SlideSelectionViewInternal: View {
    @Binding var selectedSlide: DrawerSlide?
    @Binding var selectedSlideType: SlideType
    
    private let analytics = AnalyticsManager.shared
    @Binding var filterManufacturers: [String]
    @Binding var filterMaxThickness: Double?
    @Environment(\.dismiss) var dismiss
    @State private var showFilterOptions = false
    @State private var showAddCustom = false
    @State private var showFavoritesOnly = false
    @State private var showUserAddedOnly = false
    @State private var favoriteIDs: Set<UUID> = DrawerSlide.loadFavoriteIDs()
    @State private var navigationPath = NavigationPath()
    @State private var refreshID = UUID()  // Force refresh when custom slides change
    
    var filterType: SlideType {
        selectedSlideType
    }
    
    var availableManufacturers: [String] {
        let slides = DrawerSlide.slides(for: filterType)
        let manufacturers = Set(slides.map { $0.manufacturer })
        return Array(manufacturers).sorted()
    }
    
    var availableThicknesses: [Double] {
        let slides = DrawerSlide.slides(for: filterType)
        var uniqueThicknesses: Set<Double> = []
        
        for slide in slides {
            let mm = slide.maxMaterialThicknessMM
            // Group similar thicknesses (within 0.1mm)
            var foundSimilar = false
            for existing in uniqueThicknesses {
                if abs(existing - mm) < 0.1 {
                    foundSimilar = true
                    break
                }
            }
            if !foundSimilar {
                uniqueThicknesses.insert(mm)
            }
        }
        
        return Array(uniqueThicknesses).sorted()
    }
    
    var activeFilterCount: Int {
        var count = 0
        if !filterManufacturers.isEmpty { count += 1 }
        if filterMaxThickness != nil { count += 1 }
        // Don't count favorites and user-added since they have their own buttons
        return count
    }
    
    var filteredSlides: [DrawerSlide] {
        var slides = DrawerSlide.slides(for: filterType)
        
        if showFavoritesOnly {
            slides = slides.filter { favoriteIDs.contains($0.id) }
        }
        
        if showUserAddedOnly {
            slides = slides.filter { DrawerSlide.isCustomSlide($0) }
        }
        
        if !filterManufacturers.isEmpty {
            slides = slides.filter { filterManufacturers.contains($0.manufacturer) }
        }
        
        if let maxThickness = filterMaxThickness {
            // Filter for slides that can handle at least the selected thickness
            // Account for small differences (within 0.1mm)
            slides = slides.filter { 
                $0.maxMaterialThicknessMM >= maxThickness || 
                abs($0.maxMaterialThicknessMM - maxThickness) < 0.1
            }
        }
        
        return slides
    }
    
    // Group slides hierarchically by manufacturer, then by line
    var groupedByManufacturer: [(manufacturer: String, lines: [(line: String, slides: [DrawerSlide])])] {
        // First group by manufacturer
        let byManufacturer = Dictionary(grouping: filteredSlides) { $0.manufacturer }
        
        // Then for each manufacturer, group by line
        return byManufacturer.map { manufacturer, slides in
            let byLine = Dictionary(grouping: slides) { $0.line }
            let sortedLines = byLine.sorted { $0.key < $1.key }.map { (line: $0.key, slides: $0.value) }
            return (manufacturer: manufacturer, lines: sortedLines)
        }.sorted { $0.manufacturer < $1.manufacturer }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // Filters Section
                VStack(spacing: 12) {
                    // Slide Type and Filter Button
                    HStack(spacing: 16) {
                        Menu {
                            ForEach(SlideType.allCases, id: \.self) { type in
                                Button(action: {
                                    selectedSlideType = type
                                }) {
                                    Text(type.rawValue)
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(selectedSlideType.rawValue)
                                    .font(Typography.body)
                                    .foregroundColor(.white)
                                    .frame(minWidth: 90, alignment: .leading)
                                Image(systemName: "chevron.down")
                                    .font(Typography.caption2)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Constants.inputBackgroundColor)
                            .cornerRadius(8)
                        }
                        .frame(width: 150)
                        .onChange(of: selectedSlideType) { _, _ in
                            // Reset filters when slide type changes
                            filterManufacturers.removeAll()
                            filterMaxThickness = nil
                            showFavoritesOnly = false
                            showUserAddedOnly = false
                        }
                        
                        Spacer(minLength: 0)
                        
                        HStack(spacing: 25) {
                        
                            
                            Button(action: {
                                showUserAddedOnly.toggle()
                            }) {
                                Image(systemName: showUserAddedOnly ? "person.fill" : "person")
                                    .font(Typography.title3)
                                    .foregroundColor(showUserAddedOnly ? Constants.appTintColor : .gray)
                            }
                            
                            Button(action: {
                                showFavoritesOnly.toggle()
                            }) {
                                Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                                    .font(Typography.title3)
                                    .foregroundColor(showFavoritesOnly ? .yellow : .gray)
                            }
                            
                            Button(action: {
                                showFilterOptions = true
                            }) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .font(Typography.title3)
                                        .foregroundColor(activeFilterCount > 0 ? Constants.appTintColor : .gray)
                                    if activeFilterCount > 0 {
                                        Text("\(activeFilterCount)")
                                            .font(Typography.caption2)
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                            .padding(4)
                                            .background(Circle().fill(Constants.appTintColor))
                                            .offset(x: 6, y: -6)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 15)
                .padding(.bottom, 10)
                .padding(.trailing, 20)
                .padding(.leading, 5)
                .background(Constants.backgroundColor)
                
                // Active Filters and Results count
                VStack(spacing: 0) {
                    if activeFilterCount > 0 || showFavoritesOnly || showUserAddedOnly {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                if showFavoritesOnly {
                                    FilterChip(label: "Favorites", onRemove: {
                                        showFavoritesOnly = false
                                    })
                                }
                                
                                if showUserAddedOnly {
                                    FilterChip(label: "User Added", onRemove: {
                                        showUserAddedOnly = false
                                    })
                                }
                                
                                ForEach(filterManufacturers, id: \.self) { manufacturer in
                                    FilterChip(label: manufacturer, onRemove: {
                                        filterManufacturers.removeAll { $0 == manufacturer }
                                    })
                                }
                                
                                if let thickness = filterMaxThickness {
                                    let thicknessInches = thickness / Constants.inchesToMM
                                    let label = formatThicknessForChip(mm: thickness, inches: thicknessInches)
                                    FilterChip(label: "Max: \(label)", onRemove: {
                                        filterMaxThickness = nil
                                    })
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    filterManufacturers.removeAll()
                                    filterMaxThickness = nil
                                    showFavoritesOnly = false
                                    showUserAddedOnly = false
                                }) {
                                    Text("Clear All")
                                        .font(Typography.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
//                        .background(Color.blue.opacity(0.1))
                    }
                }
                
                // Slides List
                if filteredSlides.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(Typography.largeTitle)
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No slides found")
                            .font(Typography.headline)
                            .foregroundColor(.gray)
                        if activeFilterCount > 0 {
                            Text("Try adjusting or clearing filters")
                                .font(Typography.caption)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(groupedByManufacturer, id: \.manufacturer) { manufacturerGroup in
                                ManufacturerSection(
                                    manufacturer: manufacturerGroup.manufacturer,
                                    lines: manufacturerGroup.lines,
                                    selectedSlide: selectedSlide,
                                    favoriteIDs: favoriteIDs,
                                    onSelect: { slide in
                                        analytics.trackHardwareSelection(slide: slide)
                                        selectedSlide = slide
                                        selectedSlideType = slide.type
                                        // Add a small delay to show selection feedback
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            dismiss()
                                        }
                                    },
                                    onToggleFavorite: { slide in
                                        DrawerSlide.toggleFavorite(for: slide)
                                        favoriteIDs = DrawerSlide.loadFavoriteIDs()
                                    },
                                    onShowDetails: { slide in
                                        navigationPath.append(slide)
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                        .id(refreshID)  // Force refresh when ID changes
                    }
                    .background(Constants.backgroundColor)
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CustomSlideDeleted"))) { _ in
                        // Refresh view when a custom slide is deleted
                        refreshID = UUID()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CustomSlideAdded"))) { _ in
                        // Refresh view when a custom slide is added
                        refreshID = UUID()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CustomSlideUpdated"))) { _ in
                        // Refresh view when a custom slide is updated
                        refreshID = UUID()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("HardwareDataUpdated"))) { _ in
                        // Refresh view when hardware data is loaded from server
                        refreshID = UUID()
                        hardwareDataVersion = UUID()  // Force recomputation of computed properties
                        print("[SlideSelectionView] Received HardwareDataUpdated notification, refreshing UI")
                    }
                }
            }
            .background(Constants.backgroundColor)
            .navigationTitle("Select Hardware")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: DrawerSlide.self) { slide in
                SlideDetailView(slide: slide)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(Typography.body)
                    .foregroundColor(Constants.appTintColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddCustom = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(Typography.body)
                            .foregroundColor(Constants.appTintColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showFilterOptions) {
            FilterOptionsView(
                selectedManufacturers: $filterManufacturers,
                selectedMaxThickness: $filterMaxThickness,
                availableManufacturers: availableManufacturers,
                availableThicknesses: availableThicknesses,
                slideType: filterType
            )
        }
        .sheet(isPresented: $showAddCustom) {
            CustomSlideFormView { newSlide in
                analytics.trackCustomHardwareAdded(slide: newSlide)
                DrawerSlide.saveCustomSlide(newSlide)
                // Post notification to refresh the list
                NotificationCenter.default.post(name: Notification.Name("CustomSlideAdded"), object: nil)
            }
        }
    }
    
    private func formatThicknessForChip(mm: Double, inches: Double) -> String {
        if abs(inches - 0.625) < 0.01 {
            return "5/8\""
        } else if abs(inches - 0.75) < 0.01 {
            return "3/4\""
        } else if abs(inches - 0.5) < 0.01 {
            return "1/2\""
        } else if abs(inches - 1.0) < 0.01 {
            return "1\""
        } else {
            return String(format: "%.0fmm", mm)
        }
    }
}

// MARK: - Manufacturer Section (Top level grouping)
struct ManufacturerSection: View {
    let manufacturer: String
    let lines: [(line: String, slides: [DrawerSlide])]
    let selectedSlide: DrawerSlide?
    let favoriteIDs: Set<UUID>
    let onSelect: (DrawerSlide) -> Void
    let onToggleFavorite: (DrawerSlide) -> Void
    let onShowDetails: (DrawerSlide) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Manufacturer header
            HStack {
                Text(manufacturer.uppercased())
                    .font(Typography.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(lines.map { $0.slides.count }.reduce(0, +)) slides")
                    .font(Typography.caption2)
                    .foregroundColor(.gray.opacity(0.7))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Constants.inputBackgroundColor)
            
            // Lines within manufacturer
            VStack(spacing: 1) {
                ForEach(lines, id: \.line) { lineGroup in
                    LineGroupRow(
                        manufacturer: manufacturer,
                        line: lineGroup.line,
                        slides: lineGroup.slides,
                        selectedSlide: selectedSlide,
                        favoriteIDs: favoriteIDs,
                        onSelect: onSelect,
                        onToggleFavorite: onToggleFavorite,
                        onShowDetails: onShowDetails
                    )
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                }
            }
        }
    }
}

// MARK: - Line Group Row (Second level grouping)
struct LineGroupRow: View {
    let manufacturer: String
    let line: String
    let slides: [DrawerSlide]
    let selectedSlide: DrawerSlide?
    let favoriteIDs: Set<UUID>
    let onSelect: (DrawerSlide) -> Void
    let onToggleFavorite: (DrawerSlide) -> Void
    let onShowDetails: (DrawerSlide) -> Void
    @State private var isExpanded = false
    
    var hasSelectedSlide: Bool {
        slides.contains { $0.id == selectedSlide?.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Line header (always visible)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(line)
                            .font(Typography.headline)
                            .foregroundColor(.white)
                        
                        // Always show variant count
                        Text(slides.count == 1 ? "1 variant" : "\(slides.count) variants")
                            .font(Typography.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Always show expansion chevron
                    Image(systemName: "chevron.right")
                        .font(Typography.caption)
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Animated expansion for all slides
            VStack(spacing: 0) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                    VStack(spacing: 0) {
                        PartNumberRow(
                            slide: slide,
                            isSelected: selectedSlide?.id == slide.id,
                            isFavorite: favoriteIDs.contains(slide.id),
                            onSelect: { onSelect(slide) },
                            onToggleFavorite: { onToggleFavorite(slide) },
                            onShowDetails: { onShowDetails(slide) }
                        )
                        .padding(.vertical, 10)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                        
                        // Add divider between items (not after the last one)
                        if index < slides.count - 1 {
                            Divider()
                                .background(Color.gray.opacity(0.2))
                                .padding(.leading, 20)
                        }
                    }
                }
            }
            .padding(.leading, 20)
            .frame(height: isExpanded ? nil : 0, alignment: .top)
            .clipped()
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
        }
//        .background(
//            RoundedRectangle(cornerRadius: 8)
//                .fill(hasSelectedSlide ? Constants.appTintColor.opacity(0.1) : Constants.inputBackgroundColor)
//        )
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
}

// MARK: - Grouped Slide Row (Legacy - kept for compatibility)
struct GroupedSlideRow: View {
    let groupKey: String
    let slides: [DrawerSlide]
    let selectedSlide: DrawerSlide?
    let favoriteIDs: Set<UUID>
    let onSelect: (DrawerSlide) -> Void
    let onToggleFavorite: (DrawerSlide) -> Void
    let onShowDetails: (DrawerSlide) -> Void = { _ in } // Default no-op for legacy compatibility
    @State private var isExpanded = false
    
    var groupInfo: (manufacturer: String, line: String) {
        let parts = groupKey.split(separator: " - ").map(String.init)
        return (parts[0], parts[1])
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Group header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(groupInfo.line)
                            .font(Typography.headline)
                            .foregroundColor(.white)
                        
                        Text(groupInfo.manufacturer)
                            .font(Typography.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if slides.count > 1 {
                        Text("\(slides.count) variants")
                            .font(Typography.caption)
                            .foregroundColor(.gray)
                            .padding(.trailing, 8)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Typography.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded part number selection
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(slides) { slide in
                        PartNumberRow(
                            slide: slide,
                            isSelected: selectedSlide?.id == slide.id,
                            isFavorite: favoriteIDs.contains(slide.id),
                            onSelect: { onSelect(slide) },
                            onToggleFavorite: { onToggleFavorite(slide) },
                            onShowDetails: { onShowDetails(slide) }
                        )
                    }
                }
                .padding(.leading, 20)
            } else if slides.count == 1 {
                // If only one slide, allow direct selection without expanding
                let slide = slides[0]
                SimpleSlideInfo(
                    slide: slide,
                    isSelected: selectedSlide?.id == slide.id,
                    isFavorite: favoriteIDs.contains(slide.id),
                    onSelect: { onSelect(slide) },
                    onToggleFavorite: { onToggleFavorite(slide) }
                )
            }
        }
        .listRowBackground(Constants.inputBackgroundColor)
        .listRowSeparatorTint(.gray.opacity(0.3))
    }
}

// MARK: - Part Number Row (for expanded view)
struct PartNumberRow: View {
    let slide: DrawerSlide
    let isSelected: Bool
    let isFavorite: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void
    let onShowDetails: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var showEditForm = false
    
    var body: some View {
        HStack {
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(isFavorite ? .yellow : .gray)
                    .font(Typography.caption)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 8)
            
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("#\(slide.partNumber)")
                                .font(Typography.body)
                                .foregroundColor(.white)
                            
                            // Show icon for user-added slides
                            if DrawerSlide.isCustomSlide(slide) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray.opacity(0.6))
                            }
                        }
                        
                        HStack(spacing: 8) {
                            if slide.type == .undermount {
                                Text("Max: \(slide.formattedMaxThickness)")
                                    .font(Typography.caption2)
                                    .foregroundColor(.gray)
                            }
                            
                            Text("Deduct: \(slide.formattedDeduction)")
                                .font(Typography.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(Constants.appTintColor)
                            .font(Typography.headline)
                    }
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onShowDetails) {
                Image(systemName: "info.circle")
                    .foregroundColor(.gray)
                    .font(Typography.headline)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.leading, 4)
        }
        .contextMenu {
            Button(action: onToggleFavorite) {
                Label(isFavorite ? "Remove from Favorites" : "Add to Favorites", 
                      systemImage: isFavorite ? "star.slash" : "star")
            }
            
            Button(action: onShowDetails) {
                Label("View Details", systemImage: "info.circle")
            }
            
            if DrawerSlide.isCustomSlide(slide) {
                Divider()
                
                Button(action: {
                    showEditForm = true
                }) {
                    Label("Edit User-Added Hardware", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    Label("Delete User-Added Hardware", systemImage: "trash")
                }
            }
        }
        .confirmationDialog(
            "Delete User-Added Hardware",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete \(slide.line) - \(slide.partNumber)", role: .destructive) {
                withAnimation {
                    DrawerSlide.deleteCustomSlide(slide)
                    NotificationCenter.default.post(name: Notification.Name("CustomSlideDeleted"), object: nil)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this user-added hardware from your list.")
        }
        .sheet(isPresented: $showEditForm) {
            EditCustomSlideFormView(slideToEdit: slide) { updatedSlide in
                withAnimation {
                    DrawerSlide.updateCustomSlide(updatedSlide)
                    NotificationCenter.default.post(name: Notification.Name("CustomSlideUpdated"), object: nil)
                }
            }
        }
    }
}

// MARK: - Simple Slide Info (for single slide groups)
struct SimpleSlideInfo: View {
    let slide: DrawerSlide
    let isSelected: Bool
    let isFavorite: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(isFavorite ? .yellow : .gray)
                    .font(Typography.body)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 8)
            
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("#\(slide.partNumber)")
                            .font(Typography.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 8) {
                            if slide.type == .undermount {
                                Text("Maximum side thickness: \(slide.formattedMaxThickness)")
                                    .font(Typography.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Text("Deduct: \(slide.formattedDeduction)")
                                .font(Typography.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Constants.appTintColor)
                            .font(Typography.title3)
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.leading, 20)
    }
}

// MARK: - Original SlideRow (kept for compatibility but not used in grouped view)
struct SlideRow: View {
    let slide: DrawerSlide
    let isSelected: Bool
    let isFavorite: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack {
            VStack {
                
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .gray)
                        .font(Typography.body)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 8)
                .padding(.top, 5)
                
                Spacer()
            }
            
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        
                        HStack(spacing: 8) {
                            Text(slide.line)
                                .font(Typography.headline)
                                .foregroundColor(.white)
                            
                            Text("#\(slide.partNumber)")
                                .font(Typography.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Text(slide.manufacturer)
                            .font(Typography.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            
                            if slide.type == .undermount {
                                
                                Text("Max Thickness: \(slide.formattedMaxThickness)")
                                    .font(Typography.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Text("Deduct: \(slide.formattedDeduction)")
                                .font(Typography.caption)
                                .foregroundColor(.gray)
                        }
//                        .padding(.top, -10)
//                        .padding(.bottom, -15)

                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Constants.appTintColor)
                            .font(Typography.title2)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
//        .padding(.vertical)
        .listRowBackground(Constants.inputBackgroundColor)
        .listRowSeparatorTint(.gray.opacity(0.3))
    }
}

#Preview("SlideRow - Selected & Favorite") {
    List {
        SlideRow(
            slide: DrawerSlide.undermountSlides.first!,
            isSelected: true,
            isFavorite: true,
            onSelect: {},
            onToggleFavorite: {}
        )
    }
    .listStyle(PlainListStyle())
    .background(Constants.backgroundColor)
    .previewLayout(.sizeThatFits)
}

#Preview("SlideRow - Not Selected") {
    List {
        SlideRow(
            slide: DrawerSlide.sidemountSlides.first!,
            isSelected: false,
            isFavorite: false,
            onSelect: {},
            onToggleFavorite: {}
        )
    }
    .listStyle(PlainListStyle())
    .background(Constants.backgroundColor)
    .previewLayout(.sizeThatFits)
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(Typography.caption)
                .foregroundColor(.white)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(Typography.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Constants.appTintColor)
        .cornerRadius(12)
    }
}

// MARK: - Filter Options View
struct FilterOptionsView: View {
    @Binding var selectedManufacturers: [String]
    @Binding var selectedMaxThickness: Double?
    let availableManufacturers: [String]
    let availableThicknesses: [Double]
    let slideType: SlideType
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Manufacturer Section
                Section(header: Text("Manufacturer").font(Typography.subheadline)) {
                    HStack {
                        Text("All")
                            .font(Typography.body)
                            .foregroundColor(.white)
                        Spacer()
                        if selectedManufacturers.isEmpty {
                            Image(systemName: "checkmark")
                                .foregroundColor(Constants.appTintColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedManufacturers.removeAll()
                    }
                    
                    ForEach(availableManufacturers, id: \.self) { manufacturer in
                        HStack {
                            Text(manufacturer)
                                .font(Typography.body)
                                .foregroundColor(.white)
                            Spacer()
                            if selectedManufacturers.contains(manufacturer) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Constants.appTintColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let idx = selectedManufacturers.firstIndex(of: manufacturer) {
                                selectedManufacturers.remove(at: idx)
                            } else {
                                selectedManufacturers.append(manufacturer)
                            }
                        }
                    }
                }
                
                // Material Thickness Section
                if slideType == .undermount {
                    Section(header: Text("Maximum Material Thickness").font(Typography.subheadline)) {
                        ForEach([nil] + availableThicknesses.map { Optional($0) }, id: \.self) { thickness in
                            HStack {
                                if let thick = thickness {
                                    Text(formatThickness(mm: thick))
                                        .font(Typography.body)
                                        .foregroundColor(.white)
                                } else {
                                    Text("Any")
                                        .font(Typography.body)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                if selectedMaxThickness == thickness {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Constants.appTintColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedMaxThickness = thickness
                            }
                        }
                    }
                }
                
                // Clear Filters Section
                if !selectedManufacturers.isEmpty || selectedMaxThickness != nil {
                    Section {
                        Button(action: {
                            selectedManufacturers.removeAll()
                            selectedMaxThickness = nil
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                    .font(Typography.body)
                                Text("Clear All Filters")
                                    .font(Typography.body)
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Filter Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(Typography.body)
                    .foregroundColor(Constants.appTintColor)
                }
            }
        }
    }
    
    private func formatThickness(mm: Double) -> String {
        let inches = mm / Constants.inchesToMM
        
        // Round to nearest 1/16"
        let sixteenths = Int(round(inches * 16))
        let whole = sixteenths / 16
        var numerator = sixteenths % 16
        var denominator = 16
        
        if numerator == 0 {
            // Whole number inches (e.g. 1")
            return String(format: "Up to %d\" (%dmm)", whole, Int(mm))
        }
        
        // Simplify fraction using GCD
        func gcd(_ a: Int, _ b: Int) -> Int {
            var x = a, y = b
            while y != 0 { let t = x % y; x = y; y = t }
            return x
        }
        let g = gcd(numerator, denominator)
        numerator /= g
        denominator /= g
        
        if whole > 0 {
            return String(format: "Up to %d-%d/%d\" (%dmm)", whole, numerator, denominator, Int(mm))
        } else {
            return String(format: "Up to %d/%d\" (%dmm)", numerator, denominator, Int(mm))
        }
    }
}

#Preview {
    SlideSelectionViewWithFilters(
        selectedSlide: .constant(nil),
        selectedSlideType: .constant(.undermount),
        filterManufacturer: .constant([]),
        filterMaxThickness: .constant(nil)
    )
}
