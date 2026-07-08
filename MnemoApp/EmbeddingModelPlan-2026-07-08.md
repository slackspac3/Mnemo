# Embedding Model Plan - 2026-07-08

Recommendation: start with a small local embedding model before local answer generation. Semantic retrieval improves Mnemo's core loop more reliably than immediately adding a local generative model.

| Option | Expected model size | iPhone compatibility | Offline support | Latency risk | Privacy posture | App Store/TestFlight risk | Implementation complexity |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MLX Swift embedding model | Likely tens to hundreds of MB depending model and quantisation. Exact size must be measured with chosen model. | Best on newer Apple silicon iPhones; must gate by model asset presence, memory, thermal state, and OS. | Yes if bundled or downloaded with consent. | Medium; Metal shader and first-run load cost need Xcode/device profiling. | Strong if model and vectors stay local. | Medium; package, model assets, ODR/download consent, and shader build path must be validated. | High. Requires MLX package, model conversion/packaging, asset management, and app build validation. |
| Core ML embedding model | Tens of MB for compact sentence embedding models; depends conversion/quantisation. | Broad iOS support and App Store-friendly. | Yes when bundled or downloaded with consent. | Low to medium; Core ML tooling is mature. | Strong if local. | Lower than MLX, but model license and conversion quality must be checked. | Medium. Requires model selection/conversion and vector dimension migration. |
| Foundation Models | Unknown suitability for embeddings; Apple public positioning is language-model prompting, not necessarily embedding vectors. | Requires OS/device/language/region availability checks. | On-device where available; Private Cloud Compute paths must be treated separately. | Unknown for embedding-style usage. | Good only if constrained to on-device execution; PCC is not the same as local-only. | Medium; unsupported API use or overclaiming local-only would be risky. | Medium to high until exact API contract is validated in code. |
| Deterministic fallback | No model. Current 26-dimensional character-frequency vectors. | All supported devices. | Yes. | Low. | Strong local-only. | Low if described honestly as non-semantic. | Already implemented. |

## MLX Dependency Feasibility
MLX Swift can be added via Swift Package and linked with products such as `MLX` and `MLXNN`. The MLX Swift README states that command-line SwiftPM cannot build the Metal shaders for the final app path, so Xcode/xcodebuild validation is mandatory. For this reason, this branch does not add the dependency yet.

## Proposed First Implementation
1. Add `EmbeddingProvider` abstraction.
2. Keep current deterministic provider as default.
3. Extend vector metadata with provider ID, version, dimensions, and source modality.
4. Add dimension mismatch rejection and reindex-on-provider-change.
5. Add MLX embedding provider only after selecting a licensed model and validating app builds on device.

## Device Gates
- Model asset exists and version matches index metadata.
- Battery is not critically low.
- Device is not under severe thermal pressure.
- Available memory is above measured threshold.
- User has consented to any model download.
- Feature flag is enabled for internal/prototype builds.
