# Manual Recall Validation Results - 2026-07-07

## Pass Metadata

| Field | Value |
| --- | --- |
| Build / commit | `9767692986ec142594a21b990ec73536675d7418` |
| Device / simulator | RecallEngine runner on macOS 14 target, app simulator build checked separately |
| Tester | Codex |
| Date | 2026-07-07 |
| Starting state | Synthetic clean seed set from `ManualRecallValidation.md` |

## Summary Metrics

| Metric | Count |
| --- | ---: |
| Total queries | 50 |
| Pass | 44 |
| Wrong answer | 2 |
| Wrong source | 1 |
| No match when expected match | 0 |
| False positive | 2 |
| Confusing wording/source display | 1 |
| Permanent delete failures | 0 in simulated delete path |
| App crashes | 0 during app build/launch smoke check |
| Pass rate | 88% |

## Top 5 Failure Patterns

1. False positives on specific missing attributes: `passport number` matched the saved passport-location memory.
2. False positives on person-specific unknowns: `Ahmed's birthday` matched the saved Ahmed preference.
3. Context mismatch on location scope: `Wi-Fi password at home` matched `beach house` because password/Wi-Fi tokens dominated.
4. Variant conflict after delete: after deleting regular Zara size, recall used loose-fit Zara size without a strong enough caveat.
5. Update validation is only engine-simulated here; the full ChatViewModel last-cited update flow still needs a simulator UI pass.

## Scope Notes

- This pass uses the production `RecallEngine` and `MemoryRecord` model with the 30-memory validation fixture.
- Text/voice/photo/camera source labels are represented in memory records, but simulator microphone, camera, OCR, and source-card tap-through were not exhaustively operated by hand in this pass.
- Source-card UI still needs a physical-device pass because camera and voice behavior are not equivalent in Simulator.
- Q41 and Q43 were validated by simulating the intended last-cited update target from Q01 and Q28. They should be re-run in app UI before tuning update logic.

## Query Results

