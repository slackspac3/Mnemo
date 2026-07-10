import SwiftUI
import SwiftData
import UIKit
import MnemoUI
import MnemoCore
import MnemoMemory
import MnemoSecurity

/// Settings: processing mode, feature toggles, personalisation index, backup, and delete all data.
struct SettingsView: View {

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userModels: [UserModel]

    @State private var showingDeleteAllConfirm = false
    @State private var destructiveErrorMessage: String?
    @State private var appLockErrorMessage: String?
    @State private var appLockUnavailableMessage: String?
    @State private var canUseAppLock = true
    @State private var isChangingAppLock = false
    private let appLockSettingsPolicy = AppLockSettingsPolicy()

    private var userModel: UserModel? {
        userModels.first
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let model = userModel {
                        Toggle("App Lock", isOn: Binding(
                            get: { model.appLockEnabled },
                            set: { enabled in
                                Task {
                                    await updateAppLock(enabled, model: model)
                                }
                            }
                        ))
                        .tint(DS.Colours.accent)
                        .disabled((!canUseAppLock && !model.appLockEnabled) || isChangingAppLock)
                        .accessibilityIdentifier(AccessibilityID.Settings.appLockToggle)

                        if isChangingAppLock {
                            Label("Waiting for device authentication", systemImage: "faceid")
                                .foregroundStyle(DS.Colours.textSecondary)
                        }

                        if let appLockUnavailableMessage {
                            Label(appLockUnavailableMessage, systemImage: "exclamationmark.shield")
                                .foregroundStyle(DS.Colours.textSecondary)
                        }

                        if let appLockErrorMessage {
                            Label(appLockErrorMessage, systemImage: "exclamationmark.circle")
                                .foregroundStyle(DS.Colours.destructive)
                        }
                    } else {
                        Text("App Lock is available after onboarding.")
                            .foregroundStyle(DS.Colours.textSecondary)
                    }

                    NavigationLink {
                        PrivacyAndProcessingView(capability: appState.deviceCapability)
                    } label: {
                        Label("Privacy & Processing", systemImage: "hand.raised")
                    }
                } header: {
                    Text("Privacy & Security")
                } footer: {
                    Text("App Lock requires Face ID, Touch ID, or your device passcode when Mnemo opens.")
                }
                .accessibilityIdentifier(AccessibilityID.Settings.securitySection)

                if let model = userModel {
                    Section {
                        PersonalisationIndexRow(userModel: model)
                    } header: {
                        Text("Memory")
                    }
                }

                Section {
                    NavigationLink {
                        BackupRestoreView()
                    } label: {
                        Label("iCloud Backup", systemImage: "icloud")
                    }
                } header: {
                    Text("Backup")
                }

                #if DEBUG
                Section {
                    NavigationLink {
                        DesignExplorationView()
                    } label: {
                        Label("Design Preview", systemImage: "paintpalette")
                    }

                    NavigationLink {
                        AILabView()
                    } label: {
                        Label("AI Lab", systemImage: "apple.intelligence")
                    }
                } header: {
                    Text("Developer")
                }
                #endif

