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
    @State private var customTags: [String] = []
    @State private var selectedTags: Set<String> = []
    @State private var newTagText = ""
    @State private var allTags: [String] = []
    @State private var showingTagDeleteAlert = false
    @State private var tagToDelete = ""
    
    // Sleep tracking
    @State private var hoursSlept: Double = 8.0
    @State private var sleepQuality: Double = 0 // 0 = N/A, 1-5 = rating
    @State private var selectedDisturbances: Set<String> = []
    
    // Lifestyle tracking
    @State private var caffeineIntake = "N/A" // N/A, Low, Medium, High
    @State private var alcoholIntake = "N/A"
    @State private var waterIntake = "N/A"
    @State private var exerciseLevel = "N/A"
    @State private var energyLevel: Double = 0 // 0 = N/A, 1-5 = rating
    @State private var stressLevel: Double = 0 // 0 = N/A, 1-5 = rating
    @State private var selectedMedications: Set<String> = []
    @State private var selectedDietaryTriggers: Set<String> = []
    
    // Visibility settings
    @State private var visibilitySettings = VisibilitySettings()
    
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
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Compact Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Date")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: { showingDatePicker = true }) {
                                HStack {
                                    Text(selectedDate, formatter: compactDateFormatter)
                                        .font(.body)
                                        .foregroundColor(.blue)
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    if isLoading {
                        ProgressView("Loading...")
                            .padding()
                    } else {
                        // Symptoms Section
                        if visibilitySettings.showSymptoms {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Symptoms")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                ForEach(Array(groupedSymptoms.keys.sorted()), id: \.self) { category in
                                    SymptomCategorySection(
                                        category: category,
                                        symptoms: groupedSymptoms[category] ?? [],
                                        ratings: $symptomRatings
                                    )
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Sleep Section
                        if visibilitySettings.showSleep {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Sleep")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                // Sleep Duration
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Hours Slept")
                                            .font(.body)
                                        
                                        Spacer()
                                        
                                        Text(String(format: "%.1f hours", hoursSlept))
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Slider(value: $hoursSlept, in: 0...12, step: 0.5) {
                                        Text("Hours Slept")
                                    } minimumValueLabel: {
                                        Text("0h").font(.caption)
                                    } maximumValueLabel: {
                                        Text("12h").font(.caption)
                                    }
                                }
                                
                                // Sleep Quality
                                EnhancedRatingSlider(
                                    title: "Sleep Quality",
                                    value: $sleepQuality,
                                    color: .indigo
                                )
                                
                                // Sleep Disturbances
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Sleep Disturbances")
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                        ForEach(sleepDisturbances, id: \.self) { disturbance in
                                            ToggleButton(
                                                text: disturbance,
                                                isSelected: selectedDisturbances.contains(disturbance),
                                                color: .indigo
                                            ) {
                                                if selectedDisturbances.contains(disturbance) {
                                                    selectedDisturbances.remove(disturbance)
                                                } else {
                                                    selectedDisturbances.insert(disturbance)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Lifestyle Section
                        if visibilitySettings.showLifestyle {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Lifestyle")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                // Intake Tracking with simplified ratings
                                VStack(spacing: 12) {
                                    SimpleRatingRow(
                                        title: "Caffeine",
                                        value: $caffeineIntake,
                                        color: .brown
                                    )
                                    
                                    SimpleRatingRow(
                                        title: "Alcohol",
                                        value: $alcoholIntake,
                                        color: .purple
                                    )
                                    
                                    SimpleRatingRow(
                                        title: "Water",
                                        value: $waterIntake,
                                        color: .blue
                                    )
                                    
                                    SimpleRatingRow(
                                        title: "Exercise",
                                        value: $exerciseLevel,
                                        color: .green
                                    )
                                }
                                
                                // Energy Level
                                EnhancedRatingSlider(
                                    title: "Energy Level",
                                    value: $energyLevel,
                                    color: .yellow
                                )
                                
                                // Stress Level
                                EnhancedRatingSlider(
                                    title: "Stress Level",
                                    value: $stressLevel,
                                    color: .orange
                                )
                                
                                // Medications
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Medications Taken")
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                        ForEach(commonMedications, id: \.self) { medication in
                                            ToggleButton(
                                                text: medication,
                                                isSelected: selectedMedications.contains(medication),
                                                color: .blue
                                            ) {
                                                if selectedMedications.contains(medication) {
                                                    selectedMedications.remove(medication)
                                                } else {
                                                    selectedMedications.insert(medication)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Dietary Triggers
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Dietary Triggers")
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                        ForEach(dietaryTriggers, id: \.self) { trigger in
                                            ToggleButton(
                                                text: trigger,
                                                isSelected: selectedDietaryTriggers.contains(trigger),
                                                color: .red
                                            ) {
                                                if selectedDietaryTriggers.contains(trigger) {
                                                    selectedDietaryTriggers.remove(trigger)
                                                } else {
                                                    selectedDietaryTriggers.insert(trigger)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Custom Tags Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Additional Tags")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            // Existing tags with delete option
                            if !allTags.isEmpty {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    ForEach(allTags, id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            ToggleButton(
                                                text: tag,
                                                isSelected: selectedTags.contains(tag),
                                                color: .purple
                                            ) {
                                                if selectedTags.contains(tag) {
                                                    selectedTags.remove(tag)
                                                } else {
                                                    selectedTags.insert(tag)
                                                }
                                            }
                                            
                                            Button(action: {
                                                tagToDelete = tag
                                                showingTagDeleteAlert = true
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Add new tag
                            HStack {
                                TextField("Add new tag...", text: $newTagText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Button("Add") {
                                    addNewTag()
                                }
                                .disabled(newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Notes Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Save Button
                        Button(action: saveDailyEntry) {
                            Text("Save Entry")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Daily Entry")
            .navigationBarItems(
                trailing: Button("Edit") {
                    showingEditModal = true
                }
            )
            .onAppear {
                loadSymptoms()
                loadExistingEntry()
                loadAllTags()
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerModal(selectedDate: $selectedDate) {
                    loadExistingEntry()
                }
            }
            .sheet(isPresented: $showingEditModal) {
                EnhancedEditVisibilityModal(
                    settings: $visibilitySettings,
                    context: viewContext,
                    onSymptomsChanged: {
                        // Reload symptoms when visibility changes
                        loadSymptoms()
                    }
                )
            }
            .alert("Delete Tag", isPresented: $showingTagDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteTag(tagToDelete)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete the tag '\(tagToDelete)'?")
            }
            .alert("Entry Saved", isPresented: $showingSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your daily entry has been saved successfully.")
            }
        }
    }
    
    private func loadSymptoms() {
        print("DEBUG: Loading symptoms in DailyTrackingView")
        isLoading = true
        
        groupedSymptoms = SymptomDataManager.shared.fetchSymptomsByCategory(context: viewContext)
        symptoms = SymptomDataManager.shared.fetchActiveSymptoms(context: viewContext)
        
        // Initialize ratings dictionary with 0 (N/A) for all symptoms
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
        
        // Load daily entry, sleep entry, and lifestyle entry for the selected date
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
                // Reset all ratings to 0 first
                for symptom in symptoms {
                    symptomRatings[symptom.name] = 0
                }
                
                // Load existing ratings
                if let ratings = entry.symptomRatings as? Set<SymptomRating> {
                    for rating in ratings {
                        symptomRatings[rating.symptomName] = Double(rating.rating)
                    }
                }
                
                notes = entry.notes ?? ""
                
                // Parse tags from notes
                if let entryNotes = entry.notes {
                    if entryNotes.contains("Tags: ") {
                        let components = entryNotes.components(separatedBy: "Tags: ")
                        if components.count > 1 {
                            let tagsString = components[1].components(separatedBy: "\n").first ?? ""
                            selectedTags = Set(tagsString.components(separatedBy: ", ").filter { !$0.isEmpty })
                            
                            // Remove tags from notes display
                            notes = entryNotes.replacingOccurrences(of: "\nTags: \(tagsString)", with: "")
                                .replacingOccurrences(of: "Tags: \(tagsString)", with: "")
                        }
                    }
                }
            } else {
                // Reset to defaults
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
                // Parse intake levels from notes
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
                    caffeineIntake = "N/A"
                    alcoholIntake = "N/A"
                    waterIntake = "N/A"
                    exerciseLevel = "N/A"
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
        // For now, we'll store tags in UserDefaults
        // In a full implementation, you might want to create a Tags entity
        if let tags = UserDefaults.standard.array(forKey: "CustomTags") as? [String] {
            allTags = tags
        }
    }
    
    private func addNewTag() {
        let trimmedTag = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty && !allTags.contains(trimmedTag) else { return }
        
        allTags.append(trimmedTag)
        selectedTags.insert(trimmedTag)
        
        // Save to UserDefaults
        UserDefaults.standard.set(allTags, forKey: "CustomTags")
        
        newTagText = ""
        print("DEBUG: Added new tag: \(trimmedTag)")
    }
    
    private func deleteTag(_ tag: String) {
        allTags.removeAll { $0 == tag }
        selectedTags.remove(tag)
        
        // Save to UserDefaults
        UserDefaults.standard.set(allTags, forKey: "CustomTags")
        
        print("DEBUG: Deleted tag: \(tag)")
    }
    
    // Add these functions to your DailyTrackingView class (replace the existing saveDailyEntry function)

    private func saveDailyEntry() {
        print("DEBUG: Saving comprehensive daily entry")
        
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
        
        // Save sleep entry
        saveSleepEntry()
        
        // Save lifestyle entry
        saveLifestyleEntry()
        
        // Reset the form after successful save
        resetFormToDefaults()
        
        showingSaveConfirmation = true
    }

    private func resetFormToDefaults() {
        print("DEBUG: Resetting daily entry form to defaults")
        
        // Reset all symptom ratings to 0
        for symptom in symptoms {
            symptomRatings[symptom.name] = 0
        }
        
        // Reset notes
        notes = ""
        
        // Reset tags
        selectedTags.removeAll()
        newTagText = ""
        
        // Reset sleep data
        hoursSlept = 8.0
        sleepQuality = 0
        selectedDisturbances.removeAll()
        
        // Reset lifestyle data
        resetLifestyleToDefaults()
        
        print("DEBUG: Form reset completed")
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
    
    // MARK: - Helper Functions
    
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
    
    private var compactDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// MARK: - Supporting Views

struct VisibilitySettings {
    var showSymptoms = true
    var showSleep = true
    var showLifestyle = true
}

struct DatePickerModal: View {
    @Binding var selectedDate: Date
    let onDateChange: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    onDateChange()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct EnhancedRatingSlider: View {
    let title: String
    @Binding var value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(value == 0 ? "N/A" : String(format: "%.0f", value))
                    .font(.headline)
                    .foregroundColor(value == 0 ? .secondary : color)
            }
            
            Slider(
                value: $value,
                in: 0...5,
                step: 1
            ) {
                Text(title)
            } minimumValueLabel: {
                Text("N/A")
                    .font(.caption)
            } maximumValueLabel: {
                Text("5")
                    .font(.caption)
            }
            .accentColor(color)
        }
    }
}

struct ToggleButton: View {
    let text: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? color : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
                .multilineTextAlignment(.center)
        }
    }
}

struct SymptomCategorySection: View {
    let category: String
    let symptoms: [PredefinedSymptom]
    @Binding var ratings: [String: Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category)
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(symptoms.filter { $0.isActive }, id: \.name) { symptom in
                EnhancedSymptomRatingRow(
                    symptomName: symptom.name,
                    rating: Binding(
                        get: { ratings[symptom.name] ?? 0 },
                        set: { ratings[symptom.name] = $0 }
                    )
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct EnhancedSymptomRatingRow: View {
    let symptomName: String
    @Binding var rating: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(symptomName)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(rating == 0 ? "N/A" : String(format: "%.0f", rating))
                    .font(.headline)
                    .foregroundColor(rating == 0 ? .secondary : .blue)
                    .frame(minWidth: 40)
            }
            
            Slider(
                value: $rating,
                in: 0...5,
                step: 1
            ) {
                Text(symptomName)
            } minimumValueLabel: {
                Text("N/A")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } maximumValueLabel: {
                Text("5")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accentColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

struct SimpleRatingRow: View {
    let title: String
    @Binding var value: String
    let color: Color
    
    private let options = ["N/A", "Low", "Medium", "High"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(value == "N/A" ? .secondary : color)
            }
            
            Picker(title, selection: $value) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

struct EnhancedEditVisibilityModal: View {
    @Binding var settings: VisibilitySettings
    let context: NSManagedObjectContext
    let onSymptomsChanged: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var symptoms: [PredefinedSymptom] = []
    @State private var newSymptomName = ""
    @State private var newSymptomCategory = "Custom"
    @State private var showingAddSymptom = false
    
    private let categories = ["Migraine", "Post-Concussion", "Physical", "Emotional", "Custom"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Main Sections")) {
                    Toggle("Symptoms", isOn: $settings.showSymptoms)
                    Toggle("Sleep", isOn: $settings.showSleep)
                    Toggle("Lifestyle", isOn: $settings.showLifestyle)
                }
                
                if settings.showSymptoms {
                    Section(header: HStack {
                        Text("Individual Symptoms")
                        Spacer()
                        Button("Add New") {
                            showingAddSymptom = true
                        }
                        .font(.caption)
                    }) {
                        ForEach(symptoms, id: \.name) { symptom in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(symptom.name)
                                        .font(.body)
                                    Text(symptom.category)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { symptom.isActive },
                                    set: { newValue in
                                        symptom.isActive = newValue
                                        saveContext()
                                        onSymptomsChanged() // Notify parent to reload
                                    }
                                ))
                                
                                Button(action: {
                                    deleteSymptom(symptom)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Customize Tracking")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                loadSymptoms()
            }
            .sheet(isPresented: $showingAddSymptom) {
                AddSymptomModal(
                    context: context,
                    onSymptomAdded: {
                        loadSymptoms()
                        onSymptomsChanged() // Notify parent when new symptom is added
                    }
                )
            }
        }
    }
    
    private func loadSymptoms() {
        // Load all symptoms (both active and inactive) for editing
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
    
    private func deleteSymptom(_ symptom: PredefinedSymptom) {
        context.delete(symptom)
        
        do {
            try context.save()
            print("DEBUG: Deleted symptom: \(symptom.name)")
            loadSymptoms() // Reload the list
            onSymptomsChanged() // Notify parent
        } catch {
            print("DEBUG ERROR: Failed to delete symptom: \(error)")
        }
    }
}

struct AddSymptomModal: View {
    let context: NSManagedObjectContext
    let onSymptomAdded: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var symptomName = ""
    @State private var selectedCategory = "Custom"
    
    private let categories = ["Migraine", "Post-Concussion", "Physical", "Emotional", "Custom"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Symptom")) {
                    TextField("Symptom Name", text: $symptomName)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
            }
            .navigationTitle("Add Symptom")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    addSymptom()
                }
                .disabled(symptomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    private func addSymptom() {
        let trimmedName = symptomName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if symptom already exists
        let request: NSFetchRequest<PredefinedSymptom> = PredefinedSymptom.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", trimmedName)
        
        do {
            let existingSymptoms = try context.fetch(request)
            if !existingSymptoms.isEmpty {
                print("DEBUG: Symptom '\(trimmedName)' already exists")
                return
            }
            
            // Create new symptom
            let newSymptom = PredefinedSymptom(context: context)
            newSymptom.name = trimmedName
            newSymptom.category = selectedCategory
            newSymptom.isActive = true
            newSymptom.createdAt = Date()
            
            try context.save()
            print("DEBUG: Added new symptom: \(trimmedName) in category: \(selectedCategory)")
            
            onSymptomAdded()
            presentationMode.wrappedValue.dismiss()
            
        } catch {
            print("DEBUG ERROR: Failed to add symptom: \(error)")
        }
    }
}
