//
//  HelpView.swift
//  DrawerBoxCalculator
//
//  Created by Agent on 9/18/25.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingCopiedAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How the Calculator Works")
                            .font(Typography.title2)
                            .foregroundColor(.white)
                        
                        Text("Understanding drawer width calculations for different slide types")
                            .font(Typography.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Undermount Slides Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image("Undermount Icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(Constants.appTintColor)
                            Text("Undermount Slides")
                                .font(Typography.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text("For undermount slides, the drawer width calculation is:")
                            .font(Typography.body)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Opening Width - (2 × Deduction) + \n(2 × Material Thickness)")
                                .font(Typography.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        Text("The deduction is defined by hardware manufacturer and varies depending on make and model.")
                            .font(Typography.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    // Sidemount Slides Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image("Sidemount Icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(Constants.appTintColor)
                            Text("Sidemount Slides")
                                .font(Typography.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text("For sidemount slides, the calculation is simpler:")
                            .font(Typography.body)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Opening Width - (2 × Deduction)")
                                .font(Typography.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        Text("The deduction is defined by hardware manufacturer and varies depending on make and model, but generally have a 1/2\" deduction. Material thickness is not factored in because sidemount slides attach to the sides of the drawer box.")
                            .font(Typography.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    // Key Points Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(Typography.title3)
                                .foregroundColor(Constants.appTintColor)
                            Text("Important Notes")
                                .font(Typography.headline)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            bulletPoint("Each hardware type has a specific deduction value")
                            bulletPoint("Material thickness only matters for undermount slides")
                            bulletPoint("Results are rounded to the nearest 1/16\" for imperial")
                            bulletPoint("Results are rounded to the nearest millimeter for metric")
                            bulletPoint("Always verify hardware specifications before fabricating")
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    // Hardware Database Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "square.stack.3d.up")
                                .font(Typography.title3)
                                .foregroundColor(Constants.appTintColor)
                            Text("Hardware Database")
                                .font(Typography.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text("The app includes a curated selection of commonly used drawer slide hardware from major manufacturers. If the hardware you're using is not included, you can add your own hardware by tapping the \"+\" icon at the top of the hardware selection list.")
                            .font(Typography.body)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(Typography.body)
                                    .foregroundColor(Constants.appTintColor)
                                Text("Adding Custom Hardware")
                                    .font(Typography.subheadline)
                                    .foregroundColor(.white)
                            }
                            
                            Text("When adding your own hardware, always refer to the manufacturer's technical documentation for accurate deduction values. These specifications ensure precise calculations for your specific slides.")
                                .font(Typography.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 28)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                    
                    // Feedback Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "envelope")
                                .font(Typography.title3)
                                .foregroundColor(Constants.appTintColor)
                            Text("Contact Us")
                                .font(Typography.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text("Have feedback or questions? We'd love to hear from you!")
                            .font(Typography.body)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            sendFeedbackEmail()
                        }) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                    .font(Typography.body)
                                Text("Send Feedback")
                                    .font(Typography.body)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Constants.appTintColor)
                            .cornerRadius(12)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Constants.backgroundColor)
            .navigationTitle("About")
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
        .alert("Email Copied", isPresented: $showingCopiedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The support email address has been copied to your clipboard.")
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(Typography.body)
                .foregroundColor(Constants.appTintColor)
            Text(text)
                .font(Typography.caption)
                .foregroundColor(.gray)
        }
    }
    
    private func sendFeedbackEmail() {
        let email = "info@drawercalculator.com"
        let subject = "Drawer Calculator Feedback"
        let deviceInfo = "\n\n\n---\nApp Version: 1.0\nDevice: \(UIDevice.current.model)\niOS Version: \(UIDevice.current.systemVersion)"
        
        // URL encode the subject and body
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = deviceInfo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Create the mailto URL
        if let mailtoURL = URL(string: "mailto:\(email)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
            // Check if we can open the URL
            if UIApplication.shared.canOpenURL(mailtoURL) {
                UIApplication.shared.open(mailtoURL)
            } else {
                // If no mail app is available, copy email to clipboard
                copyEmailAddress()
            }
        }
    }
    
    private func copyEmailAddress() {
        UIPasteboard.general.string = "help@drawercalculator.com"
        showingCopiedAlert = true
    }
}

#Preview {
    HelpView()
}
