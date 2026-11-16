# Recipe source audit — 2026-11-16

## Result

Compare acquisition datasets before importing them. Exact spell-ID overlap is useful for joining records; it does not verify learnability or acquisition in Forever.

- Addon baseline: `recipe-finder` commit `d8a6d789b7d4b74af3be61fdebafee16e9709e19`, catalog build 70862.
- MTSL baseline: commit `3013343bc4968d56db64dc5396ad1d97211538ba`.
- CraftLib inspected files on main; observed head `ec2fb99b1e81a06bfab91ca46be016e900ce1427`.
- No third-party dataset was imported into runtime files.
- Cooking pilot: the existing 30 curated entries each match exactly one Cooking candidate by English name. Bind these existing entries to those spell IDs, retaining name aliases. This improves lookup identity; it does not add or reverify source facts.
- Runtime integration already prefers numeric recipe-source keys. Its source detail UI remains compatible.

## Exact spell-ID overlap with MTSL

| Profession | Forever candidates | MTSL records | Matching candidates |
|---|---:|---:|---:|
| Alchemy | 196 | 111 | 105 |
| Blacksmithing | 506 | 239 | 233 |
| Cooking | 132 | 81 | 81 |
| Enchanting | 264 | 151 | 151 |
| Engineering | 272 | 164 | 164 |
| First Aid | 32 | 13 | 13 |
| Leatherworking | 592 | 233 | 233 |
| Tailoring | 471 | 226 | 226 |
| Total | 2465 | 1218 | 1206 |

Counts are records, not verified learnable recipes. Unmatched records are not automatically Forever additions; they can include utility spells, removed content, or candidates needing review.

## Cooking results

- Forever catalog: 132 candidate records.
- MTSL: 81 Cooking skill records; all 81 match catalog spell IDs. Its item table has 70 Cooking recipe-item records.
- CraftLib source JSON: 90 Cooking records; 88 match catalog spell IDs. 44 catalog candidates have no CraftLib match.
- Existing addon metadata: 30 unique Cooking entries, all uniquely name-matched to catalog spell IDs; 102 candidates have no curated metadata entry.
- All 88 shared CraftLib records have yellow/gray values equal to the catalog's raw low/high values. This agreement is not proof of learning requirements or Forever correctness.
- Learning-value conflicts: Goldthorn Tea (13028), MTSL 125 versus CraftLib 175; starter recipes Roasted Boar Meat (2540) and Charred Wolf Meat (2538), MTSL 1 versus CraftLib learnedAt 0. Do not treat 0 as a normal required-skill value without interpreting starter behavior.
- Acquisition conflict: CraftLib marks Slitherskin Mackerel (7752) as TRAINER with DB2 certainty, whereas MTSL links it to recipe item 6326. Resolve with Forever observations or a verified Forever reference. Do not import an inferred “Any Cooking Trainer” label as a verified NPC relationship.
- Raw catalog acquisition codes are not decoded or promoted into source types.

## Dataset selection and reuse

| Dataset | Observed contents | Reuse status | Decision |
|---|---|---|---|
| [MTSL](https://github.com/makoshark2001/MissingTradeSkillsList) | Spell IDs, min_skill, trainer IDs, recipe item IDs; item records provide vendor/drop/quest paths; NPC and zone tables available | No LICENSE/COPYING/COPYRIGHT-named file found in inspected tree; no permission inferred | Good structural reference; obtain explicit reuse terms before bundling |
| [CraftLib](https://github.com/kaldown/CraftLib) | Learning and difficulty fields, source categories, reagents, output IDs, provenance | LICENSE says All Rights Reserved, copyright 2026 Bogdan Osinnyi | Do not copy into addon without permission |
| [Playground JSON](https://playautotechnologies.org/data/forever-recipes.json) | Endpoint resolves; exposed note describes Wowhead Forever listings, four color thresholds, and change status | Index states CC BY 4.0 for its arrangement; upstream sources retain their terms | Full JSON payload was not exposed by available retrieval; coverage and source relationships NOT audited |
| [Playfulls](https://playfulls.com/database?cat=recipe) | Site advertises Forever client/server-update item sources | No bulk-export reuse permission established | Request a structured export and applicable reuse terms before import |

Public visibility is not a redistribution license. No messages were sent to maintainers.

## Proposed normalized import structure

Use a spell-ID-keyed recipe record with separate entities:

- recipe: spellID, professionSkillLineID, outputItemIDs, recipeItemIDs.
- learning: requiredSkill plus evidence; do not derive it from raw skill-up low/high.
- difficulty: orange, yellow, green, gray plus build and evidence.
- acquisitions[]: type (trainer/vendor/drop/quest/reputation/starter/object/unknown), npcID/questID/objectID where applicable, recipeItemID, faction restrictions, reputation requirements, cost/stock, location references, and evidence.
- NPC directory: NPC ID, localized names, faction, map ID and coordinate positions with their own evidence.
- evidence: source URL, source snapshot/build, observed date, status (classic_reference/forever_documented/forever_observed/unverified/conflicting).

Recipe item IDs and crafted output item IDs must remain distinct. Support multiple acquisition routes. Mark verification per claim, not once for an entire recipe. Name matching is a review aid; persist only checked IDs.

## Import and verification gates

1. Secure reusable structured data or permission; inspect full Forever JSON outside the restricted retrieval path.
2. Pin source snapshots and preserve attribution.
3. Match spell IDs; validate profession, output IDs, and recipe-item-to-learned-spell relationships.
4. Report missing/duplicate IDs and conflicting requirements/source types instead of overwriting.
5. Preserve independently observed learned status. Acquisition imports must never mark recipes learned or missing.
6. Validate a trainer, vendor, world drop, quest, reputation, and Forever-only recipe in game before enabling new metadata broadly.

## Validation performed

Parsed all eight catalog profession sections and MTSL skill sections with a brace/string-aware extractor; compared numeric spell IDs without executing upstream Lua. Parsed CraftLib source JSON. Verified 30 existing source names map one-to-one to unique numeric Cooking IDs and checked the migration preserves the previous metadata arguments. No Lua interpreter or WoW client is available in this session, so runtime/in-game validation remains outstanding.

## Sources inspected

- [Addon catalog](https://github.com/branden-butler/WoW-Forever-Addons/blob/d8a6d789b7d4b74af3be61fdebafee16e9709e19/ProfessionBarsForever/CatalogData.lua)
- [MTSL skills](https://github.com/makoshark2001/MissingTradeSkillsList/blob/3013343bc4968d56db64dc5396ad1d97211538ba/data/skills.lua), [items](https://github.com/makoshark2001/MissingTradeSkillsList/blob/3013343bc4968d56db64dc5396ad1d97211538ba/data/items.lua)
- [CraftLib license](https://github.com/kaldown/CraftLib/blob/ec2fb99b1e81a06bfab91ca46be016e900ce1427/LICENSE), [Cooking source JSON](https://github.com/kaldown/CraftLib/blob/ec2fb99b1e81a06bfab91ca46be016e900ce1427/Data/Sources/Vanilla/Cooking.json)
- [Playground terms/index](https://playautotechnologies.org/open-data)
