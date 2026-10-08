import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTimeframe = "Last 7 Days"
    @State private var dailyEntries: [DailyEntry] = []
    @State private var periodEntries: [PeriodEntry] = []
    @State private var sleepEntries: [SleepEntry] = []
    @State private var lifestyleEntries: [LifestyleEntry] = []
    @State private var showingExportSheet = false
    @State private var showingDeleteAlert = false
    @State private var dailyEntryToDelete: DailyEntry? = nil
    @State private var periodEntryToDelete: PeriodEntry? = nil
    @State private var sleepEntryToDelete: SleepEntry? = nil
    @State private var lifestyleEntryToDelete: LifestyleEntry? = nil
    
    private let timeframes = ["7 days", "30 days", "90 days", "All time"]
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.screenBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.large) {
                    // Header
                    MinimalCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("History")
                                .font(DesignSystem.Typography.largeTitle)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Text("Track your health trends over time")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    // Timeframe Selection
                    MinimalCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                            Text("Timeframe")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                ForEach(timeframes, id: \.self) { timeframe in
                                    Button(action: {
                                        selectedTimeframe = timeframe
                                        loadHistoryData()
                                    }) {
                                        Text(timeframe)
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(selectedTimeframe == timeframe ? DesignSystem.Colors.primaryBlue : DesignSystem.Colors.secondaryText)
                                            .padding(.horizontal, DesignSystem.Spacing.small)
                                            .padding(.vertical, DesignSystem.Spacing.xs)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedTimeframe == timeframe ? DesignSystem.Colors.primaryBlue.opacity(0.1) : Color.clear)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(selectedTimeframe == timeframe ? DesignSystem.Colors.primaryBlue.opacity(0.4) : DesignSystem.Colors.tertiaryText, lineWidth: 0.5)
                                                    )
                                            )
                                    }
                                }
                            }
                        }
                    }
                    
                    // Summary Statistics
                    MinimalCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                            Text("Summary")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: DesignSystem.Spacing.medium) {
                                MinimalSummaryCard(
                                    title: "Entries",
                                    value: "\(dailyEntries.count)",
                                    subtitle: "Daily logs",
                                    color: DesignSystem.Colors.primaryBlue
                                )
                                
                                MinimalSummaryCard(
                                    title: "Avg Sleep",
                                    value: averageSleepHours(),
                                    subtitle: "Hours per night",
                                    color: DesignSystem.Colors.softIndigo
                                )
                                
                                MinimalSummaryCard(
                                    title: "Avg Stress",
                                    value: averageStressLevel(),
                                    subtitle: "Out of 5",
                                    color: DesignSystem.Colors.paleOrange
                                )
                                
                                MinimalSummaryCard(
                                    title: "Period Cycles",
                                    value: "\(periodEntries.count)",
                                    subtitle: "Tracked",
                                    color: DesignSystem.Colors.softPink
                                )
                            }
                        }
                    }
                    
                    // Most Common Symptoms
                    if !dailyEntries.isEmpty {
                        MinimalCard {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("Most Common Symptoms")
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                ForEach(getTopSymptoms(limit: 5), id: \.name) { symptomData in
                                    MinimalSymptomFrequencyRow(symptomData: symptomData)
                                }
                            }
                        }
                    }
                    
                    // Sleep Quality Trends
                    if !sleepEntries.isEmpty {
                        MinimalCard {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("Sleep Quality Trends")
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                let sleepQualityStats = calculateSleepQualityStats()
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                        Text("Best Quality")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                        Text("\(sleepQualityStats.best)/5")
                                            .font(DesignSystem.Typography.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(DesignSystem.Colors.mutedGreen)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .center, spacing: DesignSystem.Spacing.xs) {
                                        Text("Average")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                        Text(String(format: "%.1f/5", sleepQualityStats.average / 2))
                                            .font(DesignSystem.Typography.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(DesignSystem.Colors.primaryBlue)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                                        Text("Worst Quality")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                        Text("\(sleepQualityStats.worst / 2)/5")
                                            .font(DesignSystem.Typography.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(DesignSystem.Colors.softPink)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Lifestyle Patterns
                    if !lifestyleEntries.isEmpty {
                        MinimalCard {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("Lifestyle Patterns")
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                let lifestyleStats = calculateLifestyleStats()
                                
                                VStack(spacing: DesignSystem.Spacing.medium) {
                                    MinimalStatRow(label: "Most Common Caffeine", value: lifestyleStats.avgCaffeine, color: DesignSystem.Colors.paleOrange)
                                    MinimalStatRow(label: "Most Common Water", value: lifestyleStats.avgWater, color: DesignSystem.Colors.primaryBlue)
                                    MinimalStatRow(label: "Most Common Exercise", value: lifestyleStats.avgExercise, color: DesignSystem.Colors.mutedGreen)
                                    MinimalStatRow(label: "Average Stress", value: lifestyleStats.avgStress, color: DesignSystem.Colors.paleOrange)
                                    MinimalStatRow(label: "High Stress Days", value: "\(lifestyleStats.highStressDays)", color: DesignSystem.Colors.softPink)
                                }
                            }
                        }
                    }
                    
                    // Recent Period Information
                    if !periodEntries.isEmpty {
                        MinimalCard {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                                Text("Period Information")
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                ForEach(periodEntries.prefix(3), id: \.createdAt) { entry in
                                    VStack {
                                        HStack {
                                            MinimalPeriodSummaryRow(entry: entry)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                print("DEBUG: Delete button tapped for period entry: \(entry.startDate)")
                                                periodEntryToDelete = entry
                                                showingDeleteAlert = true
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(DesignSystem.Colors.softPink)
                                                    .font(.system(size: 14, weight: .light))
                                                    .padding(DesignSystem.Spacing.small)
                                                    .background(
                                                        Circle()
                                                            .fill(DesignSystem.Colors.softPink.opacity(0.1))
                                                    )
                                            }
                                        }
                                        .padding(DesignSystem.Spacing.medium)
                                        .background(DesignSystem.Colors.screenBackground)
                                        .cornerRadius(8)
                                        
                                        if entry != periodEntries.prefix(3).last {
                                            Rectangle()
                                                .fill(DesignSystem.Colors.tertiaryText.opacity(0.3))
                                                .frame(height: 0.5)
                                                .padding(.horizontal, DesignSystem.Spacing.medium)
                                        }
                                    }
                                }
                                
                                if let cycleStats = calculateCycleStats() {
                                    MinimalStatRow(
                                        label: "Average Cycle Length",
                                        value: "\(cycleStats) days",
                                        color: DesignSystem.Colors.softPink
                                    )
                                    .padding(.top, DesignSystem.Spacing.small)
                                }
                            }
                        }
                    }
                    
                    // Recent Entries with Delete Options
                    MinimalCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                            Text("Recent Daily Entries")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            if dailyEntries.isEmpty {
                                Text("No daily entries yet")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                    .padding(DesignSystem.Spacing.medium)
                            } else {
                                ForEach(dailyEntries.prefix(5), id: \.createdAt) { entry in
                                    VStack {
                                        HStack {
                                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                                Text(entry.date, formatter: shortDateFormatter)
                                                    .font(DesignSystem.Typography.body)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                                
                                                if let notes = entry.notes {
                                                    Text(notes.components(separatedBy: "\n").first ?? notes)
                                                        .font(DesignSystem.Typography.caption)
                                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                                        .lineLimit(1)
                                                }
                                                
                                                if let ratings = entry.symptomRatings as? Set<SymptomRating>, !ratings.isEmpty {
                                                    Text("\(ratings.count) symptoms tracked")
                                                        .font(DesignSystem.Typography.caption)
                                                        .foregroundColor(DesignSystem.Colors.primaryBlue)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                print("DEBUG: Delete button tapped for daily entry: \(entry.date)")
                                                dailyEntryToDelete = entry
                                                showingDeleteAlert = true
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(DesignSystem.Colors.softPink)
                                                    .font(.system(size: 14, weight: .light))
                                                    .padding(DesignSystem.Spacing.small)
                                                    .background(
                                                        Circle()
                                                            .fill(DesignSystem.Colors.softPink.opacity(0.1))
                                                    )
                                            }
                                        }
                                        .padding(DesignSystem.Spacing.medium)
                                        .background(DesignSystem.Colors.screenBackground)
                                        .cornerRadius(8)
                                        
                                        if entry != dailyEntries.prefix(5).last {
                                            Rectangle()
                                                .fill(DesignSystem.Colors.tertiaryText.opacity(0.3))
                                                .frame(height: 0.5)
                                                .padding(.horizontal, DesignSystem.Spacing.medium)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    DelicateButton(
                        title: "Export Data",
                        action: {
                            print("DEBUG: Export button tapped")
                            showingExportSheet = true
                        },
                        style: .primary
                    )
                    .padding(.horizontal, DesignSystem.Spacing.large)
                }
                .padding(DesignSystem.Spacing.large)
            }
        }
        .navigationBarHidden(true)
            .onAppear {
                print("DEBUG: HistoryView appeared")
                loadHistoryData()
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView(
                    dailyEntries: dailyEntries,
                    periodEntries: periodEntries,
                    sleepEntries: sleepEntries,
                    lifestyleEntries: lifestyleEntries
                )
            }
            .alert("Delete Entry", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    print("DEBUG: Delete confirmed")
                    deleteSelectedEntry()
                }
                Button("Cancel", role: .cancel) {
                    print("DEBUG: Delete cancelled")
                    resetDeleteStates()
                }
            } message: {
                if dailyEntryToDelete != nil {
                    Text("Are you sure you want to delete this daily entry? This action cannot be undone.")
                } else if periodEntryToDelete != nil {
                    Text("Are you sure you want to delete this period entry? This action cannot be undone.")
                } else if sleepEntryToDelete != nil {
                    Text("Are you sure you want to delete this sleep entry? This action cannot be undone.")
                } else if lifestyleEntryToDelete != nil {
                    Text("Are you sure you want to delete this lifestyle entry? This action cannot be undone.")
                } else {
                    Text("Are you sure you want to delete this entry?")
                }
            }
    }
    
    private func loadHistoryData() {
        print("DEBUG: Loading history data for timeframe: \(selectedTimeframe)")
        
        let startDate = calculateStartDate()
        print("DEBUG: Calculated start date: \(startDate)")
        
        // Load Daily Entries
        let dailyRequest: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        dailyRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        dailyRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DailyEntry.date, ascending: false)]
        
        // Load Period Entries
        let periodRequest: NSFetchRequest<PeriodEntry> = PeriodEntry.fetchRequest()
        periodRequest.predicate = NSPredicate(format: "startDate >= %@", startDate as NSDate)
        periodRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PeriodEntry.startDate, ascending: false)]
        
        // Load Sleep Entries
        let sleepRequest: NSFetchRequest<SleepEntry> = SleepEntry.fetchRequest()
        sleepRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        sleepRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SleepEntry.date, ascending: false)]
        
        // Load Lifestyle Entries
        let lifestyleRequest: NSFetchRequest<LifestyleEntry> = LifestyleEntry.fetchRequest()
        lifestyleRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        lifestyleRequest.sortDescriptors = [NSSortDescriptor(keyPath: \LifestyleEntry.date, ascending: false)]
        
        do {
            dailyEntries = try viewContext.fetch(dailyRequest)
            periodEntries = try viewContext.fetch(periodRequest)
            sleepEntries = try viewContext.fetch(sleepRequest)
            lifestyleEntries = try viewContext.fetch(lifestyleRequest)
            
            print("DEBUG: Loaded \(dailyEntries.count) daily, \(periodEntries.count) period, \(sleepEntries.count) sleep, \(lifestyleEntries.count) lifestyle entries")
        } catch {
            print("DEBUG ERROR: Failed to load history data: \(error)")
        }
    }
    
    private func calculateStartDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeframe {
        case "7 days":
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case "30 days":
            return calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case "90 days":
            return calendar.date(byAdding: .day, value: -90, to: now) ?? now
        default: // All time
            return calendar.date(byAdding: .year, value: -10, to: now) ?? now
        }
    }
    
    private func averageSleepHours() -> String {
        guard !sleepEntries.isEmpty else { return "N/A" }
        
        let totalHours = sleepEntries.reduce(0.0) { $0 + $1.hoursSlept }
        let average = totalHours / Double(sleepEntries.count)
        
        return String(format: "%.1f", average)
    }
    
    private func averageStressLevel() -> String {
        guard !lifestyleEntries.isEmpty else { return "N/A" }
        
        let totalStress = lifestyleEntries.reduce(0) { $0 + Int($1.stressLevel) }
        let average = Double(totalStress) / Double(lifestyleEntries.count)
        
        return String(format: "%.1f", average)
    }
    
    private func getTopSymptoms(limit: Int) -> [(name: String, frequency: Int, averageRating: Double)] {
        var symptomData: [String: (count: Int, totalRating: Int)] = [:]
        
        for entry in dailyEntries {
            if let ratings = entry.symptomRatings as? Set<SymptomRating> {
                for rating in ratings {
                    if rating.rating > 0 { // Only count non-zero ratings
                        let existing = symptomData[rating.symptomName] ?? (count: 0, totalRating: 0)
                        symptomData[rating.symptomName] = (
                            count: existing.count + 1,
                            totalRating: existing.totalRating + Int(rating.rating)
                        )
                    }
                }
            }
        }
        
        let sorted = symptomData.map { (name, data) in
            (
                name: name,
                frequency: data.count,
                averageRating: Double(data.totalRating) / Double(data.count)
            )
        }.sorted { $0.frequency > $1.frequency }
        
        return Array(sorted.prefix(limit))
    }
    
    private func calculateSleepQualityStats() -> (best: Int, worst: Int, average: Double) {
        guard !sleepEntries.isEmpty else { return (0, 0, 0) }
        
        let qualities = sleepEntries.map { Int($0.sleepQuality) }
        let best = qualities.max() ?? 0
        let worst = qualities.min() ?? 0
        let average = Double(qualities.reduce(0, +)) / Double(qualities.count)
        
        return (best, worst, average)
    }
    
    private func calculateLifestyleStats() -> (avgCaffeine: String, avgWater: String, avgExercise: String, avgStress: String, highStressDays: Int) {
        guard !lifestyleEntries.isEmpty else { return ("N/A", "N/A", "N/A", "N/A", 0) }
        
        let count = lifestyleEntries.count
        
        // Parse caffeine levels from notes
        let caffeineValues = lifestyleEntries.compactMap { entry -> String? in
            guard let notes = entry.notes else { return "N/A" }
            if notes.contains("Caffeine: Low") { return "Low" }
            if notes.contains("Caffeine: Medium") { return "Medium" }
            if notes.contains("Caffeine: High") { return "High" }
            return "N/A"
        }
        
        // Parse water levels from notes
        let waterValues = lifestyleEntries.compactMap { entry -> String? in
            guard let notes = entry.notes else { return "N/A" }
            if notes.contains("Water: Low") { return "Low" }
            if notes.contains("Water: Medium") { return "Medium" }
            if notes.contains("Water: High") { return "High" }
            return "N/A"
        }
        
        // Parse exercise levels from notes
        let exerciseValues = lifestyleEntries.compactMap { entry -> String? in
            guard let notes = entry.notes else { return "N/A" }
            if notes.contains("Exercise: Low") { return "Low" }
            if notes.contains("Exercise: Medium") { return "Medium" }
            if notes.contains("Exercise: High") { return "High" }
            return "N/A"
        }
        
        // Calculate most common values
        let avgCaffeine = mostCommonValue(in: caffeineValues)
        let avgWater = mostCommonValue(in: waterValues)
        let avgExercise = mostCommonValue(in: exerciseValues)
        
        // Calculate stress average
        let totalStress = lifestyleEntries.reduce(0) { $0 + Double($1.stressLevel) }
        let avgStressNum = totalStress / Double(count)
        let avgStress = avgStressNum == 0 ? "N/A" : String(format: "%.1f", avgStressNum)
        
        let highStressDays = lifestyleEntries.filter { $0.stressLevel >= 7 }.count
        
        return (avgCaffeine, avgWater, avgExercise, avgStress, highStressDays)
    }
    
    private func mostCommonValue(in values: [String]) -> String {
        let valueCounts = values.reduce(into: [:]) { counts, value in
            counts[value, default: 0] += 1
        }
        
        return valueCounts.max(by: { $0.value < $1.value })?.key ?? "N/A"
    }
    
    private func calculateCycleStats() -> Int? {
        guard periodEntries.count >= 2 else { return nil }
        
        var cycleLengths: [Int] = []
        
        for i in 0..<(periodEntries.count - 1) {
            let currentPeriod = periodEntries[i]
            let previousPeriod = periodEntries[i + 1]
            
            let daysBetween = Calendar.current.dateComponents([.day], from: previousPeriod.startDate, to: currentPeriod.startDate).day ?? 0
            
            if daysBetween > 0 && daysBetween <= 45 {
                cycleLengths.append(daysBetween)
            }
        }
        
        guard !cycleLengths.isEmpty else { return nil }
        
        let averageLength = cycleLengths.reduce(0, +) / cycleLengths.count
        return averageLength
    }
    
    private func deleteSelectedEntry() {
        print("DEBUG: deleteSelectedEntry called")
        
        if let entry = dailyEntryToDelete {
            print("DEBUG: Deleting daily entry for date: \(entry.date)")
            deleteDailyEntry(entry)
        } else if let entry = periodEntryToDelete {
            print("DEBUG: Deleting period entry for date: \(entry.startDate)")
            deletePeriodEntry(entry)
        } else if let entry = sleepEntryToDelete {
            print("DEBUG: Deleting sleep entry for date: \(entry.date)")
            deleteSleepEntry(entry)
        } else if let entry = lifestyleEntryToDelete {
            print("DEBUG: Deleting lifestyle entry for date: \(entry.date)")
            deleteLifestyleEntry(entry)
        } else {
            print("DEBUG: No entry to delete found")
        }
        resetDeleteStates()
    }
    
    private func resetDeleteStates() {
        print("DEBUG: Resetting delete states")
        dailyEntryToDelete = nil
        periodEntryToDelete = nil
        sleepEntryToDelete = nil
        lifestyleEntryToDelete = nil
    }
    
    private func deleteDailyEntry(_ entry: DailyEntry) {
        print("DEBUG: Starting to delete daily entry for \(entry.date)")
        
        // Delete related symptom ratings first
        if let ratings = entry.symptomRatings as? Set<SymptomRating> {
            for rating in ratings {
                viewContext.delete(rating)
            }
            print("DEBUG: Deleted \(ratings.count) related symptom ratings")
        }
        
        viewContext.delete(entry)
        saveContext()
        loadHistoryData()
        print("DEBUG: Completed deletion of daily entry")
    }
    
    private func deletePeriodEntry(_ entry: PeriodEntry) {
        print("DEBUG: Starting to delete period entry for \(entry.startDate)")
        viewContext.delete(entry)
        saveContext()
        loadHistoryData()
        print("DEBUG: Completed deletion of period entry")
    }
    
    private func deleteSleepEntry(_ entry: SleepEntry) {
        print("DEBUG: Starting to delete sleep entry for \(entry.date)")
        viewContext.delete(entry)
        saveContext()
        loadHistoryData()
        print("DEBUG: Completed deletion of sleep entry")
    }
    
    private func deleteLifestyleEntry(_ entry: LifestyleEntry) {
        print("DEBUG: Starting to delete lifestyle entry for \(entry.date)")
        viewContext.delete(entry)
        saveContext()
        loadHistoryData()
        print("DEBUG: Completed deletion of lifestyle entry")
    }
    
    private func saveContext() {
        print("DEBUG: Attempting to save context")
        do {
            try viewContext.save()
            print("DEBUG: Successfully saved context after deletion")
        } catch {
            print("DEBUG ERROR: Failed to save context after deletion: \(error)")
        }
    }
    
    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

