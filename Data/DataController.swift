import Foundation
import SwiftData

class DataController {
    
    // Seed initial categories
    static func seedCategories(modelContext: ModelContext) {
        let defaults = ["Meal", "Outfit", "Workout"]
        
        do {
            let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
            let existing = try modelContext.fetch(descriptor)
            
            // For MVP: if empty, insert defaults
            if existing.isEmpty {
                for name in defaults {
                    let cat = Category(name: name)
                    modelContext.insert(cat)
                    
                    // Create settings for each category
                    let settings = Settings(noRepeatDays: 3, category: cat)
                    modelContext.insert(settings)
                    
                    // Add default options for each category
                    if name == "Meal" {
                        modelContext.insert(OptionItem(name: "Pizza", tags: ["Fast"], category: cat))
                        modelContext.insert(OptionItem(name: "Salad", tags: ["Healthy"], category: cat))
                    } else if name == "Outfit" {
                         modelContext.insert(OptionItem(name: "Jeans & T-Shirt", tags: ["Casual"], category: cat))
                         modelContext.insert(OptionItem(name: "Suit", tags: ["Formal"], category: cat))
                    } else if name == "Workout" {
                        modelContext.insert(OptionItem(name: "Run", tags: ["Cardio"], category: cat))
                        modelContext.insert(OptionItem(name: "Weights", tags: ["Strength"], category: cat))
                    }
                }
            }
        } catch {
            print("Seed categories failed: \(error)")
        }
    }
}
