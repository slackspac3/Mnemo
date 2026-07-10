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
                    BrowseFilterBar(
                        selectedType: $selectedTypeFilter,
                        selectedStatus: $selectedStatusFilter
                    )

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

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: DS.Spacing.sm) {
                    typeMenu
                    statusMenu
                    clearButton
                }
            } else {
                HStack(spacing: DS.Spacing.sm) {
                    typeMenu
                    statusMenu
                    clearButton
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
    }

    private var typeMenu: some View {
        Menu {
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
        } label: {
            filterLabel(
                title: selectedType.title,
                systemImage: "square.grid.2x2"
            )
        }
        .accessibilityLabel("Memory type")
        .accessibilityValue(selectedType.title)
    }

    private var statusMenu: some View {
        Menu {
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
        } label: {
            filterLabel(
                title: selectedStatus.title,
                systemImage: "line.3.horizontal.decrease"
            )
        }
        .accessibilityLabel("Memory status")
        .accessibilityValue(selectedStatus.title)
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
                        Label("Clear filters", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    } else {
                        Image(systemName: "xmark")
                            .frame(width: 44.0)
                    }
                }
                .font(DS.Typography.body.weight(.semibold))
                .frame(minHeight: 44.0)
                .background(DS.Colours.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
            }
            .foregroundStyle(DS.Colours.textSecondary)
            .buttonStyle(.mnemoPressable)
            .accessibilityLabel("Clear filters")
        }
    }

    private func filterLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Label(title, systemImage: systemImage)
                .font(DS.Typography.subheadline)
                .lineLimit(1)
            Spacer(minLength: 0)
            Image(systemName: "chevron.up.chevron.down")
                .font(DS.Typography.caption2)
                .accessibilityHidden(true)
        }
        .foregroundStyle(DS.Colours.textPrimary)
        .padding(.horizontal, DS.Spacing.sm)
        .frame(maxWidth: .infinity, minHeight: 44.0)
        .background(DS.Colours.surfaceSecondary)
        .overlay {
            RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                .stroke(DS.Colours.borderSubtle, lineWidth: 1.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
    }
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

struct MemoryCard: View {
    let record: MemoryRecord

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        let memoryType = record.memoryTypeEnum ?? .fact
        let accent = typeAccentColour(for: memoryType)

        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            MemoryTypeIcon(type: memoryType)
                .frame(width: 36.0, height: 36.0)
                .background(differentiateWithoutColor ? DS.Colours.surfaceSecondary : accent.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: DS.CornerRadius.small)
                        .stroke(DS.Colours.borderSubtle, lineWidth: differentiateWithoutColor ? 1.0 : 0.0)
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
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 6 : 3)
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
        Label(statusLabel, systemImage: statusIcon)
            .font(DS.Typography.caption1)
            .foregroundStyle(DS.Colours.textSecondary)
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
    let typeFilter: BrowseView.TypeFilter
    let statusFilter: BrowseView.StatusFilter
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

        if typeFilter == .all && statusFilter == .all {
            return "No memories yet"
        }

        return "No memories in this view"
    }

    private var subtitle: String {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Try a name, place, item, or decision you saved."
        }

        return typeFilter == .all && statusFilter == .all
            ? "Save a memory and it will appear here."
            : "Change or clear the filters to see other saved memories."
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
