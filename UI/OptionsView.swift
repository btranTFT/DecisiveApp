import SwiftUI
import SwiftData

struct OptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \OptionItem.name) private var allOptions: [OptionItem] // Just for query updates
    
    // UI State
    @State private var selectedCategory: Category?
    @State private var editingOption: OptionItem?
    @State private var isAddingOption = false
    
    // Derived state for list
    var filteredOptions: [OptionItem] {
        guard let cat = selectedCategory else { return [] }
        return (cat.options ?? []).sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Category Segmented Control
                if !categories.isEmpty {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories) { cat in
                            Text(cat.name).tag(cat as Category?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                } else {
                    ContentUnavailableView("No Categories", systemImage: "list.dash")
                }
                
                // Options List
                if let _ = selectedCategory {
                    List {
                        ForEach(filteredOptions) { option in
                            OptionRow(option: option) {
                                editingOption = option
                            }
                        }
                    }
                    .listStyle(.plain)
                    .overlay {
                        if filteredOptions.isEmpty {
                            ContentUnavailableView("No Options", systemImage: "tray")
                        }
                    }
                }
            }
            .navigationTitle("Options")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isAddingOption = true }) {
                        Image(systemName: "plus")
                    }
                    .disabled(categories.isEmpty)
                }
            }
            // Ensure selection exists on appear
            .onAppear {
                if selectedCategory == nil {
                    selectedCategory = categories.first
                }
            }
            .onChange(of: categories) { _, newCats in
                if selectedCategory == nil || !newCats.contains(selectedCategory!) {
                    selectedCategory = newCats.first
                }
            }
            // Sheets
            .sheet(isPresented: $isAddingOption) {
                NavigationStack {
                    OptionFormView(category: selectedCategory)
                }
                .presentationDetents([.medium])
            }
            .sheet(item: $editingOption) { option in
                NavigationStack {
                    OptionFormView(existingOption: option, category: option.category)
                }
                .presentationDetents([.medium])
            }
        }
    }
}

struct OptionRow: View {
    let option: OptionItem
    let onEdit: () -> Void
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(option.name)
                    .font(.body)
                if let notes = option.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Toggle("", isOn: Bindable(option).isEnabled)
                .labelsHidden()
                .accessibilityLabel("Enable \(option.name)")
        }
        .contentShape(Rectangle()) // Make full row tapable for edit if desired, or just swipe
        .onTapGesture {
            onEdit()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", role: .destructive) {
                modelContext.delete(option)
            }
        }
        .swipeActions(edge: .leading) {
            Button("Edit") {
                onEdit()
            }
            .tint(.blue)
        }
    }
}

struct OptionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Inputs
    var existingOption: OptionItem?
    var category: Category? // Context category
    
    // Form State
    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var tagsString: String = ""
    @State private var selectedCategory: Category?
    @FocusState private var isNameFocused: Bool
    
    @Query(sort: \Category.name) private var categories: [Category] // To allow changing category if needed
    
    var isEditing: Bool { existingOption != nil }
    
    var body: some View {
        Form {
            Section("Details") {
                TextField("Name (Required)", text: $name)
                    .focused($isNameFocused)
                    .autocorrectionDisabled()
                
                TextField("Notes (Optional)", text: $notes)
                
                TextField("Tags (comma separated)", text: $tagsString)
            }
            
            Section("Category") {
                if !categories.isEmpty {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories) { cat in
                            Text(cat.name).tag(cat as Category?)
                        }
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Option" : "New Option")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedCategory == nil)
            }
        }
        .onAppear {
            if let option = existingOption {
                name = option.name
                notes = option.notes ?? ""
                tagsString = option.tags.joined(separator: ", ")
                selectedCategory = option.category
            } else {
                selectedCategory = category ?? categories.first
                isNameFocused = true
            }
        }
    }
    
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        let tags = tagsString.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !trimmedName.isEmpty, let cat = selectedCategory else { return }
        
        if let option = existingOption {
            // Update
            option.name = trimmedName
            option.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            option.tags = tags
            if option.category != cat {
                option.category = cat
            }
        } else {
            // Create
            let newOption = OptionItem(
                name: trimmedName,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                tags: tags,
                category: cat
            )
            modelContext.insert(newOption)
        }
        
        dismiss()
    }
}
