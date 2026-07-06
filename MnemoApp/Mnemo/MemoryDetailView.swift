import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore
import MnemoMemory

/// Full memory detail: summary, tags, provenance chain, processing tier badge.
struct MemoryDetailView: View {

    let record: MemoryRecord
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showingArchiveConfirm = false
    @State private var showingDeleteConfirm = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colours.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            Text(record.summary)
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
                            MetadataRow(label: "Type", value: record.memoryType.capitalized, icon: "tag")
                            MetadataRow(label: "Source", value: record.inputSource.capitalized, icon: "arrow.down.circle")
                            MetadataRow(
                                label: "Processing",
                                value: record.processingTier == ProcessingTier.onDevice.rawValue ? "On Device" : "Cloud",
                                icon: "cpu"
                            )
                            MetadataRow(
                                label: "Persistence",
                                value: "\(Int(record.persistenceScore * 100))%",
                                icon: "chart.bar"
                            )
                            MetadataRow(
                                label: "Confidence",
                                value: "\(Int(record.confidence * 100))%",
                                icon: "checkmark.seal"
                            )
                            MetadataRow(
                                label: "Captured",
                                value: record.createdAt.formatted(.dateTime.day().month().year()),
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

                        if !record.tags.isEmpty {
                            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                                Text("Tags")
                                    .font(DS.Typography.subheadline)
                                    .foregroundStyle(DS.Colours.textSecondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: DS.Spacing.xs) {
                                        ForEach(record.tags, id: \.self) { tag in
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

                        if !record.corroboratingEvidenceIds.isEmpty {
                            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                                Text("Confirmed by \(record.corroboratingEvidenceIds.count) other source(s)")
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
                            Text(record.rawInput)
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
        do {
            try MemoryCRUD.archive(id: record.id, in: modelContext)
            dismiss()
        } catch {
            errorMessage = "Could not archive this memory. Try again."
        }
    }

    @MainActor
    private func deleteMemory() async {
        let memoryId = record.id
        isDeleting = true
        errorMessage = nil
        dismiss()

        do {
            try await MemoryCRUD.deletePermanently(id: memoryId, in: modelContext)
        } catch {
            isDeleting = false
        }
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
