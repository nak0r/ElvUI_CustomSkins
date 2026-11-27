# ElvUI_CustomSkins

Extra addon skins for [ElvUI_AddOnSkins](https://github.com/ElvUI-WotLK/ElvUI_AddOnSkins) (WotLK 3.3.5), shipped as a separate addon so the original AddOnSkins code never has to be edited.

**Version:** 1

## Included skins

| Addon | What gets skinned |
| --- | --- |
| [MarketWatcher](https://www.curseforge.com/wow/addons/market-watcher/files/422870) | Auction house History and Scan tabs, dialogs, filters, config window, tooltips |
| [DressMe](https://github.com/GetLocalPlayer/DressMe) | Main window, dressing room, slots, tabs, dropdowns, preview tiles, lists |
| [EnhancedStackSplit](https://www.curseforge.com/wow/addons/enhanced-stack-split/files/422345)| Stack split frame, always using the expanded (XL) layout |
| [RaidBuffStatus](https://www.curseforge.com/wow/addons/raidbuffstatus/files/457723)| Dashboard, talents window, options window, plus Scale / Opacity sliders |

Each skin only applies if the target addon is installed and loaded.

## Requirements

- WoW 3.3.5 (Interface 30300)
- [ElvUI (WotLK)](https://github.com/ElvUI-WotLK/ElvUI)
- [ElvUI_AddOnSkins (WotLK)](https://github.com/ElvUI-WotLK/ElvUI_AddOnSkins)

## Installation

1. Download or clone this repository.
2. Copy the inner **`ElvUI_CustomSkins`** folder (the one containing `ElvUI_CustomSkins.toc`) into `Interface\AddOns\`.
3. Fully quit and restart the game client.

The final layout must be:

```
Interface\AddOns\ElvUI_CustomSkins\ElvUI_CustomSkins.toc
Interface\AddOns\ElvUI_CustomSkins\core.lua
Interface\AddOns\ElvUI_CustomSkins\skins\*.lua
```

> **Note:** WoW caches each addon's file list. After adding or renaming files in the `.toc`, `/reload` is not enough; restart the client.

## Usage

Open ElvUI and go to **AddOn Skins > Skins**. A **ElvUI_CustomSkins** section lists one checkbox per custom skin. Changing a checkbox shows a reload prompt; the new setting applies after the UI reloads.

Settings are stored alongside AddOnSkins' own toggles in `E.private.addOnSkins`. A skin is enabled unless its value is explicitly `false`.

## Configuration

Colours, sizes and layout options are constants at the top of each file in `skins/` (for example `BORDER_MODE`, which can be `"elvui"`, `"class"` or `"custom"`). Edit them and reload.

## Adding a skin

1. Add the addon name to `CUSTOM_SKIN_NAMES` in `core.lua` so it gets a checkbox.
2. Create `skins/<Name>.lua`.
3. Add that path to the `.toc`.
4. In the skin, skip work when the toggle is off:

   ```lua
   if E.private and E.private.addOnSkins and E.private.addOnSkins.<Name> == false then return end
   ```

Skins should run after ElvUI has initialised (`PLAYER_LOGIN` or later), because ElvUI's API and database are not ready before then.

## Troubleshooting

- **Addon loads but no skin applies:** restart the client fully (see the note above), then check that the files exist in `skins\`.
- **Check that it loaded:** `/run print(IsAddOnLoaded("ElvUI_CustomSkins"), ElvUI[1].CustomSkins ~= nil)` should print `1 true`.
- **Check individual skins:** `/run print(DressMe_SkinLoaded, EnhancedStackSplit_SkinLoaded, RaidBuffStatus_SkinLoaded)` should print `true true true` when the skin files are loaded.
- **Lua errors:** enable them with `/console scriptErrors 1` and include the error text when reporting an issue.

## Notes

- The checkboxes are always listed, whether or not the target addon is installed.
- EnhancedStackSplit's skin removes the XL toggle button and keeps the expanded layout on.

## Screenshot
<imc src="https://github.com/nak0r/ElvUI_CustomSkins/blob/main/screenshot.png">
