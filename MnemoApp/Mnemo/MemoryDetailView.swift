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

                        Button {
                            showingArchiveConfirm = true
                        } label: {
                            Text("Archive Memory")
                                .font(DS.Typography.body)
                                .foregroundStyle(DS.Colours.destructive)
                                .frame(maxWidth: .infinity)
                                .padding(DS.Spacing.md)
                                .background(DS.Colours.destructiveLight)
                                .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                        }
                        .confirmationDialog(
                            "Archive this memory?",
                            isPresented: $showingArchiveConfirm,
                            titleVisibility: .visible
                        ) {
                            Button("Archive", role: .destructive) {
                                record.isArchived = true
                                record.updatedAt = Date()
                                try? modelContext.save()
                                dismiss()
                            }
                            Button("Cancel", role: .cancel) {}
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
