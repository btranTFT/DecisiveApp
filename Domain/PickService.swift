import Foundation
import SwiftData
import DecisionPicker

final class PickService {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Core Logic

    func getOrCreateTodayPick(for category: Category) -> PickHistory? {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 1. Check for existing pick for today
        if let existing = category.history?.first(where: { Calendar.current.startOfDay(for: $0.dateOnly) == today }) {
            return existing
        }
        
        // 2. Generate if missing
        return generatePick(for: category, source: .auto)
    }
    
    func reroll(category: Category) -> PickHistory? {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 1. Delete today's existing pick
        if let existing = category.history?.first(where: { Calendar.current.startOfDay(for: $0.dateOnly) == today }) {
            context.delete(existing)
        }
        
        // 2. Generate new
        return generatePick(for: category, source: .reroll)
    }
    
    private func generatePick(for category: Category, source: PickSource) -> PickHistory? {
        // Prepare PickerInput
        let today = Calendar.current.startOfDay(for: Date())
        
        // Options & History Logic
        var optionsMap: [UUID: OptionItem] = [:]
        var logicOptions: [PickerOption] = []
        
        // Map enabled options to Logic IDs
        for item in (category.options?.filter { $0.isEnabled } ?? []) {
            let logicID = UUID()
            optionsMap[logicID] = item
            logicOptions.append(PickerOption(id: logicID, name: item.name))
        }
        
        // Map History
        // We need to map history items to the SAME temporary IDs used for options
        var itemToLogicID: [PersistentIdentifier: UUID] = [:]
        for (logicID, item) in optionsMap {
            itemToLogicID[item.persistentModelID] = logicID
        }
        
        let logicHistory = category.history?.compactMap { hist -> PickerHistoryItem? in
            if let opt = hist.option, let logicId = itemToLogicID[opt.id] {
                return PickerHistoryItem(optionId: logicId, dateOnly: hist.dateOnly)
            }
            return nil
        } ?? []
        
        // RE-CREATE input with correct mapping
        let smartInput = PickerInput(
            options: logicOptions,
            history: logicHistory,
            rules: rules,
            dateOnly: today,
            seed: seed
        )
        
        guard let smartResult = DecisionPicker.pick(input: smartInput),
              let pickedOptionItem = optionsMap[smartResult.optionId] else {
            return nil
        }
        
        // Save
        let pick = PickHistory(
            date: Date(),
            category: category,
            option: pickedOptionItem,
            source: source,
            reason: smartResult.reason
        )
        context.insert(pick)
        
        return pick
    }
}


