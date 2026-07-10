import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore
import MnemoMemory

/// Browsable list of unarchived memories, filterable by category and persistence state.
struct BrowseView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationCoordinator.self) private var coordinator
    @Query(sort: \MemoryRecord.createdAt, order: .reverse) private var records: [MemoryRecord]

    @State private var searchText = ""
    @State private var selectedTypeFilter: TypeFilter = .all
    @State private var selectedStatusFilter: StatusFilter = .all
    @State private var selectedMemory: SelectedMemory?

    private var hasBrowsableMemories: Bool {
        records.contains { !$0.isArchived }
    }

    enum TypeFilter: String, CaseIterable {
        case all
        case preference
        case list
        case credential
        case people

        var title: String {
            switch self {
            case .all: "All types"
            case .preference: "Preferences"
            case .list: "Lists"
            case .credential: "Credentials"
            case .people: "People"
            }
        }
    }

    enum StatusFilter: String, CaseIterable {
        case all
        case active
        case dormant
        case review

        var title: String {
            switch self {
            case .all: "Any status"
            case .active: "Active"
            case .dormant: "Dormant"
            case .review: "Review"
            }
        }
    }

    var filteredRecords: [MemoryRecord] {
        records
            .filter { !$0.isArchived }
            .filter { record in
                switch selectedTypeFilter {
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
                }
            }
            .filter { record in
                switch selectedStatusFilter {
                case .all:
                    return true
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
                    if hasBrowsableMemories {
                        BrowseFilterBar(
                            selectedType: $selectedTypeFilter,
                            selectedStatus: $selectedStatusFilter
                        )
                    }

                    if filteredRecords.isEmpty {
                        EmptyBrowseView(
                            typeFilter: selectedTypeFilter,
                            statusFilter: selectedStatusFilter,
                            searchText: searchText,
                            onWriteMemory: {
                                coordinator.present(.captureText)
                            }
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DS.Spacing.sm) {
                                ForEach(filteredRecords) { record in
                                    Button {
                                        selectedMemory = SelectedMemory(id: record.id)
                                    } label: {
                                        MemoryCard(record: record)
                                    }
                                    .buttonStyle(.mnemoPressable)
                                    .accessibilityLabel(record.summary)
                                    .accessibilityValue(
                                        "\(typeLabel(for: record.memoryTypeEnum ?? .fact)), "
                                            + (record.isDone ? "Done" : record.persistenceState.capitalized)
                                    )
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
                                }
                            }
                            .padding(.horizontal, DS.Spacing.md)
                            .padding(.top, DS.Spacing.sm)
                            .padding(.bottom, DS.Spacing.xxxl)
                        }
                    }
                }
            }
            .navigationTitle("Memories")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search memories")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        coordinator.present(.settings)
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(DS.Colours.accent)
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityIdentifier(AccessibilityID.Main.settings)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            coordinator.present(.captureText)
                        } label: {
                            Label("Write Memory", systemImage: "square.and.pencil")
                        }

                        Button {
                            coordinator.present(.captureVoice)
                        } label: {
                            Label("Record Voice", systemImage: "mic.fill")
                        }

                        Button {
                            coordinator.present(.captureImage(.camera))
                        } label: {
                            Label("Take Photo", systemImage: "camera.fill")
                        }

                        Button {
                            coordinator.present(.captureImage(.photoLibrary))
                        } label: {
                            Label("Choose Photo", systemImage: "photo")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(DS.Colours.accent)
                    }
                    .accessibilityLabel("Add memory")
                    .accessibilityHint("Choose how to save a memory")
                    .accessibilityIdentifier(AccessibilityID.Main.capture)
                }
            }
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

private struct BrowseFilterBar: View {
    @Binding var selectedType: BrowseView.TypeFilter
    @Binding var selectedStatus: BrowseView.StatusFilter

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var hasActiveFilter: Bool {
        selectedType != .all || selectedStatus != .all
    }

    private var activeFilterCount: Int {
        (selectedType == .all ? 0 : 1) + (selectedStatus == .all ? 0 : 1)
    }

