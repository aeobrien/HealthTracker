import SwiftUI
import CoreData

// MARK: - Data Models
struct HormoneDay {
    let day: Int
    let LH: Double
    let FSH: Double
    let estradiol: Double
    let progesterone: Double
    
    func getValue(for hormone: HormoneChartView.HormoneType) -> Double {
        switch hormone {
        case .LH: return LH
        case .FSH: return FSH
        case .estradiol: return estradiol
        case .progesterone: return progesterone
        }
    }
}

struct CalendarMonth {
    let id: String
    let monthName: String
    let days: [CalendarDay]
}

struct CalendarDay {
    let id: String
    let date: Date
    let dayNumber: Int
    let isEmpty: Bool
}

struct PeriodPrediction {
    let startDate: Date
    let periodDays: [Date]
}

// MARK: - Main View
struct HormoneChartView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedHormone: HormoneType = .LH
    @State private var currentCycleDay: Int? = nil
    @State private var lastPeriodStart: Date? = nil
    @State private var periodEntries: [PeriodEntry] = []
    @State private var selectedTab = 0
    
    // Hormone data from CSV (keeping your existing data)
    private let hormoneData: [HormoneDay] = [
        HormoneDay(day: 1, LH: 2.0, FSH: 3.5, estradiol: 40.0, progesterone: 0.2),
        HormoneDay(day: 2, LH: 2.0, FSH: 3.6, estradiol: 50.0, progesterone: 0.2),
        HormoneDay(day: 3, LH: 2.0, FSH: 3.7, estradiol: 60.0, progesterone: 0.2),
        HormoneDay(day: 4, LH: 2.0, FSH: 4.0, estradiol: 70.0, progesterone: 0.2),
        HormoneDay(day: 5, LH: 2.0, FSH: 5.0, estradiol: 80.0, progesterone: 0.2),
        HormoneDay(day: 6, LH: 2.0, FSH: 6.0, estradiol: 90.0, progesterone: 0.2),
        HormoneDay(day: 7, LH: 2.0, FSH: 7.0, estradiol: 100.0, progesterone: 0.2),
        HormoneDay(day: 8, LH: 2.0, FSH: 8.0, estradiol: 110.0, progesterone: 0.2),
        HormoneDay(day: 9, LH: 2.0, FSH: 9.0, estradiol: 120.0, progesterone: 0.2),
        HormoneDay(day: 10, LH: 2.0, FSH: 10.0, estradiol: 130.0, progesterone: 0.2),
        HormoneDay(day: 11, LH: 2.0, FSH: 9.5, estradiol: 140.0, progesterone: 0.2),
        HormoneDay(day: 12, LH: 2.0, FSH: 9.0, estradiol: 150.0, progesterone: 0.2),
        HormoneDay(day: 13, LH: 5.0, FSH: 8.0, estradiol: 150.0, progesterone: 0.2),
        HormoneDay(day: 14, LH: 10.0, FSH: 7.0, estradiol: 200.0, progesterone: 0.5),
        HormoneDay(day: 15, LH: 20.0, FSH: 5.0, estradiol: 200.0, progesterone: 1.0),
        HormoneDay(day: 16, LH: 10.0, FSH: 5.0, estradiol: 166.67, progesterone: 5.0),
        HormoneDay(day: 17, LH: 5.0, FSH: 5.0, estradiol: 133.33, progesterone: 10.0),
        HormoneDay(day: 18, LH: 2.0, FSH: 5.0, estradiol: 100.0, progesterone: 12.0),
        HormoneDay(day: 19, LH: 2.0, FSH: 5.0, estradiol: 100.0, progesterone: 10.0),
        HormoneDay(day: 20, LH: 2.0, FSH: 5.0, estradiol: 112.5, progesterone: 8.0),
        HormoneDay(day: 21, LH: 2.0, FSH: 5.0, estradiol: 125.0, progesterone: 6.0),
        HormoneDay(day: 22, LH: 2.0, FSH: 5.0, estradiol: 137.5, progesterone: 4.0),
        HormoneDay(day: 23, LH: 2.0, FSH: 5.0, estradiol: 150.0, progesterone: 2.0),
        HormoneDay(day: 24, LH: 2.0, FSH: 5.0, estradiol: 125.0, progesterone: 1.0),
        HormoneDay(day: 25, LH: 2.0, FSH: 4.5, estradiol: 100.0, progesterone: 0.5),
        HormoneDay(day: 26, LH: 2.0, FSH: 4.0, estradiol: 75.0, progesterone: 0.3),
        HormoneDay(day: 27, LH: 2.0, FSH: 3.7, estradiol: 50.0, progesterone: 0.2),
        HormoneDay(day: 28, LH: 2.0, FSH: 3.5, estradiol: 40.0, progesterone: 0.2)
    ]
    
    enum HormoneType: String, CaseIterable {
        case LH = "LH"
        case FSH = "FSH"
        case estradiol = "E2"
        case progesterone = "P4"
        
        var color: Color {
            switch self {
            case .LH: return .blue
            case .FSH: return .green
            case .estradiol: return .pink
            case .progesterone: return .purple
            }
        }
        
        var unit: String {
            switch self {
            case .LH, .FSH: return "IU/L"
            case .estradiol: return "pg/mL"
            case .progesterone: return "ng/mL"
            }
        }
        
        var fullName: String {
            switch self {
            case .LH: return "Luteinizing Hormone"
            case .FSH: return "Follicle Stimulating Hormone"
            case .estradiol: return "Estradiol"
            case .progesterone: return "Progesterone"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Chart Tab
                chartView
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Hormone Chart")
                    }
                    .tag(0)
                
                // Predictions Tab
                predictionsView
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Predictions")
                    }
                    .tag(1)
            }
            .navigationTitle("Hormone Tracking")
            
            .onAppear {
                print("DEBUG: HormoneChartView appeared")
                loadPeriodData()
                calculateCurrentCycleDay()
                debugPeriodData() // Add this line
            }
            
        }
    }
    
    private var chartView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current Cycle Status with Phase Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Cycle")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let cycleDay = currentCycleDay {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Day \(cycleDay)")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.pink)
                                
                                Text(cyclePhase(for: cycleDay))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if let startDate = lastPeriodStart {
                                VStack(alignment: .trailing) {
                                    Text("Started")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(startDate, formatter: dateFormatter)
                                        .font(.footnote)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        
                        // Phase description
                        Text(getPhaseDescription(for: cycleDay))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                            .lineSpacing(2)
                        
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No Active Cycle")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text("Start tracking your period to see hormone predictions")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Hormone Selection - Single Row
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Hormone")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        ForEach(HormoneType.allCases, id: \.self) { hormone in
                            CompactHormoneButton(
                                hormone: hormone,
                                isSelected: selectedHormone == hormone,
                                action: {
                                    print("DEBUG: Selected hormone: \(hormone.rawValue)")
                                    selectedHormone = hormone
                                }
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Chart Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Hormone Levels Throughout Cycle")
                                .font(.headline)
                            Text(selectedHormone.unit)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let cycleDay = currentCycleDay,
                           let dayData = hormoneData.first(where: { $0.day == cycleDay }) {
                            VStack(alignment: .trailing) {
                                Text("Current Level")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f", dayData.getValue(for: selectedHormone)))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(selectedHormone.color)
                            }
                        }
                    }
                    
                    ImprovedHormoneChart(
                        data: hormoneData,
                        selectedHormone: selectedHormone,
                        currentCycleDay: currentCycleDay
                    )
                    .frame(height: 300)
                    
                    // Cycle Phase Information
                    CyclePhaseInfo()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    private var predictionsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Next Period Prediction
                VStack(alignment: .leading, spacing: 12) {
                    Text("Next Period Prediction")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let nextPeriod = predictNextPeriod() {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "calendar.circle.fill")
                                    .foregroundColor(.pink)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text("Expected Start")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(nextPeriod, formatter: dateFormatter)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.pink)
                                }
                                
                                Spacer()
                                
                                let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: nextPeriod).day ?? 0
                                VStack(alignment: .trailing) {
                                    Text("Days Until")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(max(0, daysUntil))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.pink)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                    } else {
                        Text("Track at least 2 periods to see predictions")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Calendar View - Full Height
                VStack(alignment: .leading, spacing: 16) {
                    Text("6-Month Calendar")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    FullHeightPeriodCalendar(
                        lastPeriodStart: lastPeriodStart,
                        averageCycleLength: calculateAverageCycleLength()
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer(minLength: 50)
            }
            .padding()
        }
    }
    
    // MARK: - Helper Functions
    
    private func cyclePhase(for day: Int) -> String {
        switch day {
        case 1...5: return "Menstrual Phase"
        case 6...13: return "Follicular Phase"
        case 14...15: return "Ovulation"
        case 16...28: return "Luteal Phase"
        default: return "Day \(day) of cycle"
        }
    }
    
    private func getPhaseDescription(for day: Int) -> String {
        switch day {
        case 1...5:
            return "Your cycle begins here, with most major hormones at a low ebb. Estrogen, progesterone, LH, and FSH are all quiet, and your body is focused on shedding the uterine lining. Don't be surprised if your energy feels drained, or if you feel more inward-facing than usual. This is a time for rest, warmth, and softness—mentally and physically. You might crave comfort food, sleep, or solitude. Go with it. Even if the world doesn't pause for your cycle, it's OK if you move through these days more slowly, listening to what your body needs."
        case 6...13:
            return "Estrogen and FSH are rising now, and you can feel it. Energy tends to build gradually, and your mood may lift along with it. You might find yourself feeling more clear-headed, more social, more motivated to get things done. Physically, things tend to feel lighter—less bloated, more agile. Creativity, confidence, and appetite for challenge can all increase during this phase, especially as ovulation nears. It's a great time for trying new things or making plans. Just don't overdo it too quickly—build up rather than blast off."
        case 14...15:
            return "Estrogen peaks, LH surges, and ovulation is triggered. This is your most fertile moment of the cycle, but even if you're not focused on fertility, you might notice a natural high here—more charm, more sparkle, more physical confidence. Some people feel flirty or expressive; others just feel oddly decisive or clear. Progesterone is about to rise, but for now estrogen is the star, and it can be a great time for social events, collaboration, or public-facing work. Just keep an eye on energy spikes—they can tip into irritability or restlessness if unbalanced."
        case 16...28:
            return "Progesterone takes the lead now, and everything starts to slow down. Estrogen dips, then gently rises again, but it's not the same buzzy feeling as before. You might feel more tired or sensitive, or crave more quiet and comfort. If PMS hits, it usually does so here—mood swings, cravings, sleep disruption, or feelings of doubt or overwhelm. Not everyone gets these, but if you do, it's helpful to know they're hormonally driven, not personal failings. Try to reduce stress, eat steadily, and protect your sleep. There's a lot of wisdom in leaning into reflection now—this is a phase for tying up loose ends, not starting new marathons."
        default:
            return "Continue listening to your body's needs during this phase of your cycle."
        }
    }
    
    private func predictNextPeriod() -> Date? {
        guard let lastStart = lastPeriodStart else { return nil }
        let averageLength = calculateAverageCycleLength()
        return Calendar.current.date(byAdding: .day, value: averageLength, to: lastStart)
    }
    
    private func loadPeriodData() {
        let request: NSFetchRequest<PeriodEntry> = PeriodEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PeriodEntry.startDate, ascending: false)]
        request.fetchLimit = 10
        
        do {
            periodEntries = try viewContext.fetch(request)
            print("DEBUG: Loaded \(periodEntries.count) period entries for hormone chart")
        } catch {
            print("DEBUG ERROR: Failed to load period entries: \(error)")
            periodEntries = []
        }
    }
    
    private func calculateCurrentCycleDay() {
        guard !periodEntries.isEmpty else {
            print("DEBUG: No period entries found")
            currentCycleDay = nil
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
            let calculatedDay = (daysSinceStart % 28) + 1 // Wrap around 28-day cycle
            currentCycleDay = calculatedDay
            
            print("DEBUG: Current cycle day: \(calculatedDay) (started \(daysSinceStart) days ago)")
        } else {
            print("DEBUG: No cycle start found")
            currentCycleDay = nil
        }
    }
    
    private func calculateAverageCycleLength() -> Int {
        guard periodEntries.count >= 2 else {
            print("DEBUG: Not enough period entries for cycle calculation")
            return 28
        }
        
        var cycleLengths: [Int] = []
        
        for (index, entry) in periodEntries.enumerated() {
            if let notes = entry.notes, notes.contains("Status: On") {
                // Check if this is the start of a new cycle
                if index < periodEntries.count - 1 {
                    let nextOnEntry = periodEntries.dropFirst(index + 1).first { nextEntry in
                        nextEntry.notes?.contains("Status: On") == true
                    }
                    
                    if let nextEntry = nextOnEntry {
                        let daysBetween = Calendar.current.dateComponents([.day], from: entry.startDate, to: nextEntry.startDate).day ?? 0
                        if daysBetween > 7 && daysBetween <= 45 { // Valid cycle length
                            cycleLengths.append(daysBetween)
                            print("DEBUG: Found cycle length: \(daysBetween) days")
                        }
                    }
                }
            }
        }
        
        if cycleLengths.isEmpty {
            print("DEBUG: No valid cycle lengths found, using default")
            return 28 // Default
        }
        
        let average = cycleLengths.reduce(0, +) / cycleLengths.count
        print("DEBUG: Average cycle length: \(average) days")
        return average
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    private func debugPeriodData() {
            print("=== HORMONE CHART VIEW - DEBUG PERIOD DATA ANALYSIS ===")
            
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
                
                print("=== HORMONE VIEW CYCLE CALCULATION DEBUG ===")
                debugHormoneCycleCalculation()
                
            } catch {
                print("DEBUG ERROR: Failed to fetch period entries: \(error)")
            }
        }
        
        private func debugHormoneCycleCalculation() {
            guard !periodEntries.isEmpty else {
                print("DEBUG: No period entries found for hormone cycle calculation")
                return
            }
            
            print("DEBUG: Analyzing \(periodEntries.count) period entries for hormone cycle calculation")
            
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
                
                print("DEBUG: Hormone view cycle start found: \(cycleStart)")
                print("DEBUG: Days since start: \(daysSinceStart)")
                print("DEBUG: Calculated cycle day: \(calculatedDay)")
                print("DEBUG: Current cycle day state variable: \(currentCycleDay ?? -1)")
                print("DEBUG: Last period start: \(lastPeriodStart?.description ?? "None")")
            } else {
                print("DEBUG: No valid cycle start found in hormone view")
            }
        }
    
}

