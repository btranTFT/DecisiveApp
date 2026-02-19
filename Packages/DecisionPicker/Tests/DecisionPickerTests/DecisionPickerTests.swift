import XCTest
@testable import DecisionPicker

final class DecisionPickerTests: XCTestCase {
    
    // Helpers
    func makeOption(name: String) -> PickerOption {
        return PickerOption(name: name)
    }
    
    func makeHistory(optionId: UUID, daysAgo: Int, from today: Date) -> PickerHistoryItem {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
        let dateOnly = Calendar.current.startOfDay(for: date)
        return PickerHistoryItem(optionId: optionId, dateOnly: dateOnly)
    }

    func testExcludesRecentPicks() {
        let today = Calendar.current.startOfDay(for: Date())
        let opt1 = makeOption(name: "A")
        let opt2 = makeOption(name: "B")
        
        // History: A picked yesterday
        let history = [makeHistory(optionId: opt1.id, daysAgo: 1, from: today)]
        
        let input = PickerInput(
            options: [opt1, opt2],
            history: history,
            rules: PickerRules(noRepeatDays: 3),
            dateOnly: today,
            seed: 12345
        )
        
        let result = DecisionPicker.pick(input: input)
        
        XCTAssertEqual(result?.optionId, opt2.id, "Should pick B because A was picked yesterday (within 3 days)")
        XCTAssertEqual(result?.reason, "Standard logic (no repeats in 3 days)")
    }
    
    func testRelaxesConstraintsWhenNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let opt1 = makeOption(name: "A")
        
        // History: A picked yesterday
        let history = [makeHistory(optionId: opt1.id, daysAgo: 1, from: today)]
        
        // Rules: No Repeat 3 Days
        // But only option A exists. So it MUST relax to allow picking A.
        
        let input = PickerInput(
            options: [opt1],
            history: history,
            rules: PickerRules(noRepeatDays: 3),
            dateOnly: today,
            seed: 12345
        )
        
        let result = DecisionPicker.pick(input: input)
        
        XCTAssertEqual(result?.optionId, opt1.id, "Should eventually pick A even though it was picked yesterday")
        // It relaxes: N=3 (fail), N=2 (fail), N=1 (fail - picked 1 day ago), N=0 (success)
        // Wait. N=1 means "exclude from Yesterday". So A is excluded.
        // N=0 means "exclude from Today". A was picked Yesterday. So N=0 allows Yesterday.
        XCTAssertEqual(result?.reason, "Relaxed repeat rule to 0 days")
    }

    func testDeterministicSeed() {
        let today = Calendar.current.startOfDay(for: Date())
        let opt1 = makeOption(name: "A")
        let opt2 = makeOption(name: "B")
        let opt3 = makeOption(name: "C")
        
        let options = [opt1, opt2, opt3]
        
        let input1 = PickerInput(
            options: options,
            history: [],
            rules: PickerRules(noRepeatDays: 3),
            dateOnly: today,
            seed: 99999
        )
        
        let result1 = DecisionPicker.pick(input: input1)
        let result2 = DecisionPicker.pick(input: input1)
        
        XCTAssertEqual(result1?.optionId, result2?.optionId, "Same seed should produce same result")
        XCTAssertNotNil(result1)
        
        // Different seed
        let input2 = PickerInput(
            options: options,
            history: [],
            rules: PickerRules(noRepeatDays: 3),
            dateOnly: today,
            seed: 11111 
        )
        
        let result3 = DecisionPicker.pick(input: input2)
        XCTAssertNotNil(result3)
        // We do not check result1 != result3 because random collision is possible with small set.
    }
}
