# Minimap button controls

Branch minimap-button-controls is based on merged main 700216e3ade6301dba8da32464144683b782784d.

## Visibility

Settings (/profbar) includes Show minimap button. The choice persists per character through PBFDB.minimapHidden. Existing hidden preferences are preserved; the older showMinimap=false preference is honored only when there is no explicit minimapHidden value.

Commands: /profbar minimap toggles, /profbar minimap on shows, and /profbar minimap off hides. Settings remain available through /profbar while the icon is hidden. Slash commands synchronize the checkbox.

## Geometry and scaling

The button remains a Minimap child and inherits its parent scale once. Its local button/icon/border dimensions stay at the standard 31/19/53 pixels so enlarging the map alone does not make this icon larger than neighboring addon buttons. Physical scaling is inherited from the minimap. Position is calculated from the minimap's actual horizontal/vertical radius plus an 8px local rim offset, replacing the fixed 108px orbit. Standard square maps are supported when GetMinimapShape reports SQUARE; other shapes use an ellipse.

Size changes immediately reposition the button. A half-second geometry watcher covers addons that change dimensions without the expected event, including when the button is hidden. Parent scaling/movement is inherited automatically. Drag cursor coordinates are converted using Minimap:GetEffectiveScale(), avoiding drift from a separately scaled minimap.

## Verification

tests/minimap_button.lua exercises the actual addon functions with frame mocks: show/hide, recreation, 140-to-280px resizing, icon/border geometry, inherited scale without double scaling, rectangular/square positioning, watcher updates and dragging at 2x effective scale. The main Lua file is also syntax checked by CI.

In-game acceptance:
1. Toggle Show minimap button off/on, then reload and verify persistence.
2. While hidden, /profbar must still open settings; /profbar minimap on must restore the icon.
3. Scale the minimap; the button should follow its physical size.
4. Resize the minimap; the orbit should follow the rim while the icon stays the same local size as other addon buttons.
5. Drag around the scaled minimap and verify the pointer stays aligned.
6. Verify left-click settings and right-click Recipe Finder.

## Settings organization

All seven checkboxes are now in one consecutive block above the numeric controls: optional weapon skills, gain flash, lock positions, panel title, title on hover, category labels, and minimap button. Numeric controls follow, then action buttons. The window returns to 660px height.
