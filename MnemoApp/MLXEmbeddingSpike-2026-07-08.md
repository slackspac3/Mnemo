# MLX Embedding Spike - 2026-07-08

## Context

This branch starts from `ai-core-mlx-prototype` at `bb0cdf9`.
AI Core flags remain off by default, deterministic recall remains the active
TestFlight-safe behavior, and no MLX Swift dependency or model asset is bundled.

## What This Spike Adds

| Area | Decision | Result |
| --- | --- | --- |
| Provider boundary | Add a small `EmbeddingProvider` protocol before adding MLX Swift. | Existing embedding call sites can keep using `EmbeddingHelper`, while future MLX providers expose model ID, version, dimensions, and execution scope. |
| Current provider | Keep deterministic character-frequency vectors as the default. | V1 behavior stays unchanged. |
| MLX provider | Add `MLXEmbeddingProvider` as a fail-closed spike boundary only. | It does not import MLX, load assets, run inference, or make AI claims. |
| Dimension safety | Do not score vectors with mismatched dimensions. | Vector search avoids returning rows from a future incompatible model migration. |
| Tests | Add provider and dimension-mismatch tests. | The branch proves the safety boundary without requiring MLX runtime setup. |

## What Is Still Not Real

- No MLX Swift package dependency is added.
- No embedding model is bundled or downloaded.
- No Metal shader build path is validated.
- No semantic embedding replaces the deterministic provider.
- No app UI advertises MLX or AI Core.
- No cloud LLM, Foundation Models generation, sign-up, StoreKit, or backend auth is added.

## Next Step

Pick a licensed, compact embedding model and decide whether it ships bundled,
as On-Demand Resources, or as an explicit user-approved download. Only then add
MLX Swift and validate with an Xcode app build on simulator and physical iPhone,
because SwiftPM package tests alone do not prove the app's Metal shader path.