// MARK: - Supporting Views

struct CompactHormoneButton: View {
    let hormone: HormoneChartView.HormoneType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(hormone.color)
                    .frame(width: 12, height: 12)
                
                Text(hormone.rawValue)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? hormone.color.opacity(0.2) : Color(.systemBackground))
                    .stroke(isSelected ? hormone.color : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .foregroundColor(isSelected ? hormone.color : .primary)
    }
}

struct HormoneSelectionCard: View {
    let hormone: HormoneChartView.HormoneType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(hormone.color)
                    .frame(width: 24, height: 24)
                
                Text(hormone.rawValue)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text(hormone.unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? hormone.color.opacity(0.1) : Color(.systemBackground))
                    .stroke(isSelected ? hormone.color : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(isSelected ? hormone.color : .primary)
    }
}

struct ImprovedHormoneChart: View {
    let data: [HormoneDay]
    let selectedHormone: HormoneChartView.HormoneType
    let currentCycleDay: Int?
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let padding: CGFloat = 30
            let chartWidth = width - (padding * 2)
            let chartHeight = height - (padding * 2)
            
            ZStack {
                // Phase background shading
                PhaseBackgroundShading(width: chartWidth, height: chartHeight, padding: padding)
                
                // All hormone lines (background) - now gray
                ForEach(HormoneChartView.HormoneType.allCases, id: \.self) { hormone in
                    if hormone != selectedHormone {
                        SmoothHormoneLine(
                            data: data,
                            hormone: hormone,
                            width: chartWidth,
                            height: chartHeight,
                            padding: padding,
                            isSelected: false
                        )
                    }
                }
                
                // Selected hormone line (foreground)
                SmoothHormoneLine(
                    data: data,
                    hormone: selectedHormone,
                    width: chartWidth,
                    height: chartHeight,
                    padding: padding,
                    isSelected: true
                )
                
                // Current cycle day indicator
                if let cycleDay = currentCycleDay, cycleDay <= 28 {
                    CurrentCycleDayIndicator(
                        cycleDay: cycleDay,
                        data: data,
                        selectedHormone: selectedHormone,
                        width: chartWidth,
                        height: chartHeight,
                        padding: padding
                    )
                }
                
                // Axis labels
                ChartAxisLabels(width: chartWidth, height: chartHeight, padding: padding)
            }
        }
    }
}

