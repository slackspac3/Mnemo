import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore
import MnemoMemory

/// Canonical memory detail, including the original capture and local provenance.
struct MemoryDetailView: View {

    private let snapshot: MemoryDetailSnapshot
    private let onArchive: ((UUID) async throws -> Void)?
    private let onDeletePermanently: ((UUID) async throws -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    @State private var showingArchiveConfirm = false
    @State private var showingDeleteConfirm = false
    @State private var isArchiving = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    init(
        record: MemoryRecord,
        onArchive: ((UUID) async throws -> Void)? = nil,
        onDeletePermanently: ((UUID) async throws -> Void)? = nil
    ) {
        self.snapshot = MemoryDetailSnapshot(record: record)
        self.onArchive = onArchive
        self.onDeletePermanently = onDeletePermanently
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        Label("Saved summary", systemImage: "bookmark.fill")
                            .font(DS.Typography.subheadline.weight(.semibold))
                            .foregroundStyle(
                                differentiateWithoutColor
                                    ? DS.Colours.textPrimary
                                    : DS.Colours.accent
                            )

                        Text(snapshot.summary)
                            .font(DS.Typography.body)
                            .lineSpacing(2.0)
                            .foregroundStyle(DS.Colours.textPrimary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, DS.Spacing.xs)
                    .accessibilityIdentifier(AccessibilityID.MemoryDetail.title)
                }

                Section {
                    Text(snapshot.rawInput)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colours.textPrimary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, DS.Spacing.xs)
                } header: {
                    Label("Original capture", systemImage: originalCaptureIcon)
                }

                Section("Details") {
                    MetadataRow(
                        label: "Source",
                        value: snapshot.inputSource.capitalized,
                        icon: "arrow.down.circle"
                    )
                    MetadataRow(
                        label: "Captured",
                        value: snapshot.createdAt.formatted(
                            .dateTime.day().month().year().hour().minute()
                        ),
                        icon: "calendar"
                    )
                    MetadataRow(label: "Type", value: snapshot.memoryType.capitalized, icon: "tag")
                    MetadataRow(label: "Status", value: statusLabel, icon: statusIcon)

                    if !snapshot.tags.isEmpty {
                        MetadataRow(
                            label: "Tags",
                            value: snapshot.tags.joined(separator: ", "),
                            icon: "number"
                        )
                    }
                }

