#if DEBUG
import SwiftUI
import MnemoUI

struct AILabView: View {
    @State private var coreSpotlightResult: AILabSmokeResult?
    @State private var foundationModelsResult: AILabSmokeResult?
    @State private var runningSmoke: AILabSmoke?

    var body: some View {
        ZStack {
            DS.Colours.backgroundGrouped.ignoresSafeArea()

            List {
                Section {
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        Text("Internal AI Lab")
                            .font(DS.Typography.headline)
                            .foregroundStyle(DS.Colours.textPrimary)
                        Text("DEBUG-only smoke tests for local Apple-native AI plumbing. These controls do not change Chat recall or enable model answers for normal users.")
                            .font(DS.Typography.caption1)
                            .foregroundStyle(DS.Colours.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, DS.Spacing.xs)
                }
                .listRowBackground(DS.Colours.surfaceElevated)

                Section {
                    AILabRunButton(
                        title: "Run Core Spotlight Smoke",
                        systemImage: "magnifyingglass.circle.fill",
                        isRunning: runningSmoke == .coreSpotlight
                    ) {
                        runCoreSpotlightSmoke()
                    }
                    .disabled(runningSmoke != nil)

                    if let coreSpotlightResult {
                        AILabSmokeResultView(result: coreSpotlightResult)
                    } else {
                        AILabEmptyResultView(message: "No Core Spotlight result yet.")
                    }
                } header: {
                    SettingsSectionHeader("Core Spotlight")
                }
                .listRowBackground(DS.Colours.surfaceElevated)

                Section {
                    AILabRunButton(
                        title: "Run Foundation Models Smoke",
                        systemImage: "apple.intelligence",
                        isRunning: runningSmoke == .foundationModels
                    ) {
                        runFoundationModelsSmoke()
                    }
                    .disabled(runningSmoke != nil)

                    if let foundationModelsResult {
                        AILabSmokeResultView(result: foundationModelsResult)
                    } else {
                        AILabEmptyResultView(message: "No Foundation Models result yet.")
                    }
                } header: {
                    SettingsSectionHeader("Foundation Models")
                }
                .listRowBackground(DS.Colours.surfaceElevated)
            }
            .scrollContentBackground(.hidden)
            .background(DS.Colours.backgroundGrouped)
        }
        .navigationTitle("AI Lab")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func runCoreSpotlightSmoke() {
        guard runningSmoke == nil else { return }
        runningSmoke = .coreSpotlight

        Task {
            let result = await CoreSpotlightQuerySmokeTest.run()
            coreSpotlightResult = AILabSmokeResult(coreSpotlight: result)
            runningSmoke = nil
        }
    }

    @MainActor
    private func runFoundationModelsSmoke() {
        guard runningSmoke == nil else { return }
        runningSmoke = .foundationModels

        Task {
            let result = await FoundationModelsMemorySmokeTest.run()
            foundationModelsResult = AILabSmokeResult(foundationModels: result)
            runningSmoke = nil
        }
    }
}

private enum AILabSmoke {
    case coreSpotlight
    case foundationModels
}

private struct AILabSmokeResult {
    let title: String
    let ranAt: Date
    let durationMs: Double
    let available: String
    let indexed: String
    let queried: String
    let sourceCardResolved: String
    let modelAnswered: String
    let citationsValid: String
    let answer: String
    let error: String
    let extraRows: [(String, String)]

    init(coreSpotlight result: CoreSpotlightQuerySmokeTestResult) {
        title = "Core Spotlight Query Smoke"
        ranAt = Date()
        durationMs = result.durationMs
        available = "Not applicable"
        indexed = Self.boolean(result.indexed)
        queried = Self.boolean(result.queried)
        sourceCardResolved = Self.boolean(result.sourceCardResolved)
        modelAnswered = "Not applicable"
        citationsValid = "Not applicable"
        answer = "Not applicable"
        error = result.errorMessage ?? "none"
        extraRows = [
            ("found", Self.boolean(result.found)),
            ("sourceValidated", Self.boolean(result.sourceValidated)),
            ("archivedRejected", Self.boolean(result.archivedRejected)),
            ("deletedRejected", Self.boolean(result.deletedRejected)),
            ("cleared", Self.boolean(result.cleared))
        ]
    }

    init(foundationModels result: FoundationModelsMemorySmokeTestResult) {
        title = "Foundation Models Memory Smoke"
        ranAt = Date()
        durationMs = result.durationMs
        available = Self.boolean(result.available)
        indexed = Self.boolean(result.indexed)
        queried = Self.boolean(result.queried)
        sourceCardResolved = Self.boolean(result.sourceCardResolved)
        modelAnswered = Self.boolean(result.modelAnswered)
        citationsValid = Self.boolean(result.citationsValid)
        answer = result.answer.isEmpty ? "none" : result.answer
        error = result.errorMessage ?? "none"
        extraRows = []
    }

    private static func boolean(_ value: Bool) -> String {
        value ? "true" : "false"
    }
}

private struct AILabRunButton: View {
    let title: String
    let systemImage: String
    let isRunning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                if isRunning {
                    ProgressView()
                        .tint(DS.Colours.textOnAccent)
                } else {
                    Image(systemName: systemImage)
                        .font(DS.Typography.subheadline)
                        .accessibilityHidden(true)
                }

                Text(isRunning ? "Running..." : title)
                    .font(DS.Typography.body.weight(.semibold))

                Spacer()
            }
            .foregroundStyle(DS.Colours.textOnAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.sm)
            .padding(.horizontal, DS.Spacing.md)
            .background(DS.Colours.accent)
            .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
        }
        .buttonStyle(.mnemoPressable)
        .accessibilityLabel(isRunning ? "Running \(title)" : title)
    }
}

private struct AILabSmokeResultView: View {
    let result: AILabSmokeResult

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(result.title)
                    .font(DS.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(DS.Colours.textPrimary)
                Text("Last run \(result.ranAt.formatted(date: .omitted, time: .standard))")
                    .font(DS.Typography.caption1)
                    .foregroundStyle(DS.Colours.textSecondary)
            }

            AILabResultRow(label: "available", value: result.available)
            AILabResultRow(label: "indexed", value: result.indexed)
            AILabResultRow(label: "queried", value: result.queried)
            AILabResultRow(label: "sourceCardResolved", value: result.sourceCardResolved)
            AILabResultRow(label: "modelAnswered", value: result.modelAnswered)
            AILabResultRow(label: "citationsValid", value: result.citationsValid)
            AILabResultRow(label: "answer", value: result.answer)
            AILabResultRow(label: "error", value: result.error)
            AILabResultRow(
                label: "durationMs",
                value: String(format: "%.2f", result.durationMs)
            )

            ForEach(result.extraRows, id: \.0) { row in
                AILabResultRow(label: row.0, value: row.1)
            }
        }
        .padding(.vertical, DS.Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

private struct AILabResultRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.sm) {
            Text(label)
                .font(DS.Typography.caption1)
                .foregroundStyle(DS.Colours.textSecondary)
                .frame(width: 132, alignment: .leading)

            Text(value)
                .font(DS.Typography.caption1.weight(.semibold))
                .foregroundStyle(valueColour)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    private var valueColour: Color {
        switch value {
        case "true", "none":
            return DS.Colours.success
        case "false":
            return DS.Colours.destructive
        case "Not applicable":
            return DS.Colours.textTertiary
        default:
            return DS.Colours.textPrimary
        }
    }
}

private struct AILabEmptyResultView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(DS.Typography.caption1)
            .foregroundStyle(DS.Colours.textSecondary)
            .padding(.vertical, DS.Spacing.xs)
    }
}
#endif
