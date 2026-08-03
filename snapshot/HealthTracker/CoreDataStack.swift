import CoreData
import Foundation

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        // Create the container with the programmatic model
        let container = NSPersistentContainer(name: "HealthTracker", managedObjectModel: createManagedObjectModel())
        
        print("DEBUG: Setting up Core Data container")
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("DEBUG ERROR: Core Data failed to load: \(error)")
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            } else {
                print("DEBUG: Core Data loaded successfully")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("DEBUG: Context saved successfully")
            } catch {
                print("DEBUG ERROR: Failed to save context: \(error)")
            }
        }
    }
    
    private init() {}
    
    private func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        print("DEBUG: Creating programmatic Core Data model")
        
        // Create all entities
        let predefinedSymptomEntity = createPredefinedSymptomEntity()
        let dailyEntryEntity = createDailyEntryEntity()
        let symptomRatingEntity = createSymptomRatingEntity()
        let periodEntryEntity = createPeriodEntryEntity()
        let sleepEntryEntity = createSleepEntryEntity()
        let lifestyleEntryEntity = createLifestyleEntryEntity()
        
        // Set up relationships
        setupRelationships(dailyEntry: dailyEntryEntity, symptomRating: symptomRatingEntity)
        
        // Add all entities to the model
        model.entities = [
            predefinedSymptomEntity,
            dailyEntryEntity,
            symptomRatingEntity,
            periodEntryEntity,
            sleepEntryEntity,
            lifestyleEntryEntity
        ]
        
        print("DEBUG: Created Core Data model with \(model.entities.count) entities")
        return model
    }
    
    private func createPredefinedSymptomEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "PredefinedSymptom"
        entity.managedObjectClassName = "PredefinedSymptom"
        
        let nameAttr = NSAttributeDescription()
        nameAttr.name = "name"
        nameAttr.attributeType = .stringAttributeType
        nameAttr.isOptional = false
        
        let categoryAttr = NSAttributeDescription()
        categoryAttr.name = "category"
        categoryAttr.attributeType = .stringAttributeType
        categoryAttr.isOptional = false
        
        let isActiveAttr = NSAttributeDescription()
        isActiveAttr.name = "isActive"
        isActiveAttr.attributeType = .booleanAttributeType
        isActiveAttr.isOptional = false
        isActiveAttr.defaultValue = true
        
        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false
        
        entity.properties = [nameAttr, categoryAttr, isActiveAttr, createdAtAttr]
        return entity
    }
    
    private func createDailyEntryEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "DailyEntry"
        entity.managedObjectClassName = "DailyEntry"
        
        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = false
        
        let notesAttr = NSAttributeDescription()
        notesAttr.name = "notes"
        notesAttr.attributeType = .stringAttributeType
        notesAttr.isOptional = true
        
        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false
        
        entity.properties = [dateAttr, notesAttr, createdAtAttr]
        return entity
    }
    
    private func createSymptomRatingEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "SymptomRating"
        entity.managedObjectClassName = "SymptomRating"
        
        let symptomNameAttr = NSAttributeDescription()
        symptomNameAttr.name = "symptomName"
        symptomNameAttr.attributeType = .stringAttributeType
        symptomNameAttr.isOptional = false
        
        let ratingAttr = NSAttributeDescription()
        ratingAttr.name = "rating"
        ratingAttr.attributeType = .integer16AttributeType
        ratingAttr.isOptional = false
        
        entity.properties = [symptomNameAttr, ratingAttr]
        return entity
    }
    
    private func createPeriodEntryEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "PeriodEntry"
        entity.managedObjectClassName = "PeriodEntry"
        
        let startDateAttr = NSAttributeDescription()
        startDateAttr.name = "startDate"
        startDateAttr.attributeType = .dateAttributeType
        startDateAttr.isOptional = false
        
        let endDateAttr = NSAttributeDescription()
        endDateAttr.name = "endDate"
        endDateAttr.attributeType = .dateAttributeType
        endDateAttr.isOptional = true
        
        let flowAttr = NSAttributeDescription()
        flowAttr.name = "flow"
        flowAttr.attributeType = .stringAttributeType
        flowAttr.isOptional = true
        
        let symptomsAttr = NSAttributeDescription()
        symptomsAttr.name = "symptoms"
        symptomsAttr.attributeType = .stringAttributeType
        symptomsAttr.isOptional = true
        
        let notesAttr = NSAttributeDescription()
        notesAttr.name = "notes"
        notesAttr.attributeType = .stringAttributeType
        notesAttr.isOptional = true
        
        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false
        
        entity.properties = [startDateAttr, endDateAttr, flowAttr, symptomsAttr, notesAttr, createdAtAttr]
        return entity
    }
    
    private func createSleepEntryEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "SleepEntry"
        entity.managedObjectClassName = "SleepEntry"
        
        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = false
        
        let hoursSleptAttr = NSAttributeDescription()
        hoursSleptAttr.name = "hoursSlept"
        hoursSleptAttr.attributeType = .doubleAttributeType
        hoursSleptAttr.isOptional = false
        
        let sleepQualityAttr = NSAttributeDescription()
        sleepQualityAttr.name = "sleepQuality"
        sleepQualityAttr.attributeType = .integer16AttributeType
        sleepQualityAttr.isOptional = false
        
        let disturbancesAttr = NSAttributeDescription()
        disturbancesAttr.name = "disturbances"
        disturbancesAttr.attributeType = .stringAttributeType
        disturbancesAttr.isOptional = true
        
        let notesAttr = NSAttributeDescription()
        notesAttr.name = "notes"
        notesAttr.attributeType = .stringAttributeType
        notesAttr.isOptional = true
        
        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false
        
        entity.properties = [dateAttr, hoursSleptAttr, sleepQualityAttr, disturbancesAttr, notesAttr, createdAtAttr]
        return entity
    }
    
    private func createLifestyleEntryEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "LifestyleEntry"
        entity.managedObjectClassName = "LifestyleEntry"
        
        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = false
        
        let caffeineIntakeAttr = NSAttributeDescription()
        caffeineIntakeAttr.name = "caffeineIntake"
        caffeineIntakeAttr.attributeType = .integer16AttributeType
        caffeineIntakeAttr.isOptional = false
        
        let alcoholIntakeAttr = NSAttributeDescription()
        alcoholIntakeAttr.name = "alcoholIntake"
        alcoholIntakeAttr.attributeType = .integer16AttributeType
        alcoholIntakeAttr.isOptional = false
        
        let waterIntakeAttr = NSAttributeDescription()
        waterIntakeAttr.name = "waterIntake"
        waterIntakeAttr.attributeType = .doubleAttributeType
        waterIntakeAttr.isOptional = false
        
        let exerciseMinutesAttr = NSAttributeDescription()
        exerciseMinutesAttr.name = "exerciseMinutes"
        exerciseMinutesAttr.attributeType = .integer16AttributeType
        exerciseMinutesAttr.isOptional = false
        
        let energyLevelAttr = NSAttributeDescription()
        energyLevelAttr.name = "energyLevel"
        energyLevelAttr.attributeType = .integer16AttributeType
        energyLevelAttr.isOptional = false
        
        let stressLevelAttr = NSAttributeDescription()
        stressLevelAttr.name = "stressLevel"
        stressLevelAttr.attributeType = .integer16AttributeType
        stressLevelAttr.isOptional = false
        
        let medicationsAttr = NSAttributeDescription()
        medicationsAttr.name = "medications"
        medicationsAttr.attributeType = .stringAttributeType
        medicationsAttr.isOptional = true
        
        let dietaryTriggersAttr = NSAttributeDescription()
        dietaryTriggersAttr.name = "dietaryTriggers"
        dietaryTriggersAttr.attributeType = .stringAttributeType
        dietaryTriggersAttr.isOptional = true
        
        let notesAttr = NSAttributeDescription()
        notesAttr.name = "notes"
        notesAttr.attributeType = .stringAttributeType
        notesAttr.isOptional = true
        
        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false
        
        entity.properties = [
            dateAttr, caffeineIntakeAttr, alcoholIntakeAttr, waterIntakeAttr,
            exerciseMinutesAttr, energyLevelAttr, stressLevelAttr, medicationsAttr,
            dietaryTriggersAttr, notesAttr, createdAtAttr
        ]
        
        return entity
    }
    
    private func setupRelationships(dailyEntry: NSEntityDescription, symptomRating: NSEntityDescription) {
        // DailyEntry -> SymptomRating (one-to-many)
        let symptomRatingsRelationship = NSRelationshipDescription()
        symptomRatingsRelationship.name = "symptomRatings"
        symptomRatingsRelationship.destinationEntity = symptomRating
        symptomRatingsRelationship.maxCount = 0 // 0 means unlimited (to-many)
        symptomRatingsRelationship.deleteRule = .cascadeDeleteRule
        
        // SymptomRating -> DailyEntry (many-to-one)
        let dailyEntryRelationship = NSRelationshipDescription()
        dailyEntryRelationship.name = "dailyEntry"
        dailyEntryRelationship.destinationEntity = dailyEntry
        dailyEntryRelationship.maxCount = 1 // to-one relationship
        dailyEntryRelationship.deleteRule = .nullifyDeleteRule
        
        // Set inverse relationships
        symptomRatingsRelationship.inverseRelationship = dailyEntryRelationship
        dailyEntryRelationship.inverseRelationship = symptomRatingsRelationship
        
        // Add relationships to entities
        dailyEntry.properties.append(symptomRatingsRelationship)
        symptomRating.properties.append(dailyEntryRelationship)
        
        print("DEBUG: Set up Core Data relationships")
    }
}

