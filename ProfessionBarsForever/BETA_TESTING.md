# ProfessionBars Forever — Public Beta 1 Testing

**Version:** 1.0.0-beta.1  
**Client:** WoW Forever only

## Install
1. Download the ZIP attached to the GitHub pre-release.
2. Extract the `ProfessionBarsForever` folder to `Interface/AddOns/`.
3. Confirm `Interface/AddOns/ProfessionBarsForever/ProfessionBarsForever.toc` exists.
4. Restart the game or enter `/reload`.

Back up your existing saved settings before upgrading.

## Checklist
- [ ] Addon loads without Lua errors on login or `/reload`.
- [ ] Primary and secondary profession bars display correct values.
- [ ] Defense and weapon skill bars display correct values.
- [ ] Bars update after skill gains.
- [ ] Compact grouped and individual modes work.
- [ ] Category order and optional headings display correctly.
- [ ] Heading sizes, bar dimensions, opacity, and visibility settings work.
- [ ] Settings persist after reloading and relogging.
- [ ] Clicking a character skill opens the Character pane (select Skills manually).
- [ ] Minimap and settings controls work.

### Recipe Finder
- [ ] Right-clicking a profession bar opens the Recipe Finder on that profession; right-clicking a Defense/weapon bar does not.
- [ ] Right-clicking the minimap icon, `/profbar recipes`, and the settings button open and close it.
- [ ] Switching professions in the dropdown lists every recipe (including ones you have not learned).
- [ ] After opening a profession's window, learned recipes show **Known** and the rest **Missing**; the count in the header matches.
- [ ] Search, status filter, source filter, header sorting, scrollbar and mouse wheel work.
- [ ] The upgrade line shows the next rank and a trainer; **Trainer List** opens the directory (also for a profession you have not learned).
- [ ] Client Catalog button, `/pbfcatalog` and the settings button open the catalog window.
- [ ] No Lua errors when opening/closing either window or switching professions.

## Known limitations
Automatic Skills-tab navigation is deferred. Recipe source/location data is documented only for Cooking so far, and catalog entries are unverified client data. Official Classic and Retail are not supported by this beta.

## Report bugs
[Open a bug report](https://github.com/branden-butler/WoW-Forever-Addons/issues/new/choose) with addon version, WoW Forever build, steps to reproduce, expected and actual results, and any Lua errors.
