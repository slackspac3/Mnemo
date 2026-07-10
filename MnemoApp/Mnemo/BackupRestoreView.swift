import SwiftUI
import SwiftData
import MnemoUI
import MnemoSync
import MnemoCore
#if os(iOS)
import UIKit
#endif

/// Backup and restore interface surfaced from SettingsView.
struct BackupRestoreView: View {

    @Environment(\.modelContext) private var modelContext

    @State private var isBackingUp = false
    @State private var isRestoring = false
    @State private var availableBackups: [BackupManifest] = []
    @State private var lastBackupManifest: BackupManifest?
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showingRestoreConfirm = false
    @State private var selectedManifest: BackupManifest?

    var body: some View {
        ZStack {
                DS.Colours.backgroundGrouped.ignoresSafeArea()

                List {
                    Section {
                        if let manifest = lastBackupManifest {
                            HStack(alignment: .top, spacing: DS.Spacing.sm) {
                                Image(systemName: "checkmark.icloud.fill")
                                    .font(DS.Typography.subheadline)
                                    .foregroundStyle(DS.Colours.success)
                                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                    Text("Last backup: \(manifest.createdAt.formatted(.dateTime.day().month().year()))")
                                        .font(DS.Typography.subheadline)
                                        .foregroundStyle(DS.Colours.textPrimary)
                                    Text("\(manifest.recordCount) memories, \(manifest.threadCount) threads")
                                        .font(DS.Typography.caption1)
                                        .foregroundStyle(DS.Colours.textSecondary)
                                }
                            }
                        } else {
                            HStack(spacing: DS.Spacing.sm) {
                                Image(systemName: "icloud.slash")
                                    .font(DS.Typography.subheadline)
                                    .foregroundStyle(DS.Colours.textTertiary)
                                Text("No backup found")
                                    .font(DS.Typography.subheadline)
                                    .foregroundStyle(DS.Colours.textSecondary)
                            }
                        }
                    } header: {
                        SettingsSectionHeader("Backup Status")
                    }
                    .listRowBackground(DS.Colours.surfaceElevated)

                    Section {
                        Button {
                            performBackup()
                        } label: {
                            HStack(spacing: DS.Spacing.sm) {
                                if isBackingUp {
                                    ProgressView()
                                        .tint(DS.Colours.accent)
                                        .accessibilityHidden(true)
                                } else {
                                    Image(systemName: "icloud.and.arrow.up")
                                        .font(DS.Typography.subheadline)
                                        .foregroundStyle(DS.Colours.accent)
                                }
                                Text(isBackingUp ? "Backing up..." : "Back Up Now")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colours.accent)
                            }
                        }
                        .disabled(isBackingUp || isRestoring)
                        .accessibilityLabel("Back up now")
                        .accessibilityValue(isBackingUp ? "In progress" : "Available")
                    }
                    .listRowBackground(DS.Colours.surfaceElevated)

                    if !availableBackups.isEmpty {
                        Section {
                            ForEach(availableBackups) { manifest in
                                ViewThatFits(in: .horizontal) {
                                    HStack(spacing: DS.Spacing.sm) {
                                        backupDescription(for: manifest)
                                        Spacer(minLength: DS.Spacing.sm)
                                        restoreButton(for: manifest)
                                    }

                                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                                        backupDescription(for: manifest)
                                        restoreButton(for: manifest)
                                    }
                                }
                            }
                        } header: {
                            SettingsSectionHeader("Available Backups")
                        }
                        .listRowBackground(DS.Colours.surfaceElevated)
                    }

