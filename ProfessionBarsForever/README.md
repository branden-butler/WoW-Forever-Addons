# ProfessionBars Forever

**Version:** 1.0  
**Game:** WoW Forever

An addon for tracking profession and character skill progress with customizable bars and recipe-browsing tools.

## Features

- **Profession and skill bars:** Track primary professions, secondary professions, Defense, and weapon skills.
- **Display modes:** Use a compact grouped panel or individual bars.
- **Group headings:** Fixed category order (Primary Professions, Secondary Professions, Skills), optional labels, and adjustable label sizes.
- **Appearance controls:** Adjust bar dimensions, opacity, panel appearance, and title visibility.
- **Recipe Collection:** Browse learned and missing recipes and trainer information.
- **Client Catalog (Preview):** Search recipes extracted from client data.
- **Character skill shortcuts:** Clicking a character skill bar is intended to open the Character → Skills tab.

## Installation

1. Download the addon ZIP and extract the `ProfessionBarsForever` directory.
2. Copy that directory into your WoW Forever `Interface/AddOns/` folder.
3. Confirm the file exists at `Interface/AddOns/ProfessionBarsForever/ProfessionBarsForever.toc`.
4. Restart the game or reload the interface.

## Configuration

Use the in-game settings or enter `/profbar` in chat.

## Files

- `ProfessionBarsForever.toc` — addon manifest and load order
- `ProfessionBarsForever.lua` — main addon and bar UI
- `CatalogUI.lua`, `CatalogData.lua` — client catalog UI and data
- `RecipeSources.lua`, `SeedCooking.lua`, `TrainerData.lua` — recipe and trainer information
- `ProfessionIcon.tga` — addon icon
- `TRAINER_DATA.csv` — supporting trainer data

## Known limitations

- The **Client Catalog** is a preview; not all candidate recipes have been independently verified.
- Opening the Character → Skills tab from a skill bar still needs confirmation in-game.

## Versioning

**v1.0** is the initial repository release label for the latest developed addon build; it does not represent a rollback to older code.