// MARK: - Core Data Model Definitions (keep these the same)

@objc(PredefinedSymptom)
public class PredefinedSymptom: NSManagedObject {
    @NSManaged public var name: String
    @NSManaged public var category: String
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date
}

extension PredefinedSymptom {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PredefinedSymptom> {
        return NSFetchRequest<PredefinedSymptom>(entityName: "PredefinedSymptom")
    }
}

@objc(DailyEntry)
public class DailyEntry: NSManagedObject {
    @NSManaged public var date: Date
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var symptomRatings: NSSet?
}

extension DailyEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyEntry> {
        return NSFetchRequest<DailyEntry>(entityName: "DailyEntry")
    }
    
    @objc(addSymptomRatingsObject:)
    @NSManaged public func addToSymptomRatings(_ value: SymptomRating)
    
    @objc(removeSymptomRatingsObject:)
    @NSManaged public func removeFromSymptomRatings(_ value: SymptomRating)
    
    @objc(addSymptomRatings:)
    @NSManaged public func addToSymptomRatings(_ values: NSSet)
    
    @objc(removeSymptomRatings:)
    @NSManaged public func removeFromSymptomRatings(_ values: NSSet)
}

@objc(SymptomRating)
public class SymptomRating: NSManagedObject {
    @NSManaged public var symptomName: String
    @NSManaged public var rating: Int16
    @NSManaged public var dailyEntry: DailyEntry?
}

