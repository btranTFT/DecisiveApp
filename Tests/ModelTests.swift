import XCTest
import SwiftData
@testable import DecisiveApp

final class ModelTests: XCTestCase {
    var modelContext: ModelContext!
    var container: ModelContainer!

    override func setUpWithError() throws {
        // Create an in-memory test container
        let schema = Schema([
            Category.self,
            OptionItem.self,
            PickHistory.self,
            Settings.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        modelContext = container.mainContext
    }

    override func tearDownWithError() throws {
        container = nil
        modelContext = nil
    }

    func testCategoryCreation() throws {
        let category = Category(name: "Test Category")
        modelContext.insert(category)
        
        // Fetch to verify
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.name == "Test Category" })
        let savedCategory = try modelContext.fetch(descriptor).first
        
        XCTAssertNotNil(savedCategory)
        XCTAssertEqual(savedCategory?.name, "Test Category")
    }
    
    func testOptionItemCreationAndRelationship() throws {
        let category = Category(name: "Food")
        modelContext.insert(category)
        
        let option = OptionItem(name: "Pizza", category: category)
        modelContext.insert(option)
        
        // Check relationships
        XCTAssertEqual(option.category?.name, "Food")
        // Note: Inverse relationships might not auto-populate in unit tests until save/fetch cycle or manual assignment depending on SwiftData version
        // But let's check basic link
    }
    
    func testPickHistoryCreation() throws {
        let category = Category(name: "Workout")
        let option = OptionItem(name: "Run", category: category)
        modelContext.insert(category)
        modelContext.insert(option)
        
        let history = PickHistory(date: Date(), category: category, option: option, source: .auto, reason: "Test")
        modelContext.insert(history)
        
        XCTAssertEqual(history.source, .auto)
        XCTAssertEqual(history.reason, "Test")
        XCTAssertEqual(history.dateOnly, Calendar.current.startOfDay(for: Date()))
    }
    
    func testSettingsCreation() throws {
        let category = Category(name: "Category")
        modelContext.insert(category)
        
        let settings = Settings(noRepeatDays: 5, category: category)
        modelContext.insert(settings)
        
        XCTAssertEqual(settings.noRepeatDays, 5)
        XCTAssertEqual(settings.category?.name, "Category")
    }
}
