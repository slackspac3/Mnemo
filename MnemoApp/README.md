# Mnemo

Mnemo is a native SwiftUI memory capture and recall app for iPhone. The app is built as a thin iOS shell backed by local Swift packages for memory storage, capture, intelligence, sync, security, and shared UI.

## Current State

Mnemo currently supports:

- Text memory capture into SwiftData.
- Voice capture with live audio recording and speech-recognition fallback handling.
- Image OCR capture using Apple Vision.
- Local memory browsing.
- Local chat recall over saved memories.
- Local SQLite-backed placeholder vector indexing.
- CloudKit backup and restore hooks using the user's own iCloud account.
- Optional local App Lock using Apple LocalAuthentication.
- Keychain, Secure Enclave, LocalAuthentication, file protection, and secure deletion helper layers.

Mnemo does not yet ship a production Foundation Models or MLX embedding model. The current vector embedding is deterministic placeholder logic intended to keep the app functional until the model assets are bundled.

## Repository Layout

```
Mnemo/
├── MnemoApp/              # Xcode app project and iOS app target
│   ├── Mnemo/             # SwiftUI app screens and app lifecycle
│   └── Config/            # XCConfig and entitlements
├── MnemoCore/             # Shared model enums, DTOs, and error types
├── MnemoMemory/           # SwiftData models, memory CRUD, vector bridge
├── MnemoCapture/          # Text, voice, and image capture handlers
├── MnemoIntelligence/     # Extraction, routing, scoring, learning engines
├── MnemoSecurity/         # Keychain, Secure Enclave, LocalAuthentication, file protection
├── MnemoSync/             # Backup and restore support
└── MnemoUI/               # Shared design system and reusable UI components
```

## Build Commands

Run package checks from the repo root:

```sh
for package in MnemoCore MnemoSecurity MnemoMemory MnemoCapture MnemoIntelligence MnemoSync MnemoUI; do
  (cd "$package" && swift build)
done
```

Run package tests where available:

```sh
Scripts/run_local_checks.sh fast
```

Run the slower local efficiency baseline:

```sh
Scripts/run_local_checks.sh efficiency
```

Build and run the app from `MnemoApp/Mnemo.xcworkspace` with the `Mnemo` scheme. The workspace is required because it includes the local Swift packages used by the app target.

If XcodeBuildMCP is installed, the app smoke build can also be run from the repo root:

```sh
MNEMO_SIMULATOR_ID=<simulator-udid> Scripts/run_local_checks.sh app
```

## Development Notes

- Prefer small, package-scoped changes with package builds before app builds.
- App screens can use SwiftUI state directly or `@Observable` UI state objects when state needs to be shared across a multi-screen flow.
- Business logic belongs in package services and actors, not in large SwiftUI views.
- Use `ManualRecallValidation.md` before tuning recall so changes are driven by observed failures.
- Use `AutomatedTestingPlan-2026-07-07.md` and `EfficiencyBaseline-2026-07-07.md` before changing recall, indexing, archive/delete, or source citation behavior.
- Keep privacy and App Review notes factual. Do not claim bundled Foundation Models, MLX embeddings, or cloud LLM processing until those code paths are active and tested.

## Known Gaps

- Recall is local and deterministic; production semantic recall still needs a real embedding model or hybrid keyword/vector search.
- Foundation Models and MLX routes are present as architecture hooks, not production model execution paths.
- Voice recognition in Simulator can receive microphone audio while Apple Speech fails to initialise. Validate voice capture on a physical iPhone before submission.
- App Lock uses Face ID, Touch ID, or device passcode through LocalAuthentication. Validate on a physical iPhone before submission.
- App Store metadata, screenshots, privacy policy URL, support URL, and legal/account setup remain manual pre-submission work.
