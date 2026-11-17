# Recipe character-level requirements

Branch recipe-level-requirements, based on merged main a4956ee6e16889f617d52b283f3220abc0b97991.

## Labels and layout

Recipe Finder adds Learn Lvl immediately to the right of Skill. Skill remains the profession skill required to learn a recipe. Learn Lvl is the character learning level reported by the spell-level API. Hover its header for the full definition. Clicking the header switches to Flat view and uses the existing ascending/descending and Shift-click secondary sorting; unknown values remain last.

The details panel separately displays:
- Required skill
- Level required to learn
- Level required to use

The recipe/status columns are narrowed to fit the new column without crossing the list scrollbar. Group headers leave numeric columns blank.

## Learning level

C_Spell.GetSpellLevelLearned, or legacy GetSpellLevelLearned when the modern function is absent, supplies the reported character learning level. Positive numeric values are saved in the existing build/locale-scoped presentation record. Zero, missing results and errors remain unknown and do not erase previously reported values. No item level, crafted-item use requirement, profession rank or raw skill-up range is substituted.

Forever coverage must be checked in game: a callable spell API may not expose a useful level for every crafting recipe. The retail API documentation notes level-linking can affect its returned value; this is client-reported spell-level evidence, not an independently verified universal server rule. Unknown entries show ? in the column and Not reported by client in details.

## Output usage level

C_Item.GetItemInfo or legacy GetItemInfo supplies itemMinLevel (the fifth return value) for each actual output item ID in the client recipe catalog. itemLevel is a different field and is never used. A cached item with an explicit minimum of zero displays None. Missing information remains Not reported; missing output IDs do not imply no requirement.

Multiple outputs list their use levels separately. Item data is requested asynchronously, shares the existing item-load refresh handler, and successful readings are cached by build/locale for later and offline-character browsing. These values concern the output's character-level restriction; they do not establish class, reputation, profession or other use restrictions.

## Verification

Automated tests distinguish spell learning levels, output minLevel and itemLevel, check explicit zero vs unavailable values, modern/legacy adapters, preservation through incomplete responses, multiple outputs and async item completion. Existing grouping, character isolation, minimap and vendor tests remain enabled.

In game: compare a recipe's Learn Lvl with its training/learning requirement, then compare Level required to use against the crafted item's tooltip. Check an item with no use-level requirement and one whose use level differs from learning. Confirm sorting, grouped headers, column fit and saved-alt views.

## Finder category hydration

Opening a profession in Recipe Finder now attempts to load missing category/reagent presentation data directly for that profession's catalog spells. It does not open the native profession UI or use these queries to overwrite character learned status. If Forever has not loaded the requested data, Uncategorized remains until the client makes category information available; a native profession scan still supplements the same cache. Previously captured data within the same build/locale is retained on nil responses.


## Use-level column

Recipe Finder shows sortable Use Lvl beside Learn Lvl with tighter column spacing. Use Lvl reads output item minimum character level, independently of learn level. None means an explicit zero requirement; ? means unavailable or no identified output. Multiple outputs with different reported requirements show Varies (sorted with unknown values); details retain each output requirement. Item data completion refreshes the column automatically.


Category compatibility: category IDs are treated as opaque finite integers, including zero and negative IDs. Category ordering accepts both a table and multiple GetCategories return values, as used by Forever UI. Missing API results retain captured presentation data. In-game verification is still required for the reported First Aid/Cooking issue.
