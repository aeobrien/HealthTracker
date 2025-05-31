// Replace your existing PeriodTrackingView.swift with this complete minimal version

import SwiftUI
import CoreData

struct PeriodTrackingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var currentPeriodStatus: PeriodStatus = .off
    @State private var selectedFlow = "Medium"
    @State private var selectedPeriodSymptoms: [String: Double] = [:]
    @State private var selectedEmotions: Set<String> = []
    @State private var selectedDischarge = "None"
    @State private var sexualActivity = false
    @State private var notes = ""
    @State private var showingSaveConfirmation = false
    @State private var periodEntries: [PeriodEntry] = []
    @State private var estimatedNextPeriod: Date?
    @State private var currentCycleDay: Int = 0
    @State private var lastPeriodStart: Date?
    
    // Minimal UI state
    @State private var expandedSections: Set<String> = ["status"] // Start with status expanded
    
    private let flowOptions = ["Spotting", "Light", "Medium", "Heavy"]
    
    private let periodSymptoms = [
        "Cramps", "Bloating", "Breast Tenderness", "Back Pain",
        "Headache", "Nausea", "Acne", "Food Cravings"
    ]
    
    private let emotions = [
        "Happy", "Sad", "Irritable", "Anxious", "Calm",
        "Energetic", "Tired", "Moody", "Confident", "Stressed"
    ]
    
    private let dischargeTypes = [
        "None", "Dry", "Sticky", "Creamy", "Watery", "Raw egg white"
    ]
    
    enum PeriodStatus {
        case on, off
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.screenBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.large) {
                    // Header section
                    headerSection
                    
                    // Current status and cycle info
                    statusSection
                    
                    // Period details (only when period is on)
                    if currentPeriodStatus == .on {
                        periodDetailsSection
                    }
                    
                    // Emotions and additional tracking
                    emotionsSection
                    additionalTrackingSection
                    notesSection
                    
                    // Recent history
                    historySection
                }
                .padding(DesignSystem.Spacing.large)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("DEBUG: Minimal PeriodTrackingView appeared")
            loadPeriodEntries()
            calculateCycleInfo()
            loadSelectedDateEntry()
            debugPeriodData()
        }
        .onChange(of: selectedDate) { _ in
            loadSelectedDateEntry()
        }
        .sheet(isPresented: $showingDatePicker) {
            MinimalDatePicker(selectedDate: $selectedDate) {
                loadSelectedDateEntry()
            }
        }
        .alert("Period Entry Saved", isPresented: $showingSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your period entry has been saved")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        MinimalCard {
            VStack(spacing: DesignSystem.Spacing.medium) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Period Tracking")
                            .font(DesignSystem.Typography.largeTitle)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(selectedDate, formatter: subtleDateFormatter)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    DelicateButton(title: "Date", action: { showingDatePicker = true }, style: .subtle)
                }
            }
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        CollapsibleSection(
            title: "Period Status",
            subtitle: statusSubtitle,
            isExpanded: expandedSections.contains("status"),
            color: DesignSystem.Colors.softPink
        ) {
            toggleSection("status")
        } content: {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Status toggle
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                    Text("Current Status")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(["Off", "On"], id: \.self) { status in
                            let isSelected = (status == "On" && currentPeriodStatus == .on) || (status == "Off" && currentPeriodStatus == .off)
                            
                            Button(action: {
                                currentPeriodStatus = status == "On" ? .on : .off
                            }) {
                                Text(status)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(isSelected ? DesignSystem.Colors.softPink : DesignSystem.Colors.secondaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, DesignSystem.Spacing.large)
                                    .padding(.vertical, DesignSystem.Spacing.medium)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isSelected ? DesignSystem.Colors.softPink.opacity(0.1) : Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(isSelected ? DesignSystem.Colors.softPink.opacity(0.4) : DesignSystem.Colors.tertiaryText, lineWidth: 0.5)
                                            )
                                    )
                            }
                        }
                    }
                }
                
                // Cycle information
                if let nextPeriod = estimatedNextPeriod {
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        HStack {
                            Image(systemName: "calendar.circle")
                                .foregroundColor(DesignSystem.Colors.softPink)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("Next period predicted")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                Text(nextPeriod, formatter: dateFormatter)
                                    .font(DesignSystem.Typography.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(DesignSystem.Colors.softPink)
                            }
                            
                            Spacer()
                            
                            if currentCycleDay > 0 {
                                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                                    Text("Cycle day")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                    
                                    Text("\(currentCycleDay)")
                                        .font(DesignSystem.Typography.title)
                                        .fontWeight(.light)
                                        .foregroundColor(DesignSystem.Colors.primaryBlue)
                                }
                            }
                        }
                        
                        DelicateButton(
                            title: currentPeriodStatus == .on ? "Log Period Day" : "Log Off Day",
                            action: logPeriodStatus,
                            style: .secondary
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Period Details Section
    
    private var periodDetailsSection: some View {
        CollapsibleSection(
            title: "Period Details",
            subtitle: periodDetailsSubtitle,
            isExpanded: expandedSections.contains("details"),
            color: DesignSystem.Colors.softPink
        ) {
            toggleSection("details")
        } content: {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Flow selection
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                    Text("Flow Intensity")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(flowOptions, id: \.self) { flow in
                            Button(action: { selectedFlow = flow }) {
                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    Circle()
                                        .fill(flowColor(for: flow))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(flow)
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(selectedFlow == flow ? DesignSystem.Colors.softPink : DesignSystem.Colors.secondaryText)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.small)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedFlow == flow ? DesignSystem.Colors.softPink.opacity(0.1) : Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedFlow == flow ? DesignSystem.Colors.softPink.opacity(0.4) : DesignSystem.Colors.tertiaryText, lineWidth: 0.5)
                                        )
                                )
                            }
                        }
                    }
                }
                
                // Period symptoms
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                    Text("Symptoms")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        ForEach(periodSymptoms, id: \.self) { symptom in
                            MinimalSlider(
                                title: symptom,
                                value: Binding(
                                    get: { selectedPeriodSymptoms[symptom] ?? 0 },
                                    set: { selectedPeriodSymptoms[symptom] = $0 }
                                ),
                                range: 0...5,
                                step: 1,
                                unit: "/5",
                                color: DesignSystem.Colors.softPink
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Emotions Section
    
    private var emotionsSection: some View {
        CollapsibleSection(
            title: "Emotions & Mood",
            subtitle: emotionsSubtitle,
            isExpanded: expandedSections.contains("emotions"),
            color: DesignSystem.Colors.lightLavender
        ) {
            toggleSection("emotions")
        } content: {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.small) {
                ForEach(emotions, id: \.self) { emotion in
                    SimpleToggleChip(
                        text: emotion,
                        isSelected: selectedEmotions.contains(emotion),
                        color: DesignSystem.Colors.lightLavender
                    ) {
                        toggleEmotion(emotion)
                    }
                }
            }
        }
    }
    
    // MARK: - Additional Tracking Section
    
    private var additionalTrackingSection: some View {
        CollapsibleSection(
            title: "Additional Tracking",
            subtitle: additionalTrackingSubtitle,
            isExpanded: expandedSections.contains("additional"),
            color: DesignSystem.Colors.mutedGreen
        ) {
            toggleSection("additional")
        } content: {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Discharge type
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                    Text("Discharge Type")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: DesignSystem.Spacing.small) {
                        ForEach(dischargeTypes, id: \.self) { discharge in
                            SimpleToggleChip(
                                text: discharge,
                                isSelected: selectedDischarge == discharge,
                                color: DesignSystem.Colors.mutedGreen
                            ) {
                                selectedDischarge = discharge
                            }
                        }
                    }
                }
                
                // Sexual activity
                HStack {
                    Text("Sexual Activity")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Toggle("", isOn: $sexualActivity)
                        .tint(DesignSystem.Colors.mutedGreen)
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
                
                TextField("How are you feeling today?", text: $notes, axis: .vertical)
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
    
    // MARK: - History Section
    
    private var historySection: some View {
        CollapsibleSection(
            title: "Recent Periods",
            subtitle: historySubtitle,
            isExpanded: expandedSections.contains("history"),
            color: DesignSystem.Colors.primaryBlue
        ) {
            toggleSection("history")
        } content: {
            VStack(spacing: DesignSystem.Spacing.medium) {
                if periodEntries.isEmpty {
                    Text("No period entries yet")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding()
                } else {
                    ForEach(periodEntries.prefix(5), id: \.createdAt) { entry in
                        MinimalPeriodEntryRow(entry: entry)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusSubtitle: String {
        if currentPeriodStatus == .on {
            return "Period is currently on"
        } else {
            return "Period is currently off"
        }
    }
    
    private var periodDetailsSubtitle: String {
        if currentPeriodStatus == .on {
            let trackedSymptoms = selectedPeriodSymptoms.values.filter { $0 > 0 }.count
            return "\(selectedFlow) flow, \(trackedSymptoms) symptoms"
        }
        return "Not applicable"
    }
    
    private var emotionsSubtitle: String {
        return selectedEmotions.isEmpty ? "No emotions selected" : "\(selectedEmotions.count) emotions tracked"
    }
    
    private var additionalTrackingSubtitle: String {
        var items: [String] = []
        if selectedDischarge != "None" { items.append("discharge") }
        if sexualActivity { items.append("sexual activity") }
        return items.isEmpty ? "Nothing tracked" : items.joined(separator: ", ")
    }
    
    private var historySubtitle: String {
        return periodEntries.isEmpty ? "No entries yet" : "\(periodEntries.count) entries"
    }
    
    private var subtleDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    // MARK: - Actions
    
    private func toggleSection(_ section: String) {
        print("DEBUG: Toggling section: \(section)")
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
    
    private func toggleEmotion(_ emotion: String) {
        if selectedEmotions.contains(emotion) {
            selectedEmotions.remove(emotion)
        } else {
            selectedEmotions.insert(emotion)
        }
    }
    
    private func flowColor(for flow: String) -> Color {
        switch flow {
        case "Spotting": return DesignSystem.Colors.softPink.opacity(0.3)
        case "Light": return DesignSystem.Colors.softPink.opacity(0.5)
        case "Medium": return DesignSystem.Colors.softPink.opacity(0.7)
        case "Heavy": return DesignSystem.Colors.softPink
        default: return DesignSystem.Colors.tertiaryText
        }
    }
    
    // MARK: - Data Management (keeping your existing logic)
    
    private func logPeriodStatus() {
        print("DEBUG: Logging period status: \(currentPeriodStatus)")
        
        let periodEntry = PeriodEntry(context: viewContext)
        periodEntry.startDate = selectedDate
        periodEntry.flow = currentPeriodStatus == .on ? selectedFlow : nil
        periodEntry.createdAt = Date()
        
        var entryNotes = currentPeriodStatus == .on ? "Status: On" : "Status: Off"
        
        if currentPeriodStatus == .on {
            let symptomsData = selectedPeriodSymptoms.compactMapValues { $0 > 0 ? $0 : nil }
            if !symptomsData.isEmpty {
                let symptomsJSON = encodePeriodSymptoms(symptomsData)
                entryNotes += "\nSymptoms: \(symptomsJSON)"
            }
        }
        
        if !selectedEmotions.isEmpty {
            entryNotes += "\nEmotions: \(selectedEmotions.joined(separator: ", "))"
        }
        
        entryNotes += "\nDischarge: \(selectedDischarge)"
        entryNotes += "\nSexual Activity: \(sexualActivity ? "Yes" : "No")"
        
        if !notes.isEmpty {
            entryNotes += "\nNotes: \(notes)"
        }
        
        periodEntry.notes = entryNotes
        
        do {
            try viewContext.save()
            print("DEBUG: Period entry saved successfully")
            
            resetPeriodFormToDefaults()
            loadPeriodEntries()
            calculateCycleInfo()
            showingSaveConfirmation = true
        } catch {
            print("DEBUG ERROR: Failed to save period entry: \(error)")
        }
    }
    
    private func resetPeriodFormToDefaults() {
        print("DEBUG: Resetting period form to defaults")
        selectedPeriodSymptoms.removeAll()
        selectedEmotions.removeAll()
        selectedDischarge = "None"
        sexualActivity = false
        notes = ""
        print("DEBUG: Period form reset completed")
    }
    
    private func loadPeriodEntries() {
        let request: NSFetchRequest<PeriodEntry> = PeriodEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PeriodEntry.startDate, ascending: false)]
        request.fetchLimit = 20
        
        do {
            periodEntries = try viewContext.fetch(request)
            print("DEBUG: Loaded \(periodEntries.count) period entries")
        } catch {
            print("DEBUG ERROR: Failed to load period entries: \(error)")
            periodEntries = []
        }
    }
    
    private func calculateCycleInfo() {
        guard !periodEntries.isEmpty else {
            estimatedNextPeriod = nil
            currentCycleDay = 0
            return
        }
        
        var lastCycleStart: Date?
        
        for (index, entry) in periodEntries.enumerated() {
            if let notes = entry.notes, notes.contains("Status: On") {
                if index == periodEntries.count - 1 {
                    lastCycleStart = entry.startDate
                    break
                } else {
                    let previousEntry = periodEntries[index + 1]
                    let daysBetween = Calendar.current.dateComponents([.day], from: previousEntry.startDate, to: entry.startDate).day ?? 0
                    
                    if daysBetween > 7 || (previousEntry.notes?.contains("Status: Off") == true) {
                        lastCycleStart = entry.startDate
                        break
                    }
                }
            }
        }
        
        if let cycleStart = lastCycleStart {
            lastPeriodStart = cycleStart
            let daysSinceStart = Calendar.current.dateComponents([.day], from: cycleStart, to: Date()).day ?? 0
            currentCycleDay = daysSinceStart + 1
            estimatedNextPeriod = Calendar.current.date(byAdding: .day, value: 28, to: cycleStart)
            print("DEBUG: Last cycle started on \(cycleStart), current day: \(currentCycleDay)")
        }
    }
    
    private func loadSelectedDateEntry() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let dateEntries = periodEntries.filter { entry in
            entry.startDate >= startOfDay && entry.startDate < endOfDay
        }
        
        if let latestEntry = dateEntries.first {
            if let notes = latestEntry.notes {
                currentPeriodStatus = notes.contains("Status: On") ? .on : .off
                
                if let flow = latestEntry.flow {
                    selectedFlow = flow
                }
                
                parseEntryNotes(notes)
            }
        } else {
            currentPeriodStatus = .off
            selectedFlow = "Medium"
            selectedPeriodSymptoms.removeAll()
            selectedEmotions.removeAll()
            selectedDischarge = "None"
            sexualActivity = false
            notes = ""
        }
    }
    
    private func parseEntryNotes(_ notes: String) {
        let lines = notes.components(separatedBy: "\n")
        
        for line in lines {
            if line.hasPrefix("Emotions: ") {
                let emotionsString = String(line.dropFirst(10))
                selectedEmotions = Set(emotionsString.components(separatedBy: ", "))
            } else if line.hasPrefix("Discharge: ") {
                selectedDischarge = String(line.dropFirst(11))
            } else if line.hasPrefix("Sexual Activity: ") {
                sexualActivity = String(line.dropFirst(17)) == "Yes"
            } else if line.hasPrefix("Notes: ") {
                self.notes = String(line.dropFirst(7))
            }
        }
    }
    
    private func encodePeriodSymptoms(_ symptoms: [String: Double]) -> String {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(symptoms)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            print("DEBUG ERROR: Failed to encode period symptoms: \(error)")
            return "{}"
        }
    }
    
    private func debugPeriodData() {
        print("=== PERIOD TRACKING VIEW - DEBUG PERIOD DATA ANALYSIS ===")
        
        let request: NSFetchRequest<PeriodEntry> = PeriodEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PeriodEntry.startDate, ascending: false)]
        
        do {
            let allEntries = try viewContext.fetch(request)
            print("DEBUG: Total period entries in database: \(allEntries.count)")
            print("DEBUG: Period entries state variable count: \(periodEntries.count)")
            
            for (index, entry) in allEntries.enumerated() {
                print("DEBUG Entry \(index + 1):")
                print("  - Date: \(entry.startDate)")
                print("  - Notes: \(entry.notes ?? "No notes")")
                print("  - Flow: \(entry.flow ?? "No flow")")
                print("  - Created: \(entry.createdAt)")
                
                if let notes = entry.notes {
                    if notes.contains("Status: On") {
                        print("  ➤ This is an ON entry")
                    } else if notes.contains("Status: Off") {
                        print("  ➤ This is an OFF entry")
                    } else {
                        print("  ➤ Status unclear from notes")
                    }
                }
            }
            
            print("=== CYCLE CALCULATION DEBUG ===")
            debugCycleCalculation()
            
        } catch {
            print("DEBUG ERROR: Failed to fetch period entries: \(error)")
        }
    }
    
    private func debugCycleCalculation() {
        guard !periodEntries.isEmpty else {
            print("DEBUG: No period entries found for cycle calculation")
            return
        }
        
        print("DEBUG: Analyzing \(periodEntries.count) period entries for cycle calculation")
        
        var lastCycleStart: Date?
        
        for (index, entry) in periodEntries.enumerated() {
            print("DEBUG: Entry \(index + 1) - Date: \(entry.startDate)")
            
            if let notes = entry.notes {
                print("  Notes: \(notes)")
                
                if notes.contains("Status: On") {
                    print("  ➤ Found ON entry")
                    
                    if index == periodEntries.count - 1 {
                        print("  ➤ This is the oldest entry and it's ON - using as cycle start")
                        lastCycleStart = entry.startDate
                        break
                    } else {
                        let previousEntry = periodEntries[index + 1]
                        let daysBetween = Calendar.current.dateComponents([.day], from: previousEntry.startDate, to: entry.startDate).day ?? 0
                        
                        print("  ➤ Days between this and previous entry: \(daysBetween)")
                        
                        if let prevNotes = previousEntry.notes {
                            print("  ➤ Previous entry notes: \(prevNotes)")
                        }
                        
                        if daysBetween > 7 || (previousEntry.notes?.contains("Status: Off") == true) {
                            print("  ➤ This appears to be a new cycle start")
                            lastCycleStart = entry.startDate
                            break
                        } else {
                            print("  ➤ This appears to be continuation of same period")
                        }
                    }
                }
            }
        }
        
        if let cycleStart = lastCycleStart {
            let daysSinceStart = Calendar.current.dateComponents([.day], from: cycleStart, to: Date()).day ?? 0
            let calculatedDay = (daysSinceStart % 28) + 1
            
            print("DEBUG: Cycle start found: \(cycleStart)")
            print("DEBUG: Days since start: \(daysSinceStart)")
            print("DEBUG: Calculated cycle day: \(calculatedDay)")
            print("DEBUG: Current cycle day state variable: \(currentCycleDay)")
            print("DEBUG: Estimated next period: \(estimatedNextPeriod?.description ?? "None")")
        } else {
            print("DEBUG: No valid cycle start found")
        }
    }
}

// MARK: - Supporting Views

struct MinimalPeriodEntryRow: View {
    let entry: PeriodEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(entry.startDate, formatter: dateFormatter)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if let notes = entry.notes {
                    let displayNotes = extractDisplayNotes(from: notes)
                    if !displayNotes.isEmpty {
                        Text(displayNotes)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .lineLimit(2)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: DesignSystem.Spacing.small) {
                if let notes = entry.notes {
                    if notes.contains("Status: On") {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Circle()
                                .fill(DesignSystem.Colors.softPink)
                                .frame(width: 6, height: 6)
                            Text("On")
                                .font(DesignSystem.Typography.micro)
                                .foregroundColor(DesignSystem.Colors.softPink)
                        }
                    } else {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Circle()
                                .fill(DesignSystem.Colors.tertiaryText)
                                .frame(width: 6, height: 6)
                            Text("Off")
                                .font(DesignSystem.Typography.micro)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                    }
                }
                
                if let flow = entry.flow {
                    Text(flow)
                        .font(DesignSystem.Typography.micro)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.softPink.opacity(0.1))
                        .foregroundColor(DesignSystem.Colors.softPink)
                        .cornerRadius(6)
                }
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: DesignSystem.Shadows.subtle, radius: 2, x: 0, y: 1)
    }
    
    private func extractDisplayNotes(from notes: String) -> String {
        let lines = notes.components(separatedBy: "\n")
        var displayLines: [String] = []
        
        for line in lines {
            if line.hasPrefix("Emotions: ") && !line.hasSuffix("Emotions: ") {
                displayLines.append(line)
            } else if line.hasPrefix("Notes: ") {
                displayLines.append(String(line.dropFirst(7)))
            }
        }
        
        return displayLines.joined(separator: " • ")
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}
