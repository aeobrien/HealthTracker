import SwiftUI
import CoreData

struct SleepTrackingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var hoursSlept: Double = 8.0
    @State private var sleepQuality: Double = 3.0
    @State private var selectedDisturbances: Set<String> = []
    @State private var notes = ""
    @State private var showingSaveConfirmation = false
    @State private var recentSleepEntries: [SleepEntry] = []
    
    // Minimal UI state
    @State private var expandedSections: Set<String> = ["sleep", "quality"] // Start with main sections expanded
    
    private let sleepDisturbances = [
        "Difficulty falling asleep",
        "Woke up frequently",
        "Woke up too early",
        "Nightmares",
        "Restless legs",
        "Sleep talking/walking",
        "Snoring",
        "Hot flashes",
        "Bathroom breaks",
        "Noise disturbances",
        "Light disturbances",
        "Stress/anxiety"
    ]
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.screenBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.large) {
                    // Header section
                    headerSection
                    
                    // Sleep Duration Section
                    sleepDurationSection
                    
                    // Sleep Quality Section
                    sleepQualitySection
                    
                    // Sleep Disturbances Section
                    sleepDisturbancesSection
                    
                    // Notes Section
                    notesSection
                    
                    // Save Button
                    saveButton
                    
                    // Recent Sleep Trends
                    if !recentSleepEntries.isEmpty {
                        recentSleepSection
                    }
                }
                .padding(DesignSystem.Spacing.large)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadExistingSleepEntry()
            loadRecentSleepEntries()
        }
        .sheet(isPresented: $showingDatePicker) {
            MinimalDatePicker(selectedDate: $selectedDate) {
                loadExistingSleepEntry()
            }
        }
        .alert("Sleep Entry Saved", isPresented: $showingSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your sleep entry has been saved successfully.")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        MinimalCard {
            VStack(spacing: DesignSystem.Spacing.medium) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Sleep Tracking")
                            .font(DesignSystem.Typography.largeTitle)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(selectedDate, formatter: subtleDateFormatter)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingDatePicker = true }) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .light))
                            Text("Date")
                                .font(DesignSystem.Typography.body)
                        }
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                        .padding(.vertical, DesignSystem.Spacing.small)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignSystem.Colors.tertiaryText, lineWidth: 0.5)
                        )
                    }
                }
                
                // Quick status indicator
                if hasAnyData {
                    HStack {
                        Circle()
                            .fill(DesignSystem.Colors.mutedGreen)
                            .frame(width: 6, height: 6)
                        
                        Text("Data recorded for this night")
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Sleep Duration Section
    
    private var sleepDurationSection: some View {
        CollapsibleSection(
            title: "Sleep Duration",
            subtitle: durationSubtitle,
            isExpanded: expandedSections.contains("sleep"),
            color: DesignSystem.Colors.softIndigo
        ) {
            toggleSection("sleep")
        } content: {
            MinimalSlider(
                title: "Hours Slept",
                value: $hoursSlept,
                range: 0...12,
                step: 0.5,
                unit: "h",
                color: DesignSystem.Colors.softIndigo
            )
        }
    }
    
    // MARK: - Sleep Quality Section
    
    private var sleepQualitySection: some View {
        CollapsibleSection(
            title: "Sleep Quality",
            subtitle: qualitySubtitle,
            isExpanded: expandedSections.contains("quality"),
            color: DesignSystem.Colors.softIndigo
        ) {
            toggleSection("quality")
        } content: {
            VStack(spacing: DesignSystem.Spacing.medium) {
                MinimalSlider(
                    title: "Quality Rating",
                    value: $sleepQuality,
                    range: 0...5,
                    step: 1,
                    unit: "/5",
                    color: DesignSystem.Colors.softIndigo
                )
                
                HStack {
                    Text("1 = Very Poor")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                    
                    Spacer()
                    
                    Text("5 = Excellent")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                }
            }
        }
    }
    
    // MARK: - Sleep Disturbances Section
    
    private var sleepDisturbancesSection: some View {
        CollapsibleSection(
            title: "Sleep Disturbances",
            subtitle: disturbancesSubtitle,
            isExpanded: expandedSections.contains("disturbances"),
            color: DesignSystem.Colors.lightLavender
        ) {
            toggleSection("disturbances")
        } content: {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.small) {
                ForEach(sleepDisturbances, id: \.self) { disturbance in
                    SimpleToggleChip(
                        text: disturbance,
                        isSelected: selectedDisturbances.contains(disturbance),
                        color: DesignSystem.Colors.lightLavender
                    ) {
                        toggleDisturbance(disturbance)
                    }
                }
            }
        }
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        MinimalCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Text("Notes")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                TextField("Any additional notes about your sleep?", text: $notes, axis: .vertical)
                    .font(DesignSystem.Typography.body)
                    .textFieldStyle(PlainTextFieldStyle())
                    .lineLimit(3...6)
                    .padding(DesignSystem.Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DesignSystem.Colors.tertiaryText, lineWidth: 0.5)
                    )
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        DelicateButton(
            title: hasAnyData ? "Update Entry" : "Save Entry",
            action: saveSleepEntry,
            style: .primary
        )
        .padding(.horizontal, DesignSystem.Spacing.large)
    }
    
    // MARK: - Recent Sleep Section
    
    private var recentSleepSection: some View {
        MinimalCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Text("Recent Sleep")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                ForEach(recentSleepEntries.prefix(7), id: \.createdAt) { entry in
                    MinimalSleepEntryRow(entry: entry)
                }
                
                if let avgSleep = calculateAverageSleep() {
                    HStack {
                        Text("7-day average:")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f hours", avgSleep))
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.softIndigo)
                    }
                    .padding(.top, DesignSystem.Spacing.small)
                }
            }
        }
    }
    
    // MARK: - Helper Views and Computed Properties
    
    private var hasAnyData: Bool {
        hoursSlept != 8.0 ||
        sleepQuality != 0 ||
        !selectedDisturbances.isEmpty ||
        !notes.isEmpty
    }
    
    private var durationSubtitle: String {
        return String(format: "%.1f hours", hoursSlept)
    }
    
    private var qualitySubtitle: String {
        if sleepQuality == 0 {
            return "Not rated"
        }
        return "\(qualityDescription(for: sleepQuality)) (\(Int(sleepQuality))/5)"
    }
    
    private var disturbancesSubtitle: String {
        let count = selectedDisturbances.count
        return count == 0 ? "None reported" : "\(count) disturbances"
    }
    
    private var subtleDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    // MARK: - Actions
    
    private func toggleSection(_ section: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
    
    private func toggleDisturbance(_ disturbance: String) {
        if selectedDisturbances.contains(disturbance) {
            selectedDisturbances.remove(disturbance)
        } else {
            selectedDisturbances.insert(disturbance)
        }
    }
    
    private func saveSleepEntry() {
        print("DEBUG: Saving sleep entry for \(selectedDate)")
        
        // Check if entry already exists for this date
        let request: NSFetchRequest<SleepEntry> = SleepEntry.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let existingEntries = try viewContext.fetch(request)
            let sleepEntry: SleepEntry
            
            if let existing = existingEntries.first {
                print("DEBUG: Updating existing sleep entry")
                sleepEntry = existing
            } else {
                print("DEBUG: Creating new sleep entry")
                sleepEntry = SleepEntry(context: viewContext)
                sleepEntry.date = selectedDate
                sleepEntry.createdAt = Date()
            }
            
            sleepEntry.hoursSlept = hoursSlept
            sleepEntry.sleepQuality = Int16(sleepQuality * 2) // Convert to 0-10 scale for storage
            sleepEntry.disturbances = encodeDisturbances(selectedDisturbances)
            sleepEntry.notes = notes.isEmpty ? nil : notes
            
            try viewContext.save()
            print("DEBUG: Sleep entry saved successfully")
            
            loadRecentSleepEntries()
            showingSaveConfirmation = true
            
        } catch {
            print("DEBUG ERROR: Failed to save sleep entry: \(error)")
        }
    }
    
    private func loadExistingSleepEntry() {
        print("DEBUG: Loading existing sleep entry for \(selectedDate)")
        
        let request: NSFetchRequest<SleepEntry> = SleepEntry.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let entries = try viewContext.fetch(request)
            
            if let entry = entries.first {
                print("DEBUG: Found existing sleep entry")
                hoursSlept = entry.hoursSlept
                sleepQuality = Double(entry.sleepQuality) / 2.0 // Convert from 0-10 to 0-5
                selectedDisturbances = decodeDisturbances(entry.disturbances) ?? []
                notes = entry.notes ?? ""
            } else {
                print("DEBUG: No existing sleep entry found, using defaults")
                hoursSlept = 8.0
                sleepQuality = 0
                selectedDisturbances.removeAll()
                notes = ""
            }
        } catch {
            print("DEBUG ERROR: Failed to load existing sleep entry: \(error)")
        }
    }
    
    private func loadRecentSleepEntries() {
        let request: NSFetchRequest<SleepEntry> = SleepEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SleepEntry.date, ascending: false)]
        request.fetchLimit = 10
        
        do {
            recentSleepEntries = try viewContext.fetch(request)
            print("DEBUG: Loaded \(recentSleepEntries.count) recent sleep entries")
        } catch {
            print("DEBUG ERROR: Failed to load recent sleep entries: \(error)")
            recentSleepEntries = []
        }
    }
    
    private func calculateAverageSleep() -> Double? {
        let last7Entries = Array(recentSleepEntries.prefix(7))
        guard !last7Entries.isEmpty else { return nil }
        
        let totalHours = last7Entries.reduce(0.0) { $0 + $1.hoursSlept }
        return totalHours / Double(last7Entries.count)
    }
    
    private func encodeDisturbances(_ disturbances: Set<String>) -> String {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(Array(disturbances))
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            print("DEBUG ERROR: Failed to encode disturbances: \(error)")
            return "[]"
        }
    }
    
    private func decodeDisturbances(_ disturbancesString: String?) -> Set<String>? {
        guard let disturbancesString = disturbancesString,
              let data = disturbancesString.data(using: .utf8) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        do {
            let array = try decoder.decode([String].self, from: data)
            return Set(array)
        } catch {
            print("DEBUG ERROR: Failed to decode disturbances: \(error)")
            return nil
        }
    }
    
    private func qualityDescription(for quality: Double) -> String {
        switch Int(quality) {
        case 0: return "Not rated"
        case 1: return "Very Poor"
        case 2: return "Poor"
        case 3: return "Fair"
        case 4: return "Good"
        case 5: return "Excellent"
        default: return "Unknown"
        }
    }
}

struct MinimalSleepEntryRow: View {
    let entry: SleepEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(entry.date, formatter: dateFormatter)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Text(String(format: "%.1f hours", entry.hoursSlept))
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                Text("Quality: \(Int(entry.sleepQuality / 2))/5")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Circle()
                    .fill(qualityColor(for: Double(entry.sleepQuality) / 2))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
    
    private func qualityColor(for quality: Double) -> Color {
        switch Int(quality) {
        case 0: return DesignSystem.Colors.tertiaryText
        case 1...2: return DesignSystem.Colors.softPink
        case 3: return DesignSystem.Colors.paleOrange
        case 4...5: return DesignSystem.Colors.mutedGreen
        default: return DesignSystem.Colors.tertiaryText
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}