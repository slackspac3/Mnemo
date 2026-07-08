import SwiftUI
import SwiftData
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
            ZStack {
                DS.Colours.backgroundGrouped.ignoresSafeArea()

                List {
                    Section {
                        SettingsBrandHeader()
                            .listRowInsets(EdgeInsets(
                                top: DS.Spacing.md,
                                leading: DS.Spacing.md,
                                bottom: DS.Spacing.md,
                                trailing: DS.Spacing.md
                            ))
                            .listRowBackground(DS.Colours.surfaceElevated)
                    }

                    Section {
                        DeviceTierRow(capability: appState.deviceCapability)
                            .listRowBackground(DS.Colours.surfaceElevated)
                    } header: {
                        SettingsSectionHeader("Your Device")
                    }

                    Section {
                        if userModel != nil {
                            HStack(alignment: .top, spacing: DS.Spacing.sm) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(DS.Typography.subheadline)
                                    .foregroundStyle(DS.Colours.accent)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                    Text("Local Capture & Recall")
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.Colours.textPrimary)
                                    Text("Capture and recall stay on this iPhone. Optional iCloud Backup stores encrypted backups in your iCloud account; no cloud AI is enabled in this build.")
                                        .font(DS.Typography.footnote)
                                        .foregroundStyle(DS.Colours.textSecondary)
                                }
                            }
                            .accessibilityElement(children: .combine)

                            HStack(alignment: .top, spacing: DS.Spacing.sm) {
                                Image(systemName: "person.crop.circle.badge.xmark")
                                    .font(DS.Typography.subheadline)
                                    .foregroundStyle(DS.Colours.accent)
                                    .accessibilityHidden(true)
                                Text("Mnemo works without an account, email, or sign-in.")
                                    .font(DS.Typography.footnote)
                                    .foregroundStyle(DS.Colours.textSecondary)
                            }
                        } else {
                            Text("Privacy settings will appear after onboarding.")
                                .font(DS.Typography.footnote)
                                .foregroundStyle(DS.Colours.textSecondary)
                        }
                    } header: {
                        SettingsSectionHeader("Privacy")
                    }
                    .listRowBackground(DS.Colours.surfaceElevated)

                    Section {
                        if let model = userModel {
                            Toggle(isOn: Binding(
                                get: { model.appLockEnabled },
                                set: { enabled in
                                    Task {
                                        await updateAppLock(enabled, model: model)
                                    }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                    Text("Require App Lock to Open Mnemo")
                                        .font(DS.Typography.body)
                                        .foregroundStyle(DS.Colours.textPrimary)
                                    Text("When enabled, Mnemo asks for Face ID, Touch ID or your device passcode when you reopen the app.")
                                        .font(DS.Typography.caption1)
                                        .foregroundStyle(DS.Colours.textSecondary)
                                }
                            }
                            .tint(DS.Colours.accent)
                            .disabled((!canUseAppLock && !model.appLockEnabled) || isChangingAppLock)
                            .accessibilityIdentifier(AccessibilityID.Settings.appLockToggle)

                            if isChangingAppLock {
                                Text("Waiting for device authentication...")
                                    .font(DS.Typography.footnote)
                                    .foregroundStyle(DS.Colours.textSecondary)
                            }

                            if let appLockUnavailableMessage {
                                Text(appLockUnavailableMessage)
                                    .font(DS.Typography.footnote)
                                    .foregroundStyle(DS.Colours.textSecondary)
                            }

                            if let appLockErrorMessage {
                                Text(appLockErrorMessage)
                                    .font(DS.Typography.footnote)
                                    .foregroundStyle(DS.Colours.destructive)
                            }
                        } else {
                            Text("App Lock settings will appear after onboarding.")
                                .font(DS.Typography.footnote)
                                .foregroundStyle(DS.Colours.textSecondary)
                        }
                    } header: {
                        SettingsSectionHeader("Security")
                    }
                    .listRowBackground(DS.Colours.surfaceElevated)
                    .accessibilityIdentifier(AccessibilityID.Settings.securitySection)

                    Section {
                        if userModel != nil {
                            SenseComingSoonRow(
                                title: "Memory Moments",
                                detail: "Coming soon"
                            )
                            SenseComingSoonRow(
                                title: "Pattern Insights",
                                detail: "Coming soon"
                            )
                            SenseComingSoonRow(
                                title: "Thread Suggestions",
                                detail: "Coming soon"
                            )
                        } else {
                            Text("Mnemo Sense settings will appear after onboarding.")
                                .font(DS.Typography.footnote)
                                .foregroundStyle(DS.Colours.textSecondary)
                        }
                    } header: {
                        SettingsSectionHeader("Mnemo Sense")
                    }
                    .listRowBackground(DS.Colours.surfaceElevated)

                    if let model = userModel {
                        Section {
                            PersonalisationIndexRow(userModel: model)
                        } header: {
                            SettingsSectionHeader("Personalisation")
                        }
                        .listRowBackground(DS.Colours.surfaceElevated)
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
                    .listRowBackground(DS.Colours.surfaceElevated)

                    Section {
                        if let destructiveErrorMessage {
                            Text(destructiveErrorMessage)
                                .font(DS.Typography.footnote)
                                .foregroundStyle(DS.Colours.destructive)
                        }

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
                    }
                    .listRowBackground(DS.Colours.surfaceElevated)
                }
                .scrollContentBackground(.hidden)
                .background(DS.Colours.backgroundGrouped)
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
        .task {
            refreshAppLockAvailability()
            enforceLocalOnlySetting()
        }
    }

    @MainActor
    private func deleteAllData() async {
        destructiveErrorMessage = nil
        do {
            try modelContext.delete(model: MemoryRecord.self)
            try modelContext.delete(model: MemoryThread.self)
            try modelContext.delete(model: UserModel.self)
            try modelContext.delete(model: ConflictRecord.self)
            try modelContext.delete(model: PersonSubject.self)
            try modelContext.save()
            try await VectorBridge.shared.wipe()
            try await MemoryCRUD.removeAllSearchIndexItems()
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

struct SettingsBrandHeader: View {
    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.md) {
            MnemoLogoMark(size: 52.0, style: .subtle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Mnemo")
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.Colours.textPrimary)
                Text("Private memory on this iPhone. No Mnemo account required.")
                    .font(DS.Typography.caption1)
                    .foregroundStyle(DS.Colours.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Mnemo. Private memory on this iPhone. No Mnemo account required.")
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

struct SenseComingSoonRow: View {
    let title: String
    let detail: String

    var body: some View {
        HStack {
            Text(title)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colours.textPrimary)
            Spacer()
            Text(detail)
                .font(DS.Typography.caption1)
                .foregroundStyle(DS.Colours.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xs)
                .background(DS.Colours.surfaceDisabled)
                .clipShape(Capsule())
        }
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
                .foregroundStyle(DS.Colours.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(tierLabel)
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.textPrimary)
                Text("Mnemo stores memories on this iPhone and uses local recall.")
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
