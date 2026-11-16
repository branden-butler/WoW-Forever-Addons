# Saved characters and Recipe Finder

Recipe data is stored locally in account-wide PBFAccountDB.characters, keyed by character GUID (realm/name fallback for store API callers). Each profile contains its own name, realm, faction, profession skill snapshot, per-profession recipe flags and scan timestamps. This includes gathering professions such as Herbalism. Shared catalog names and client candidates carry no learned state.

Recipe Finder's character dropdown selects a saved profile. The profession dropdown groups that profile's recorded professions first; recipe Known/Missing/Unverified and Skill Met use that profile's saved flags and skill values. A current-character profession scan never replaces an alt view or writes learned flags onto an alt. Hover a recipe to see saved characters with positive learned evidence.

## Persistence and migration

Existing per-character recipeKnownByID and recipeSnapshots are migrated when each character first logs into this version. Other characters' per-character SavedVariables cannot be read until they log in. Existing character settings remain per-character. New accounts must log into each alt and open its crafting profession windows once; gathering skill levels are recorded on login.

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
