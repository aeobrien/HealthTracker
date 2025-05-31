// Replace your existing DailyTrackingView.swift with this cleaned version
// Make sure you've added the DesignSystem.swift file to your project first

import SwiftUI
import CoreData

struct DailyTrackingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var symptomRatings: [String: Double] = [:]
    @State private var notes = ""
    @State private var symptoms: [PredefinedSymptom] = []
    @State private var groupedSymptoms: [String: [PredefinedSymptom]] = [:]
    @State private var showingSaveConfirmation = false
    @State private var isLoading = true
    @State private var showingEditModal = false
    @State private var selectedTags: Set<String> = []
    @State private var newTagText = ""
    @State private var allTags: [String] = []
    @State private var showingTagDeleteAlert = false
    @State private var tagToDelete = ""
    
    // Sleep tracking
    @State private var hoursSlept: Double = 8.0
    @State private var sleepQuality: Double = 0
    @State private var selectedDisturbances: Set<String> = []
    
    // Lifestyle tracking
    @State private var caffeineIntake = "N/A"
    @State private var alcoholIntake = "N/A"
    @State private var waterIntake = "N/A"
    @State private var exerciseLevel = "N/A"
    @State private var energyLevel: Double = 0
    @State private var stressLevel: Double = 0
    @State private var selectedMedications: Set<String> = []
    @State private var selectedDietaryTriggers: Set<String> = []
    
    // Minimal UI state
    @State private var expandedSections: Set<String> = ["symptoms"] // Start with symptoms expanded
    
    private let sleepDisturbances = [
        "Difficulty falling asleep", "Woke up frequently", "Woke up too early",
        "Nightmares", "Restless legs", "Snoring", "Hot flashes", "Bathroom breaks"
    ]
    
    private let commonMedications = [
        "Ibuprofen", "Acetaminophen", "Aspirin", "Sumatriptan",
        "Birth Control", "Antidepressants", "Vitamins", "Supplements"
    ]
    
    private let dietaryTriggers = [
        "Chocolate", "Cheese", "Wine", "Beer", "Citrus Fruits",
        "Nuts", "Processed Foods", "MSG", "Caffeine", "Gluten"
    ]
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.screenBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.large) {
                    // Minimal header with date
                    headerSection
                    
                    if isLoading {
                        loadingView
                    } else {
                        // Core sections - only show what's essential
                        symptomsSection
                        sleepSection
                        lifestyleSection
                        tagsAndNotesSection
                        
                        // Clean save button
                        saveButton
                    }
                }
                .padding(DesignSystem.Spacing.large)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("DEBUG: Minimal DailyTrackingView appeared")
            loadSymptoms()
            loadExistingEntry()
            loadAllTags()
        }
        .sheet(isPresented: $showingDatePicker) {
            MinimalDatePicker(selectedDate: $selectedDate) {
                loadExistingEntry()
            }
        }
        .sheet(isPresented: $showingEditModal) {
            MinimalEditModal(
                context: viewContext,
                onSymptomsChanged: loadSymptoms
            )
        }
        .alert("Entry Saved", isPresented: $showingSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your daily entry has been saved")
        }
        .alert("Delete Tag", isPresented: $showingTagDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteTag(tagToDelete)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Remove '\(tagToDelete)' from your tags?")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        MinimalCard {
            VStack(spacing: DesignSystem.Spacing.medium) {
                // Date and edit controls
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Daily Entry")
                            .font(DesignSystem.Typography.largeTitle)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text(selectedDate, formatter: subtleDateFormatter)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Button(action: { showingDatePicker = true }) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .stroke(DesignSystem.Colors.tertiaryText, lineWidth: 0.5)
                                )
                        }
                        
                        Button(action: { showingEditModal = true }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .stroke(DesignSystem.Colors.tertiaryText, lineWidth: 0.5)
                                )
                        }
                    }
                }
                
                // Quick status indicator
                if hasAnyData {
                    HStack {
                        Circle()
                            .fill(DesignSystem.Colors.mutedGreen)
                            .frame(width: 6, height: 6)
                        
                        Text("Data recorded for this day")
                            .font(DesignSystem.Typography.micro)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Symptoms Section
    
    private var symptomsSection: some View {
        CollapsibleSection(
            title: "Symptoms",
            subtitle: trackingSubtitle(for: symptomRatings),
            isExpanded: expandedSections.contains("symptoms"),
            color: DesignSystem.Colors.primaryBlue
        ) {
            toggleSection("symptoms")
        } content: {
            VStack(spacing: DesignSystem.Spacing.large) {
                ForEach(Array(groupedSymptoms.keys.sorted()), id: \.self) { category in
                    MinimalSymptomCategory(
                        category: category,
                        symptoms: groupedSymptoms[category] ?? [],
                        ratings: $symptomRatings
                    )
                }
            }
        }
    }
    
    // MARK: - Sleep Section
    
    private var sleepSection: some View {
        CollapsibleSection(
            title: "Sleep",
            subtitle: sleepSubtitle,
            isExpanded: expandedSections.contains("sleep"),
            color: DesignSystem.Colors.softIndigo
        ) {
            toggleSection("sleep")
        } content: {
            VStack(spacing: DesignSystem.Spacing.large) {
                MinimalSlider(
                    title: "Hours Slept",
                    value: $hoursSlept,
                    range: 0...12,
                    step: 0.5,
                    unit: "h",
                    color: DesignSystem.Colors.softIndigo
                )
                
                MinimalSlider(
                    title: "Sleep Quality",
                    value: $sleepQuality,
                    range: 0...5,
                    step: 1,
                    unit: "/5",
                    color: DesignSystem.Colors.softIndigo
                )
                
                if !selectedDisturbances.isEmpty || expandedSections.contains("sleep") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        Text("Sleep Disturbances")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.small) {
                            ForEach(sleepDisturbances, id: \.self) { disturbance in
                                SimpleToggleChip(
                                    text: disturbance,
                                    isSelected: selectedDisturbances.contains(disturbance),
                                    color: DesignSystem.Colors.softIndigo
                                ) {
                                    toggleDisturbance(disturbance)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Lifestyle Section
    
    private var lifestyleSection: some View {
        CollapsibleSection(
            title: "Lifestyle",
            subtitle: lifestyleSubtitle,
            isExpanded: expandedSections.contains("lifestyle"),
            color: DesignSystem.Colors.mutedGreen
        ) {
            toggleSection("lifestyle")
        } content: {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Simple intake tracking
                VStack(spacing: DesignSystem.Spacing.medium) {
                    MinimalIntakeRow(title: "Caffeine", value: $caffeineIntake, color: DesignSystem.Colors.mutedGreen)
                    MinimalIntakeRow(title: "Alcohol", value: $alcoholIntake, color: DesignSystem.Colors.mutedGreen)
                    MinimalIntakeRow(title: "Water", value: $waterIntake, color: DesignSystem.Colors.mutedGreen)
                    MinimalIntakeRow(title: "Exercise", value: $exerciseLevel, color: DesignSystem.Colors.mutedGreen)
                }
                
                MinimalSlider(
                    title: "Energy Level",
                    value: $energyLevel,
                    range: 0...5,
                    step: 1,
                    unit: "/5",
                    color: DesignSystem.Colors.mutedGreen
                )
                
                MinimalSlider(
                    title: "Stress Level",
                    value: $stressLevel,
                    range: 0...5,
                    step: 1,
                    unit: "/5",
                    color: DesignSystem.Colors.mutedGreen
                )
                
                // Only show medications/triggers if there are selections or section is expanded
                if !selectedMedications.isEmpty || expandedSections.contains("lifestyle") {
                    medicationsSection
                }
                
                if !selectedDietaryTriggers.isEmpty || expandedSections.contains("lifestyle") {
                    triggersSection
                }
            }
        }
    }
    
    private var medicationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Medications")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.small) {
                ForEach(commonMedications, id: \.self) { medication in
                    SimpleToggleChip(
                        text: medication,
                        isSelected: selectedMedications.contains(medication),
                        color: DesignSystem.Colors.mutedGreen
                    ) {
                        toggleMedication(medication)
                    }
                }
            }
        }
    }
    
    private var triggersSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Dietary Triggers")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.small) {
                ForEach(dietaryTriggers, id: \.self) { trigger in
                    SimpleToggleChip(
                        text: trigger,
                        isSelected: selectedDietaryTriggers.contains(trigger),
                        color: DesignSystem.Colors.mutedGreen
                    ) {
                        toggleTrigger(trigger)
                    }
                }
            }
        }
    }
    
    // MARK: - Tags and Notes Section
    
    private var tagsAndNotesSection: some View {
        MinimalCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                // Tags
                if !allTags.isEmpty || !newTagText.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        Text("Tags")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        if !allTags.isEmpty {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.small) {
                                ForEach(allTags, id: \.self) { tag in
                                    TagChip(
                                        text: tag,
                                        isSelected: selectedTags.contains(tag),
                                        onToggle: { toggleTag(tag) },
                                        onDelete: { deleteTagAction(tag) }
                                    )
                                }
                            }
                        }
                        
                        // Add new tag
                        HStack {
                            TextField("Add tag...", text: $newTagText)
                                .font(DesignSystem.Typography.body)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(.horizontal, DesignSystem.Spacing.small)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(DesignSystem.Colors.tertiaryText, lineWidth: 0.5)
                                )
                            
                            DelicateButton(title: "Add", action: addNewTag, style: .subtle)
                                .disabled(newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                
                // Notes
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
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        DelicateButton(
            title: hasAnyData ? "Update Entry" : "Save Entry",
            action: saveDailyEntry,
            style: .primary
        )
        .padding(.horizontal, DesignSystem.Spacing.large)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            ProgressView()
                .tint(DesignSystem.Colors.primaryBlue)
            
            Text("Loading...")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .padding(DesignSystem.Spacing.xxl)
    }
    
    // MARK: - Helper Views and Computed Properties
    
    private var hasAnyData: Bool {
        !symptomRatings.values.allSatisfy { $0 == 0 } ||
        hoursSlept != 8.0 ||
        sleepQuality != 0 ||
        !selectedDisturbances.isEmpty ||
        energyLevel != 0 ||
        stressLevel != 0 ||
        !selectedMedications.isEmpty ||
        !selectedDietaryTriggers.isEmpty ||
        !notes.isEmpty ||
        !selectedTags.isEmpty
    }
    
    private var sleepSubtitle: String {
        if hoursSlept != 8.0 || sleepQuality != 0 || !selectedDisturbances.isEmpty {
            return "\(String(format: "%.1f", hoursSlept))h sleep, quality \(Int(sleepQuality))/5"
        }
        return "Not tracked"
    }
    
    private var lifestyleSubtitle: String {
        let trackedItems = [caffeineIntake, alcoholIntake, waterIntake, exerciseLevel].filter { $0 != "N/A" }
        if !trackedItems.isEmpty || energyLevel != 0 || stressLevel != 0 {
            return "\(trackedItems.count) items tracked"
        }
        return "Not tracked"
    }
    
    private func trackingSubtitle(for ratings: [String: Double]) -> String {
        let trackedSymptoms = ratings.values.filter { $0 > 0 }.count
        return trackedSymptoms > 0 ? "\(trackedSymptoms) symptoms tracked" : "No symptoms"
    }
    
    private var subtleDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
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
    
    private func toggleDisturbance(_ disturbance: String) {
        if selectedDisturbances.contains(disturbance) {
            selectedDisturbances.remove(disturbance)
        } else {
            selectedDisturbances.insert(disturbance)
        }
    }
    
    private func toggleMedication(_ medication: String) {
        if selectedMedications.contains(medication) {
            selectedMedications.remove(medication)
        } else {
            selectedMedications.insert(medication)
        }
    }
    
    private func toggleTrigger(_ trigger: String) {
        if selectedDietaryTriggers.contains(trigger) {
            selectedDietaryTriggers.remove(trigger)
        } else {
            selectedDietaryTriggers.insert(trigger)
        }
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    private func deleteTagAction(_ tag: String) {
        tagToDelete = tag
        showingTagDeleteAlert = true
    }
    
    private func addNewTag() {
        let trimmedTag = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty && !allTags.contains(trimmedTag) else { return }
        
        allTags.append(trimmedTag)
        selectedTags.insert(trimmedTag)
        UserDefaults.standard.set(allTags, forKey: "CustomTags")
        newTagText = ""
        print("DEBUG: Added new tag: \(trimmedTag)")
    }
    
    private func deleteTag(_ tag: String) {
        allTags.removeAll { $0 == tag }
        selectedTags.remove(tag)
        UserDefaults.standard.set(allTags, forKey: "CustomTags")
        print("DEBUG: Deleted tag: \(tag)")
    }
    
    // MARK: - Data Loading and Saving (keeping your existing logic)
    
    private func loadSymptoms() {
        print("DEBUG: Loading symptoms in minimal DailyTrackingView")
        isLoading = true
        
        groupedSymptoms = SymptomDataManager.shared.fetchSymptomsByCategory(context: viewContext)
        symptoms = SymptomDataManager.shared.fetchActiveSymptoms(context: viewContext)
        
        for symptom in symptoms {
            if symptomRatings[symptom.name] == nil {
                symptomRatings[symptom.name] = 0
            }
        }
        
        isLoading = false
        print("DEBUG: Loaded \(symptoms.count) symptoms, \(groupedSymptoms.keys.count) categories")
    }
    
    private func loadExistingEntry() {
        print("DEBUG: Loading existing entry for \(selectedDate)")
        loadExistingDailyEntry()
        loadExistingSleepEntry()
        loadExistingLifestyleEntry()
    }
    
    private func loadExistingDailyEntry() {
        let request: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let entries = try viewContext.fetch(request)
            
            if let entry = entries.first {
                for symptom in symptoms {
                    symptomRatings[symptom.name] = 0
                }
                
                if let ratings = entry.symptomRatings as? Set<SymptomRating> {
                    for rating in ratings {
                        symptomRatings[rating.symptomName] = Double(rating.rating)
                    }
                }
                
                notes = entry.notes ?? ""
                
                if let entryNotes = entry.notes {
                    if entryNotes.contains("Tags: ") {
                        let components = entryNotes.components(separatedBy: "Tags: ")
                        if components.count > 1 {
                            let tagsString = components[1].components(separatedBy: "\n").first ?? ""
                            selectedTags = Set(tagsString.components(separatedBy: ", ").filter { !$0.isEmpty })
                            notes = entryNotes.replacingOccurrences(of: "\nTags: \(tagsString)", with: "")
                                .replacingOccurrences(of: "Tags: \(tagsString)", with: "")
                        }
                    }
                }
            } else {
                for symptom in symptoms {
                    symptomRatings[symptom.name] = 0
                }
                notes = ""
                selectedTags.removeAll()
            }
        } catch {
            print("DEBUG ERROR: Failed to load existing daily entry: \(error)")
        }
    }
    
    private func loadExistingSleepEntry() {
        let request: NSFetchRequest<SleepEntry> = SleepEntry.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let entries = try viewContext.fetch(request)
            
            if let entry = entries.first {
                hoursSlept = entry.hoursSlept
                sleepQuality = Double(entry.sleepQuality)
                selectedDisturbances = decodeDisturbances(entry.disturbances) ?? []
            } else {
                hoursSlept = 8.0
                sleepQuality = 0
                selectedDisturbances.removeAll()
            }
        } catch {
            print("DEBUG ERROR: Failed to load existing sleep entry: \(error)")
        }
    }
    
    private func loadExistingLifestyleEntry() {
        let request: NSFetchRequest<LifestyleEntry> = LifestyleEntry.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let entries = try viewContext.fetch(request)
            
            if let entry = entries.first {
                if let entryNotes = entry.notes {
                    caffeineIntake = entryNotes.contains("Caffeine: Low") ? "Low" :
                                     entryNotes.contains("Caffeine: Medium") ? "Medium" :
                                     entryNotes.contains("Caffeine: High") ? "High" : "N/A"
                    
                    alcoholIntake = entryNotes.contains("Alcohol: Low") ? "Low" :
                                    entryNotes.contains("Alcohol: Medium") ? "Medium" :
                                    entryNotes.contains("Alcohol: High") ? "High" : "N/A"
                    
                    waterIntake = entryNotes.contains("Water: Low") ? "Low" :
                                  entryNotes.contains("Water: Medium") ? "Medium" :
                                  entryNotes.contains("Water: High") ? "High" : "N/A"
                    
                    exerciseLevel = entryNotes.contains("Exercise: Low") ? "Low" :
                                    entryNotes.contains("Exercise: Medium") ? "Medium" :
                                    entryNotes.contains("Exercise: High") ? "High" : "N/A"
                } else {
                    resetLifestyleToDefaults()
                }
                
                energyLevel = Double(entry.energyLevel)
                stressLevel = Double(entry.stressLevel)
                selectedMedications = decodeMedications(entry.medications) ?? []
                selectedDietaryTriggers = decodeDietaryTriggers(entry.dietaryTriggers) ?? []
            } else {
                resetLifestyleToDefaults()
            }
        } catch {
            print("DEBUG ERROR: Failed to load existing lifestyle entry: \(error)")
            resetLifestyleToDefaults()
        }
    }
    
    private func resetLifestyleToDefaults() {
        caffeineIntake = "N/A"
        alcoholIntake = "N/A"
        waterIntake = "N/A"
        exerciseLevel = "N/A"
        energyLevel = 0
        stressLevel = 0
        selectedMedications.removeAll()
        selectedDietaryTriggers.removeAll()
    }
    
    private func loadAllTags() {
        if let tags = UserDefaults.standard.array(forKey: "CustomTags") as? [String] {
            allTags = tags
        }
    }
    
    private func saveDailyEntry() {
        print("DEBUG: Saving minimal daily entry")
        
        // Save daily entry with symptoms
        let ratingsToSave = symptomRatings.compactMapValues { rating in
            rating > 0 ? Int(rating) : nil
        }
        
        var notesWithTags = notes
        if !selectedTags.isEmpty {
            let tagsString = selectedTags.joined(separator: ", ")
            notesWithTags += notesWithTags.isEmpty ? "Tags: \(tagsString)" : "\nTags: \(tagsString)"
        }
        
        SymptomDataManager.shared.saveDailyEntry(
            date: selectedDate,
            symptomRatings: ratingsToSave,
            notes: notesWithTags.isEmpty ? nil : notesWithTags,
            context: viewContext
        )
        
        saveSleepEntry()
        saveLifestyleEntry()
        showingSaveConfirmation = true
        print("DEBUG: Minimal daily entry saved successfully")
    }
    
    private func saveSleepEntry() {
        let request: NSFetchRequest<SleepEntry> = SleepEntry.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let existingEntries = try viewContext.fetch(request)
            let sleepEntry: SleepEntry
            
            if let existing = existingEntries.first {
                sleepEntry = existing
            } else {
                sleepEntry = SleepEntry(context: viewContext)
                sleepEntry.date = selectedDate
                sleepEntry.createdAt = Date()
            }
            
            sleepEntry.hoursSlept = hoursSlept
            sleepEntry.sleepQuality = Int16(sleepQuality)
            sleepEntry.disturbances = encodeDisturbances(selectedDisturbances)
            
            try viewContext.save()
            print("DEBUG: Sleep entry saved")
        } catch {
            print("DEBUG ERROR: Failed to save sleep entry: \(error)")
        }
    }
    
    private func saveLifestyleEntry() {
        let request: NSFetchRequest<LifestyleEntry> = LifestyleEntry.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let existingEntries = try viewContext.fetch(request)
            let lifestyleEntry: LifestyleEntry
            
            if let existing = existingEntries.first {
                lifestyleEntry = existing
            } else {
                lifestyleEntry = LifestyleEntry(context: viewContext)
                lifestyleEntry.date = selectedDate
                lifestyleEntry.createdAt = Date()
            }
            
            lifestyleEntry.caffeineIntake = Int16(intakeToNumber(caffeineIntake))
            lifestyleEntry.alcoholIntake = Int16(intakeToNumber(alcoholIntake))
            lifestyleEntry.waterIntake = Double(intakeToNumber(waterIntake))
            lifestyleEntry.exerciseMinutes = Int16(intakeToNumber(exerciseLevel))
            lifestyleEntry.energyLevel = Int16(energyLevel)
            lifestyleEntry.stressLevel = Int16(stressLevel)
            lifestyleEntry.medications = encodeMedications(selectedMedications)
            lifestyleEntry.dietaryTriggers = encodeDietaryTriggers(selectedDietaryTriggers)
            
            // Store intake levels in notes for retrieval
            var lifestyleNotes = ""
            if caffeineIntake != "N/A" { lifestyleNotes += "Caffeine: \(caffeineIntake)\n" }
            if alcoholIntake != "N/A" { lifestyleNotes += "Alcohol: \(alcoholIntake)\n" }
            if waterIntake != "N/A" { lifestyleNotes += "Water: \(waterIntake)\n" }
            if exerciseLevel != "N/A" { lifestyleNotes += "Exercise: \(exerciseLevel)\n" }
            
            lifestyleEntry.notes = lifestyleNotes.isEmpty ? nil : lifestyleNotes
            
            try viewContext.save()
            print("DEBUG: Lifestyle entry saved")
        } catch {
            print("DEBUG ERROR: Failed to save lifestyle entry: \(error)")
        }
    }
    
    // MARK: - Helper Functions (keeping your existing encoding/decoding logic)
    
    private func intakeToNumber(_ intake: String) -> Int {
        switch intake {
        case "Low": return 1
        case "Medium": return 2
        case "High": return 3
        default: return 0 // N/A
        }
    }
    
    private func encodeDisturbances(_ disturbances: Set<String>) -> String {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(Array(disturbances))
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            return "[]"
        }
    }
    
    private func decodeDisturbances(_ disturbancesString: String?) -> Set<String>? {
        guard let disturbancesString = disturbancesString,
              let data = disturbancesString.data(using: .utf8) else { return nil }
        
        let decoder = JSONDecoder()
        do {
            let array = try decoder.decode([String].self, from: data)
            return Set(array)
        } catch {
            return nil
        }
    }
    
    private func encodeMedications(_ medications: Set<String>) -> String {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(Array(medications))
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            return "[]"
        }
    }
    
    private func decodeMedications(_ medicationsString: String?) -> Set<String>? {
        guard let medicationsString = medicationsString,
              let data = medicationsString.data(using: .utf8) else { return nil }
        
        let decoder = JSONDecoder()
        do {
            let array = try decoder.decode([String].self, from: data)
            return Set(array)
        } catch {
            return nil
        }
    }
    
    private func encodeDietaryTriggers(_ triggers: Set<String>) -> String {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(Array(triggers))
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            return "[]"
        }
    }
    
    private func decodeDietaryTriggers(_ triggersString: String?) -> Set<String>? {
        guard let triggersString = triggersString,
              let data = triggersString.data(using: .utf8) else { return nil }
        
        let decoder = JSONDecoder()
        do {
            let array = try decoder.decode([String].self, from: data)
            return Set(array)
        } catch {
            return nil
        }
    }
}
