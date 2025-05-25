import CoreData
import Foundation

class SymptomDataManager {
    static let shared = SymptomDataManager()
    
    private init() {}
    
    // Predefined symptoms for migraine and post-concussion syndrome
    private let migrainePCSSymptoms: [(name: String, category: String)] = [
        // Migraine-specific symptoms
        ("Headache", "Migraine"),
        ("Nausea", "Migraine"),
        ("Vomiting", "Migraine"),
        ("Light Sensitivity", "Migraine"),
        ("Sound Sensitivity", "Migraine"),
        ("Visual Aura", "Migraine"),
        ("Throbbing Pain", "Migraine"),
        ("One-sided Pain", "Migraine"),
        
        // Post-Concussion Syndrome symptoms
        ("Confusion", "Post-Concussion"),
        ("Memory Problems", "Post-Concussion"),
        ("Concentration Difficulty", "Post-Concussion"),
        ("Dizziness", "Post-Concussion"),
        ("Balance Problems", "Post-Concussion"),
        ("Fatigue", "Post-Concussion"),
        ("Sleep Disturbances", "Post-Concussion"),
        ("Irritability", "Post-Concussion"),
        ("Anxiety", "Post-Concussion"),
        ("Depression", "Post-Concussion"),
        ("Personality Changes", "Post-Concussion"),
        ("Brain Fog", "Post-Concussion"),
        
        // Shared/Common symptoms
        ("Neck Pain", "Physical"),
        ("Shoulder Tension", "Physical"),
        ("Eye Strain", "Physical"),
        ("Blurred Vision", "Physical"),
        ("Ringing in Ears", "Physical"),
        ("Mood Changes", "Emotional"),
        ("Stress", "Emotional"),
        ("Restlessness", "Emotional"),
        ("Appetite Changes", "Physical"),
        ("Digestive Issues", "Physical")
    ]
    
    func populatePredefinedSymptoms(context: NSManagedObjectContext) {
        print("DEBUG: Starting to populate predefined symptoms")
        
        for symptom in migrainePCSSymptoms {
            let predefinedSymptom = PredefinedSymptom(context: context)
            predefinedSymptom.name = symptom.name
            predefinedSymptom.category = symptom.category
            predefinedSymptom.isActive = true
            predefinedSymptom.createdAt = Date()
            
            print("DEBUG: Created symptom: \(symptom.name) in category: \(symptom.category)")
        }
        
        do {
            try context.save()
            print("DEBUG: Successfully saved \(migrainePCSSymptoms.count) predefined symptoms")
        } catch {
            print("DEBUG ERROR: Failed to save predefined symptoms: \(error)")
        }
    }
    
    func fetchActiveSymptoms(context: NSManagedObjectContext) -> [PredefinedSymptom] {
        let request: NSFetchRequest<PredefinedSymptom> = PredefinedSymptom.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == %@", NSNumber(value: true))
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \PredefinedSymptom.category, ascending: true),
            NSSortDescriptor(keyPath: \PredefinedSymptom.name, ascending: true)
        ]
        
        do {
            let symptoms = try context.fetch(request)
            print("DEBUG: Fetched \(symptoms.count) active symptoms")
            return symptoms
        } catch {
            print("DEBUG ERROR: Failed to fetch symptoms: \(error)")
            return []
        }
    }
    
    func fetchSymptomsByCategory(context: NSManagedObjectContext) -> [String: [PredefinedSymptom]] {
        let symptoms = fetchActiveSymptoms(context: context)
        let grouped = Dictionary(grouping: symptoms) { $0.category }
        
        print("DEBUG: Grouped symptoms into \(grouped.keys.count) categories")
        for (category, categorySymptoms) in grouped {
            print("DEBUG: Category '\(category)' has \(categorySymptoms.count) symptoms")
        }
        
        return grouped
    }
    
    func saveDailyEntry(
        date: Date,
        symptomRatings: [String: Int],
        notes: String?,
        context: NSManagedObjectContext
    ) {
        print("DEBUG: Saving daily entry for \(date) with \(symptomRatings.count) ratings")
        
        // Check if entry already exists for this date
        let request: NSFetchRequest<DailyEntry> = DailyEntry.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let existingEntries = try context.fetch(request)
            let dailyEntry: DailyEntry
            
            if let existing = existingEntries.first {
                print("DEBUG: Updating existing daily entry")
                dailyEntry = existing
                // Clear existing ratings
                if let ratings = dailyEntry.symptomRatings {
                    for rating in ratings {
                        context.delete(rating as! NSManagedObject)
                    }
                }
            } else {
                print("DEBUG: Creating new daily entry")
                dailyEntry = DailyEntry(context: context)
                dailyEntry.date = date
                dailyEntry.createdAt = Date()
            }
            
            dailyEntry.notes = notes
            
            // Add symptom ratings
            for (symptomName, rating) in symptomRatings {
                let symptomRating = SymptomRating(context: context)
                symptomRating.symptomName = symptomName
                symptomRating.rating = Int16(rating)
                symptomRating.dailyEntry = dailyEntry
                
                print("DEBUG: Added rating - \(symptomName): \(rating)")
            }
            
            try context.save()
            print("DEBUG: Successfully saved daily entry")
            
        } catch {
            print("DEBUG ERROR: Failed to save daily entry: \(error)")
        }
    }
}