struct MinimalSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.micro)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(value)
                .font(DesignSystem.Typography.title)
                .fontWeight(.light)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.tertiaryText)
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.screenBackground)
        .cornerRadius(8)
        .shadow(color: DesignSystem.Shadows.subtle, radius: 2, x: 0, y: 1)
    }
}

struct MinimalStatRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.body)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct MinimalSymptomFrequencyRow: View {
    let symptomData: (name: String, frequency: Int, averageRating: Double)
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(symptomData.name)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("\(symptomData.frequency) occurrences")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                Text(String(format: "%.1f", symptomData.averageRating))
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryBlue)
                
                Text("avg rating")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

struct MinimalPeriodSummaryRow: View {
    let entry: PeriodEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(entry.startDate, formatter: dateFormatter)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                if let notes = entry.notes {
                    if notes.contains("Status: On") {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Circle()
                                .fill(DesignSystem.Colors.softPink)
                                .frame(width: 6, height: 6)
                            Text("On")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.softPink)
                        }
                    } else {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Circle()
                                .fill(DesignSystem.Colors.tertiaryText)
                                .frame(width: 6, height: 6)
                            Text("Off")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.tertiaryText)
                        }
                    }
                }
                
                if let flow = entry.flow {
                    Text(flow)
                        .font(DesignSystem.Typography.micro)
                        .padding(.horizontal, DesignSystem.Spacing.small)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.softPink.opacity(0.1))
                        .foregroundColor(DesignSystem.Colors.softPink)
                        .cornerRadius(6)
                }
            }
            
            if let endDate = entry.endDate {
                let duration = Calendar.current.dateComponents([.day], from: entry.startDate, to: endDate).day ?? 0
                Text("Duration: \(duration + 1) days")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

struct ExportDataView: View {
    let dailyEntries: [DailyEntry]
    let periodEntries: [PeriodEntry]
    let sleepEntries: [SleepEntry]
    let lifestyleEntries: [LifestyleEntry]
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Your Health Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("This will create a CSV file containing all your tracked data for analysis.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data to Export:")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(dailyEntries.count) Daily symptom entries")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(periodEntries.count) Period entries")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(sleepEntries.count) Sleep entries")
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(lifestyleEntries.count) Lifestyle entries")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button(action: exportData) {
                    Text("Export to CSV")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Export Data")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private func exportData() {
        print("DEBUG: Starting data export")
        
        var csvContent = ""
        
        // Daily Entries CSV
        csvContent += "Daily Entries\n"
        csvContent += "Date,Symptom,Rating,Notes\n"
        
        for entry in dailyEntries {
            let dateString = dateFormatter.string(from: entry.date)
            let notes = entry.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            if let ratings = entry.symptomRatings as? Set<SymptomRating> {
                for rating in ratings {
                    if rating.rating > 0 {
                        csvContent += "\(dateString),\(rating.symptomName),\(rating.rating),\(notes)\n"
                    }
                }
            }
        }
        
        csvContent += "\n"
        
        // Sleep Entries CSV
        csvContent += "Sleep Entries\n"
        csvContent += "Date,Hours Slept,Sleep Quality,Disturbances,Notes\n"
        
        for entry in sleepEntries {
            let dateString = dateFormatter.string(from: entry.date)
            let disturbances = entry.disturbances?.replacingOccurrences(of: ",", with: ";") ?? ""
            let notes = entry.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csvContent += "\(dateString),\(entry.hoursSlept),\(entry.sleepQuality),\(disturbances),\(notes)\n"
        }
        
        csvContent += "\n"
        
        // Period Entries CSV
        csvContent += "Period Entries\n"
        csvContent += "Start Date,End Date,Flow,Symptoms,Notes\n"
        
        for entry in periodEntries {
            let startDateString = dateFormatter.string(from: entry.startDate)
            let endDateString = entry.endDate != nil ? dateFormatter.string(from: entry.endDate!) : ""
            let flow = entry.flow ?? ""
            let symptoms = entry.symptoms?.replacingOccurrences(of: ",", with: ";") ?? ""
            let notes = entry.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csvContent += "\(startDateString),\(endDateString),\(flow),\(symptoms),\(notes)\n"
        }
        
        csvContent += "\n"
        
        // Lifestyle Entries CSV
        csvContent += "Lifestyle Entries\n"
        csvContent += "Date,Caffeine (mg),Alcohol (units),Water (L),Exercise (min),Stress Level,Medications,Dietary Triggers,Notes\n"
        
        for entry in lifestyleEntries {
            let dateString = dateFormatter.string(from: entry.date)
            let alcoholUnits = Double(entry.alcoholIntake) / 2.0
            let medications = entry.medications?.replacingOccurrences(of: ",", with: ";") ?? ""
            let triggers = entry.dietaryTriggers?.replacingOccurrences(of: ",", with: ";") ?? ""
            let notes = entry.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csvContent += "\(dateString),\(entry.caffeineIntake),\(alcoholUnits),\(entry.waterIntake),\(entry.exerciseMinutes),\(entry.stressLevel),\(medications),\(triggers),\(notes)\n"
        }
        
        // Save to file
        let fileName = "HealthTracker_Export_\(dateFormatter.string(from: Date())).csv"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("DEBUG: CSV exported successfully to \(fileURL)")
            
            exportURL = fileURL
            showingShareSheet = true
        } catch {
            print("DEBUG ERROR: Failed to export CSV: \(error)")
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
