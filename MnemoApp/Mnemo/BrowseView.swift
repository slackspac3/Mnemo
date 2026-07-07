import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore
import MnemoMemory

/// Browsable grid of all memories. Filterable by type, persistence state, source, and date.
struct BrowseView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemoryRecord.createdAt, order: .reverse) private var records: [MemoryRecord]

    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedMemory: SelectedMemory?

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case preference = "Preferences"
        case list = "Lists"
        case credential = "Credentials"
        case people = "People"
        case active = "Active"
        case dormant = "Dormant"
        case review = "Review"
    }

    var filteredRecords: [MemoryRecord] {
        records
            .filter { !$0.isArchived }
            .filter { record in
                switch selectedFilter {
                case .all:
                    return true
                case .preference:
                    return record.memoryType == MemoryType.preference.rawValue
                case .list:
                    return record.memoryType == MemoryType.list.rawValue
                case .credential:
                    return record.memoryType == MemoryType.credential.rawValue
                case .people:
                    return record.subjectType == "person"
                case .active:
                    return record.persistenceState == PersistenceState.active.rawValue
                case .dormant:
                    return record.persistenceState == PersistenceState.dormant.rawValue
                case .review:
                    return record.persistenceState == PersistenceState.review.rawValue
                }
            }
            .filter { record in
                searchText.isEmpty ||
                    record.summary.localizedCaseInsensitiveContains(searchText) ||
                    record.rawInput.localizedCaseInsensitiveContains(searchText) ||
                    record.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colours.background.ignoresSafeArea()

                VStack(spacing: DS.Spacing.xs) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Spacing.sm) {
                            ForEach(FilterOption.allCases, id: \.self) { filter in
                                FilterChip(
                                    label: filter.rawValue,
                                    isSelected: selectedFilter == filter
                                ) {
                                    withAnimation(DS.Animation.quick) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, DS.Spacing.sm)
                    }

                    if filteredRecords.isEmpty {
                        EmptyBrowseView(filter: selectedFilter)
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ],
                                spacing: DS.Spacing.sm
                            ) {
                                ForEach(filteredRecords, id: \.id) { record in
                                    Button {
                                        selectedMemory = SelectedMemory(id: record.id)
                                    } label: {
                                        MemoryCard(record: record)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(record.summary)
                                    .accessibilityHint("Open memory details")
                                }
                            }
                            .padding(.horizontal, DS.Spacing.md)
                            .padding(.top, DS.Spacing.sm)
                            .padding(.bottom, DS.Spacing.xxxl)
                        }
                    }
                }
            }
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search memories")
            .sheet(item: $selectedMemory) { selected in
                if let record = records.first(where: { $0.id == selected.id }) {
                    MemoryDetailView(
                        record: record,
                        onArchive: archiveMemory,
                        onDeletePermanently: deleteMemoryPermanently
                    )
                } else {
                    EmptyBrowseView(filter: .all)
                }
            }
        }
    }

    private func archiveMemory(id: UUID) throws {
        try MemoryCRUD.archive(id: id, in: modelContext)
    }

    private func deleteMemoryPermanently(id: UUID) async throws {
        try await MemoryCRUD.deletePermanently(id: id, in: modelContext)
    }
}

private struct SelectedMemory: Identifiable {
    let id: UUID
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DS.Typography.caption1)
                .foregroundStyle(isSelected ? DS.ComponentTokens.PrimaryButton.foreground : DS.Colours.textSecondary)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.sm)
                .background(isSelected ? DS.Colours.accent : DS.Colours.surfaceSecondary)
                .clipShape(Capsule())
        }
    }
}

struct MemoryCard: View {
    let record: MemoryRecord

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                MemoryTypeIcon(type: record.memoryTypeEnum ?? .fact)
                Spacer()
                ProcessingTierBadge(tier: record.processingTierEnum ?? .onDevice)
            }

            Text(record.summary)
                .font(DS.Typography.subheadline)
                .foregroundStyle(DS.Colours.textPrimary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Text(record.createdAt.formatted(.dateTime.day().month()))
                .font(DS.Typography.caption2)
                .foregroundStyle(DS.Colours.textTertiary)
        }
        .padding(DS.Spacing.md)
        .frame(
            maxWidth: .infinity,
            minHeight: DS.Spacing.xxxl + DS.Spacing.xxl + DS.Spacing.sm
        )
        .background(DS.Colours.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
        .shadow(
            color: DS.Shadows.subtle.color,
            radius: DS.Shadows.subtle.radius,
            x: DS.Shadows.subtle.x,
            y: DS.Shadows.subtle.y
        )
    }
}

struct MemoryTypeIcon: View {
    let type: MemoryType

    var icon: String {
        switch type {
        case .preference:
            return "heart.fill"
        case .list:
            return "checklist"
        case .credential:
            return "key.fill"
        case .event:
            return "calendar"
        case .fact:
            return "lightbulb.fill"
        case .instruction:
            return "arrow.right.circle.fill"
        case .intention:
            return "target"
        }
    }

    var color: Color {
        switch type {
        case .preference, .intention:
            return DS.Colours.sense
        case .list:
            return DS.Colours.success
        case .credential:
            return DS.Colours.warning
        case .event, .instruction:
            return DS.Colours.accent
        case .fact:
            return DS.Colours.primary
        }
    }

    var body: some View {
        Image(systemName: icon)
            .font(DS.Typography.caption1)
            .foregroundStyle(color)
    }
}

struct ProcessingTierBadge: View {
    let tier: ProcessingTier

    var body: some View {
        Image(systemName: tier == .onDevice ? "lock.shield.fill" : "cloud.fill")
            .font(DS.Typography.caption2)
            .foregroundStyle(tier == .onDevice ? DS.Colours.success : DS.Colours.accent)
    }
}

struct EmptyBrowseView: View {
    let filter: BrowseView.FilterOption

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            Spacer()
            Image(systemName: "tray")
                .font(DS.Typography.largeTitle)
                .foregroundStyle(DS.Colours.textTertiary)
            Text(filter == .all ? "No memories yet" : "No \(filter.rawValue.lowercased())")
                .font(DS.Typography.title3)
                .foregroundStyle(DS.Colours.textPrimary)
            Text("Tap + to capture your first memory")
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textSecondary)
            Spacer()
        }
        .padding(DS.Spacing.xl)
    }
}
