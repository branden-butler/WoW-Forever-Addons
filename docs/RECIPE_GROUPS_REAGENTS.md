# Recipe groups and reagents

Branch: recipe-groups-reagents, based on merged main 171cc698a9951b59ee6fd9752b0b60183784b908.

## Recipe Finder

The default view groups recipes under collapsible category headers. The client supplies categoryID, category name and uiOrder; GetCategories ordering is used when a category does not expose uiOrder. GetFilteredRecipeIDs supplies observed recipe ordering. Categories or recipes without observed order use a deterministic name/ID fallback; recipes without a named category appear under Uncategorized.

Use View: WoW Groups / View: Flat to switch. Existing search and status/source filters apply before grouping. Clicking a sort column switches to Flat so user sorting is honored. Collapsed headers remain visible with their matching-recipe count.

This is a first client-driven grouping implementation, not a bundled guessed taxonomy. It uses leaf categories; nested parent categories are retained as IDs for future expansion. Exact native ordering depends on which category/order APIs Forever exposes and the current native profession filter. No filters are changed and no collapsed native headers are expanded automatically.

## Collection and persistence

RecipeLayout captures metadata during normal profession scans, using the existing per-spell profession owners. Selecting a recipe also attempts a protected metadata query, which can work without opening professions when the client exposes it. A fresh install may need a profession opened once to populate presentation metadata that is not queryable in the background. Known/Missing still uses the independent character store.

Metadata is local and account-wide under PBFAccountDB.recipePresentation, namespaced by game build and locale, then profession/spell ID. This permits offline-alt browsing of observed categories and reagents without mixing character knowledge. Missing API results do not erase previously captured data.

## Reagents

GetRecipeSchematic reagentSlotSchematics supplies item/currency alternatives and quantityRequired. A slot marked required=false is labeled optional. Multiple choices appear as OR, not as ingredients all needed together. Quantities are per craft. Names use the item cache when available and fall back to item IDs; currencies use IDs. No bag inventory or offline-alt stock is implied.

Incomplete, empty or mismatched schematics do not replace known complete slot data or imply a reagent-free recipe. Missing data is labeled Not reported by the client yet. Crafting tools, enchant targets, quality selection, reagent inventory counts and crafting-cost calculations are outside this initial implementation.

The details panel now scrolls independently so long reagent lists remain accessible.

## Validation and in-game checks

Automated tests cover group/category order, observed recipe order, collapsible headers, flat sort preservation, Uncategorized fallback, quantities, optional slots, alternatives, currency reagents, incomplete/mismatched responses and build/locale persistence. Existing character-boundary and vendor tests remain enabled.

In game:
1. Open Enchanting and Recipe Finder; compare Runed Enchanting Rods, Wizard Oils, Chest, Bracer, Cloak and Wands categories with the native frame.
2. Check recipe order within each populated group; collapse/reopen a group and search/filter.
3. Select an enchant and compare reagent names and quantities to the native details.
4. Scroll details with a long ingredient list.
5. Reload and inspect the saved character without reopening the native profession.
6. Test View: Flat and the existing column sorts.
7. If Forever lacks category/schematic APIs, verify Uncategorized and explicit missing-data labels instead of invented data.