| # | Query | Expected answer | Expected source | Actual answer | Actual source | Outcome | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Q01 | What size does mum wear? | Size 38 shoes. | M02 | I found a couple of saved sizes. The most recent one says your Mum's shoe size is 38. | M02, M12, M01 | `pass` |  |
| Q02 | What did I decide about Gamma? | Cancel because I am travelling. | M06 | I found a few possible matches: 1. "For Gamma, I decided to cancel because I am travelling." 2. "I decided not to renew the trial for Notion AI." | M06, M20 | `pass` |  |
| Q03 | Which waterfall did I like in Guam? | Tarzan Falls. | M04 | I found a few possible matches: 1. "The Guam waterfall I liked was Tarzan Falls." 2. "I liked the salmon starter at Orfali Bros." 3. "The hotel breakfast I liked had shakshuka and strong coffee." | M04, M17, M26 | `pass` |  |
| Q04 | What do I always forget to buy? | Dishwasher tablets. | M03 | I found a few possible matches: 1. "I always forget to buy dishwasher tablets." 2. "When buying candles, choose cedar or fig, not vanilla." | M03, M28 | `pass` |  |
| Q05 | Where was the waterfall? | Guam, ideally with Tarzan Falls if available. | M04 | It was in Guam. | M04 | `pass` |  |
| Q06 | What did I save most recently? | The backup hard drive is labelled Mnemo Archive. | M30 | You most recently saved: "The backup hard drive is labelled Mnemo Archive." | M30 | `pass` |  |
| Q07 | When is the board paper due? | Two weeks from the saved date. | M09 | By July 20, 2026. I calculated that from "in two weeks" in the saved memory. | M09 | `pass` |  |
| Q08 | What does Ahmed prefer? | Quiet restaurants. | M07 | I found a few possible matches: 1. "Ahmed prefers quiet restaurants." 2. "Dad prefers aisle seats on long flights." 3. "Mum wears size 38 shoes." | M07, M22, M02 | `pass` |  |
| Q09 | What hotel room do I prefer? | Away from the lift. | M10 | I found a few possible matches: 1. "My preferred hotel room is away from the lift." 2. "The hotel breakfast I liked had shakshuka and strong coffee." 3. "Ahmed prefers quiet restaurants." | M10, M26, M07 | `pass` |  |
| Q10 | What skincare did the dermatologist recommend? | La Roche-Posay Cicaplast. | M05 | My dermatologist recommended La Roche-Posay Cicaplast. | M05 | `pass` |  |
| Q11 | Where is my passport? | Top drawer of the study desk. | M11 | It was in The Top Drawer Of The Study Desk. | M11 | `pass` |  |
| Q12 | What is my Zara regular T-shirt size? | M. | M12 | I found a couple of saved sizes. The most recent one says your Zara T-shirt size is M. | M12, M13, M01 | `pass` |  |
| Q13 | What is my Zara loose-fit T-shirt size? | S. | M13 | I found a couple of saved sizes. The most recent one says your Zara T-shirt size is S. | M13, M12, M01 | `pass` |  |
| Q14 | What gift idea did I save for Nora? | A Kindle case. | M14 | Nora's birthday gift idea is a Kindle case. | M14 | `pass` |  |
| Q15 | What is the beach house Wi-Fi password? | ReefSunset42. | M15 | The Wi-Fi password at the beach house is ReefSunset42. | M15 | `pass` |  |
| Q16 | Where did I park at Dubai Mall? | P3, row C18. | M16 | It was in Dubai Mall. | M16 | `wrong-answer` | Correct source but answer did not include expected fragment.  |
| Q17 | What did I like at Orfali Bros? | The salmon starter. | M17 | I found a few possible matches: 1. "I liked the salmon starter at Orfali Bros." 2. "The Guam waterfall I liked was Tarzan Falls." 3. "The hotel breakfast I liked had shakshuka and strong coffee." | M17, M04, M26 | `pass` |  |
| Q18 | Who should I call after insurance approval? | The dentist. | M18 | Call the dentist after the insurance approval arrives. | M18 | `pass` |  |
| Q19 | When does the BluePeak invoice need paying? | By Thursday. | M19 | The invoice from BluePeak needs to be paid by Thursday. | M19 | `pass` |  |
| Q20 | What trial did I decide not to renew? | Notion AI. | M20 | I found a few possible matches: 1. "I decided not to renew the trial for Notion AI." 2. "For Gamma, I decided to cancel because I am travelling." 3. "When buying candles, choose cedar or fig, not vanilla." | M20, M06, M28 | `pass` |  |
| Q21 | Where is the spare car key? | In the black pouch. | M21 | It was in The Black Pouch. | M21 | `pass` |  |
| Q22 | What seat does Dad prefer on long flights? | Aisle seats. | M22 | I found a few possible matches: 1. "Dad prefers aisle seats on long flights." 2. "Ahmed prefers quiet restaurants." | M22, M07 | `pass` |  |
| Q23 | What did the plumber say needs replacing? | The water pressure valve. | M23 | The plumber said the water pressure valve needs replacing. | M23 | `pass` |  |
| Q24 | What should happen before the podcast guest announcement? | Publish the teaser. | M24 | For the podcast launch, publish the teaser before the guest announcement. | M24 | `pass` |  |
| Q25 | What is my gym locker code? | 2806. | M25 | My gym locker code is 2806. | M25 | `pass` |  |
| Q26 | What hotel breakfast did I like? | Shakshuka and strong coffee. | M26 | I found a few possible matches: 1. "The hotel breakfast I liked had shakshuka and strong coffee." 2. "My preferred hotel room is away from the lift." 3. "I liked the salmon starter at Orfali Bros." | M26, M10, M17 | `pass` |  |
| Q27 | When is my tailor appointment? | Next Tuesday at 4 PM. | M27 | My tailor appointment is next Tuesday at 4 PM. | M27 | `pass` |  |
| Q28 | What candle scent should I choose? | Cedar or fig, not vanilla. | M28 | When buying candles, choose cedar or fig, not vanilla. | M28 | `pass` |  |
| Q29 | What is the workshop budget cap? | 15,000 AED. | M29 | Sarah said the workshop budget cap is 15,000 AED. | M29 | `pass` |  |
| Q30 | What is the backup hard drive labelled? | Mnemo Archive. | M30 | The backup hard drive is labelled Mnemo Archive. | M30 | `pass` |  |
| Q31 | Where should I take Ahmed for dinner? | Quiet restaurants, or a cautious answer citing Ahmed's preference. | M07 | I found a few possible matches: 1. "Ahmed prefers quiet restaurants." 2. "Mum wears size 38 shoes." | M07, M02 | `pass` |  |
| Q32 | What shopping thing do I keep forgetting? | Dishwasher tablets. | M03 | I found a few possible matches: 1. "When buying candles, choose cedar or fig, not vanilla." 2. "I always forget to buy dishwasher tablets." | M28, M03 | `wrong-source` | Expected M03, got M28, M03.  |
| Q33 | Which skincare product was recommended? | La Roche-Posay Cicaplast. | M05 | My dermatologist recommended La Roche-Posay Cicaplast. | M05 | `pass` |  |
| Q34 | Did I renew Notion AI? | No, I decided not to renew it. | M20 | I found a few possible matches: 1. "I decided not to renew the trial for Notion AI." 2. "For Gamma, I decided to cancel because I am travelling." | M20, M06 | `pass` |  |
| Q35 | What room should I ask for at a hotel? | Away from the lift. | M10 | I found a few possible matches: 1. "My preferred hotel room is away from the lift." 2. "The hotel breakfast I liked had shakshuka and strong coffee." | M10, M26 | `pass` |  |
| Q36 | What size is my blue suit? | 42. | M01 | I found a couple of saved sizes. The most recent one says your Zara size is 42. | M01, M13, M02 | `pass` |  |
| Q37 | What did Sarah say about the workshop? | Budget cap is 15,000 AED. | M29 | Sarah said the workshop budget cap is 15,000 AED. | M29 | `pass` |  |
| Q38 | What needs to be announced soon? | ACME forum winners. | M08 | The ACME forum winners need to be announced soon. | M08 | `pass` |  |
| Q39 | What should I avoid when buying candles? | Vanilla. | M28 | I found a few possible matches: 1. "When buying candles, choose cedar or fig, not vanilla." 2. "I always forget to buy dishwasher tablets." | M28, M03 | `pass` |  |
| Q40 | What should I do for the podcast launch first? | Publish the teaser before the guest announcement. | M24 | For the podcast launch, publish the teaser before the guest announcement. | M24 | `pass` |  |
| Q45 | What is my passport number? | Graceful no-match. | None | My passport is in the top drawer of the study desk. | M11 | `false-positive` | Expected no source, but cited M11.  |
| Q46 | What is Ahmed's birthday? | Graceful no-match. | None | I found a few possible matches: 1. "Ahmed prefers quiet restaurants." 2. "Nora's birthday gift idea is a Kindle case." 3. "Mum wears size 38 shoes." | M07, M14, M02 | `false-positive` | Expected no source, but cited M07, M14, M02.  |
| Q47 | Where did I leave my sunglasses? | Graceful no-match. | None | I could not find a saved memory that matched that. Try asking with a specific name, place, or detail you remember saving. | None | `pass` |  |
| Q48 | What is the Wi-Fi password at home? | Graceful no-match unless beach house context is clearly used. | None or M15 if phrased cautiously | The Wi-Fi password at the beach house is ReefSunset42. | M15 | `confusing` | Accepted by checklist, but answer needs caveat wording. Checklist allows M15 only if phrased cautiously. |
| Q41 | Update that to size 39. | After Q01, updates Mum's shoe-size memory to 39. | M02 | Updated simulated last cited memory M02 to: Mum wears size 39 shoes. | M02 | `pass` | Engine validation simulates the update target from Q01; full ChatViewModel update flow still needs UI/device validation. |
| Q42 | What size does mum wear now? | Size 39 shoes after the update. | M02 | I found a couple of saved sizes. The most recent one says your Mum's shoe size is 39. | M02, M13, M12 | `pass` |  |
| Q43 | Update it to cedar only. | After Q28, updates candle preference to cedar only. | M28 | Updated simulated last cited memory M28 to: When buying candles, choose cedar only. | M28 | `pass` | Engine validation simulates the update target from Q28; full ChatViewModel update flow still needs UI/device validation. |
| Q44 | What candle scent should I choose now? | Cedar only after the update. | M28 | When buying candles, choose cedar only. | M28 | `pass` |  |
| Q49 | Delete the Zara regular T-shirt memory, then ask: what is my Zara regular T-shirt size? | No match or only loose-fit size with clear caveat. | None or M13 with caveat | I found a couple of saved sizes. The most recent one says your Zara T-shirt size is S. | M13, M01, M02 | `wrong-answer` | Correct source but answer did not include expected fragment. Checklist allows M13 only with a caveat after M12 deletion. |
| Q50 | Delete all data, then ask: what did I save most recently? | Says there are no saved memories. | None | I do not have any saved memories yet. Save something first, then ask me again. | None | `pass` |  |

## Recommended Next Actions

1. Fix false positives by requiring stronger intent compatibility for sensitive attribute queries such as numbers, birthdays, passwords, and locations.
2. Add explicit mismatch handling for qualifier conflicts such as `home` vs `beach house`, and `regular` vs `loose-fit`.
3. Improve no-match confidence thresholds before expanding synonyms further.
4. Run Q41-Q44 through the actual chat UI to validate last-cited-memory update behavior.
5. Run a physical iPhone pass for voice capture, camera capture, OCR, source-card tap-through, and delete UI behavior.