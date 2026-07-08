# MLX Runtime Smoke Test - 2026-07-08

## Summary

This branch links the official MLX Swift package into the Mnemo app target and adds a DEBUG-only runtime smoke diagnostic. It does not add an embedding model, model assets, model downloads, local LLM generation, Foundation Models generation, cloud LLM, or any user-facing AI claim.

## Linkage

| Area | Decision |
| --- | --- |
| Package | `https://github.com/ml-explore/mlx-swift.git` |
| Resolved version | `0.31.6` |
| Product linked | `MLX` only |
| Link location | `MnemoApp/Mnemo.xcodeproj` app target only |
| Local package linkage | `MnemoMemory`, `MnemoIntelligence`, `MnemoUI`, and other local packages do not link MLX |
| Duplicate-link risk | Reduced by linking MLX once in the app target rather than through a local framework package and the app |

## Smoke Diagnostic

`MnemoApp/Mnemo/MLXRuntimeSmokeTest.swift` defines a DEBUG-only smoke diagnostic:

- `isLinked`
- `operationSucceeded`
- `resultPreview`
- `errorMessage`
- `durationMs`

The physical-device code path performs a real MLX operation:

1. Create `MLXArray(1.0)`.
2. Create `MLXArray(2.0)`.
3. Add them.
4. Call `eval()`.
5. Read the scalar result with `item(Float.self)`.

The diagnostic is opt-in via the DEBUG launch argument:

```text
--run-mlx-runtime-smoke
```

Mnemo does not run this diagnostic during normal launch. Deterministic recall remains the default path.

## Simulator Result

An initial simulator attempt ran the real MLX operation during DEBUG app startup. On iPhone 17 Pro simulator, iOS 26.4, MLX aborted before returning a result with:

```text
libc++ Hardening assertion __s != nullptr failed: basic_string(const char*) detected nullptr
```

To keep DEBUG launches fail-closed, the simulator path now reports:

```text
MLX linked; simulator runtime smoke skipped
```

The app remains running and usable with MLX linked. Simulator validation therefore proves package linkage and app launch stability, but it does not prove MLX runtime execution.

## Physical iPhone Result

Physical device discovery found:

- Device: `Mr B`
- OS: `26.6`
- UDID: `FFE5C4A6-31E5-580B-83D3-CD05172A8F2D`

Physical iPhone validation passed after enabling the MLX package plugin and adding the DEBUG launch argument locally in Xcode:

```text
--run-mlx-runtime-smoke
```

The app built, signed locally, installed, launched on the physical iPhone, and ran a real MLX operation successfully:

```text
MLX runtime smoke: linked=true passed=true durationMs=718.17 preview="1 + 2 = 3.0" error="none"
Type: stdio
```

The operation was:

1. Create `MLXArray(1.0)`.
2. Create `MLXArray(2.0)`.
3. Add them.
4. Call `eval()`.
5. Read the scalar result with `item(Float.self)`.

Duration was `718.17 ms`.

This proves MLX Swift linked and executed a tiny runtime operation inside the Mnemo app target on device. It still does not load a model, generate embeddings, replace deterministic recall, or make any TestFlight-facing AI claim.

The simulator runtime operation remains guarded off because of the previous libc++ assertion described above. Signing changes, package plugin approval, and the DEBUG launch argument were local-only validation steps and were not committed.

## Build Validation

Package resolution passed after Xcode resolved MLX and transitive packages:

- `mlx-swift @ 0.31.6`
- `swift-argument-parser @ 1.8.2`
- `swift-numerics @ 1.1.1`

The MLX package requires Xcode's Metal Toolchain component. The first app build failed with:

```text
cannot execute tool 'metal' due to missing Metal Toolchain
```

After installing the Xcode Metal Toolchain component, this build passed:

```text
xcodebuild -workspace /Users/barora/Mnemo/MnemoApp/Mnemo.xcworkspace \
  -scheme Mnemo \
  -destination 'generic/platform=iOS' \
  -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Xcode emitted the existing AppIntents metadata warning:

```text
Metadata extraction skipped. No AppIntents.framework dependency found.
```

No MLX model assets or generated logs are committed.

## Why This Is Not Yet an Embedding Model

This smoke test proves the app can link MLX Swift and compile the MLX package through Xcode's iOS app build path. It does not:

- load an embedding model,
- generate semantic embeddings,
- alter `VectorBridge`,
- replace `CharacterFrequencyEmbeddingProvider`,
- change RecallEngine behavior,
- compose answers with a local LLM,
- expose any TestFlight-facing AI feature.

`MLXEmbeddingProvider` still fails closed without model assets. `CharacterFrequencyEmbeddingProvider` remains the default embedding provider.

## Rollback Plan

If MLX linkage becomes unstable:

1. Remove the `mlx-swift` package reference and `MLX` product from `MnemoApp/Mnemo.xcodeproj/project.pbxproj`.
2. Remove `MnemoApp/Mnemo/MLXRuntimeSmokeTest.swift`.
3. Remove the DEBUG launch-argument hook in `AppState.initialise()`.
4. Remove the MLX pins from `MnemoApp/Mnemo.xcworkspace/xcshareddata/swiftpm/Package.resolved`.
5. Re-run package checks and the app build.