struct PhaseBackgroundShading: View {
    let width: CGFloat
    let height: CGFloat
    let padding: CGFloat
    
    var body: some View {
        ZStack {
            // Menstrual Phase (Days 1-5)
            Rectangle()
                .fill(Color.red.opacity(0.05))
                .frame(width: (4.0 / 27.0) * width, height: height)
                .position(
                    x: padding + (2.0 / 27.0) * width,
                    y: padding + height / 2
                )
            
            // Follicular Phase (Days 6-13)
            Rectangle()
                .fill(Color.blue.opacity(0.05))
                .frame(width: (7.0 / 27.0) * width, height: height)
                .position(
                    x: padding + (8.5 / 27.0) * width,
                    y: padding + height / 2
                )
            
            // Ovulation Phase (Days 14-15)
            Rectangle()
                .fill(Color.orange.opacity(0.08))
                .frame(width: (1.0 / 27.0) * width, height: height)
                .position(
                    x: padding + (13.5 / 27.0) * width,
                    y: padding + height / 2
                )
            
            // Luteal Phase (Days 16-28)
            Rectangle()
                .fill(Color.purple.opacity(0.05))
                .frame(width: (12.0 / 27.0) * width, height: height)
                .position(
                    x: padding + (20.5 / 27.0) * width,
                    y: padding + height / 2
                )
        }
    }
}

