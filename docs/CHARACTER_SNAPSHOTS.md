# Saved characters and Recipe Finder

Recipe data is stored locally in account-wide PBFAccountDB.characters, keyed by character GUID (realm/name fallback for store API callers). Each profile contains its own name, realm, faction, profession skill snapshot, per-profession recipe flags and scan timestamps. This includes gathering professions such as Herbalism. Shared catalog names and client candidates carry no learned state.

Recipe Finder's character dropdown selects a saved profile. The profession dropdown groups that profile's recorded professions first; recipe Known/Missing/Unverified and Skill Met use that profile's saved flags and skill values. A current-character profession scan never replaces an alt view or writes learned flags onto an alt. Hover a recipe to see saved characters with positive learned evidence.

## Persistence and migration

Existing per-character recipeKnownByID and recipeSnapshots are migrated when each character first logs into this version. Other characters' per-character SavedVariables cannot be read until they log in. Existing character settings remain per-character. Log into each alt to record its local profile. On login, entering the world, spell/recipe changes and opening Recipe Finder, the addon queries catalog spell IDs using available known-spell APIs. Positive results update that character without opening professions. Gathering skill levels are recorded on login. A one-time profession scan can supply recipe details or knowledge this build does not expose through known-spell queries; saved results remain visible thereafter.

Closing Recipe Finder only hides the window. Profession scans run only while a profession UI is visible and skip linked/guild/NPC crafting sources. Empty responses and absent learned fields cannot overwrite flags. A positive learned observation is retained over later false/loading responses; an explicitly reported false on an unconfirmed recipe records Missing. Catalog-only IDs never become Missing merely by omission.

This prioritizes durable positive evidence. Profession unlearning/relearning with the same spell IDs is not an automatic reset of learned history in this version; a saved profile is a last-observed snapshot, not a real-time query of an offline character. Missing profession entries hide its recipe status as Unlearned Profession once a usable profession list was recorded. Last-known profiles may be stale until scanned again.

WoW writes SavedVariables on logout, reload, or clean exit; a crash can lose unsaved changes. Character/account names and recipe snapshots remain local and are not part of the vendor observation export allowlist.

## Acceptance checks

1. On character A with Alchemy/Herbalism, open Alchemy; check Known and Missing. Close/reopen Recipe Finder repeatedly, then /reload. Status must remain.
2. On character B with Tailoring/Enchanting, open both professions. Reload and compare their saved counts.
3. From B, choose A in the character dropdown. Alchemy/Herbalism and A's known flags/skill values should appear. Choose B and confirm independent values.
4. While inspecting A on B, open B's profession window; the saved scan must update B only, keeping A selected.
5. Hover a recipe: list only characters whose snapshots explicitly contain learned=true.
6. A character/profession not scanned should remain Not Scanned/Unverified, not inherit another character's Missing flags.
7. Confirm /pbfdata export still contains only vendor observations and no character profiles.

## Background known-spell updates and header

The known-spell adapters use C_SpellBook.IsSpellKnown, IsPlayerSpell, and legacy IsSpellKnown where present, protected by pcall. Only true results establish Known. False, nil, unavailable APIs and errors do not reset saved flags or turn unverified candidates into Missing. Queries do not open profession windows or depend on the profession UI's cached recipe list.

These APIs must be checked in-game for Forever crafting recipes; availability of an API does not guarantee it exposes every learned recipe. Offline alts always show their last saved state, updated when that character logs in. Character names are displayed without realm suffixes; identity remains GUID-based internally so names on different realms do not share state.

The catalog button is shortened to 155px and ends 76px from the browser's right edge, leaving a 27px gap before the X button. Character dropdown text now shows names only.

Acceptance: restart WoW and open Recipe Finder without opening any profession. Confirm previously saved Known states remain, and any positively queryable recipes are detected. Learn a recipe and confirm its status updates without reopening professions. Test an alt, hover the known-on list, and confirm character names plus separated Catalog/X buttons.
