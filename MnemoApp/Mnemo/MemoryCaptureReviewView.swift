import SwiftUI
import UIKit
import MnemoCore
import MnemoUI

struct MemoryCaptureReviewView: View {
    let result: ExtractionResult
    let rawInput: String
    @Binding var summary: String
    let isSaving: Bool
    let onSave: (String) -> Void
    let onBack: () -> Void
    let onDiscard: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var proposal: MemoryNormalizationProposal? {
        result.normalizationProposal
    }

    private var trimmedSummary: String {
        summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("Review memory")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)

                if let proposal, !proposal.corrections.isEmpty {
                    correctionReview(proposal)
                }

                if let question = proposal?.clarificationQuestion,
                   proposal?.requiresClarification == true {
                    Label(question, systemImage: "questionmark.bubble")
                        .font(DS.Typography.subheadline)
                        .foregroundStyle(DS.Colours.warning)
                        .padding(DS.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DS.Colours.warningSoft)
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                        .accessibilityLabel("Check before saving. \(question)")
                }

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("Saved summary")
                        .font(DS.Typography.subheadline.weight(.semibold))
                        .foregroundStyle(DS.Colours.textSecondary)

                    TextEditor(text: $summary)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colours.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 112.0)
                        .padding(DS.Spacing.sm)
                        .background(DS.Colours.memoryCardSurface)
                        .overlay {
                            RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                                .stroke(DS.Colours.memoryCardBorder, lineWidth: 1.0)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                        .accessibilityLabel("Memory summary")
                        .accessibilityHint("Edit the exact summary Mnemo will save")
                }

                HStack(spacing: DS.Spacing.sm) {
                    Label(result.memoryType.rawValue.capitalized, systemImage: "tag")
                        .font(DS.Typography.caption1)
                        .foregroundStyle(DS.Colours.textSecondary)

                    Spacer()

                    Text(confidenceLabel)
                        .font(DS.Typography.caption1.weight(.semibold))
                        .foregroundStyle(result.confidence > 0.70 ? DS.Colours.success : DS.Colours.warning)
                        .padding(.horizontal, DS.Spacing.sm)
                        .padding(.vertical, DS.Spacing.xs)
                        .background(result.confidence > 0.70 ? DS.Colours.successSoft : DS.Colours.warningSoft)
                        .clipShape(Capsule())
                }

                DisclosureGroup {
                    Text(rawInput)
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colours.textSecondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, DS.Spacing.xs)
                } label: {
                    Label("Original capture", systemImage: "doc.text")
                        .font(DS.Typography.subheadline.weight(.semibold))
                        .foregroundStyle(DS.Colours.textPrimary)
                }
                .tint(DS.Colours.accent)
            }
            .transition(DS.Animation.cardAppearTransition(reduceMotion: reduceMotion))
            .accessibilityIdentifier(AccessibilityID.CaptureText.review)

            VStack(spacing: DS.Spacing.sm) {
                Button {
                    onSave(trimmedSummary)
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(DS.ComponentTokens.PrimaryButton.foreground)
                        } else {
                            Text(primaryActionLabel)
                        }
                    }
                }
                .disabled(trimmedSummary.isEmpty || isSaving)
                .buttonStyle(.mnemoPrimary)
                .accessibilityIdentifier(AccessibilityID.CaptureText.save)

                if let proposal, proposal.hasChanges {
                    Button {
                        summary = summary == proposal.originalSummary
                            ? proposal.proposedSummary
                            : proposal.originalSummary
                        UIAccessibility.post(
                            notification: .announcement,
                            argument: summary == proposal.originalSummary
                                ? "Using the uncorrected draft"
                                : "Using Mnemo's suggestion"
                        )
                    } label: {
                        Text(summary == proposal.originalSummary ? "Use Suggested Wording" : "Keep Draft Wording")
                    }
                    .disabled(isSaving)
                    .buttonStyle(.mnemoSecondary)
                }

                Button(action: onBack) {
                    Text("Back")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colours.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44.0)
                }
                .disabled(isSaving)
                .buttonStyle(.mnemoPressable)

                Button(action: onDiscard) {
                    Text("Discard")
                        .font(DS.Typography.body)
                        .foregroundStyle(DS.Colours.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44.0)
                }
                .disabled(isSaving)
                .buttonStyle(.mnemoPressable)
            }
        }
    }

    @ViewBuilder
    private func correctionReview(_ proposal: MemoryNormalizationProposal) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Label("Suggested corrections", systemImage: "checkmark.circle")
                .font(DS.Typography.subheadline.weight(.semibold))
                .foregroundStyle(DS.Colours.accent)

            ForEach(proposal.corrections) { correction in
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: DS.Spacing.sm) {
                            correctionText(correction.original)
                            Image(systemName: "arrow.right")
                                .foregroundStyle(DS.Colours.textTertiary)
                                .accessibilityHidden(true)
                            correctionText(correction.replacement)
                        }

                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            correctionText(correction.original)
                            Image(systemName: "arrow.down")
                                .foregroundStyle(DS.Colours.textTertiary)
                                .accessibilityHidden(true)
                            correctionText(correction.replacement)
                        }
                    }

                    Text(correction.reason)
                        .font(DS.Typography.caption1)
                        .foregroundStyle(DS.Colours.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "Changed \(correction.original) to \(correction.replacement). \(correction.reason)"
                )
            }
        }
        .padding(DS.Spacing.md)
        .background(DS.Colours.sourceSurface)
        .overlay {
            RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                .stroke(DS.Colours.sourceBorder, lineWidth: 1.0)
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
    }

    private func correctionText(_ text: String) -> some View {
        Text(text)
            .font(DS.Typography.body.weight(.medium))
            .foregroundStyle(DS.Colours.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var primaryActionLabel: String {
        proposal?.hasChanges == true && summary != proposal?.originalSummary
            ? "Save Corrected Memory"
            : "Save Memory"
    }

    private var confidenceLabel: String {
        if result.confidence < 0.50 {
            return "Review suggested"
        }
        return result.confidence > 0.70 ? "Looks ready" : "Check before saving"
    }
}