    private var filterSummary: String {
        guard hasActiveFilter else { return "All memories" }
        return [
            selectedType == .all ? nil : selectedType.title,
            selectedStatus == .all ? nil : selectedStatus.title,
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: DS.Spacing.sm) {
                filterSummaryLabel
                Spacer(minLength: DS.Spacing.sm)
                filterMenu
                clearButton
            }

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                filterSummaryLabel
                HStack(spacing: DS.Spacing.sm) {
                    filterMenu
                    clearButton
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.xs)
        .padding(.bottom, DS.Spacing.sm)
    }

    private var filterSummaryLabel: some View {
        Text(filterSummary)
            .font(DS.Typography.subheadline)
            .foregroundStyle(hasActiveFilter ? DS.Colours.textPrimary : DS.Colours.textSecondary)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var filterMenu: some View {
        Menu {
            Section("Type") {
                ForEach(BrowseView.TypeFilter.allCases, id: \.self) { filter in
                    Button {
                        guard selectedType != filter else { return }
                        selectedType = filter
                        HapticManager.selection()
                    } label: {
                        if selectedType == filter {
                            Label(filter.title, systemImage: "checkmark")
                        } else {
                            Text(filter.title)
                        }
                    }
                }
            }

            Section("Status") {
                ForEach(BrowseView.StatusFilter.allCases, id: \.self) { filter in
                    Button {
                        guard selectedStatus != filter else { return }
                        selectedStatus = filter
                        HapticManager.selection()
                    } label: {
                        if selectedStatus == filter {
                            Label(filter.title, systemImage: "checkmark")
                        } else {
                            Text(filter.title)
                        }
                    }
                }
            }
        } label: {
            Label(
                activeFilterCount == 0 ? "Filter" : "Filter (\(activeFilterCount))",
                systemImage: "line.3.horizontal.decrease"
            )
            .font(DS.Typography.subheadline.weight(.semibold))
            .frame(minHeight: 44.0)
        }
        .buttonStyle(.bordered)
        .tint(DS.Colours.accent)
        .accessibilityLabel("Filter memories")
        .accessibilityValue(filterSummary)
    }

    @ViewBuilder
    private var clearButton: some View {
        if hasActiveFilter {
            Button {
                selectedType = .all
                selectedStatus = .all
                HapticManager.selection()
            } label: {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        Label("Clear", systemImage: "xmark")
                    } else {
                        Image(systemName: "xmark")
                            .frame(width: 44.0)
                    }
                }
                .font(DS.Typography.body.weight(.semibold))
                .frame(minHeight: 44.0)
            }
            .buttonStyle(.bordered)
            .tint(DS.Colours.textSecondary)
            .accessibilityLabel("Clear filters")
        }
    }
}

