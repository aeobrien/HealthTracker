import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DailyTrackingView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Daily Entry")
                }
                .tag(0)
            
            PeriodTrackingView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Period")
                }
                .tag(1)
            
            HormoneChartView()
                .tabItem {
                    Image(systemName: "waveform.path.ecg")
                    Text("Hormones")
                }
                .tag(2)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("History")
                }
                .tag(3)
        }
        .onAppear {
            // Debug: Check if symptoms are populated
            checkAndPopulateSymptoms()
        }
    }
    
    private func checkAndPopulateSymptoms() {
        let request: NSFetchRequest<PredefinedSymptom> = PredefinedSymptom.fetchRequest()
        
        do {
            let count = try viewContext.count(for: request)
            if count == 0 {
                print("DEBUG: No predefined symptoms found, populating...")
                SymptomDataManager.shared.populatePredefinedSymptoms(context: viewContext)
            } else {
                print("DEBUG: Found \(count) predefined symptoms")
            }
        } catch {
            print("DEBUG ERROR: Failed to check symptoms: \(error)")
        }
    }
}
