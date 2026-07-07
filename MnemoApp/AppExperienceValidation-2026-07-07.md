# App Experience Validation - 2026-07-07

## Build Tested

| Item | Value |
| --- | --- |
| Base commit | `89f1f8c` (`Extract parking location details`) |
| Validation state | Working tree with V1 app-experience fixes from this pass |
| Simulator | iPhone 17 Pro, iOS 26.4 |
| Simulator UDID | `8F8259E7-F4C0-472A-833D-CD9BCD443425` |
| Physical device | Not available in this run |
| iCloud account | Not validated in this run |

## Flow Results

| Flow | Environment | Expected | Actual | Outcome | Notes |
| --- | --- | --- | --- | --- | --- |
| Text capture -> Browse | Simulator | Saved memory appears | Saved `Mum wears size 38 shoes.` and it appeared in Browse | Pass | Confirmation screen showed `Review suggested` instead of low-confidence percentage copy. |
| Text capture -> Chat recall | Simulator | Correct answer with source | `What size does mum wear?` returned the correct Mum size answer with source cards | Pass with note | Existing simulator data caused extra source-card noise; primary answer and cited memory were correct. |
| Source card tap-through | Simulator | Opens correct memory | Tapping the Mum source card opened `MemoryDetailView` for that memory | Pass | Source card displayed the source type (`Text`) and summary. |
| Voice capture | Physical device required | Transcript saved and recalled | Not validated on physical device | Pending | Simulator Speech recognition is not a reliable launch signal. Physical iPhone validation remains required. |
| Camera OCR | Physical device required | OCR memory saved and recalled | Not validated on physical device | Pending | Camera permission, camera capture, OCR quality, and source-card recall still need physical iPhone validation. |
| Chat update Q41-Q44 | Simulator | Last cited memory updates correctly | Initial run exposed a bug; after fix, `Update that to size 41.` updated only the cited Tania memory and follow-up recall returned 41 | Pass after fix | Parser now accepts `to size N`; updates use the immediately preceding assistant source, primary cited memory only. |
| Archive from Browse | Simulator / source detail | Hidden from Browse and recall | Source-card detail archive hid the Tania memory from recall | Pass with follow-up fix | After archive, a person-specific size query borrowed unrelated size memories. Added a guard so missing person-size memories fail gracefully. Browse uses the same detail/delete callbacks but was not separately tapped in this pass. |
| Permanent delete from Browse | Simulator / Device | Removed from store and index | Implementation audited; not manually exercised in this run | Pending hands-on | `MemoryCRUD.deletePermanently` removes SwiftData and vector index entries; UI now reports throwing errors instead of swallowing failures. Needs one hands-on delete pass before external testing. |
| Permanent delete from source card | Simulator / Device | Removed from store and index | Implementation audited; not manually exercised in this run | Pending hands-on | Source-card detail uses the same `MemoryDetailView` deletion flow. Needs one hands-on delete pass, including stale source-card behavior. |
| Delete All Data | Simulator / Device | Empty memory state | Settings flow audited; not executed in this run | Pending hands-on | Flow clears SwiftData and vector index; this pass also dismisses stale memory sheets before reset. Needs destructive hands-on validation on a disposable simulator/device. |
| Onboarding honesty | Simulator / source audit | No inactive feature overclaims | Copy no longer implies active cloud assist setup | Pass | `Future Cloud Assist` avoids implying a configured provider. |
| Settings honesty | Simulator / source audit | Cloud/Sense/AI copy accurate | `Local Recall Ready` describes current deterministic local recall | Pass | Inactive Sense features remain labelled as future/inactive. |
| iCloud backup | Physical device/iCloud required | Backup completes or pending documented | Not validated | Pending | Requires signed-in physical device or configured simulator account. Do not treat backup as launch-validated yet. |
| Restore | Physical device/iCloud required | Restore rebuilds local index | Not validated | Pending | Restore rebuild path exists, but end-to-end iCloud restore still needs device/account validation. |

## Bugs Found And Fixed

- Chat update parsing did not recognise `Update that to size 39`; it fell through to a generic rewrite and could replace the whole memory with `size 39.`.
- Last-cited updates could operate on too many cited memories. The app now uses the immediately preceding assistant answer and the primary cited memory.
- Text capture could be tapped repeatedly during save. The save button now disables while saving and trims input before storing.
- The text confirmation screen displayed `20% confident` for fallback extraction, which looked untrustworthy for simple facts. It now shows `Review suggested`.
- Source cards did not display source type clearly enough. They now show the memory source label.
- Archived-only state could still make the landing and recall surfaces look populated. Chat now counts active, unarchived records for those states.
- A person-specific size query after archive could answer from unrelated size memories. Recall now returns a no-match when the requested person's size is not saved.
- Settings and onboarding copy implied broader active processing than the current build supports. Copy now describes local deterministic recall and future cloud assist more accurately.
- Speech privacy copy implied on-device transcription. It now describes voice-note transcription without claiming a route.
- Vector index storage had no local security setup. The SQLite vector store now enables secure delete and applies file protection on device.
- Backup and model-loader comments overclaimed future cryptography/model paths. Comments now describe current Keychain-backed backup keys and stub model hooks accurately.

## Physical-Device Validation Still Required

- Microphone permission prompt, live recording, speech transcription, saved voice-memory recall, and source-card tap-through.
- Camera permission prompt, camera capture, photo library selection, Vision OCR quality, saved image-memory recall, and source-card tap-through.
- File protection behavior while the device is locked.
- iCloud backup and restore with a signed-in account, including restore index rebuild.
- Notification prompts should be checked to confirm inactive Memory Moments do not request notification access.

## Result

The simulator pass validates the core V1 loop for text memories: save, browse, ask, get the right answer, see the source, open the source, update the cited memory, and archive it. Physical-device capture and iCloud paths remain launch blockers until they are validated on real hardware/account setup.
