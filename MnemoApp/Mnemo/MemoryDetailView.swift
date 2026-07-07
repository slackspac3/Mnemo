import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore
import MnemoMemory

/// Full memory detail: summary, tags, provenance chain, processing tier badge.
struct MemoryDetailView: View {

    private let snapshot: MemoryDetailSnapshot
    private let onArchive: ((UUID) async throws -> Void)?
    private let onDeletePermanently: ((UUID) async throws -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingArchiveConfirm = false
    @State private var showingDeleteConfirm = false
    @State private var isArchiving = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var summaryAppeared = false

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
            ZStack {
                DS.Colours.backgroundGrouped.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                        HStack(alignment: .top, spacing: DS.Spacing.sm) {
                            Capsule()
                                .fill(typeAccentColour(for: memoryTypeEnum))
                                .frame(width: 3.0)
                                .frame(maxHeight: .infinity)
                                .accessibilityHidden(true)

                            ZStack(alignment: .bottomTrailing) {
                                MnemoThreadMotif(style: .watermark, lineWidth: 1.8)
                                    .frame(width: 124.0, height: 92.0)
                                    .padding(.trailing, DS.Spacing.sm)

                                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                                    Label("Saved memory", systemImage: "bookmark.fill")
                                        .font(DS.Typography.caption1.weight(.semibold))
                                        .foregroundStyle(DS.Colours.sourceCardAccent)
                                        .accessibilityHidden(true)

                                    Text(snapshot.summary)
                                        .font(DS.Typography.body)
                                        .lineSpacing(4.0)
                                        .foregroundStyle(DS.Colours.textPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(DS.Spacing.md)
                                .padding(.trailing, DS.Spacing.sm)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DS.Colours.memoryCardSurface)
                        .overlay {
                            RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                                .stroke(DS.Colours.memoryCardBorder, lineWidth: 1.0)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.large))
                        .shadow(
                            color: DS.Shadows.subtle.color,
                            radius: DS.Shadows.subtle.radius,
                            x: DS.Shadows.subtle.x,
                            y: DS.Shadows.subtle.y
                        )
                        .transition(DS.Animation.cardAppearTransition(reduceMotion: reduceMotion))
                        .opacity(summaryAppeared ? 1.0 : 0.0)
                        .offset(y: reduceMotion || summaryAppeared ? 0.0 : 8.0)
                        .scaleEffect(reduceMotion ? 1.0 : (summaryAppeared ? 1.0 : 0.98))
                        .animation(reduceMotion ? DS.Animation.fade : DS.Animation.cardAppear, value: summaryAppeared)
                        .onAppear {
                            summaryAppeared = true
                        }
                        .accessibilityIdentifier(AccessibilityID.MemoryDetail.title)

                        VStack(spacing: DS.Spacing.sm) {
                            MetadataRow(label: "Type", value: snapshot.memoryType.capitalized, icon: "tag")
                            MetadataRow(label: "Source", value: snapshot.inputSource.capitalized, icon: "arrow.down.circle")
                            MetadataRow(
                                label: "Captured",
                                value: snapshot.createdAt.formatted(.dateTime.day().month().year()),
                                icon: "calendar"
                            )
                            Divider()
                                .overlay(DS.Colours.borderSubtle)
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
                        }
                        .padding(DS.Spacing.md)
                        .background(DS.Colours.surfaceElevated)
                        .overlay {
                            RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                                .stroke(DS.Colours.borderSubtle, lineWidth: 1.0)
                        }
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
                                                .background(DS.Colours.accentSoft)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            .padding(DS.Spacing.md)
                            .background(DS.Colours.surfaceElevated)
                            .overlay {
                                RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                                    .stroke(DS.Colours.borderSubtle, lineWidth: 1.0)
                            }
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
                            .background(DS.Colours.successSoft)
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
                        .background(DS.Colours.surfaceElevated)
                        .overlay {
                            RoundedRectangle(cornerRadius: DS.CornerRadius.large)
                                .stroke(DS.Colours.borderSubtle, lineWidth: 1.0)
                        }
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
                                Text(isArchiving ? "Archiving..." : "Archive Memory")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colours.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(DS.Spacing.md)
                                    .background(DS.Colours.surfaceSecondary)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                                            .stroke(DS.Colours.borderSubtle, lineWidth: 1.0)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                            }
                            .disabled(isArchiving || isDeleting)
                            .buttonStyle(.mnemoPressable)
                            .accessibilityIdentifier(AccessibilityID.MemoryDetail.archive)

                            Button {
                                showingDeleteConfirm = true
                            } label: {
                                Text(isDeleting ? "Deleting..." : "Delete Permanently")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colours.destructive)
                                    .frame(maxWidth: .infinity)
                                    .padding(DS.Spacing.md)
                                    .background(DS.Colours.destructiveSoft)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                                            .stroke(DS.Colours.borderDestructive, lineWidth: 1.0)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                            }
                            .disabled(isDeleting)
                            .buttonStyle(.mnemoPressable)
                            .accessibilityIdentifier(AccessibilityID.MemoryDetail.delete)
                        }
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

    private var memoryTypeEnum: MemoryType {
        MemoryType(rawValue: snapshot.memoryType) ?? .fact
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

struct MetadataRow: View {
    let label: String
    let value: String
    let icon: String
    var isSecondary = false

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .frame(width: DS.Spacing.lg)
                .foregroundStyle(DS.Colours.textTertiary)
                .accessibilityHidden(true)
            Text(label)
                .font(labelFont)
                .foregroundStyle(DS.Colours.textSecondary)
            Spacer()
            Text(value)
                .font(valueFont)
                .foregroundStyle(DS.Colours.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    private var labelFont: Font {
        isSecondary ? DS.Typography.caption1 : DS.Typography.subheadline
    }

    private var valueFont: Font {
        isSecondary ? DS.Typography.caption1 : DS.Typography.subheadline
    }
}
