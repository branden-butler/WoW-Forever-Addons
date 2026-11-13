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
- [ ] Recipe Browser button is absent from settings.
- [ ] Right-clicking a bar, panel, or minimap icon does not open Recipe Browser.
- [ ] Minimap and settings controls work.

## Known limitations
Automatic Skills-tab navigation and recipe browsing are deferred. Official Classic and Retail are not supported by this beta.

## Report bugs
[Open a bug report](https://github.com/branden-butler/WoW-Forever-Addons/issues/new/choose) with addon version, WoW Forever build, steps to reproduce, expected and actual results, and any Lua errors.
