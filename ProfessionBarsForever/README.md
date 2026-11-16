# ProfessionBars Forever

**Version:** 1.0.0-beta.1  
**Client:** WoW Forever (beta)

Configurable progress bars for primary and secondary professions, Defense, and weapon skills. Includes compact grouped and individual display modes, adjustable category headings, bar dimensions, opacity, and minimap settings.

## Installation

Extract the `ProfessionBarsForever` directory into `Interface/AddOns/`. Verify `Interface/AddOns/ProfessionBarsForever/ProfessionBarsForever.toc` exists. Restart WoW or use `/reload`. Configure using `/profbar` or the minimap icon.

## Recipe Finder

Open it by **right-clicking a profession bar** or the **minimap icon**, with `/profbar recipes`, or from the settings window.

- Browse every recipe for a profession, search by name or spell ID, and filter by known, missing, or skill met.
- **Known / Missing** comes from your own character: open a profession's window once so the addon can scan it. Until then recipes show **Not Scanned**. Recipes the game's profession window does not report show **Unverified**.
- **Where to find it:** source, NPC and location are shown only where documented (currently Cooking). Everything else says *Not documented yet*; nothing is guessed.
- **Upgrades:** the line under the list shows your next rank, the skill needed, how to get it, and a nearby trainer. **Trainer List** opens the full trainer directory (Alt+right-click a bar also opens it). Entries marked *Classic ref* are historical locations not yet confirmed on Forever. TomTom is optional.
- **Client Catalog** (`/pbfcatalog` or the Client Catalog button) shows the raw client candidate data, including IDs. It is unverified and never marks anything learned.

## Current beta limitations

- Clicking Defense or a weapon skill bar **opens the Character pane**. Select the **Skills tab manually**. Automatic navigation is a future enhancement.
- Recipe Finder catalog entries are **unverified client candidates**: not every entry is guaranteed learnable, and skill-up ranges are not learning requirements. Acquisition sources are incomplete outside Cooking.
- This build is for **WoW Forever only**. Official WoW Classic and Retail are not yet supported.

Report issues: https://github.com/branden-butler/WoW-Forever-Addons/issues/new/choose
Beta checklist: https://github.com/branden-butler/WoW-Forever-Addons/blob/main/ProfessionBarsForever/BETA_TESTING.md

## Automatic vendor observations

Vendor inventories are recorded locally when you open a shop; no scan button is needed. Use `/pbfdata` for status, `/pbfdata off` or `on` to control collection, and `/pbfdata export [page]` to review and copy a game-data-only JSON export.

No data is uploaded. Observations include item/NPC IDs, contextual prices, stock, game build and optional nearby observer coordinates. They do not automatically change recipe verification or learned status. See [collection and export details](../docs/VENDOR_OBSERVATIONS.md), including storage limits and the future desktop-client contract.