struct ChartGridLines: View {
    let width: CGFloat
    let height: CGFloat
    let padding: CGFloat
    
    var body: some View {
        Path { path in
            // Horizontal grid lines
            for i in 0...4 {
                let y = padding + (CGFloat(i) / 4.0) * height
                path.move(to: CGPoint(x: padding, y: y))
                path.addLine(to: CGPoint(x: padding + width, y: y))
            }
            
            // Vertical grid lines for cycle phases
            let phaseMarkers = [7, 14, 21] // End of menstrual, ovulation, end of luteal
            for marker in phaseMarkers {
                let x = padding + (CGFloat(marker - 1) / 27.0) * width
                path.move(to: CGPoint(x: x, y: padding))
                path.addLine(to: CGPoint(x: x, y: padding + height))
            }
        }
        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    }
}

struct ChartAxisLabels: View {
    let width: CGFloat
    let height: CGFloat
    let padding: CGFloat
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                ForEach([1, 7, 14, 21, 28], id: \.self) { day in
                    Text("\(day)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if day != 28 {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, padding)
        }
    }
}

struct CurrentCycleDayIndicator: View {
    let cycleDay: Int
    let data: [HormoneDay]
    let selectedHormone: HormoneChartView.HormoneType
    let width: CGFloat
    let height: CGFloat
    let padding: CGFloat
    
