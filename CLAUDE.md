# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

XIV_Databar TomeOfTeleportation is a standalone companion addon for [XIV_Databar Continued](https://github.com/Starter-WoW/XIV_Databar-Continued). It replaces the Travel module with a simplified hearthstone button that integrates with the [Tome of Teleportation](https://www.curseforge.com/wow/addons/tomeofteleportation) addon.

- **Language**: Lua 5.1 with WoW API
- **Parent addon**: XIV_Databar Continued (required)
- **External addon**: Tome of Teleportation (required for right-click functionality)

## How It Works

- **Left-click**: Uses the hearthstone (supports random hearthstone and hearthstone selection from XIV_Databar settings)
- **Right-click**: Opens Tome of Teleportation via `SlashCmdList["TELEPORTER"]`
- **Tooltip**: Shows hearthstone cooldown and click instructions

## Build & Release

No build step. Pure Lua loaded by the WoW client. The single TOC file (`XIV_Databar_TomeOfTeleportation.toc`) targets Retail (Mainline).

## Architecture

### Files

| File | Purpose |
|------|---------|
| `XIV_Databar_TomeOfTeleportation.toc` | Addon metadata, declares OptionalDeps on XIV_Databar |
| `tele.lua` | Entire addon — module definition, frames, config, hooks |

### Integration with XIV_Databar

This addon registers a module on XIV_Databar's AceAddon instance without modifying any XIV_Databar files. Key integration points:

1. **Addon reference**: Obtained via `LibStub("AceAddon-3.0"):GetAddon()`, trying both `XIV_Databar_Continued` (packaged) and `XIV_Databar-Continued` (dev repo) naming conventions.

2. **Module registration**: `xb:NewModule("TeleModule", 'AceEvent-3.0')` — registers as a first-class XIV_Databar module. Since our addon loads after XIV_Databar's `OnInitialize` has already iterated modules, AceAddon calls our `OnInitialize`/`OnEnable` immediately.

3. **Late initialization** (PLAYER_LOGIN): Because we missed XIV_Databar's module iteration in `core.lua`, we manually:
   - Inject DB defaults into `xb.defaults.profile.modules.tele`
   - Inject config into XIV_Databar's `_Modules` AceConfig options table via `AceConfigRegistry:GetOptionsTable()`

4. **Frame registration**: Registers as `travelFrame` (same name as the Travel module) so the bar's layout chain works. Adjacent modules (Gold, System) position themselves relative to `travelFrame`.

5. **Layout hooks**: Gold and System modules hardcode a check on `xb.db.profile.modules.travel.enabled` to decide whether to anchor to `travelFrame`. Since Travel is disabled when using this addon, we `hooksecurefunc` their `Refresh` to override positioning when tele is active.

6. **Shared settings**: Reads hearthstone preferences from XIV_Databar's DB (`selectedHearthstones`, `randomizeHs`) — no duplication of settings.

7. **Locale strings**: Reuses XIV_Databar's locale for shared keys (`Hearthstone`, `Left-Click`, `Right-Click`, `Ready`). Tome-specific strings are hardcoded in English.

### TOC Loading Strategy

Uses `OptionalDeps` (not `Dependencies`) with both naming conventions to handle dev vs packaged folder names. Does NOT use `LoadOnDemand`/`LoadWith` — the addon loads normally at startup, after XIV_Databar (guaranteed by OptionalDeps ordering).

### Bar Layout Chain

XIV_Databar modules position in a chain from right to left:

```
bar:RIGHT → travelFrame → goldFrame → systemFrame → ...
```

Each module anchors to the previous one's LEFT edge. Our addon takes the `travelFrame` slot. The user must disable the Travel module to avoid conflicts (both would register the same frame name).

## Development Notes

- **No modifications to XIV_Databar**: This addon must never require changes to XIV_Databar files. All integration is done via AceAddon module registration, DB access, AceConfig injection, and hooks.
- **Combat lockdown**: Check `InCombatLockdown()` before modifying secure frames or button attributes.
- **Naming robustness**: Always handle both `XIV_Databar_Continued` (underscore, packaged) and `XIV_Databar-Continued` (hyphen, dev repo) addon names.
- **Testing**: Manual in the WoW client. Enable this module, disable Travel module, verify layout chain, verify hearthstone click and Tome of Teleportation right-click.