                    Section {
                        HStack(alignment: .top, spacing: DS.Spacing.sm) {
                            Image(systemName: "lock.shield")
                                .font(DS.Typography.subheadline)
                                .foregroundStyle(DS.Colours.privateBadgeText)
                            Text("Backups are encrypted before being stored in your iCloud account. Mnemo does not operate a backup server. Restore currently requires this iPhone's local Keychain backup key, so restore on a new or replacement iPhone is not available in this build.")
                                .font(DS.Typography.footnote)
                                .foregroundStyle(DS.Colours.textSecondary)
                        }
                    }
                    .listRowBackground(DS.Colours.surfaceElevated)

                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .font(DS.Typography.footnote)
                                .foregroundStyle(DS.Colours.destructive)
                        }
                        .listRowBackground(DS.Colours.surfaceElevated)
                    }

                    if let success = successMessage {
                        Section {
                            Text(success)
                                .font(DS.Typography.footnote)
                                .foregroundStyle(DS.Colours.success)
                        }
                        .listRowBackground(DS.Colours.surfaceElevated)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(DS.Colours.backgroundGrouped)
            }
            .navigationTitle("iCloud Backup")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "Restore from backup?",
                isPresented: $showingRestoreConfirm,
                titleVisibility: .visible
            ) {
                Button("Restore", role: .destructive) {
                    if let manifest = selectedManifest {
                        performRestore(from: manifest)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will replace all current memories and threads with the backup. This cannot be undone.")
            }
            .task {
                await loadBackups()
            }
            .onChange(of: errorMessage) { _, message in
                guard let message else { return }
                announceForAccessibility(message)
            }
            .onChange(of: successMessage) { _, message in
                guard let message else { return }
                announceForAccessibility(message)
            }
    }

    private func performBackup() {
        guard !isBackingUp, !isRestoring else { return }
        isBackingUp = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                let backupManager = BackupManager()
                let manifest = try await backupManager.backup(context: modelContext)
                await MainActor.run {
                    lastBackupManifest = manifest
                    successMessage = "Backup complete: \(manifest.recordCount) memories saved."
                    isBackingUp = false
                }
                await loadBackups()
            } catch {
                await MainActor.run {
                    errorMessage = "Backup failed: \(error.localizedDescription)"
                    isBackingUp = false
                }
            }
        }
    }

    private func performRestore(from manifest: BackupManifest) {
        guard !isBackingUp, !isRestoring else { return }
        isRestoring = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                let restoreManager = RestoreManager()
                try await restoreManager.restore(from: manifest, into: modelContext)
                await MainActor.run {
                    successMessage = "Restore complete."
                    isRestoring = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Restore failed: \(error.localizedDescription)"
                    isRestoring = false
                }
            }
        }
    }

    private func backupDescription(for manifest: BackupManifest) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(manifest.createdAt.formatted(.dateTime.day().month().year().hour().minute()))
                .font(DS.Typography.subheadline)
                .foregroundStyle(DS.Colours.textPrimary)
            Text("\(manifest.recordCount) memories")
                .font(DS.Typography.caption1)
                .foregroundStyle(DS.Colours.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func restoreButton(for manifest: BackupManifest) -> some View {
        let isCurrentRestore = isRestoring && selectedManifest?.id == manifest.id

        return Button {
            guard !isBackingUp, !isRestoring else { return }
            selectedManifest = manifest
            showingRestoreConfirm = true
        } label: {
            HStack(spacing: DS.Spacing.xs) {
                if isCurrentRestore {
                    ProgressView()
                        .controlSize(.small)
                        .tint(DS.Colours.accent)
                        .accessibilityHidden(true)
                }
                Text(isCurrentRestore ? "Restoring..." : "Restore")
                    .font(DS.Typography.caption1.weight(.semibold))
                    .foregroundStyle(DS.Colours.accent)
            }
            .frame(minHeight: 44.0)
        }
        .disabled(isBackingUp || isRestoring)
        .accessibilityLabel(
            "Restore backup from \(manifest.createdAt.formatted(.dateTime.day().month().year().hour().minute()))"
        )
        .accessibilityValue(isCurrentRestore ? "In progress" : "Available")
    }

    private func announceForAccessibility(_ message: String) {
        #if os(iOS)
        UIAccessibility.post(notification: .announcement, argument: message)
        #endif
    }

    private func loadBackups() async {
        do {
            let backupManager = BackupManager()
            let backups = try await backupManager.availableBackups()
            await MainActor.run {
                availableBackups = backups
                lastBackupManifest = backups.first
            }
        } catch {
            await MainActor.run {
                availableBackups = []
                lastBackupManifest = nil
            }
        }
    }
}
