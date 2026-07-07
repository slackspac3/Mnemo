# Mnemo Manual Recall Validation

Use this field sheet before each launch candidate. Start from a clean simulator or use Settings -> Delete All Data before seeding. The goal is to measure whether Mnemo feels reliable with realistic personal memories, not to prove that every future intelligence feature exists.

## Pass Metadata

| Field | Value |
| --- | --- |
| Build / commit |  |
| Device / simulator |  |
| Tester |  |
| Date |  |
| Starting state | Clean install / Delete All Data / Existing data |

## Outcome Labels

Use one outcome per query:

- `pass`: correct answer and correct cited memory.
- `wrong-answer`: cited memory may be right, but the answer text is wrong.
- `wrong-source`: answer may look plausible, but cited memory is wrong.
- `no-match`: Mnemo failed to find a memory that should have matched.
- `false-positive`: Mnemo answered when it should have said no match.
- `confusing`: technically correct, but wording or source display reduces trust.

## Seed Memories

Create these through a realistic mix of text, voice, camera, and photo capture. Confirm each saved memory appears in Browse before running recall queries.

| ID | Suggested source | Memory to save |
| --- | --- | --- |
| M01 | Text | My blue suit size at Zara is 42. |
| M02 | Text | Mum wears size 38 shoes. |
| M03 | Voice | I always forget to buy dishwasher tablets. |
| M04 | Photo | The Guam waterfall I liked was Tarzan Falls. |
| M05 | Text | My dermatologist recommended La Roche-Posay Cicaplast. |
| M06 | Text | For Gamma, I decided to cancel because I am travelling. |
| M07 | Voice | Ahmed prefers quiet restaurants. |
| M08 | Text | The ACME forum winners need to be announced soon. |
| M09 | Text | The board paper needs to be submitted in two weeks. |
| M10 | Text | My preferred hotel room is away from the lift. |
| M11 | Camera | My passport is in the top drawer of the study desk. |
| M12 | Text | My regular T-shirt size at Zara is M. |
| M13 | Text | My loose-fit T-shirt size at Zara is S. |
| M14 | Voice | Nora's birthday gift idea is a Kindle case. |
| M15 | Text | The Wi-Fi password at the beach house is ReefSunset42. |
| M16 | Photo | The parking spot at Dubai Mall was P3, row C18. |
| M17 | Text | I liked the salmon starter at Orfali Bros. |
| M18 | Voice | Call the dentist after the insurance approval arrives. |
| M19 | Text | The invoice from BluePeak needs to be paid by Thursday. |
| M20 | Text | I decided not to renew the trial for Notion AI. |
| M21 | Camera | The spare car key is in the black pouch. |
| M22 | Text | Dad prefers aisle seats on long flights. |
| M23 | Voice | The plumber said the water pressure valve needs replacing. |
| M24 | Text | For the podcast launch, publish the teaser before the guest announcement. |
| M25 | Text | My gym locker code is 2806. |
| M26 | Photo | The hotel breakfast I liked had shakshuka and strong coffee. |
| M27 | Text | My tailor appointment is next Tuesday at 4 PM. |
| M28 | Voice | When buying candles, choose cedar or fig, not vanilla. |
| M29 | Text | Sarah said the workshop budget cap is 15,000 AED. |
| M30 | Text | The backup hard drive is labelled Mnemo Archive. |

## Recall Query Sheet

Ask these in Chat after all seed memories are saved. Record the actual answer and actual cited source exactly enough to diagnose failures.