                Section {
                    DisclosureGroup {
                        VStack(spacing: DS.Spacing.md) {
                            MetadataRow(
                                label: "Processing",
                                value: processingLabel,
                                icon: "cpu",
                                isSecondary: true
                            )
                            MetadataRow(
                                label: "Recall priority",
                                value: recallPriorityLabel,
                                icon: "chart.bar",
                                isSecondary: true
                            )
                            MetadataRow(
                                label: "Review status",
                                value: reviewStatusLabel,
                                icon: "checkmark.seal",
                                isSecondary: true
                            )

                            if snapshot.corroboratingEvidenceCount > 0 {
                                MetadataRow(
                                    label: "Evidence",
                                    value: corroborationText(for: snapshot.corroboratingEvidenceCount),
                                    icon: "link.badge.plus",
                                    isSecondary: true
                                )
                            }
                        }
                        .padding(.top, DS.Spacing.md)
                    } label: {
                        Label("Provenance and review", systemImage: "checkmark.shield")
                            .foregroundStyle(DS.Colours.textPrimary)
                    }
                    .tint(DS.Colours.accent)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(DS.Typography.footnote)
                            .foregroundStyle(DS.Colours.destructive)
                    }
                }

                Section("Memory controls") {
                    Button {
                        showingArchiveConfirm = true
                    } label: {
                        actionLabel(
                            title: isArchiving ? "Archiving..." : "Archive Memory",
                            systemImage: "archivebox",
                            isWorking: isArchiving
                        )
                    }
                    .disabled(isArchiving || isDeleting)
                    .accessibilityIdentifier(AccessibilityID.MemoryDetail.archive)

                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        actionLabel(
                            title: isDeleting ? "Deleting..." : "Delete Permanently",
                            systemImage: "trash",
                            isWorking: isDeleting
                        )
                    }
                    .disabled(isArchiving || isDeleting)
                    .accessibilityIdentifier(AccessibilityID.MemoryDetail.delete)
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.Colours.backgroundGrouped)
            .confirmationDialog(
                "Archive this memory?",
                isPresented: $showingArchiveConfirm,
                titleVisibility: .visible
            ) {
                Button("Archive") {
                    Task {
                        await archiveMemory()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Archive hides this memory from Browse and Chat recall, but keeps it in your local store.")
            }
            .confirmationDialog(
                "Delete this memory permanently?",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Permanently", role: .destructive) {
                    Task {
                        await deleteMemory()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the memory from Mnemo and deletes its local search index entry. This cannot be undone.")
            }
            .navigationTitle("Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func actionLabel(title: String, systemImage: String, isWorking: Bool) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            if isWorking {
                ProgressView()
            } else {
                Image(systemName: systemImage)
                    .accessibilityHidden(true)
            }

            Text(title)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(DS.Typography.body)
        .frame(minHeight: 44)
    }

    private var originalCaptureIcon: String {
        switch InputSource(rawValue: snapshot.inputSource) {
        case .text: return "text.alignleft"
        case .voice: return "mic.fill"
        case .image: return "photo"
        case .none: return "doc.text"
        }
    }

    private var statusLabel: String {
        snapshot.isDone ? "Done" : snapshot.persistenceState.capitalized
    }

    private var statusIcon: String {
        if snapshot.isDone {
            return "checkmark.circle.fill"
        }

        switch PersistenceState(rawValue: snapshot.persistenceState) {
        case .active: return "circle.fill"
        case .dormant: return "pause.circle"
        case .review: return "exclamationmark.circle"
        case .none: return "bookmark"
        }
    }

    private var processingLabel: String {
        snapshot.processingTier == ProcessingTier.onDevice.rawValue ? "On Device" : "External Processing"
    }

    private var recallPriorityLabel: String {
        if snapshot.persistenceScore >= 0.75 {
            return "High"
        }

        if snapshot.persistenceScore >= 0.40 {
            return "Medium"
        }

        return "Low"
    }

    private var reviewStatusLabel: String {
        if snapshot.confidence >= 0.70 {
            return "Looks ready"
        }

        if snapshot.confidence >= 0.50 {
            return "Check if needed"
        }

        return "Review suggested"
    }

    @MainActor
    private func archiveMemory() async {
        isArchiving = true
        errorMessage = nil

        do {
            if let onArchive {
                try await onArchive(snapshot.id)
            } else {
                try await MemoryCRUD.archiveAndUnindex(id: snapshot.id, in: modelContext)
            }
            dismiss()
        } catch {
            errorMessage = "Could not archive this memory. Try again."
        }

        isArchiving = false
    }

    @MainActor
    private func deleteMemory() async {
        let memoryId = snapshot.id
        isDeleting = true
        errorMessage = nil

        do {
            if let onDeletePermanently {
                try await onDeletePermanently(memoryId)
            } else {
                try await MemoryCRUD.deletePermanently(id: memoryId, in: modelContext)
            }
            dismiss()
        } catch {
            errorMessage = "Could not delete this memory. Try again."
            isDeleting = false
        }
    }
}

private struct MemoryDetailSnapshot {
    let id: UUID
    let summary: String
    let memoryType: String
    let inputSource: String
    let processingTier: String
    let persistenceState: String
    let isDone: Bool
    let persistenceScore: Double
    let confidence: Double
    let tags: [String]
    let corroboratingEvidenceCount: Int
    let rawInput: String
    let createdAt: Date

    init(record: MemoryRecord) {
        self.id = record.id
        self.summary = record.summary
        self.memoryType = record.memoryType
        self.inputSource = record.inputSource
        self.processingTier = record.processingTier
        self.persistenceState = record.persistenceState
        self.isDone = record.isDone
        self.persistenceScore = record.persistenceScore
        self.confidence = record.confidence
        self.tags = record.tags
        self.corroboratingEvidenceCount = record.corroboratingEvidenceIds.count
        self.rawInput = record.rawInput
        self.createdAt = record.createdAt
    }
}

private func corroborationText(for count: Int) -> String {
    count == 1 ? "Confirmed by 1 other source" : "Confirmed by \(count) other sources"
}

struct MetadataRow: View {
    let label: String
    let value: String
    let icon: String
    var isSecondary = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    labelView
                    valueView
                        .padding(.leading, DS.Spacing.xl)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.sm) {
                    labelView
                    Spacer(minLength: DS.Spacing.md)
                    valueView
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
    }

    private var labelView: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .frame(width: DS.Spacing.lg)
                .foregroundStyle(DS.Colours.textTertiary)
                .accessibilityHidden(true)

            Text(label)
                .font(labelFont)
                .foregroundStyle(DS.Colours.textSecondary)
        }
    }

    private var valueView: some View {
        Text(value)
            .font(valueFont)
            .foregroundStyle(DS.Colours.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var labelFont: Font {
        isSecondary ? DS.Typography.caption1 : DS.Typography.subheadline
    }

    private var valueFont: Font {
        isSecondary ? DS.Typography.caption1 : DS.Typography.subheadline
    }
}
