import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore
import MnemoMemory

/// Browsable grid of all memories. Filterable by type, persistence state, source, and date.
struct BrowseView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationCoordinator.self) private var coordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \MemoryRecord.createdAt, order: .reverse) private var records: [MemoryRecord]

    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedMemory: SelectedMemory?
    @State private var appeared = false

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
                DS.Colours.backgroundGrouped.ignoresSafeArea()

                VStack(spacing: DS.Spacing.xs) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Spacing.sm) {
                            ForEach(FilterOption.allCases, id: \.self) { filter in
                                FilterChip(
                                    label: filter.rawValue,
                                    isSelected: selectedFilter == filter
                                ) {
                                    guard selectedFilter != filter else { return }
                                    HapticManager.selection()
                                    if reduceMotion {
                                        selectedFilter = filter
                                    } else {
                                        withAnimation(DS.Animation.quick) {
                                            selectedFilter = filter
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.vertical, DS.Spacing.sm)
                    }

                    if filteredRecords.isEmpty {
                        EmptyBrowseView(
                            filter: selectedFilter,
                            searchText: searchText,
                            onWriteMemory: {
                                coordinator.present(.captureText)
                            }
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DS.Spacing.sm) {
                                ForEach(Array(filteredRecords.enumerated()), id: \.element.id) { index, record in
                                    Button {
                                        selectedMemory = SelectedMemory(id: record.id)
                                    } label: {
                                        MemoryCard(record: record)
                                    }
                                    .buttonStyle(.mnemoPressable)
                                    .accessibilityLabel(record.summary)
                                    .accessibilityHint("Open memory details")
                                    .accessibilityIdentifier(AccessibilityID.Browse.memoryCell)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            Task {
                                                do {
                                                    try await archiveMemory(id: record.id)
                                                    HapticManager.impact(.medium)
                                                } catch {
                                                    HapticManager.error()
                                                }
                                            }
                                        } label: {
                                            Label("Archive", systemImage: "archivebox")
                                        }
                                        .tint(DS.Colours.warning)
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button {
                                            Task { @MainActor in
                                                if let found = records.first(where: { $0.id == record.id }) {
                                                    found.isDone = true
                                                    found.updatedAt = Date()
                                                    do {
                                                        try modelContext.save()
                                                        HapticManager.success()
                                                    } catch {
                                                        HapticManager.error()
                                                    }
                                                }
                                            }
                                        } label: {
                                            Label("Done", systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(DS.Colours.success)
                                    }
                                    .opacity(appeared ? 1.0 : 0.0)
                                    .offset(y: reduceMotion || appeared ? 0.0 : 10.0)
                                    .animation(
                                        reduceMotion
                                            ? DS.Animation.fade
                                            : DS.Animation.cardAppear.delay(Double(min(index, 12)) * 0.04),
                                        value: appeared
                                    )
                                }
                            }
                            .padding(.horizontal, DS.Spacing.md)
                            .padding(.top, DS.Spacing.sm)
                            .padding(.bottom, DS.Spacing.xxxl)
                        }
                        .onAppear {
                            appeared = true
                        }
                    }
                }
            }
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search memories")
            .accessibilityIdentifier(AccessibilityID.Browse.screen)
            .sheet(item: $selectedMemory) { selected in
                if let record = records.first(where: { $0.id == selected.id }) {
                    MemoryDetailView(
                        record: record,
                        onArchive: archiveMemory,
                        onDeletePermanently: deleteMemoryPermanently
                    )
                } else {
                    MissingSourceView()
                }
            }
        }
    }

    @MainActor
    private func archiveMemory(id: UUID) async throws {
        try await MemoryCRUD.archiveAndUnindex(id: id, in: modelContext)
    }

    @MainActor
    private func deleteMemoryPermanently(id: UUID) async throws {
        try await MemoryCRUD.deletePermanently(id: id, in: modelContext)
    }
}

