# Automatic vendor observations (schema 1)

ProfessionBars silently collects local observations whenever the player opens a vendor shop. It reads available vendor inventory, without buying items, changing filters, opening NPCs, or reading buyback entries. Walking past an NPC does not reveal its shop.

## Commands

- `/pbfdata`: local collection status, stored count and capacity.
- `/pbfdata off`: disable collection without deleting existing observations.
- `/pbfdata on`: re-enable; collection starts on the next shop opening.
- `/pbfdata export [page]`: open a review/copy window. Ctrl+A and Ctrl+C copy the JSON page. Escape closes it. Each page contains up to 200 observations; export every page for a complete submission.

No desktop application, network transfer, upload endpoint or community database download is included. Nothing is automatically sent. Exports can be saved as JSON and submitted manually when a submission process is available.

## Saved data and future desktop client

The separate account-wide `PBFObservationDB` SavedVariable is stored in WoW's account SavedVariables file for ProfessionBarsForever, alongside the addon's other saved variables. WoW normally writes SavedVariables on logout, reload, or a clean exit; an unexpected crash can lose unsaved observations.

A future desktop uploader must parse only `PBFObservationDB`, validate this schema and its allowlist, and require explicit upload opt-in. It must NEVER upload the whole SavedVariables file: other addon variables can contain character and realm information. No uploader is implemented now.

## Export envelope

- `format`: `professionbars-observations`
- `schemaVersion`: 1
- `page`, `totalPages`, `storedRecords`: pagination metadata; export while collection is idle so page boundaries stay stable.
- `observations`: array of allowlisted vendor-item observations, including an empty array when no records exist.

## Observation fields

| Field | Meaning |
|---|---|
| kind / evidence | vendor_item / observed |
| clientVersion / clientBuild / interfaceVersion | Client context; do not combine incompatible builds blindly |
| locale | Language of NPC and item names |
| npcID / npcName | Numeric creature identity and game-provided NPC name; full GUID is discarded |
| itemID / itemName | Observed vendor item; raw item links are not stored |
| faction | Observing player's faction; no character identity |
| location | Optional mapID and x/y fractions (0–1), rounded to four decimals; positionType=observer |
| priceCopper | Observed copper cost per purchase bundle, potentially reputation-discounted |
| purchaseQuantity | Number of items in that purchase bundle |
| available | Observed remaining quantity; -1 means unlimited in the merchant API |
| purchasable | Whether the merchant API currently marks the item purchasable; not a decoded requirement |
| hasExtendedCost | If true, copper is not the full cost; currency/item cost breakdown is not collected in v1 |
| itemClassID / itemSubclassID / isRecipeItem | Optional cached classification; class 9 flags a recipe item, not its taught spell |
| firstSeen / lastSeen | Server timestamps for this distinct observation |
| observations | Number of shop visits in which this exact variant was seen, not unique contributors |

Unknown or unavailable fields are omitted. Observing position near the NPC is not an exact spawn coordinate. An item's presence does not prove universal availability, full requirements, a learned spell relationship, or a recipe's learned status. Prices are contextual observations, not canonical base prices. The collector never changes Recipe Finder learned/missing flags or promotes observations into bundled source facts.

## Merge and storage rules

An observation variant is keyed by a deterministic serialization of its allowlisted fields. Repeated event retries in the same shop visit do not inflate its count. Changed stock, price, classification, build, faction or observer position can create another variant. Missing entries never delete positive evidence. Item-data events and three bounded post-open retries can enrich uncached information while the shop remains open.

Storage is capped at 20,000 distinct variants. At capacity, known variants can still be refreshed but new ones are skipped; `/pbfdata` reports capacity. Nothing is silently evicted. Future schema versions are retained untouched and cannot be exported by an older collector. This is a prototype bound; downstream aggregation should group by build/NPC/item while preserving conflicting claims.

The export rebuilds every observation with an explicit allowlist. Character names, account identifiers, realm, full NPC GUIDs, chat, bags and arbitrary saved fields are absent. Local collection is on by default and can be disabled. Future uploading must be separately opt-in.

## Validation

`lua5.1 tests/vendor_observations.lua` mocks merchant events and both API shapes, including late item links, changed NPCs, closed shops, deduplication, stock variants, privacy filtering, pagination, capacity and future-schema retention. The GitHub Actions workflow also syntax-checks the module and parses an exported JSON fixture with Python.

In-game acceptance is still required on Forever:
1. Restart WoW after installing the new TOC, visit a vendor, and check `/pbfdata`.
2. Confirm a vendor with multiple pages records inventory without manually scanning.
3. Check a recipe vendor and limited-stock/out-of-stock item.
4. Close a shop immediately, visit another vendor, and confirm no cross-NPC records.
5. Export and inspect item/NPC IDs, contextual prices and optional observer location.
6. Reload, confirm records persist, then disable collection and verify no new records.
7. Confirm Recipe Finder's learned/missing status remains unchanged.
