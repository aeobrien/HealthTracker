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
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Compact Date Picker (same as daily entry)
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
                    
                    // Current Status & Next Period Prediction
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Period Status")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        // Status Toggle
                        HStack {
                            Text("Period Status:")
                                .font(.headline)
                            
                            Spacer()
                            
                            Picker("Period Status", selection: $currentPeriodStatus) {
                                Text("Off").tag(PeriodStatus.off)
                                Text("On").tag(PeriodStatus.on)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 120)
                        }
                        
                        // Cycle Information
                        if let nextPeriod = estimatedNextPeriod {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.pink)
                                    Text("Next period predicted:")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(nextPeriod, formatter: dateFormatter)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.pink)
                                }
                                
                                if currentCycleDay > 0 {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(.blue)
                                        Text("Day \(currentCycleDay) of cycle")
                                            .font(.body)
                                            .foregroundColor(.blue)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        
                        Button(action: logPeriodStatus) {
                            Text(currentPeriodStatus == .on ? "Log Period Day" : "Log Off Day")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(currentPeriodStatus == .on ? Color.pink : Color.gray)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Period Details (only show when period is on)
                    if currentPeriodStatus == .on {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Period Details")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            // Flow Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Flow")
                                    .font(.headline)
                                
                                Picker("Flow", selection: $selectedFlow) {
                                    ForEach(flowOptions, id: \.self) { flow in
                                        HStack {
                                            Text(flow)
                                            Spacer()
                                            Circle()
                                                .fill(flowColor(for: flow))
                                                .frame(width: 12, height: 12)
                                        }
                                        .tag(flow)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            // Period Symptoms with 1-5 scale
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Symptoms")
                                    .font(.headline)
                                
                                ForEach(periodSymptoms, id: \.self) { symptom in
                                    EnhancedRatingSlider(
                                        title: symptom,
                                        value: Binding(
                                            get: { selectedPeriodSymptoms[symptom] ?? 0 },
                                            set: { selectedPeriodSymptoms[symptom] = $0 }
                                        ),
                                        color: .pink
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Emotions/Mood (always visible)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Emotions & Mood")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(emotions, id: \.self) { emotion in
                                ToggleButton(
                                    text: emotion,
                                    isSelected: selectedEmotions.contains(emotion),
                                    color: .purple
                                ) {
                                    if selectedEmotions.contains(emotion) {
                                        selectedEmotions.remove(emotion)
                                    } else {
                                        selectedEmotions.insert(emotion)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Discharge & Sexual Activity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Additional Tracking")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        // Discharge Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Discharge Type")
                                .font(.headline)
                            
                            Picker("Discharge", selection: $selectedDischarge) {
                                ForEach(dischargeTypes, id: \.self) { discharge in
                                    Text(discharge).tag(discharge)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        // Sexual Activity
                        Toggle("Sexual Activity", isOn: $sexualActivity)
                            .font(.headline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Notes
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
                    
                    // Recent Period History
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Periods")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if periodEntries.isEmpty {
                            Text("No period entries yet")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(periodEntries.prefix(5), id: \.createdAt) { entry in
                                PeriodEntryRow(entry: entry)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Period Tracking")
            .onAppear {
                loadPeriodEntries()
                calculateCycleInfo()
                loadSelectedDateEntry()
                debugPeriodData() // Add this line
            }
            .onChange(of: selectedDate) { _ in
                loadSelectedDateEntry()
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerModal(selectedDate: $selectedDate) {
                    loadSelectedDateEntry()
                }
            }
            .alert("Period Entry Saved", isPresented: $showingSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your period entry has been saved successfully.")
            }
        }
    }
    
    // Replace the logPeriodStatus function in your PeriodTrackingView with this updated version:
    
    private func logPeriodStatus() {
        print("DEBUG: Logging period status: \(currentPeriodStatus)")
        
        let periodEntry = PeriodEntry(context: viewContext)
        periodEntry.startDate = selectedDate // Use selected date instead of current date
        periodEntry.flow = currentPeriodStatus == .on ? selectedFlow : nil
        periodEntry.createdAt = Date()
        
        // Store period status in notes for now (in full implementation, add a status field)
        var entryNotes = currentPeriodStatus == .on ? "Status: On" : "Status: Off"
        
        if currentPeriodStatus == .on {
            // Add period-specific data
            let symptomsData = selectedPeriodSymptoms.compactMapValues { $0 > 0 ? $0 : nil }
            if !symptomsData.isEmpty {
                let symptomsJSON = encodePeriodSymptoms(symptomsData)
                entryNotes += "\nSymptoms: \(symptomsJSON)"
            }
        }
        
        // Add emotions
        if !selectedEmotions.isEmpty {
            entryNotes += "\nEmotions: \(selectedEmotions.joined(separator: ", "))"
        }
        
        // Add discharge and sexual activity
        entryNotes += "\nDischarge: \(selectedDischarge)"
        entryNotes += "\nSexual Activity: \(sexualActivity ? "Yes" : "No")"
        
        if !notes.isEmpty {
            entryNotes += "\nNotes: \(notes)"
        }
        
        periodEntry.notes = entryNotes
        
        do {
            try viewContext.save()
            print("DEBUG: Period entry saved successfully")
            
            // Reset form to defaults after successful save
            resetPeriodFormToDefaults()
            
            // Reload data
            loadPeriodEntries()
            calculateCycleInfo()
            
            showingSaveConfirmation = true
        } catch {
            print("DEBUG ERROR: Failed to save period entry: \(error)")
        }
    }
    
    private func resetPeriodFormToDefaults() {
        print("DEBUG: Resetting period form to defaults")
        
        // Reset period symptoms
        selectedPeriodSymptoms.removeAll()
        
        // Reset emotions
        selectedEmotions.removeAll()
        
        // Reset discharge and sexual activity
        selectedDischarge = "None"
        sexualActivity = false
        
        // Reset notes
        notes = ""
        
        // Keep the period status and flow as they were set by the user
        // since they might want to log multiple days with the same status
        
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
        
        // Find the most recent "On" entry that starts a new cycle
        var lastCycleStart: Date?
        
        for (index, entry) in periodEntries.enumerated() {
            if let notes = entry.notes, notes.contains("Status: On") {
                // Check if this is the start of a new cycle
                if index == periodEntries.count - 1 {
                    // This is the oldest entry and it's "On"
                    lastCycleStart = entry.startDate
                    break
                } else {
                    // Check if previous entry was "Off" or more than 7 days ago
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
            
            // Calculate current cycle day
            let daysSinceStart = Calendar.current.dateComponents([.day], from: cycleStart, to: Date()).day ?? 0
            currentCycleDay = daysSinceStart + 1
            
            // Predict next period (28-day cycle)
            estimatedNextPeriod = Calendar.current.date(byAdding: .day, value: 28, to: cycleStart)
            
            print("DEBUG: Last cycle started on \(cycleStart), current day: \(currentCycleDay)")
        }
    }
    
    private func loadSelectedDateEntry() {
        // Load entries for the selected date to pre-fill form if already logged
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let dateEntries = periodEntries.filter { entry in
            entry.startDate >= startOfDay && entry.startDate < endOfDay
        }
        
        if let latestEntry = dateEntries.first {
            // Pre-fill form with selected date's data
            if let notes = latestEntry.notes {
                currentPeriodStatus = notes.contains("Status: On") ? .on : .off
                
                if let flow = latestEntry.flow {
                    selectedFlow = flow
                }
                
                // Parse other data from notes
                parseEntryNotes(notes)
            }
        } else {
            // Reset form for new entry
            currentPeriodStatus = .off
            selectedFlow = "Medium"
            selectedPeriodSymptoms.removeAll()
            selectedEmotions.removeAll()
            selectedDischarge = "None"
            sexualActivity = false
            notes = ""
        }
    }
    
    private var compactDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private func parseEntryNotes(_ notes: String) {
        // Simple parsing - in full implementation, these would be separate Core Data fields
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
    
    private func flowColor(for flow: String) -> Color {
        switch flow {
        case "Spotting": return .pink.opacity(0.3)
        case "Light": return .pink.opacity(0.5)
        case "Medium": return .pink.opacity(0.7)
        case "Heavy": return .pink
        default: return .gray
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
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
                       
                       // Check if this is the start of a new cycle
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

struct PeriodEntryRow: View {
    let entry: PeriodEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.startDate, formatter: dateFormatter)
                    .font(.headline)
                
                Spacer()
                
                if let notes = entry.notes {
                    if notes.contains("Status: On") {
                        HStack {
                            Circle()
                                .fill(Color.pink)
                                .frame(width: 8, height: 8)
                            Text("On")
                                .font(.caption)
                                .foregroundColor(.pink)
                        }
                    } else {
                        HStack {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 8, height: 8)
                            Text("Off")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                if let flow = entry.flow {
                    Text(flow)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.pink.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            if let notes = entry.notes {
                let displayNotes = extractDisplayNotes(from: notes)
                if !displayNotes.isEmpty {
                    Text(displayNotes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func extractDisplayNotes(from notes: String) -> String {
        let lines = notes.components(separatedBy: "\n")
        var displayLines: [String] = []
        
        for line in lines {
            if line.hasPrefix("Emotions: ") && !line.hasPrefix("Emotions: ") {
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

