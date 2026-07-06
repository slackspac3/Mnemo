import SwiftUI
import MnemoUI

/// Floating capture button that presents the capture type selector.
struct CaptureButton: View {

    @Environment(NavigationCoordinator.self) private var coordinator
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
                        color: DS.Colours.primary
                    ) {
                        expanded = false
                        coordinator.present(.captureText)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            Button {
                withAnimation(DS.Animation.spring) {
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
        }
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
                    .background(DS.Colours.surface)
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
    }
}
