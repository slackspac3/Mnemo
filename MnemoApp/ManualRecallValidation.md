# Mnemo Manual Recall Validation

Use this script before each launch candidate. Start from a clean simulator or use Settings -> Delete All Data before seeding.

## Seed Memories

Create each memory through text capture and confirm it appears in Browse:

1. My blue suit size at Zara is 42.
2. Mum wears size 38 shoes.
3. I always forget to buy dishwasher tablets.
4. The Guam waterfall I liked was Tarzan Falls.
5. My dermatologist recommended La Roche-Posay Cicaplast.
6. For Gamma, I decided to cancel because I am travelling.
7. Ahmed prefers quiet restaurants.
8. The ACME forum winners need to be announced soon.

## Recall Queries

Ask these in Chat after all seed memories are saved.

| Query | Expected result | Source expectation |
| --- | --- | --- |
| What size does mum wear? | Returns the mum shoe-size memory, preferably answering size 38. | Shows the "Mum wears size 38 shoes." source card. |
| What did I decide about Gamma? | Returns the Gamma cancellation memory. | Shows the Gamma source card. |
| Which waterfall did I like in Guam? | Returns Tarzan Falls or the full Guam waterfall memory. | Shows the Guam waterfall source card. |
| What do I always forget to buy? | Returns dishwasher tablets. | Shows the dishwasher tablets source card. |
| Where was the waterfall? | Returns the Guam/Tarzan Falls waterfall memory. | Shows the Guam waterfall source card. |
| What did I save most recently? | Returns the ACME forum winners memory. | Shows the ACME source card. |
| Update that to size 39. | After asking mum's size, updates that cited memory to size 39. | Shows the updated mum source card. |
| What does Ahmed prefer? | Returns quiet restaurants. | Shows the Ahmed source card. |
| What is my passport number? | Fails gracefully; no fabricated answer. | Shows no source card. |

## Observed In This Pass

- Text, voice, image, and restore paths now index memories through `MemoryCRUD`.
- Chat responses carry cited memory IDs and source summaries.
- Chat UI shows source cards under cited answers and opens the memory detail when tapped.
- Individual permanent delete removes the SwiftData record and its vector index row.
- Package tests cover insert-and-index, permanent delete index cleanup, and index rebuild.

## Known Limits

- Recall is deterministic keyword plus placeholder-vector scoring, not production semantic retrieval.
- Some answers may quote the correct memory instead of fully synthesising a natural sentence.
- There is no app UI test target yet, so this script remains a manual simulator/device checklist.
