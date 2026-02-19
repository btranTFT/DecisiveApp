import Foundation

public struct PickerInput {
    public let options: [PickerOption]
    public let history: [PickerHistoryItem]
    public let rules: PickerRules
    public let dateOnly: Date // Represents 'today'
    public let seed: Int // For deterministic randomness
}

public struct PickerOption: Identifiable {
    public let id: UUID
    public let name: String
    
    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

public struct PickerHistoryItem {
    public let optionId: UUID
    public let dateOnly: Date
    
    public init(optionId: UUID, dateOnly: Date) {
        self.optionId = optionId
        self.dateOnly = dateOnly
    }
}

public struct PickerRules {
    public let noRepeatDays: Int
    
    public init(noRepeatDays: Int) {
        self.noRepeatDays = noRepeatDays
    }
}

public struct PickerResult {
    public let optionId: UUID
    public let reason: String
}

public struct DecisionPicker {
    
    public static func pick(input: PickerInput) -> PickerResult? {
        // 1. Filter out options used recently based on noRepeatDays
        // We might need to relax N if no options are available
        
        let availableOptions = input.options
        if availableOptions.isEmpty { return nil }
        
        var currentN = input.rules.noRepeatDays
        var candidates: [PickerOption] = []
        var finalReason = ""
        
        // Loop to relax constraints if needed
        // Constraint: We want to exclude options that were picked in [Today - N, Today - 1]
        // Actually, usually it is "last N days" meaning strictly before today?
        // Or including today if we already picked today?
        // Let's assume input.history includes past picks. If we picked today, user is asking for a reroll or new pick implies ignoring today's previous pick?
        // The prompt says "Exclude options picked in last N days (by dateOnly)". 
        // Let's assume standard intuitive "don't repeat what I ate yesterday".
        
        while currentN >= 0 {
            // Define cutoff. If N=1, we exclude picks from Yesterday (Today-1).
            // If N=0, we exclude nothing (allow repeats immediately).
            
            // Calculate prohibited IDs
            // A pick is prohibited if: pickDate >= Today - N (and pickDate < Today)
            // We should treat "Today" as the reference.
            
            let cutoff = Calendar.current.date(byAdding: .day, value: -currentN, to: input.dateOnly)!
            
            // Filter history to find prohibited option IDs
            // We are looking for picks strictly AFTER the cutoff ( >= cutoff? usually "within last N days" means >= Today-N)
            // Let's be precise: if N=1, we can't pick what we had Yesterday.
            // So if pickDate == Today-1, it is prohibited.
            // pickDate > Today - (N+1) ?
            
            // Let's stick to: prohibited if pick.dateOnly >= (Today - N) && pick.dateOnly < Today
            // If history contains today's date, we usually ignore it for the decision of "what to pick" if we are re-rolling, 
            // but the caller passes history. If caller passes a pick from today, we should probably exclude it if we want to avoid repeats *of today*? 
            // "Stable daily picks" means we only pick once. Logic handles "what should be the pick". 
            // If we are re-rolling, the "current" pick is effectively removed from history by the caller (or ignored).
            
            let recentPicks = input.history.filter { $0.dateOnly >= cutoff && $0.dateOnly < input.dateOnly }
            let prohibitedIds = Set(recentPicks.map { $0.optionId })
            
            candidates = availableOptions.filter { !prohibitedIds.contains($0.id) }
            
            if !candidates.isEmpty {
                if currentN < input.rules.noRepeatDays {
                    finalReason = "Relaxed repeat rule to \(currentN) days"
                } else {
                    finalReason = "Standard logic (no repeats in \(currentN) days)"
                }
                break
            }
            
            currentN -= 1
        }
        
        if candidates.isEmpty { 
            // Should theoretically effectively be N=0 case which allows everything unless options check failed
            // If N=0 and still empty, means history has options not in available??
            // Or if history has today's picks?
            // With N=0, cutoff is Today. recentPicks (>= Today && < Today) is empty.
            // So candidates should be all availableOptions.
            // Thus this block is unreachable if availableOptions is not empty.
            candidates = availableOptions 
            finalReason = "Fallback: All options exhausted"
        }
        
        // Deterministic Randomness
        // Use seed + something specific to the candidate list or just simple index mapping?
        // Swift's random is not seedable easily efficiently in standard lib without GKM.
        // We can implement a simple LCG or Xorshift for this logic to be pure and deterministic.
        
        // Simple LCG
        var rngState = UInt64(bitPattern: Int64(input.seed))
        
        // Sort candidates by ID to ensure stable order before picking
        let sortedCandidates = candidates.sorted { $0.id.uuidString < $1.id.uuidString }
        
        // Roll
        let index = pseudoRandom(state: &rngState, max: sortedCandidates.count)
        let chosen = sortedCandidates[index]
        
        return PickerResult(optionId: chosen.id, reason: finalReason)
    }
    
    // Simple Linear Congruential Generator for deterministic behavior
    private static func pseudoRandom(state: inout UInt64, max: Int) -> Int {
        // Constants for MMIX by Knuth
        let a: UInt64 = 6364136223846793005
        let c: UInt64 = 1442695040888963407
        state = state &* a &+ c
        // Create double in range [0, 1)
        // Shift down to 53 bits for double precision mapping
        // or just modulo max? Modulo biased for small max if plain modulo.
        // Double mapping is safer for distribution basics.
        let randomDouble = Double(state >> 11) * (1.0 / 9007199254740992.0)
        return Int(randomDouble * Double(max))
    }
}