    var body: some View {
        let x = padding + (CGFloat(cycleDay - 1) / 27.0) * width
        
        ZStack {
            // Vertical line
            Path { path in
                path.move(to: CGPoint(x: x, y: padding))
                path.addLine(to: CGPoint(x: x, y: padding + height))
            }
            .stroke(Color.pink, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
            
            // Dot on selected hormone line
            if let dayData = data.first(where: { $0.day == cycleDay }) {
                let normalizedValue = normalizeValue(
                    dayData.getValue(for: selectedHormone),
                    for: selectedHormone
                )
                let y = padding + height - (normalizedValue * height)
                
                Circle()
                    .fill(selectedHormone.color)
                    .frame(width: 10, height: 10)
                    .position(x: x, y: y)
            }
        }
    }
    
    private func normalizeValue(_ value: Double, for hormone: HormoneChartView.HormoneType) -> Double {
        let ranges: [HormoneChartView.HormoneType: (min: Double, max: Double)] = [
            .LH: (0, 22),
            .FSH: (0, 12),
            .estradiol: (0, 220),
            .progesterone: (0, 14)
        ]
        
        guard let range = ranges[hormone] else { return 0 }
        return (value - range.min) / (range.max - range.min)
    }
}

struct CyclePhaseInfo: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Cycle Phases")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                PhaseLabel(title: "Menstrual", days: "1-5", color: .red)
                PhaseLabel(title: "Follicular", days: "1-13", color: .blue)
                PhaseLabel(title: "Ovulation", days: "14", color: .orange)
                PhaseLabel(title: "Luteal", days: "15-28", color: .purple)
            }
        }
    }
}

