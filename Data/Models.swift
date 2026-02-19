import Foundation
import SwiftData

// DateOnly Helper
// SwiftData doesn't store DateComponents directly well, stick to normalized Date (midnight UTC or Local)
// For simplicity in MVP: Local midnight
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

enum PickSource: String, Codable {
    case auto
    case reroll
    case manual
}

@Model
final class Category {
    @Attribute(.unique) var name: String
    var createdAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \OptionItem.category)
    var options: [OptionItem]?
    
    @Relationship(deleteRule: .cascade, inverse: \PickHistory.category)
    var history: [PickHistory]?
    
    @Relationship(deleteRule: .cascade, inverse: \Settings.category)
    var settings: Settings?
    
    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}

@Model
final class OptionItem {
    var name: String
    var notes: String?
    var tags: [String]
    var isEnabled: Bool
    var createdAt: Date
    
    @Relationship
    var category: Category?
    
    init(name: String, notes: String? = nil, tags: [String] = [], isEnabled: Bool = true, category: Category? = nil) {
        self.name = name
        self.notes = notes
        self.tags = tags
        self.isEnabled = isEnabled
        self.createdAt = Date()
        self.category = category
    }
}

@Model
final class PickHistory {
    var dateOnly: Date // Normalized to midnight
    var pickedAt: Date // Actual timestamp
    var sourceRaw: String 
    var reason: String
    
    @Relationship
    var category: Category?
    
    @Relationship
    var option: OptionItem?
    
    var source: PickSource {
        get { PickSource(rawValue: sourceRaw) ?? .auto }
        set { sourceRaw = newValue.rawValue }
    }
    
    init(date: Date, category: Category, option: OptionItem, source: PickSource = .auto, reason: String = "") {
        self.dateOnly = Calendar.current.startOfDay(for: date)
        self.pickedAt = date
        self.category = category
        self.option = option
        self.sourceRaw = source.rawValue
        self.reason = reason
    }
}

@Model
final class Settings {
    var noRepeatDays: Int
    
    @Relationship
    var category: Category?
    
    init(noRepeatDays: Int = 3, category: Category? = nil) {
        self.noRepeatDays = noRepeatDays
        self.category = category
    }
}
