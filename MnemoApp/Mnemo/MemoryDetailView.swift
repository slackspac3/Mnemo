import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore
import MnemoMemory

/// Full memory detail: summary, tags, provenance chain, processing tier badge.
struct MemoryDetailView: View {

    private let snapshot: MemoryDetailSnapshot
    private let onArchive: ((UUID) -> Void)?
    private let onDeletePermanently: ((UUID) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showingArchiveConfirm = false
    @State private var showingDeleteConfirm = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    init(
        record: MemoryRecord,
        onArchive: ((UUID) -> Void)? = nil,
        onDeletePermanently: ((UUID) -> Void)? = nil
    ) {
        self.snapshot = MemoryDetailSnapshot(record: record)
        self.onArchive = onArchive
        self.onDeletePermanently = onDeletePermanently
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colours.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            Text(snapshot.summary)
                                .font(DS.Typography.body)
                                .foregroundStyle(DS.Colours.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(DS.Spacing.md)
                        .background(DS.Colours.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
                        .shadow(
                            color: DS.Shadows.subtle.color,
                            radius: DS.Shadows.subtle.radius,
                            x: DS.Shadows.subtle.x,
                            y: DS.Shadows.subtle.y
                        )

                        VStack(spacing: DS.Spacing.sm) {
                            MetadataRow(label: "Type", value: snapshot.memoryType.capitalized, icon: "tag")
                            MetadataRow(label: "Source", value: snapshot.inputSource.capitalized, icon: "arrow.down.circle")
                            MetadataRow(
                                label: "Processing",
                                value: snapshot.processingTier == ProcessingTier.onDevice.rawValue ? "On Device" : "Cloud",
                                icon: "cpu"
                            )
                            MetadataRow(
                                label: "Persistence",
                                value: "\(Int(snapshot.persistenceScore * 100))%",
                                icon: "chart.bar"
                            )
                            MetadataRow(
                                label: "Confidence",
                                value: "\(Int(snapshot.confidence * 100))%",
                                icon: "checkmark.seal"
                            )
                            MetadataRow(
                                label: "Captured",
                                value: snapshot.createdAt.formatted(.dateTime.day().month().year()),
                                icon: "calendar"
                            )
                        }
                        .padding(DS.Spacing.md)
                        .background(DS.Colours.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
                        .shadow(
                            color: DS.Shadows.subtle.color,
                            radius: DS.Shadows.subtle.radius,
                            x: DS.Shadows.subtle.x,
                            y: DS.Shadows.subtle.y
                        )

                        if !snapshot.tags.isEmpty {
                            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                                Text("Tags")
                                    .font(DS.Typography.subheadline)
                                    .foregroundStyle(DS.Colours.textSecondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: DS.Spacing.xs) {
                                        ForEach(snapshot.tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(DS.Typography.caption1)
                                                .foregroundStyle(DS.Colours.accent)
                                                .padding(.horizontal, DS.Spacing.sm)
                                                .padding(.vertical, DS.Spacing.xs)
                                                .background(DS.Colours.surfaceSecondary)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            .padding(DS.Spacing.md)
                            .background(DS.Colours.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
                            .shadow(
                                color: DS.Shadows.subtle.color,
                                radius: DS.Shadows.subtle.radius,
                                x: DS.Shadows.subtle.x,
                                y: DS.Shadows.subtle.y
                            )
                        }

                        if snapshot.corroboratingEvidenceCount > 0 {
                            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                                Text("Confirmed by \(snapshot.corroboratingEvidenceCount) other source(s)")
                                    .font(DS.Typography.subheadline)
                                    .foregroundStyle(DS.Colours.success)
                            }
                            .padding(DS.Spacing.md)
                            .background(DS.Colours.successLight)
                            .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
                        }

                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            Text("Original capture")
                                .font(DS.Typography.subheadline)
                                .foregroundStyle(DS.Colours.textSecondary)
                            Text(snapshot.rawInput)
                                .font(DS.Typography.footnote)
                                .foregroundStyle(DS.Colours.textTertiary)
                        }
                        .padding(DS.Spacing.md)
                        .background(DS.Colours.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))

                        if let errorMessage {
                            Text(errorMessage)
                                .font(DS.Typography.footnote)
                                .foregroundStyle(DS.Colours.destructive)
                        }

                        VStack(spacing: DS.Spacing.sm) {
                            Button {
                                showingArchiveConfirm = true
                            } label: {
                                Text("Archive Memory")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colours.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(DS.Spacing.md)
                                    .background(DS.Colours.surfaceSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                            }

                            Button {
                                showingDeleteConfirm = true
                            } label: {
                                Text(isDeleting ? "Deleting..." : "Delete Permanently")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colours.destructive)
                                    .frame(maxWidth: .infinity)
                                    .padding(DS.Spacing.md)
                                    .background(DS.Colours.destructiveLight)
                                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                            }
                            .disabled(isDeleting)
                        }
                        .confirmationDialog(
                            "Archive this memory?",
                            isPresented: $showingArchiveConfirm,
                            titleVisibility: .visible
                        ) {
                            Button("Archive", role: .destructive) {
                                archiveMemory()
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
                    }
                    .padding(DS.Spacing.md)
                    .padding(.bottom, DS.Spacing.xxxl)
                }
            }
            .navigationTitle("Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colours.accent)
                }
            }
        }
    }

    private func archiveMemory() {
        if let onArchive {
            dismiss()
            onArchive(snapshot.id)
            return
        }

        do {
            try MemoryCRUD.archive(id: snapshot.id, in: modelContext)
            dismiss()
        } catch {
            errorMessage = "Could not archive this memory. Try again."
        }
    }

    @MainActor
    private func deleteMemory() async {
        let memoryId = snapshot.id
        isDeleting = true
        errorMessage = nil
        dismiss()

        if let onDeletePermanently {
            onDeletePermanently(memoryId)
            return
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        do {
            try await MemoryCRUD.deletePermanently(id: memoryId, in: modelContext)
        } catch {
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
        self.persistenceScore = record.persistenceScore
        self.confidence = record.confidence
        self.tags = record.tags
        self.corroboratingEvidenceCount = record.corroboratingEvidenceIds.count
        self.rawInput = record.rawInput
        self.createdAt = record.createdAt
    }
}

struct MetadataRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .frame(width: DS.Spacing.lg)
                .foregroundStyle(DS.Colours.textTertiary)
            Text(label)
                .font(DS.Typography.subheadline)
                .foregroundStyle(DS.Colours.textSecondary)
            Spacer()
            Text(value)
                .font(DS.Typography.subheadline)
                .foregroundStyle(DS.Colours.textPrimary)
        }
    }
}
