import SwiftUI
import CoreData

@main
struct HealthTrackerApp: App {
    let persistentContainer = CoreDataStack.shared.persistentContainer
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistentContainer.viewContext)
                .onAppear {
                    print("DEBUG: HealthTracker app launched")
                    setupCoreData()
                }
        }
    }
    
    private func setupCoreData() {
        print("DEBUG: Setting up Core Data")
        
        // Ensure the managed object model is properly configured
        let context = persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Auto-save context when app moves to background
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            print("DEBUG: App moving to background, saving context")
            CoreDataStack.shared.save()
        }
        
        print("DEBUG: Core Data setup complete")
    }
}
