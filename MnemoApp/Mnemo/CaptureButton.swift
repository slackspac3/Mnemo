import SwiftUI
import MnemoUI

/// Floating capture button that presents the capture type selector.
struct CaptureButton: View {

    @Environment(NavigationCoordinator.self) private var coordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            if expanded {
                VStack(spacing: DS.Spacing.xs) {
                    CaptureOptionButton(
                        icon: "camera.fill",
                        label: "Camera",
                        color: DS.Colours.success
                    ) {
                        expanded = false
                        coordinator.present(.captureImage(.camera))
                    }

                    CaptureOptionButton(
                        icon: "photo.on.rectangle",
                        label: "Photo",
                        color: DS.Colours.warning
                    ) {
                        expanded = false
                        coordinator.present(.captureImage(.photoLibrary))
                    }

                    CaptureOptionButton(
                        icon: "mic.fill",
                        label: "Voice",
                        color: DS.Colours.accent
                    ) {
                        expanded = false
                        coordinator.present(.captureVoice)
                    }

                    CaptureOptionButton(
                        icon: "square.and.pencil",
                        label: "Text",
                        color: DS.Colours.brandInk
                    ) {
                        expanded = false
                        coordinator.present(.captureText)
                    }
                }
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            }

            Button {
                withAnimation(reduceMotion ? DS.Animation.fade : DS.Animation.gentleSpring) {
                    expanded.toggle()
                }
            } label: {
                Image(systemName: expanded ? "xmark" : "plus")
                    .font(DS.Typography.title2)
                    .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                    .frame(width: DS.Spacing.xxxl, height: DS.Spacing.xxxl)
                    .background(DS.Colours.accent)
                    .clipShape(Circle())
                    .shadow(
                        color: DS.Shadows.medium.color,
                        radius: DS.Shadows.medium.radius,
                        x: DS.Shadows.medium.x,
                        y: DS.Shadows.medium.y
                    )
            }
            .buttonStyle(.mnemoPressable)
            .accessibilityLabel(expanded ? "Close capture menu" : "Add memory")
            .accessibilityHint("Choose how to save a memory")
            .accessibilityIdentifier(AccessibilityID.Main.capture)
        }
        .animation(reduceMotion ? DS.Animation.fade : DS.Animation.gentleSpring, value: expanded)
    }
}

struct CaptureOptionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                Text(label)
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(DS.Colours.textPrimary)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.sm)
                    .background(DS.Colours.surfaceElevated)
                    .overlay {
                        RoundedRectangle(cornerRadius: DS.CornerRadius.medium)
                            .stroke(DS.Colours.borderSubtle, lineWidth: 1.0)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DS.CornerRadius.medium))
                    .shadow(
                        color: DS.Shadows.subtle.color,
                        radius: DS.Shadows.subtle.radius,
                        x: DS.Shadows.subtle.x,
                        y: DS.Shadows.subtle.y
                    )

                Image(systemName: icon)
                    .font(DS.Typography.headline)
                    .foregroundStyle(DS.ComponentTokens.PrimaryButton.foreground)
                    .frame(
                        width: DS.ComponentTokens.InputField.height,
                        height: DS.ComponentTokens.InputField.height
                    )
                    .background(color)
                    .clipShape(Circle())
            }
        }
        .buttonStyle(.mnemoPressable)
        .accessibilityLabel("\(label) memory")
        .accessibilityHint("Open \(label.lowercased()) capture")
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private var accessibilityIdentifier: String {
        switch label {
        case "Text":
            return AccessibilityID.CaptureText.open
        case "Voice":
            return "capture.voice.open"
        case "Camera":
            return "capture.camera.open"
        case "Photo":
            return "capture.photo.open"
        default:
            return AccessibilityID.Main.capture
        }
    }
}
