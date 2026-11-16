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
