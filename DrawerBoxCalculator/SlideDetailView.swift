//
//  SlideDetailView.swift
//  DrawerBoxCalculator
//
//  Created by Agent on 9/19/25.
//

import SwiftUI

struct SlideDetailView: View {
    let slide: DrawerSlide
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showDeleteSuccess = false
    @State private var showEditForm = false
    @State private var currentSlide: DrawerSlide
    @State private var refreshID = UUID()
    
    init(slide: DrawerSlide) {
        self.slide = slide
        self._currentSlide = State(initialValue: slide)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentSlide.line)
                        .font(Typography.largeTitle)
                        .foregroundColor(.white)
                    
                    Text("Part #\(currentSlide.partNumber)")
                        .font(Typography.title2)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Label(currentSlide.manufacturer, systemImage: "building.2")
                            .font(Typography.body)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // Show if it's user-added hardware
                        if DrawerSlide.isCustomSlide(currentSlide) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(Typography.caption)
                                Text("User Added")
                                    .font(Typography.caption)
                            }
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Text(currentSlide.type.rawValue)
                            .font(Typography.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Constants.appTintColor.opacity(0.2))
                            .foregroundColor(Constants.appTintColor)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Constants.inputBackgroundColor)
                .cornerRadius(12)
                
                // Specifications Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Specifications")
                        .font(Typography.headline)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 12) {
                        SpecificationRow(
                            label: "Deduction per Side",
                            value: currentSlide.formattedDeduction,
                            detail: String(format: "%.3f\"", currentSlide.standardDeductionInches)
                        )
                        
                        if currentSlide.type == .undermount {
                            SpecificationRow(
                                label: "Maximum Material Thickness",
                                value: currentSlide.formattedMaxThickness,
                                detail: String(format: "%.1f mm", currentSlide.maxMaterialThicknessMM)
                            )
                        }
                        
                        SpecificationRow(
                            label: "Slide Type",
                            value: currentSlide.type.rawValue,
                            detail: currentSlide.type.requiresMaterialThickness ? "Requires material thickness" : "No material thickness needed"
                        )
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Compatibility Notes
                if currentSlide.type == .undermount {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Compatibility Notes")
                            .font(Typography.headline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Maximum material thickness: \(currentSlide.formattedMaxThicknessWithMM)", 
                                  systemImage: "info.circle")
                                .font(Typography.body)
                                .foregroundColor(.white)
                            
                            Text("Ensure your drawer box material does not exceed this thickness for proper slide operation.")
                                .font(Typography.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 28)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                }
                
                // Example Calculation
                VStack(alignment: .leading, spacing: 16) {
                    Text("Example Calculation")
                        .font(Typography.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("For a 24\" cabinet opening:")
                            .font(Typography.subheadline)
                            .foregroundColor(.white)
                        
                        if currentSlide.type == .undermount {
                            Text("With 1/2\" (12.7mm) material thickness:")
                                .font(Typography.caption)
                                .foregroundColor(.gray)
                            
                            let exampleWidth = currentSlide.calculateDrawerWidth(openingWidth: 24, materialThickness: 0.5)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("24\" - (2 × \(String(format: "%.3f", currentSlide.standardDeductionInches))\") + (2 × 0.5\")")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.cyan)
                                
                                Text("= \(String(format: "%.3f\"", exampleWidth))")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                        } else {
                            let exampleWidth = currentSlide.calculateDrawerWidth(openingWidth: 24, materialThickness: 0)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("24\" - (2 × \(String(format: "%.3f", currentSlide.standardDeductionInches))\")")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.cyan)
                                
                                Text("= \(String(format: "%.3f\"", exampleWidth))")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Delete button for user-added slides
                if DrawerSlide.isCustomSlide(currentSlide) {
                    VStack(spacing: 16) {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(Typography.body)
                                Text("Delete User-Added Hardware")
                                    .font(Typography.body)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                        
                        Text("This is hardware you added. Deleting it will remove it from your list.")
                            .font(Typography.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                }
            }
            .padding()
        }
        .background(Constants.backgroundColor)
        .navigationTitle("Slide Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if DrawerSlide.isCustomSlide(currentSlide) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showEditForm = true
                    }
                    .font(Typography.body)
                    .foregroundColor(Constants.appTintColor)
                }
            }
        }
        .alert("Delete User-Added Hardware", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                DrawerSlide.deleteCustomSlide(currentSlide)
                NotificationCenter.default.post(name: Notification.Name("CustomSlideDeleted"), object: nil)
                showDeleteSuccess = true
                // Dismiss after a short delay to show success
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(currentSlide.line) - \(currentSlide.partNumber)\"? This action cannot be undone.")
        }
        .alert("Hardware Deleted", isPresented: $showDeleteSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("The user-added hardware has been removed from your list.")
        }
        .sheet(isPresented: $showEditForm) {
            EditCustomSlideFormView(slideToEdit: currentSlide) { updatedSlide in
                withAnimation {
                    DrawerSlide.updateCustomSlide(updatedSlide)
                    NotificationCenter.default.post(name: Notification.Name("CustomSlideUpdated"), object: nil)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CustomSlideUpdated"))) { _ in
            // Refresh the current slide data when it's updated
            if let updatedSlide = DrawerSlide.loadCustomSlides().first(where: { $0.id == currentSlide.id }) {
                currentSlide = updatedSlide
                refreshID = UUID()
            }
        }
        .id(refreshID)
    }
}

struct SpecificationRow: View {
    let label: String
    let value: String
    let detail: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(Typography.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(detail)
                .font(Typography.caption)
                .foregroundColor(.gray)
        }
        
        Divider()
            .background(Color.gray.opacity(0.3))
    }
}

#Preview {
    NavigationStack {
        SlideDetailView(slide: DrawerSlide.undermountSlides.first!)
    }
}