extension SymptomRating {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SymptomRating> {
        return NSFetchRequest<SymptomRating>(entityName: "SymptomRating")
    }
}

@objc(PeriodEntry)
public class PeriodEntry: NSManagedObject {
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date?
    @NSManaged public var flow: String?
    @NSManaged public var symptoms: String?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date
}

extension PeriodEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PeriodEntry> {
        return NSFetchRequest<PeriodEntry>(entityName: "PeriodEntry")
    }
}

@objc(SleepEntry)
public class SleepEntry: NSManagedObject {
    @NSManaged public var date: Date
    @NSManaged public var hoursSlept: Double
    @NSManaged public var sleepQuality: Int16
    @NSManaged public var disturbances: String?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date
}

extension SleepEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SleepEntry> {
        return NSFetchRequest<SleepEntry>(entityName: "SleepEntry")
    }
}

@objc(LifestyleEntry)
public class LifestyleEntry: NSManagedObject {
    @NSManaged public var date: Date
    @NSManaged public var caffeineIntake: Int16
    @NSManaged public var alcoholIntake: Int16
    @NSManaged public var waterIntake: Double
    @NSManaged public var exerciseMinutes: Int16
    @NSManaged public var energyLevel: Int16
    @NSManaged public var stressLevel: Int16
    @NSManaged public var medications: String?
    @NSManaged public var dietaryTriggers: String?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date
}

extension LifestyleEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LifestyleEntry> {
        return NSFetchRequest<LifestyleEntry>(entityName: "LifestyleEntry")
    }
}
