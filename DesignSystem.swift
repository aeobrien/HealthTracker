// DesignSystem.swift
// Add this as a new Swift file to your HealthTracker project

import SwiftUI
import CoreData

// MARK: - Design System
struct DesignSystem {
    // MARK: - Colors
    struct Colors {
        // Soft, muted primary colors
        static let primaryBlue = Color(red: 0.4, green: 0.6, blue: 0.8, opacity: 1.0)
        static let softPink = Color(red: 0.9, green: 0.7, blue: 0.8, opacity: 1.0)
        static let mutedGreen = Color(red: 0.6, green: 0.8, blue: 0.7, opacity: 1.0)
        static let warmGray = Color(red: 0.9, green: 0.9, blue: 0.9, opacity: 1.0)
        
        // Subtle accent colors
        static let lightLavender = Color(red: 0.85, green: 0.82, blue: 0.9, opacity: 1.0)
        static let paleOrange = Color(red: 0.95, green: 0.85, blue: 0.7, opacity: 1.0)
        static let softIndigo = Color(red: 0.7, green: 0.75, blue: 0.9, opacity: 1.0)
        
        // Background colors
        static let cardBackground = Color(red: 0.98, green: 0.98, blue: 0.99, opacity: 1.0)
        static let screenBackground = Color(red: 0.96, green: 0.97, blue: 0.98, opacity: 1.0)
        
        // Text colors
        static let primaryText = Color(red: 0.2, green: 0.2, blue: 0.3, opacity: 1.0)
        static let secondaryText = Color(red: 0.5, green: 0.5, blue: 0.6, opacity: 1.0)
        static let tertiaryText = Color(red: 0.7, green: 0.7, blue: 0.75, opacity: 1.0)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.custom("SF Pro Display", size: 28).weight(.light)
        static let title = Font.custom("SF Pro Display", size: 22).weight(.light)
        static let headline = Font.custom("SF Pro Text", size: 16).weight(.medium)
        static let body = Font.custom("SF Pro Text", size: 15).weight(.regular)
        static let caption = Font.custom("SF Pro Text", size: 13).weight(.regular)
        static let micro = Font.custom("SF Pro Text", size: 11).weight(.regular)
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let subtle = Color.black.opacity(0.03)
        static let card = Color.black.opacity(0.06)
    }
}

// MARK: - Minimal UI Components

struct MinimalCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignSystem.Spacing.large)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(16)
            .shadow(color: DesignSystem.Shadows.card, radius: 8, x: 0, y: 2)
    }
}

struct DelicateButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary, secondary, subtle
        
        var backgroundColor: Color {
            switch self {
            case .primary: return DesignSystem.Colors.primaryBlue.opacity(0.1)
            case .secondary: return DesignSystem.Colors.softPink.opacity(0.1)
            case .subtle: return Color.clear
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary: return DesignSystem.Colors.primaryBlue
            case .secondary: return DesignSystem.Colors.softPink
            case .subtle: return DesignSystem.Colors.secondaryText
            }
        }
        
        var borderColor: Color {
            switch self {
            case .primary: return DesignSystem.Colors.primaryBlue.opacity(0.3)
            case .secondary: return DesignSystem.Colors.softPink.opacity(0.3)
            case .subtle: return DesignSystem.Colors.tertiaryText
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundColor(style.textColor)
                .padding(.horizontal, DesignSystem.Spacing.large)
                .padding(.vertical, DesignSystem.Spacing.medium)
                .background(style.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style.borderColor, lineWidth: 0.5)
                )
                .cornerRadius(12)
        }
    }
}

struct MinimalSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                if value == 0 {
                    Text("Not tracked")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                } else {
                    Text("\(String(format: "%.0f", value))\(unit)")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(color)
                }
            }
            
            Slider(value: $value, in: range, step: step)
                .accentColor(color)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignSystem.Colors.warmGray)
                        .frame(height: 4)
                )
        }
    }
}

struct SimpleToggleChip: View {
    let text: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(isSelected ? color : DesignSystem.Colors.secondaryText)
                .padding(.horizontal, DesignSystem.Spacing.small)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? color.opacity(0.08) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? color.opacity(0.3) : DesignSystem.Colors.tertiaryText, lineWidth: 0.5)
                        )
                )
        }
    }
}

struct CollapsibleSection<Content: View>: View {
    let title: String
    let subtitle: String
    let isExpanded: Bool
    let color: Color
    let onToggle: () -> Void
    let content: Content
    
