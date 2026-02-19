import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    
    // Alert State
    @State private var showingResetHistoryAlert = false
    @State private var showingResetAllDataAlert = false
    @State private var categoryToReset: Category?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Avoid Repeats") {
                    if categories.isEmpty {
                        ContentUnavailableView("No Categories", systemImage: "gear.badge.questionmark")
                    } else {
                        ForEach(categories) { category in
                            HStack {
                                Text(category.name)
                                Spacer()
                                if let settings = category.settings {
                                    SettingsStepper(settings: settings)
                                } else {
                                    Text("No settings")
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                    }
                    
                    Text("Set the number of days before a picked option can be suggested again.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, -8)
                }
                
                Section("Wait, clear my history") {
                    ForEach(categories) { cat in
                        Button("Reset \(cat.name) History") {
                            categoryToReset = cat
                            showingResetHistoryAlert = true
                        }
                        .foregroundStyle(.red)
                    }
                }
                
                Section("Danger Zone") {
                    Button("Reset EVERYTHING (Data & History)") {
                        showingResetAllDataAlert = true
                    }
                    .foregroundStyle(.red)
                    .fontWeight(.bold)
                }
                
                Section {
                    HStack {
                        Image(systemName: "lock.shield")
                        Text("Privacy: All data is stored locally on this device.")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            
            // Alerts
            .alert("Reset History?", isPresented: $showingResetHistoryAlert) {
                Button("Reset", role: .destructive) {
                    if let cat = categoryToReset {
                        resetHistory(for: cat)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will clear all past picks for \(categoryToReset?.name ?? "this category").")
            }
            .alert("Reset Everything?", isPresented: $showingResetAllDataAlert) {
                Button("Delete All", role: .destructive) {
                    resetAllData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will delete ALL custom options, history, and settings. This cannot be undone.")
            }
        }
    }
    
    private func resetHistory(for category: Category) {
        if let history = category.history {
            for item in history {
                modelContext.delete(item)
            }
        }
    }
    
    private func resetAllData() {
        // Safe batch delete via fetch
        do {
            let limit = FetchDescriptor<Category>()
            let cats = try modelContext.fetch(limit)
            for cat in cats { modelContext.delete(cat) }
            
            let limitOpt = FetchDescriptor<OptionItem>()
            let opts = try modelContext.fetch(limitOpt)
            for opt in opts { modelContext.delete(opt) }
            
            let limitHist = FetchDescriptor<PickHistory>()
            let hists = try modelContext.fetch(limitHist)
            for hist in hists { modelContext.delete(hist) }
            
            let limitSet = FetchDescriptor<Settings>()
            let sets = try modelContext.fetch(limitSet)
            for set in sets { modelContext.delete(set) }
            
            // Trigger Save to flush deletes
            try modelContext.save()
            
            // Seed again
            DataController.seedCategories(modelContext: modelContext)
        } catch {
            print("Reset failed: \(error)")
        }
    }
}

struct SettingsStepper: View {
    @Bindable var settings: Settings
    
    var body: some View {
        HStack(spacing: 4) {
             Text("\(settings.noRepeatDays) days")
                 .font(.subheadline)
                 .foregroundStyle(.secondary)
             Stepper("", value: $settings.noRepeatDays, in: 0...14)
                 .labelsHidden()
                 .accessibilityLabel("Days to avoid repeats for \(settings.category?.name ?? "category")")
        }
    }
}