                Section {
                    if let destructiveErrorMessage {
                        Label(destructiveErrorMessage, systemImage: "exclamationmark.circle")
                            .foregroundStyle(DS.Colours.destructive)
                    }

                    Button(role: .destructive) {
                        showingDeleteAllConfirm = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                    }
                    .accessibilityIdentifier(AccessibilityID.Settings.deleteAllData)
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
                } header: {
                    Text("Data")
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.Colours.backgroundGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            refreshAppLockAvailability()
            enforceLocalOnlySetting()
        }
        .onChange(of: appLockErrorMessage) { _, message in
            guard let message else { return }
            UIAccessibility.post(notification: .announcement, argument: message)
        }
        .onChange(of: destructiveErrorMessage) { _, message in
            guard let message else { return }
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    @MainActor
    private func deleteAllData() async {
        destructiveErrorMessage = nil
        do {
            #if DEBUG
            await DebugLocalAIBackfillState.prepareForReset()
            #endif
            try modelContext.delete(model: MemoryRecord.self)
            try modelContext.delete(model: MemoryThread.self)
            try modelContext.delete(model: UserModel.self)
            try modelContext.delete(model: ConflictRecord.self)
            try modelContext.delete(model: PersonSubject.self)
            try modelContext.save()
            try await VectorBridge.shared.wipe()
            try await MemoryCRUD.resetSearchIndexItems()
            #if DEBUG
            DebugLocalAIBackfillState.isComplete = false
            #endif
            NavigationCoordinator.shared.dismiss()
            appState.resetAfterDeleteAllData()
            dismiss()
        } catch {
            destructiveErrorMessage = "Could not delete all data. Try again before removing the app."
        }
    }

    @MainActor
    private func refreshAppLockAvailability() {
        canUseAppLock = SecurityLayer.shared.canAuthenticateWithBiometrics()
        appLockUnavailableMessage = canUseAppLock ? nil : "Face ID, Touch ID or a device passcode is not available on this device."
    }

    @MainActor
    private func enforceLocalOnlySetting() {
        guard let model = userModel, !model.onDeviceOnly || model.cloudFallbackEnabled else { return }
        model.onDeviceOnly = true
        model.cloudFallbackEnabled = false
        try? modelContext.save()
    }

    @MainActor
    private func updateAppLock(_ enabled: Bool, model: UserModel) async {
        switch appLockSettingsPolicy.decision(
            requestedEnabled: enabled,
            currentEnabled: model.appLockEnabled,
            authenticationAvailable: canUseAppLock
        ) {
        case .unchanged:
            return
        case .blockEnableUnavailable:
            appLockErrorMessage = "Set up Face ID, Touch ID or a device passcode before enabling App Lock."
            return
        case .allowDisableUnavailable:
            do {
                try persistAppLock(false, model: model)
                appState.setAppLockEnabled(false)
                appLockErrorMessage = nil
            } catch {
                appLockErrorMessage = "App Lock is still on. Try again when you are ready."
            }
            return
        case .authenticateToEnable, .authenticateToDisable:
            break
        }

        guard !isChangingAppLock else { return }

        isChangingAppLock = true
        appLockErrorMessage = nil

        do {
            let reason = enabled
                ? "Authenticate to enable App Lock for Mnemo."
                : "Authenticate to turn off App Lock for Mnemo."
            let success = try await SecurityLayer.shared.authenticateWithBiometrics(reason: reason)
            guard success else {
                appLockErrorMessage = enabled
                    ? "App Lock was not enabled. Try again when you are ready."
                    : "App Lock is still on. Try again when you are ready."
                isChangingAppLock = false
                return
            }

            try persistAppLock(enabled, model: model)
            appState.setAppLockEnabled(enabled)
        } catch {
            appLockErrorMessage = enabled
                ? "App Lock was not enabled. Try again when you are ready."
                : "App Lock is still on. Try again when you are ready."
        }

        isChangingAppLock = false
    }

    @MainActor
    private func persistAppLock(_ enabled: Bool, model: UserModel) throws {
        let previousEnabled = model.appLockEnabled
        let previousUpdatedAt = model.updatedAt

        model.appLockEnabled = enabled
        model.updatedAt = Date()

        do {
            try modelContext.save()
        } catch {
            model.appLockEnabled = previousEnabled
            model.updatedAt = previousUpdatedAt
            throw error
        }
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

private struct PrivacyAndProcessingView: View {
    let capability: DeviceCapability

    var body: some View {
        List {
            Section {
                DeviceTierRow(capability: capability)

                Label {
                    Text("Mnemo works without an account, email, or sign-in.")
                } icon: {
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .foregroundStyle(DS.Colours.privateBadgeText)
                }
            } header: {
                Text("On This iPhone")
            } footer: {
                Text("Capture and recall stay on this iPhone. No cloud AI is enabled in this build.")
            }

            Section {
                Label {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("iCloud Backup")
                        Text("Optional encrypted backups are stored in your iCloud account.")
                            .font(DS.Typography.caption1)
                            .foregroundStyle(DS.Colours.textSecondary)
                    }
                } icon: {
                    Image(systemName: "icloud")
                        .foregroundStyle(DS.Colours.accent)
                }
            } header: {
                Text("Backup")
            }
        }
        .scrollContentBackground(.hidden)
        .background(DS.Colours.backgroundGrouped)
        .navigationTitle("Privacy & Processing")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DeviceTierRow: View {
    let capability: DeviceCapability

    var tierLabel: String {
        switch capability.tier {
        case .full:
            return "Local Recall Ready"
        case .standard:
            return "Local Recall Ready"
        case .mlxOnly:
            return "Local Recall Ready"
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
            return "lock.shield.fill"
        case .unsupported:
            return "exclamationmark.triangle"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            Image(systemName: tierIcon)
                .font(DS.Typography.subheadline)
                .foregroundStyle(
                    capability.tier == .unsupported
                        ? DS.Colours.warning
                        : DS.Colours.privateBadgeText
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(tierLabel)
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.textPrimary)
                Text("Memories and recall stay on this iPhone.")
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
            ViewThatFits(in: .horizontal) {
                HStack {
                    profileTitle
                    Spacer()
                    statusView
                }

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    profileTitle
                    statusView
                }
            }

            ProgressView(value: index.overall)
                .tint(DS.Colours.accent)

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

    private var profileTitle: some View {
        Text("Memory Profile")
            .font(DS.Typography.subheadline)
            .foregroundStyle(DS.Colours.textPrimary)
    }

    private var statusView: some View {
        Text(statusLabel)
            .font(DS.Typography.subheadline)
            .foregroundStyle(DS.Colours.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