    init(title: String, subtitle: String, isExpanded: Bool, color: Color, onToggle: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.isExpanded = isExpanded
        self.color = color
        self.onToggle = onToggle
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            MinimalCard {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(title)
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(subtitle)
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: onToggle) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(color)
                            .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    }
                }
            }
            
            // Content
            if isExpanded {
                MinimalCard {
                    content
                }
                .padding(.top, DesignSystem.Spacing.small)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct MinimalSymptomCategory: View {
    let category: String
    let symptoms: [PredefinedSymptom]
    @Binding var ratings: [String: Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text(category)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .textCase(.uppercase)
                .tracking(0.5)
            
            VStack(spacing: DesignSystem.Spacing.medium) {
                ForEach(symptoms.filter { $0.isActive }, id: \.name) { symptom in
                    MinimalSlider(
                        title: symptom.name,
                        value: Binding(
                            get: { ratings[symptom.name] ?? 0 },
                            set: { ratings[symptom.name] = $0 }
                        ),
                        range: 0...5,
                        step: 1,
                        unit: "/5",
                        color: DesignSystem.Colors.primaryBlue
                    )
                }
            }
        }
    }
}

struct MinimalIntakeRow: View {
    let title: String
    @Binding var value: String
    let color: Color
    
    private let options = ["N/A", "Low", "Medium", "High"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Text(value)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(value == "N/A" ? DesignSystem.Colors.tertiaryText : color)
            }
            
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(options, id: \.self) { option in
                    Button(action: { value = option }) {
                        Text(option)
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(value == option ? color : DesignSystem.Colors.tertiaryText)
                            .padding(.horizontal, DesignSystem.Spacing.small)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(value == option ? color.opacity(0.1) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(value == option ? color.opacity(0.4) : DesignSystem.Colors.tertiaryText, lineWidth: 0.5)
                                    )
                            )
                    }
                }
            }
        }
    }
}

struct TagChip: View {
    let text: String
    let isSelected: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Button(action: onToggle) {
                Text(text)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(isSelected ? DesignSystem.Colors.softPink : DesignSystem.Colors.secondaryText)
                    .padding(.horizontal, DesignSystem.Spacing.small)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? DesignSystem.Colors.softPink.opacity(0.1) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? DesignSystem.Colors.softPink.opacity(0.4) : DesignSystem.Colors.tertiaryText, lineWidth: 0.5)
                            )
                    )
            }
            
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
    }
}

struct MinimalDatePicker: View {
    @Binding var selectedDate: Date
    let onDateChange: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.large) {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                
                Spacer()
            }
            .background(DesignSystem.Colors.screenBackground)
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DelicateButton(title: "Cancel", action: { dismiss() }, style: .subtle)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    DelicateButton(title: "Done", action: {
                        onDateChange()
                        dismiss()
                    }, style: .primary)
                }
            }
        }
    }
}

struct MinimalEditModal: View {
    let context: NSManagedObjectContext
    let onSymptomsChanged: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var symptoms: [PredefinedSymptom] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    ForEach(symptoms, id: \.name) { symptom in
                        MinimalCard {
                            HStack {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text(symptom.name)
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                    
                                    Text(symptom.category)
                                        .font(DesignSystem.Typography.micro)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { symptom.isActive },
                                    set: { newValue in
                                        symptom.isActive = newValue
                                        saveContext()
                                        onSymptomsChanged()
                                    }
                                ))
                                .tint(DesignSystem.Colors.primaryBlue)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(DesignSystem.Colors.screenBackground)
            .navigationTitle("Edit Symptoms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DelicateButton(title: "Done", action: { dismiss() }, style: .primary)
                }
            }
            .onAppear {
                loadSymptoms()
            }
        }
    }
    
    private func loadSymptoms() {
        let request: NSFetchRequest<PredefinedSymptom> = PredefinedSymptom.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \PredefinedSymptom.category, ascending: true),
            NSSortDescriptor(keyPath: \PredefinedSymptom.name, ascending: true)
        ]
        
        do {
            symptoms = try context.fetch(request)
            print("DEBUG: Loaded \(symptoms.count) symptoms for editing")
        } catch {
            print("DEBUG ERROR: Failed to load symptoms for editing: \(error)")
        }
    }
    
    private func saveContext() {
        do {
            try context.save()
            print("DEBUG: Saved symptom visibility changes")
        } catch {
            print("DEBUG ERROR: Failed to save symptom changes: \(error)")
        }
    }
}
