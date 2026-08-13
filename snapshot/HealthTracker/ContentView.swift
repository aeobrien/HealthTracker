import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    
    init() {
        // Apply minimal UI style to tab bar
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(DesignSystem.Colors.cardBackground)
        appearance.shadowColor = UIColor(DesignSystem.Shadows.subtle)
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(DesignSystem.Colors.primaryBlue)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(DesignSystem.Colors.primaryBlue),
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(DesignSystem.Colors.tertiaryText)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(DesignSystem.Colors.tertiaryText),
            .font: UIFont.systemFont(ofSize: 11, weight: .regular)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
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
        .accentColor(DesignSystem.Colors.primaryBlue)
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
                
                // Check if we need to update symptom names (run once)
                let hasUpdated = UserDefaults.standard.bool(forKey: "SymptomsUpdatedToNewNames")
                if !hasUpdated {
                    print("DEBUG: Updating existing symptoms to new names...")
                    SymptomDataManager.shared.updateExistingSymptoms(context: viewContext)
                    UserDefaults.standard.set(true, forKey: "SymptomsUpdatedToNewNames")
                }
            }
        } catch {
            print("DEBUG ERROR: Failed to check symptoms: \(error)")
        }
    }
}