| # | Query | Expected answer | Expected source | Actual answer | Actual source | Outcome | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Q01 | What size does mum wear? | Size 38 shoes. | M02 |  |  |  |  |
| Q02 | What did I decide about Gamma? | Cancel because I am travelling. | M06 |  |  |  |  |
| Q03 | Which waterfall did I like in Guam? | Tarzan Falls. | M04 |  |  |  |  |
| Q04 | What do I always forget to buy? | Dishwasher tablets. | M03 |  |  |  |  |
| Q05 | Where was the waterfall? | Guam, ideally with Tarzan Falls if available. | M04 |  |  |  |  |
| Q06 | What did I save most recently? | The backup hard drive is labelled Mnemo Archive. | M30 |  |  |  |  |
| Q07 | When is the board paper due? | Two weeks from the saved date. | M09 |  |  |  |  |
| Q08 | What does Ahmed prefer? | Quiet restaurants. | M07 |  |  |  |  |
| Q09 | What hotel room do I prefer? | Away from the lift. | M10 |  |  |  |  |
| Q10 | What skincare did the dermatologist recommend? | La Roche-Posay Cicaplast. | M05 |  |  |  |  |
| Q11 | Where is my passport? | Top drawer of the study desk. | M11 |  |  |  |  |
| Q12 | What is my Zara regular T-shirt size? | M. | M12 |  |  |  |  |
| Q13 | What is my Zara loose-fit T-shirt size? | S. | M13 |  |  |  |  |
| Q14 | What gift idea did I save for Nora? | A Kindle case. | M14 |  |  |  |  |
| Q15 | What is the beach house Wi-Fi password? | ReefSunset42. | M15 |  |  |  |  |
| Q16 | Where did I park at Dubai Mall? | P3, row C18. | M16 |  |  |  |  |
| Q17 | What did I like at Orfali Bros? | The salmon starter. | M17 |  |  |  |  |
| Q18 | Who should I call after insurance approval? | The dentist. | M18 |  |  |  |  |
| Q19 | When does the BluePeak invoice need paying? | By Thursday. | M19 |  |  |  |  |
| Q20 | What trial did I decide not to renew? | Notion AI. | M20 |  |  |  |  |
| Q21 | Where is the spare car key? | In the black pouch. | M21 |  |  |  |  |
| Q22 | What seat does Dad prefer on long flights? | Aisle seats. | M22 |  |  |  |  |
| Q23 | What did the plumber say needs replacing? | The water pressure valve. | M23 |  |  |  |  |
| Q24 | What should happen before the podcast guest announcement? | Publish the teaser. | M24 |  |  |  |  |
| Q25 | What is my gym locker code? | 2806. | M25 |  |  |  |  |
| Q26 | What hotel breakfast did I like? | Shakshuka and strong coffee. | M26 |  |  |  |  |
| Q27 | When is my tailor appointment? | Next Tuesday at 4 PM. | M27 |  |  |  |  |
| Q28 | What candle scent should I choose? | Cedar or fig, not vanilla. | M28 |  |  |  |  |
| Q29 | What is the workshop budget cap? | 15,000 AED. | M29 |  |  |  |  |
| Q30 | What is the backup hard drive labelled? | Mnemo Archive. | M30 |  |  |  |  |
| Q31 | Where should I take Ahmed for dinner? | Quiet restaurants, or a cautious answer citing Ahmed's preference. | M07 |  |  |  |  |
| Q32 | What shopping thing do I keep forgetting? | Dishwasher tablets. | M03 |  |  |  |  |
| Q33 | Which skincare product was recommended? | La Roche-Posay Cicaplast. | M05 |  |  |  |  |
| Q34 | Did I renew Notion AI? | No, I decided not to renew it. | M20 |  |  |  |  |
| Q35 | What room should I ask for at a hotel? | Away from the lift. | M10 |  |  |  |  |
| Q36 | What size is my blue suit? | 42. | M01 |  |  |  |  |
| Q37 | What did Sarah say about the workshop? | Budget cap is 15,000 AED. | M29 |  |  |  |  |
| Q38 | What needs to be announced soon? | ACME forum winners. | M08 |  |  |  |  |
| Q39 | What should I avoid when buying candles? | Vanilla. | M28 |  |  |  |  |
| Q40 | What should I do for the podcast launch first? | Publish the teaser before the guest announcement. | M24 |  |  |  |  |
| Q41 | Update that to size 39. | After Q01, updates Mum's shoe-size memory to 39. | M02 |  |  |  |  |
| Q42 | What size does mum wear now? | Size 39 shoes after the update. | M02 |  |  |  |  |
| Q43 | Update it to cedar only. | After Q28, updates candle preference to cedar only. | M28 |  |  |  |  |
| Q44 | What candle scent should I choose now? | Cedar only after the update. | M28 |  |  |  |  |
| Q45 | What is my passport number? | Graceful no-match. | None |  |  |  |  |
| Q46 | What is Ahmed's birthday? | Graceful no-match. | None |  |  |  |  |
| Q47 | Where did I leave my sunglasses? | Graceful no-match. | None |  |  |  |  |
| Q48 | What is the Wi-Fi password at home? | Graceful no-match unless beach house context is clearly used. | None or M15 if phrased cautiously |  |  |  |  |
| Q49 | Delete the Zara regular T-shirt memory, then ask: what is my Zara regular T-shirt size? | No match or only loose-fit size with clear caveat. | None or M13 with caveat |  |  |  |  |
| Q50 | Delete all data, then ask: what did I save most recently? | Says there are no saved memories. | None |  |  |  |  |

## Source Card Checks

Run these while answering the query sheet:

- Source cards appear only when Mnemo uses a memory.
- Source cards show the right memory summary or quoted line.
- Tapping a source opens the matching memory detail.
- Multiple source cards appear only when Mnemo genuinely needs multiple memories.
- A no-match answer does not show stale source cards from a previous answer.
- After permanent delete, the deleted memory no longer appears in Browse, Chat recall, or source cards.

## Summary Metrics

Fill these after the pass.

| Metric | Count |
| --- | --- |
| Total queries | 50 |
| Pass |  |
| Wrong answer |  |
| Wrong source |  |
| No match when expected match |  |
| False positive |  |
| Confusing wording/source display |  |
| Permanent delete failures |  |
| App crashes |  |

## Tuning Rule

Do not tune `RecallEngine` from guesses. Tune it from this sheet:

1. Fix crashers and privacy failures first.
2. Fix wrong-source and false-positive failures before adding broader synonyms.
3. Add synonyms only when at least two observed queries need the same expansion.
4. Prefer clearer no-match wording over a weak guessed answer.
5. Keep docs and App Review copy aligned with what this validation proves.

## Known Limits

- Recall is deterministic keyword plus placeholder-vector scoring, not production semantic retrieval.
- Some answers may quote the correct memory instead of fully synthesising a natural sentence.
- Dates based on relative phrases depend on the saved memory date and should be verified manually.
- Voice recognition can behave differently in Simulator and on physical iPhone.
- There is no app UI test target yet, so this script remains a manual simulator/device checklist.