private struct SelectedMemory: Identifiable {
    let id: UUID
}

private func typeAccentColour(for type: MemoryType) -> Color {
    switch type {
    case .preference, .intention:
        return DS.Colours.sense.opacity(0.8)
    case .list:
        return DS.Colours.success.opacity(0.8)
    case .credential:
        return DS.Colours.warning.opacity(0.8)
    case .event:
        return DS.Colours.accent.opacity(0.8)
    case .fact, .instruction:
        return DS.Colours.brandSage.opacity(0.6)
    }
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
                .frame(minHeight: 44.0)
                .background(isSelected ? DS.Colours.accent : DS.Colours.surfaceSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.mnemoPressable)
        .accessibilityLabel(label)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

struct MemoryCard: View {
    let record: MemoryRecord
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let memoryType = record.memoryTypeEnum ?? .fact
        let accent = typeAccentColour(for: memoryType)

        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            Capsule()
                .fill(accent)
                .frame(width: 3.0)
                .frame(maxHeight: .infinity)
                .accessibilityHidden(true)

            MemoryTypeIcon(type: memoryType)
                .frame(width: DS.Spacing.xl, height: DS.Spacing.xl)
                .background(accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.small))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(record.summary)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textPrimary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)

                HStack(spacing: DS.Spacing.sm) {
                    Label(sourceLabel, systemImage: sourceIcon)
                        .font(DS.Typography.caption1)
                        .foregroundStyle(DS.Colours.textSecondary)

                    Text(record.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .font(DS.Typography.caption1)
                        .foregroundStyle(DS.Colours.textTertiary)
                }
                .labelStyle(.titleAndIcon)
            }

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(DS.Typography.caption1)
                .foregroundStyle(DS.Colours.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 96.0, alignment: .leading)
        .background(DS.Colours.memoryCardSurface)
        .overlay {
            RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                .stroke(DS.Colours.memoryCardBorder, lineWidth: 1.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
        .transition(DS.Animation.cardAppearTransition(reduceMotion: reduceMotion))
    }

    private var sourceLabel: String {
        switch record.inputSourceEnum {
        case .text:
            return "Text"
        case .voice:
            return "Voice"
        case .image:
            return "Image"
        case .none:
            return "Memory"
        }
    }

    private var sourceIcon: String {
        switch record.inputSourceEnum {
        case .text:
            return "text.alignleft"
        case .voice:
            return "mic.fill"
        case .image:
            return "photo"
        case .none:
            return "doc.text"
        }
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
            return DS.Colours.accent
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
    let searchText: String
    let onWriteMemory: (() -> Void)?

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            Spacer()
            ZStack {
                MnemoThreadMotif(style: .hero, lineWidth: 2.0)
                    .frame(width: 150.0, height: 112.0)
                MnemoLogoMark(size: 72.0, style: .subtle)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(DS.Typography.title3)
                .foregroundStyle(DS.Colours.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textSecondary)
                .multilineTextAlignment(.center)

            if let onWriteMemory {
                Button(action: onWriteMemory) {
                    Label("Write memory", systemImage: "square.and.pencil")
                        .font(DS.Typography.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: DS.ComponentTokens.PrimaryButton.height)
                        .padding(.vertical, DS.Spacing.xs)
                        .background(DS.ComponentTokens.PrimaryButton.background)
                        .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                }
                .buttonStyle(.mnemoPressable)
                .accessibilityIdentifier(AccessibilityID.CaptureText.open)
            }
            Spacer()
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: DS.ComponentTokens.EmptyState.maxWidth)
        .frame(maxWidth: .infinity)
    }

    private var title: String {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No matching memories"
        }

        return filter == .all ? "No memories yet" : "No \(filter.rawValue.lowercased())"
    }

    private var subtitle: String {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Try a name, place, item, or decision you saved."
        }

        return filter == .all ? "Save a memory and it will appear here." : "Saved memories in this category will appear here."
    }
}
