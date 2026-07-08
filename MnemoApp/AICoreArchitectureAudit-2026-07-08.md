# AI Core Architecture Audit - 2026-07-08

Branch: `ai-core-mlx-prototype`

This audit reframes Mnemo toward an AI-led on-device memory architecture while keeping the current TestFlight V1 deterministic recall loop stable. The existing MLX and Foundation Models files are placeholders: `MLXModelLoader.generate()` and `FoundationModelLoader.generate()` return `nil`, and `ModelRouter.answer()` returns a stub count response.

| Area | Current state | Problem | Target state | Risk |
| --- | --- | --- | --- | --- |
| Extraction | `ExtractionEngine` attempts Foundation Models and MLX hooks, then falls back to a low-confidence raw-input result. | Fallback is useful but can be mistaken for model extraction if copy or provenance overstates it. | Local model extracts summary, type, subject, entities, dates, locations, tags, confidence, and safety flags, then deterministic fallback handles unsupported devices. | Overclaiming active AI or hiding low-confidence fallback. |
| Embeddings | `EmbeddingHelper` uses deterministic character-frequency vectors; `VectorBridge` stores/searches local rows. | It is not semantic and should not drive AI product claims. | Use a small local embedding model first, with provider ID, version, dimensions, and local execution scope stored with every vector. | Model size, device memory, index migration, and dimension mismatch. |
| Recall | `RecallEngine` combines lexical scoring, rules, small synonyms, and source-grounded citations. | Rule growth is expensive and cannot cover natural language broadly. | `AIRecallPipeline` retrieves semantically, reranks with deterministic guards, validates citations, and falls back to `RecallEngine`. | False positives if embeddings outrank safety rules. |
| Answer composition | `ModelRouter.answer()` returns a stub; current Chat uses `RecallEngine`. | No local model composes source-grounded answers yet. | Local answer composer receives only retrieved snippets and returns JSON with answer, cited IDs, confidence, and unsupported claims. | Hallucinated facts or IDs unless validated before UI display. |
| Model routing | `FoundationModelLoader` and `MLXModelLoader` are stubs. `CapabilityDetector.checkMnemoMLX()` returns true. | Capability state can overstate readiness. | Flags plus real capability checks: framework availability, model asset presence, memory budget, battery/thermal state, and user consent for downloads. | App Review and user trust risk if unavailable features appear active. |
| Device capability | Coarse capability detector exists. | It cannot yet confirm real model assets or safe runtime conditions. | Gate AI by device, OS, model availability, memory pressure, thermal state, battery, and Reduce Motion/Low Power constraints where relevant. | Crashes or hangs on lower-memory devices. |
| Privacy | Current V1 is local-first, no account, no cloud LLM. Backup uses user iCloud. | Foundation Models can include on-device and Private Cloud Compute paths; MLX models may require download consent. | Default to local-only. Treat any model download or non-local execution as explicit, documented user choice. | Unsupported AI/privacy claims. |
| TestFlight safety | Main branch V1 is deterministic, source-card-backed, and iPhone-only. | AI work can destabilise the validated loop if wired directly. | AI Core flags default off; `AIRecallPipeline` falls back to `RecallEngine` until model paths pass device and citation tests. | Internal testers may confuse prototype branch with TestFlight behavior. |

## External References Used
- Apple Developer Apple Intelligence overview: Foundation Models supports on-device Apple models, Private Cloud Compute, and providers conforming to the Language Model protocol.
- MLX Swift README: MLX Swift can be added as a Swift package, but command-line SwiftPM cannot build Metal shaders for the final app path; Xcode/xcodebuild validation is required.