struct PhaseLabel: View {
    let title: String
    let days: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
            
            Text("Days \(days)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SmoothHormoneLine: View {
    let data: [HormoneDay]
    let hormone: HormoneChartView.HormoneType
    let width: CGFloat
    let height: CGFloat
    let padding: CGFloat
    let isSelected: Bool
    
    var body: some View {
        Path { path in
            let points = data.enumerated().map { (index, dayData) -> CGPoint in
                let x = padding + (CGFloat(index) / CGFloat(data.count - 1)) * width
                let normalizedValue = normalizeValue(dayData.getValue(for: hormone), for: hormone)
                let y = padding + height - (normalizedValue * height)
                return CGPoint(x: x, y: y)
            }
            
            guard points.count > 1 else { return }
            
            path.move(to: points[0])
            
            // Use simple quadratic curves for smooth, natural lines
            for i in 1..<points.count {
                let currentPoint = points[i]
                let previousPoint = points[i-1]
                
                // Create control point for smooth curve
                let controlPoint = CGPoint(
                    x: previousPoint.x + (currentPoint.x - previousPoint.x) * 0.5,
                    y: previousPoint.y + (currentPoint.y - previousPoint.y) * 0.3
                )
                
                path.addQuadCurve(to: currentPoint, control: controlPoint)
            }
        }
        .stroke(
            isSelected ? hormone.color : Color.gray,
            style: StrokeStyle(
                lineWidth: isSelected ? 3 : 1.5,
                lineCap: .round,
                lineJoin: .round
            )
        )
        .shadow(color: isSelected ? hormone.color.opacity(0.3) : Color.clear, radius: 4)
        .opacity(isSelected ? 1.0 : 0.4)
    }
    
    private func normalizeValue(_ value: Double, for hormone: HormoneChartView.HormoneType) -> Double {
        let ranges: [HormoneChartView.HormoneType: (min: Double, max: Double)] = [
            .LH: (0, 22),
            .FSH: (0, 12),
            .estradiol: (0, 220),
            .progesterone: (0, 14)
        ]
        
        guard let range = ranges[hormone] else { return 0 }
        return (value - range.min) / (range.max - range.min)
    }
}

struct FullHeightPeriodCalendar: View {
    let lastPeriodStart: Date?
    let averageCycleLength: Int
    
    var body: some View {
        VStack(spacing: 20) {
            if let lastStart = lastPeriodStart {
                let predictions = generatePredictions(from: lastStart, cycleLength: averageCycleLength)
                let months = generateCalendarMonths()
                
                ForEach(months, id: \.id) { monthData in
                    MonthCalendarView(
                        monthData: monthData,
                        predictions: predictions
                    )
                }
                
                // Legend
                HStack(spacing: 20) {
                    LegendItem(color: .pink, text: "Period Start")
                    LegendItem(color: .pink.opacity(0.3), text: "Period Days")
                }
                .padding(.top, 16)
                
            } else {
                Text("Start tracking your period to see predictions")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    private func generatePredictions(from startDate: Date, cycleLength: Int) -> [PeriodPrediction] {
        var predictions: [PeriodPrediction] = []
        let calendar = Calendar.current
        var currentDate = startDate
        
        print("DEBUG: Generating predictions from \(startDate) with cycle length \(cycleLength)")
        
        // Generate 6 cycles
        for _ in 0..<6 {
            let periodStart = currentDate
            var periodDays: [Date] = []
            
            // Add 5 days for the period
            for day in 0..<5 {
                if let periodDay = calendar.date(byAdding: .day, value: day, to: periodStart) {
                    periodDays.append(periodDay)
                }
            }
            
            predictions.append(PeriodPrediction(startDate: periodStart, periodDays: periodDays))
            
            // Move to next cycle
            currentDate = calendar.date(byAdding: .day, value: cycleLength, to: currentDate) ?? currentDate
        }
        
        print("DEBUG: Generated \(predictions.count) period predictions")
        return predictions
    }
    
    private func generateCalendarMonths() -> [CalendarMonth] {
        let calendar = Calendar.current
        let now = Date()
        var months: [CalendarMonth] = []
        
        print("DEBUG: Generating calendar months")
        
        for monthOffset in 0..<6 {
            guard let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: now) else { continue }
            
            let monthName = DateFormatter().monthSymbols[calendar.component(.month, from: monthDate) - 1]
            let year = calendar.component(.year, from: monthDate)
            
            // Get first day of month and number of days
            guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
                  let range = calendar.range(of: .day, in: .month, for: monthDate) else { continue }
            
            let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1 // 0-based
            
            var days: [CalendarDay] = []
            
            // Add empty days for proper alignment
            for emptyDay in 0..<firstWeekday {
                days.append(CalendarDay(
                    id: "empty-\(monthOffset)-\(emptyDay)",
                    date: Date.distantPast,
                    dayNumber: 0,
                    isEmpty: true
                ))
            }
            
            // Add actual days
            for day in 1...range.count {
                if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                    days.append(CalendarDay(
                        id: "day-\(monthOffset)-\(day)",
                        date: dayDate,
                        dayNumber: day,
                        isEmpty: false
                    ))
                }
            }
            
            months.append(CalendarMonth(
                id: "month-\(monthOffset)",
                monthName: "\(monthName) \(year)",
                days: days
            ))
        }
        
        print("DEBUG: Generated \(months.count) calendar months")
        return months
    }
}

struct MonthCalendarView: View {
    let monthData: CalendarMonth
    let predictions: [PeriodPrediction]
    
