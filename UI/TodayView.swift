import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    @Query private var history: [PickHistory]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if categories.isEmpty {
                        ContentUnavailableView("No Categories", systemImage: "list.dash")
                    } else {
                        ForEach(categories) { category in
                            DailyPickCard(category: category)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Today's Picks")
            .onAppear {
                checkAndGenerateAll()
            }
        }
    }
    
    // Auto-generate picks for all categories if missing
    private func checkAndGenerateAll() {
        let picker = PickService(context: modelContext)
        for cat in categories {
            _ = picker.getOrCreateTodayPick(for: cat)
        }
    }
}

struct DailyPickCard: View {
    let category: Category
    @Environment(\.modelContext) private var modelContext
    
    @State private var showReason = false
    
    // Fetch today's pick specifically for this category
    // We can rely on relationship navigation
    var currentPick: PickHistory? {
        let today = Calendar.current.startOfDay(for: Date())
        return category.history?.first(where: { Calendar.current.startOfDay(for: $0.dateOnly) == today })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(category.name.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .tracking(1)
                
                Spacer()
                
                if currentPick != nil {
                    Button(action: reroll) {
                        Label("Re-roll", systemImage: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                }
            }
            
            // Content
            if let pick = currentPick, let option = pick.option {
                VStack(alignment: .leading, spacing: 8) {
                    Text(option.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    if !option.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(option.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    if showReason {
                         Text(pick.reason)
                             .font(.footnote)
                             .foregroundStyle(.secondary)
                             .italic()
                             .padding(.top, 4)
                             .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        Button("Why this?") {
                            withAnimation(.spring) {
                                showReason = true
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                }
            } else {
                // Empty state if no pick generated (e.g. no enabled options)
                VStack(spacing: 12) {
                    Image(systemName: "slash.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("No options available")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Add enabled options in the Options tab.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private func reroll() {
        let picker = PickService(context: modelContext)
        withAnimation {
            showReason = false
            _ = picker.reroll(category: category)
        }
    }
}
