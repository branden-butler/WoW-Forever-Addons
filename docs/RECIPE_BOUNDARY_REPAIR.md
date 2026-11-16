# Recipe profession-boundary repair

The Recipe Finder must use spell-to-profession membership, not the selected profession or an account-wide API response, to choose list contents.

Some earlier builds saved all recipes from a response under the last selected profession. Account-wide recipe catalogs then retained those mislabeled rows. Background known-spell checks could propagate that mislabeled membership into character flags. Cooking therefore showed First Aid and other crafts and its count expanded far beyond its 132 bundled candidate rows.

## Fix

- Recipe scans partition each spell independently using the bundled Forever catalog associations. A mixed response can update Cooking, First Aid and Alchemy separately without switching the user's selected profession or alt.
- Saving, display and background checks all enforce membership. Shared learned-recipe names never define a profession.
- Startup repairs shared catalogs and every saved character's flags by spell ID, preserving true over conflicting false evidence within the same character. It never transfers learned flags between characters.
- Unclassified rows and their per-character known flags are retained in unassignedRecipeRows and unassignedKnownByID, outside profession lists. They can be reassigned on a later repair if the catalog gains a mapping.
- No character or vendor data needs to be deleted. Existing older per-character snapshots are migrated when that character logs in, then repaired with the same boundaries.
- Display counts use the repaired list; cooking's bundled baseline is 132 candidates, not a guarantee of 132 obtainable recipes.

Membership is limited to the current bundled catalog. Newly discovered or gathering utility spells without a catalog association are preserved as unassigned observations and withheld from profession lists until their membership can be established. No stale profession-window hint is used to guess their owner.

## Regression checks

tests/character_store.lua loads the real catalog and recreates a Cooking cache containing Brilliant Smallfish, Anti-Venom, Heavy Linen Bandage, an Alchemy recipe and an unknown spell. It checks automatic repair, per-character flag isolation, idempotence, mixed API responses, unchanged selection, defensive display filtering and background scans. Existing persistence and vendor export tests remain enabled.

In game: install and restart without deleting SavedVariables. Select Cooking and confirm First Aid recipes no longer appear; select First Aid and confirm those learned states remain. Repeat for Alchemy and a saved alt, then reload to verify the repair persists.
