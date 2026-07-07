# Efficiency Baseline - 2026-07-07

These measurements are local guardrails for the current deterministic V1 loop. They are not production benchmarks.

## Environment

- Machine OS: macOS 26.5.1 (25F80)
- Xcode: 26.6 (17F113)
- Swift: 6.3.3
- Test command: `Scripts/run_local_checks.sh efficiency`
- Dataset: deterministic in-memory `MemoryRecord` fixtures plus synthetic records

## Thresholds

| Area | Guardrail |
| --- | --- |
| Manual recall fixture | 50/50 validation set remains passing |
| Recall over 1,000 memories | p95 under 750 ms, max under 1,500 ms |
| Vector search over 1,000 rows | max under 500 ms |
| Vector upsert baseline | 1,000 rows under 10,000 ms |
| Vector delete/wipe | each operation under 1,000 ms |

## RecallEngine Timings

Six representative queries were run against datasets of 30, 100, 500, and 1,000 memories.

| Memories | Average | p95 | Max | Outcome |
| --- | ---: | ---: | ---: | --- |
| 30 | 7.40 ms | 9.10 ms | 10.29 ms | Pass |
| 100 | 25.30 ms | 31.56 ms | 34.55 ms | Pass |
| 500 | 129.99 ms | 161.38 ms | 177.03 ms | Pass |
| 1,000 | 257.89 ms | 318.62 ms | 354.62 ms | Pass |

## VectorBridge Timings

Each dataset was inserted into a temporary SQLite vector database. Search timing is the average/max across ten searches.

| Rows | Upsert Total | Search Avg | Search Max | Delete One | Wipe | Outcome |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| 30 | 16.15 ms | 0.22 ms | 0.29 ms | 0.31 ms | 0.34 ms | Pass |
| 100 | 34.14 ms | 0.62 ms | 0.65 ms | 0.32 ms | 0.44 ms | Pass |
| 500 | 181.32 ms | 2.87 ms | 2.93 ms | 0.40 ms | 0.91 ms | Pass |
| 1,000 | 380.53 ms | 5.80 ms | 5.94 ms | 0.77 ms | 1.58 ms | Pass |

## Observations

- Recall remains linear over the in-memory candidate list. It is acceptable for V1 validation at 1,000 memories, but it should be revisited before assuming much larger local stores.
- `VectorBridge.search` loads and scores rows in process. The current SQLite row counts are fine for V1 testing, but this is not a production semantic vector index.
- The test vector database now resolves to temporary storage during SwiftPM tests, avoiding writes to app Application Support.
- Archive now removes a memory from the vector index, matching the product expectation that archived memories are hidden from Browse and Chat recall.

## Follow-Up Risks

- Add an app UI test target only when the launch flow has stable accessibility identifiers and onboarding hooks.
- Re-run this baseline after any recall-ranking, vector-storage, or SwiftData schema change.
- Physical-device timing for voice, camera, OCR, iCloud, and locked-device file protection is still pending.
