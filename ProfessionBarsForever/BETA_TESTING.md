# ProfessionBars Forever — Beta Testing

**Target:** WoW Forever  
**Version:** v1.0.0-beta.1

Install the `ProfessionBarsForever` folder under `Interface/AddOns/`. The `.toc` file must be directly inside it. Back up existing saved variables before replacing an older version.

## Checklist

- [ ] Addon loads without Lua errors on login and `/reload`
- [ ] Primary and secondary profession bars display and update correctly
- [ ] Defense and weapon skill bars display and update correctly
- [ ] Compact grouping order remains Primary, Secondary, Skills
- [ ] Group headings can be hidden without changing the order
- [ ] Group heading sizes (70–200%) don't overlap or leave excessive gaps
- [ ] Individual and compact display modes work
- [ ] Size, opacity, title and hidden-bar settings persist after relogging
- [ ] Clicking a profession bar opens its profession interface
- [ ] Clicking Defense or a weapon skill opens Character → Skills
- [ ] Recipe Collection opens, filters, and scrolls correctly
- [ ] Client Catalog search, filters, and scrolling work smoothly
- [ ] No Lua errors or UI freezes during normal use

## Reporting problems

Open a [new GitHub issue](https://github.com/branden-butler/WoW-Forever-Addons/issues/new/choose) and select the bug report template. Include addon version, WoW Forever build, steps to reproduce, expected versus actual behavior, and Lua errors or screenshots when available. Please remove personal information from logs.

The Client Catalog remains a preview; report missing, duplicated, or unobtainable recipes.