    var body: some View {
        VStack(spacing: 8) {
            // Month header
            HStack {
                Text(monthData.monthName)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Day headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(height: 30)
                }
                
                // Calendar days
                ForEach(monthData.days, id: \.id) { day in
                    CalendarDayView(
                        day: day,
                        predictions: predictions
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct CalendarDayView: View {
    let day: CalendarDay
    let predictions: [PeriodPrediction]
    
    var body: some View {
        VStack {
            if day.isEmpty {
                Text("")
                    .frame(width: 35, height: 35)
            } else {
                let dayType = getDayType(for: day.date)
                
                Text("\(day.dayNumber)")
                    .font(.caption)
                    .fontWeight(dayType.isSpecial ? .semibold : .regular)
                    .frame(width: 35, height: 35)
                    .background(dayType.backgroundColor)
                    .foregroundColor(dayType.textColor)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(dayType.borderColor, lineWidth: dayType.borderWidth)
                    )
            }
        }
    }
    
    private func getDayType(for date: Date) -> (backgroundColor: Color, textColor: Color, borderColor: Color, borderWidth: CGFloat, isSpecial: Bool) {
        let calendar = Calendar.current
        
        // Check period predictions first
        for prediction in predictions {
            // Check if this is period start day
            if calendar.isDate(date, inSameDayAs: prediction.startDate) {
                return (Color.pink, Color.white, Color.clear, 0, true)
            }
            
            // Check if this is a period day
            for periodDay in prediction.periodDays {
                if calendar.isDate(date, inSameDayAs: periodDay) {
                    return (Color.pink.opacity(0.3), Color.primary, Color.pink, 1, true)
                }
            }
            
            // Calculate cycle day relative to period start
            let daysSincePeriodStart = calendar.dateComponents([.day], from: prediction.startDate, to: date).day ?? 0
            let cycleDay = daysSincePeriodStart + 1
            
            // Check for other cycle phases (only for future dates within 28 days)
            if cycleDay > 0 && cycleDay <= 28 && date >= Date() {
                switch cycleDay {
                case 13...15: // Ovulation window
                    return (Color.orange.opacity(0.3), Color.primary, Color.orange, 2, true)
                case 20...21: // Progesterone peak
                    return (Color.purple.opacity(0.2), Color.primary, Color.purple, 1, true)
                case 25...28: // Late luteal phase (PMS onset)
                    return (Color.red.opacity(0.2), Color.primary, Color.red, 1, true)
                default:
                    break
                }
            }
        }
        
        // Check if it's today
        if calendar.isDate(date, inSameDayAs: Date()) {
            return (Color.blue.opacity(0.2), Color.primary, Color.blue, 2, true)
        }
        
        return (Color.clear, Color.primary, Color.clear, 0, false)
    }
}


    

