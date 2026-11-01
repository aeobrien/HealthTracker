import SwiftUI
import CoreData

struct SleepTrackingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var hoursSlept: Double = 8.0
    @State private var sleepQuality: Double = 7.0
    @State private var selectedDisturbances: Set<String> = []
    @State private var notes = ""
    @State private var showingSaveConfirmation = false
    @State private var recentSleepEntries: [SleepEntry] = []
    
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
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sleep Date")
                            .font(.headline)
                        
                        DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .onChange(of: selectedDate) { _ in
                                loadExistingSleepEntry()
                            }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Sleep Duration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sleep Duration")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Hours Slept")
                                    .font(.body)
                                
                                Spacer()
                                
                                Text(String(format: "%.1f hours", hoursSlept))
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            
                            Slider(
                                value: $hoursSlept,
                                in: 0...12,
                                step: 0.5
                            ) {
                                Text("Hours Slept")
                            } minimumValueLabel: {
                                Text("0h")
                                    .font(.caption)
                            } maximumValueLabel: {
                                Text("12h")
                                    .font(.caption)
                            }
                            .accentColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Sleep Quality
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sleep Quality")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Quality Rating")
                                    .font(.body)
                                
                                Spacer()
                                
                                Text(qualityDescription(for: sleepQuality))
                                    .font(.headline)
                                    .foregroundColor(qualityColor(for: sleepQuality))
                            }
                            
                            Slider(
                                value: $sleepQuality,
                                in: 1...10,
                                step: 1
                            ) {
                                Text("Sleep Quality")
                            } minimumValueLabel: {
                                Text("1")
                                    .font(.caption)
                            } maximumValueLabel: {
                                Text("10")
                                    .font(.caption)
                            }
                            .accentColor(.blue)
                        }
                        
                        HStack {
                            Text("1 = Very Poor")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("10 = Excellent")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Sleep Disturbances
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sleep Disturbances")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(sleepDisturbances, id: \.self) { disturbance in
                                DisturbanceToggleButton(
                                    disturbance: disturbance,
                                    isSelected: selectedDisturbances.contains(disturbance)
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
                    
                    // Save Button
                    Button(action: saveSleepEntry) {
                        Text("Save Sleep Entry")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Recent Sleep Trends
                    if !recentSleepEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Sleep")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            ForEach(recentSleepEntries.prefix(7), id: \.createdAt) { entry in
                                SleepEntryRow(entry: entry)
                            }
                            
                            if let avgSleep = calculateAverageSleep() {
                                HStack {
                                    Text("7-day average:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.1f hours", avgSleep))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Sleep Tracking")
            .onAppear {
                loadExistingSleepEntry()
                loadRecentSleepEntries()
            }
            .alert("Sleep Entry Saved", isPresented: $showingSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your sleep entry has been saved successfully.")
            }
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
            sleepEntry.sleepQuality = Int16(sleepQuality)
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
                sleepQuality = Double(entry.sleepQuality)
                selectedDisturbances = decodeDisturbances(entry.disturbances) ?? []
                notes = entry.notes ?? ""
            } else {
                print("DEBUG: No existing sleep entry found, using defaults")
                hoursSlept = 8.0
                sleepQuality = 7.0
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
        case 1...2: return "Very Poor"
        case 3...4: return "Poor"
        case 5...6: return "Fair"
        case 7...8: return "Good"
        case 9...10: return "Excellent"
        default: return "Unknown"
        }
    }
    
    private func qualityColor(for quality: Double) -> Color {
        switch Int(quality) {
        case 1...4: return .red
        case 5...6: return .orange
        case 7...8: return .blue
        case 9...10: return .green
        default: return .gray
        }
    }
}

struct DisturbanceToggleButton: View {
    let disturbance: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(disturbance)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.indigo : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
                .multilineTextAlignment(.center)
        }
    }
}

struct SleepEntryRow: View {
    let entry: SleepEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date, formatter: dateFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.1f hours", entry.hoursSlept))
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Quality: \(entry.sleepQuality)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Circle()
                    .fill(qualityColor(for: Double(entry.sleepQuality)))
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func qualityColor(for quality: Double) -> Color {
        switch Int(quality) {
        case 1...4: return .red
        case 5...6: return .orange
        case 7...8: return .blue
        case 9...10: return .green
        default: return .gray
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}