struct MemoryCard: View {
    let record: MemoryRecord

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        let memoryType = record.memoryTypeEnum ?? .fact

        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            MemoryTypeIcon(type: memoryType)
                .frame(width: 36.0, height: 36.0)
                .background(DS.Colours.surfaceSecondary)
                .overlay {
                    RoundedRectangle(cornerRadius: DS.CornerRadius.small)
                        .stroke(
                            differentiateWithoutColor ? DS.Colours.borderStrong : DS.Colours.borderSubtle,
                            lineWidth: 1.0
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.small))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.sm) {
                        typeMetadata(for: memoryType)
                        Spacer(minLength: 0)
                        statusMetadata
                    }

                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        typeMetadata(for: memoryType)
                        statusMetadata
                    }
                }

                Text(record.summary)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.textPrimary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 3)
                    .multilineTextAlignment(.leading)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: DS.Spacing.md) {
                        sourceMetadata
                        capturedMetadata
                    }

                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        sourceMetadata
                        capturedMetadata
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(DS.Typography.caption1)
                .foregroundStyle(DS.Colours.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Colours.memoryCardSurface)
        .overlay {
            RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                .stroke(DS.Colours.memoryCardBorder, lineWidth: 1.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
    }

    private var sourceMetadata: some View {
        Label(sourceLabel, systemImage: sourceIcon)
            .font(DS.Typography.caption1)
            .foregroundStyle(DS.Colours.textSecondary)
            .labelStyle(.titleAndIcon)
    }

    private func typeMetadata(for type: MemoryType) -> some View {
        Text(typeLabel(for: type))
            .font(DS.Typography.caption1.weight(.semibold))
            .foregroundStyle(DS.Colours.textSecondary)
    }

    private var statusMetadata: some View {
        Label {
            Text(statusLabel)
                .foregroundStyle(DS.Colours.textSecondary)
        } icon: {
            Image(systemName: statusIcon)
                .foregroundStyle(isActive ? DS.Colours.accent : DS.Colours.textSecondary)
        }
        .font(DS.Typography.caption1)
    }

    private var capturedMetadata: some View {
        Label {
            Text(record.createdAt.formatted(.dateTime.month(.abbreviated).day().year()))
        } icon: {
            Image(systemName: "calendar")
        }
        .font(DS.Typography.caption1)
        .foregroundStyle(DS.Colours.textTertiary)
        .labelStyle(.titleAndIcon)
    }

    private var statusLabel: String {
        if record.isDone {
            return "Done"
        }

        switch record.persistenceStateEnum {
        case .active: return "Active"
        case .dormant: return "Dormant"
        case .review: return "Review"
        case .none: return "Saved"
        }
    }

    private var statusIcon: String {
        if record.isDone {
            return "checkmark.circle.fill"
        }

        switch record.persistenceStateEnum {
        case .active: return "circle.fill"
        case .dormant: return "pause.circle"
        case .review: return "exclamationmark.circle"
        case .none: return "bookmark"
        }
    }

    private var isActive: Bool {
        !record.isDone && record.persistenceStateEnum == .active
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

    var body: some View {
        Image(systemName: icon)
            .font(DS.Typography.caption1)
            .foregroundStyle(DS.Colours.textSecondary)
    }
}

struct ProcessingTierBadge: View {
    let tier: ProcessingTier

    var body: some View {
        Image(systemName: tier == .onDevice ? "lock.shield.fill" : "cloud.fill")
            .font(DS.Typography.caption2)
            .foregroundStyle(tier == .onDevice ? DS.Colours.privateBadgeText : DS.Colours.accent)
    }
}

struct EmptyBrowseView: View {
    let typeFilter: BrowseView.TypeFilter
    let statusFilter: BrowseView.StatusFilter
    let searchText: String
    let onWriteMemory: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: emptyStateIcon)
        } description: {
            Text(subtitle)
        } actions: {
            if let onWriteMemory, shouldOfferCapture {
                Button(action: onWriteMemory) {
                    Label("Write memory", systemImage: "square.and.pencil")
                }
                .buttonStyle(.borderedProminent)
                .tint(DS.Colours.controlAccent)
                .accessibilityIdentifier(AccessibilityID.CaptureText.open)
            }
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: DS.ComponentTokens.EmptyState.maxWidth)
        .frame(maxWidth: .infinity)
    }

    private var title: String {
        if !trimmedSearchText.isEmpty {
            return "No matching memories"
        }

        if typeFilter == .all && statusFilter == .all {
            return "No memories yet"
        }

        return "No memories in this view"
    }

    private var subtitle: String {
        if !trimmedSearchText.isEmpty {
            return "Nothing matched \"\(displayedSearchText)\". Check the spelling or try a broader search."
        }

        return typeFilter == .all && statusFilter == .all
            ? "Save a memory and it will appear here."
            : "Change or clear the filters to see other saved memories."
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displayedSearchText: String {
        guard trimmedSearchText.count > 48 else { return trimmedSearchText }
        return String(trimmedSearchText.prefix(48)) + "..."
    }

    private var shouldOfferCapture: Bool {
        trimmedSearchText.isEmpty && typeFilter == .all && statusFilter == .all
    }

    private var emptyStateIcon: String {
        if !trimmedSearchText.isEmpty {
            return "magnifyingglass"
        }
        if typeFilter != .all || statusFilter != .all {
            return "line.3.horizontal.decrease"
        }
        return "tray"
    }
}

private func typeLabel(for type: MemoryType) -> String {
    switch type {
    case .preference: return "Preference"
    case .list: return "List"
    case .credential: return "Credential"
    case .event: return "Event"
    case .fact: return "Fact"
    case .instruction: return "Instruction"
    case .intention: return "Intention"
    }
}
