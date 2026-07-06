import SwiftUI
import SwiftData
import MnemoUI
import MnemoCore
import MnemoMemory

/// Settings: processing mode, feature toggles, personalisation index, backup, and delete all data.
struct SettingsView: View {

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userModels: [UserModel]

    @State private var showingDeleteAllConfirm = false

    private var userModel: UserModel? {
        userModels.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colours.background.ignoresSafeArea()

                List {
                    Section {
                        DeviceTierRow(capability: appState.deviceCapability)
                            .listRowBackground(DS.Colours.surface)
                    } header: {
                        SettingsSectionHeader("Your Device")
                    }

                    Section {
                        if let model = userModel {
                            Toggle(isOn: Binding(
                                get: { model.onDeviceOnly },
                                set: {
                                    model.onDeviceOnly = $0
                                    try? modelContext.save()
                                }
                            )) {
                                Text("On-Device Only")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colours.textPrimary)
                            }
                            .tint(DS.Colours.accent)

                            if !model.onDeviceOnly {
                                HStack(alignment: .top, spacing: DS.Spacing.sm) {
                                    Image(systemName: "info.circle")
                                        .font(DS.Typography.subheadline)
                                        .foregroundStyle(DS.Colours.accent)
                                    Text("Cloud Assist is not connected in this build. Mnemo keeps capture and recall local until a provider is configured and you opt in.")
                                        .font(DS.Typography.footnote)
                                        .foregroundStyle(DS.Colours.textSecondary)
                                }
                            }
                        } else {
                            Text("Privacy settings will appear after onboarding.")
                                .font(DS.Typography.footnote)
                                .foregroundStyle(DS.Colours.textSecondary)
                        }
                    } header: {
                        SettingsSectionHeader("Privacy")
                    }
                    .listRowBackground(DS.Colours.surface)

                    Section {
                        if let model = userModel {
                            SenseToggle(
                                title: "Memory Moments",
                                isOn: Binding(
                                    get: { model.memoryMomentsEnabled },
                                    set: {
                                        model.memoryMomentsEnabled = $0
                                        try? modelContext.save()
                                    }
                                )
                            )
                            SenseToggle(
                                title: "Pattern Insights",
                                isOn: Binding(
                                    get: { model.patternInsightsEnabled },
                                    set: {
                                        model.patternInsightsEnabled = $0
                                        try? modelContext.save()
                                    }
                                )
                            )
                            SenseToggle(
                                title: "Thread Suggestions",
                                isOn: Binding(
                                    get: { model.threadSuggestionsEnabled },
                                    set: {
                                        model.threadSuggestionsEnabled = $0
                                        try? modelContext.save()
                                    }
                                )
                            )
                        } else {
                            Text("Mnemo Sense settings will appear after onboarding.")
                                .font(DS.Typography.footnote)
                                .foregroundStyle(DS.Colours.textSecondary)
                        }
                    } header: {
                        SettingsSectionHeader("Mnemo Sense")
                    }
                    .listRowBackground(DS.Colours.surface)

                    if let model = userModel {
                        Section {
                            PersonalisationIndexRow(userModel: model)
                        } header: {
                            SettingsSectionHeader("Personalisation")
                        }
                        .listRowBackground(DS.Colours.surface)
                    }

                    Section {
                        NavigationLink {
                            BackupRestoreView()
                        } label: {
                            HStack(spacing: DS.Spacing.sm) {
                                Image(systemName: "icloud")
                                    .font(DS.Typography.subheadline)
                                    .foregroundStyle(DS.Colours.accent)
                                Text("iCloud Backup")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colours.textPrimary)
                            }
                        }
                    } header: {
                        SettingsSectionHeader("Backup")
                    }
                    .listRowBackground(DS.Colours.surface)

                    Section {
                        Button {
                            showingDeleteAllConfirm = true
                        } label: {
                            HStack(spacing: DS.Spacing.sm) {
                                Image(systemName: "trash")
                                    .font(DS.Typography.subheadline)
                                    .foregroundStyle(DS.Colours.destructive)
                                Text("Delete All Data")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colours.destructive)
                            }
                        }
                        .confirmationDialog(
                            "Delete all data?",
                            isPresented: $showingDeleteAllConfirm,
                            titleVisibility: .visible
                        ) {
                            Button("Delete Everything", role: .destructive) {
                                Task {
                                    await deleteAllData()
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This permanently deletes all your memories, threads, and settings. This cannot be undone.")
                        }
                    }
                    .listRowBackground(DS.Colours.surface)
                }
                .scrollContentBackground(.hidden)
                .background(DS.Colours.background)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
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

    @MainActor
    private func deleteAllData() async {
        try? modelContext.delete(model: MemoryRecord.self)
        try? modelContext.delete(model: MemoryThread.self)
        try? modelContext.delete(model: UserModel.self)
        try? modelContext.delete(model: ConflictRecord.self)
        try? modelContext.delete(model: PersonSubject.self)
        try? modelContext.save()
        try? await VectorBridge.shared.wipe()
        appState.onboardingComplete = false
    }
}

struct SettingsSectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(DS.Typography.caption1)
            .foregroundStyle(DS.Colours.textSecondary)
    }
}

struct SenseToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textPrimary)
        }
        .tint(DS.Colours.sense)
    }
}

struct DeviceTierRow: View {
    let capability: DeviceCapability

    var tierLabel: String {
        switch capability.tier {
        case .full:
            return "Local Processing Ready"
        case .standard:
            return "Local Processing Ready"
        case .mlxOnly:
            return "Local Processing Ready"
        case .cloudPrimary:
            return "Local Only in This Build"
        case .unsupported:
            return "Limited"
        }
    }

    var tierIcon: String {
        switch capability.tier {
        case .full, .standard:
            return "cpu.fill"
        case .mlxOnly:
            return "lock.shield.fill"
        case .cloudPrimary:
            return "cloud.fill"
        case .unsupported:
            return "exclamationmark.triangle"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            Image(systemName: tierIcon)
                .font(DS.Typography.subheadline)
                .foregroundStyle(DS.Colours.accent)
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(tierLabel)
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.textPrimary)
                Text("This build stores memories on device and uses local deterministic recall.")
                    .font(DS.Typography.caption1)
                    .foregroundStyle(DS.Colours.textSecondary)
            }
        }
    }
}

struct PersonalisationIndexRow: View {
    let userModel: UserModel

    var index: PersonalisationIndex {
        userModel.decodedPersonalisationIndex()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                Text("Memory Profile")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.textPrimary)
                Spacer()
                Text(statusLabel)
                    .font(DS.ComponentTokens.SenseBadge.font)
                    .foregroundStyle(DS.Colours.sense)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(DS.Colours.senseLight)
                    .clipShape(Capsule())
            }

            ProgressView(value: index.overall)
                .tint(DS.Colours.sense)

            Text("\(Int(index.overall * 100))% tuned from saved memories")
                .font(DS.Typography.caption1)
                .foregroundStyle(DS.Colours.textSecondary)
        }
    }

    private var statusLabel: String {
        if index.overall <= 0.01 {
            return "Not started"
        }

        switch index.displayLevel {
        case .learningYou:
            return "Learning"
        case .gettingPersonal:
            return "Learning"
        case .mostlyYou:
            return "Adapting"
        case .highlyPersonal:
            return "Personal"
        case .fullyPersonalised:
            return "Tuned"
        }
    }
}
