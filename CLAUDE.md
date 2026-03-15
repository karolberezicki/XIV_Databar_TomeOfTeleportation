# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

XIV_Databar TomeOfTeleportation is a lightweight companion addon for [XIV_Databar Continued](https://github.com/Starter-WoW/XIV_Databar-Continued). It hooks into the Travel module's hearthstone button to add a right-click shortcut that runs a configurable slash command (default: `/tele` for Tome of Teleportation).

- **Language**: Lua 5.1 with WoW API
- **Parent addon**: XIV_Databar Continued (required)
- **External addon**: Any addon that registers a slash command (e.g., Tome of Teleportation for `/tele`)

## How It Works

- **Left-click**: Uses the hearthstone (handled entirely by Travel module)
- **Right-click**: Runs the configured slash command (default: `/tele`)
- **Tooltip**: Appends "Right-Click: /tele" when hovering the hearthstone button
- **Config**: Enable/disable toggle and command input in XIV_Databar's Modules options panel

The Travel module works completely unmodified. This addon only adds a `*type2` attribute override on the hearthstone button, appends one tooltip line, and injects a config group.

## Build & Release

No build step. Pure Lua loaded by the WoW client. The single TOC file targets Retail (Mainline).

## Architecture

### Files

| File | Purpose |
|------|---------|
| `XIV_Databar_TomeOfTeleportation.toc` | Addon metadata, declares OptionalDeps and SavedVariables |
| `tele.lua` | Hooks, config injection, slash command execution |

### Integration with XIV_Databar

This addon uses **zero copied code** from XIV_Databar. It hooks two TravelModule methods and injects config at PLAYER_LOGIN:

1. **`hooksecurefunc(TravelModule, "OnEnable", ...)`** — Sets `*type2 = 'teleFunction'` on the hearthstone button when enabled. The `*type2` attribute overrides the generic `type` for right-clicks only, so left-click (hearthstone macro) is completely unaffected.

2. **`hooksecurefunc(TravelModule, "ShowTooltip", ...)`** — Appends the configured command to the tooltip when hovering the hearthstone button.

3. **Config injection at PLAYER_LOGIN** — Adds a "Tome of Teleportation" group to `AceConfigRegistry`'s modules options table with enable toggle and command input.

### Slash command execution

Modern WoW makes `SlashCmdList` a metatable proxy — `pairs(SlashCmdList)` returns nothing. To execute an arbitrary slash command, we search `_G` for `SLASH_*` globals matching the target command, extract the handler key name, then call `SlashCmdList[key]` directly.

### SavedVariables

Uses `XIVDatabarTomeOfTeleportationDB` (declared in TOC). Must be initialized at `ADDON_LOADED`, not at file load time — WoW loads SavedVariables between file execution and `ADDON_LOADED`, so a `local db` captured at file scope would point to a stale table.

### Event timing

1. **File load** — hooks are set up (closures reference `db` upvalue, which is nil at this point)
2. **ADDON_LOADED** — `db` is set to `XIVDatabarTomeOfTeleportationDB` (now loaded from disk)
3. **PLAYER_LOGIN** — AceAddon fires `OnEnable` for TravelModule → our hook applies the handler; then our PLAYER_LOGIN handler injects config

## Development Notes

- **No modifications to XIV_Databar**: This addon hooks methods but never modifies XIV_Databar's own tables, frames, or config.
- **Combat lockdown**: Both the OnEnable hook and the teleFunction check `InCombatLockdown()`.
- **Naming robustness**: Handles both `XIV_Databar_Continued` (packaged) and `XIV_Databar-Continued` (dev repo) naming.
- **Do not use `pairs(SlashCmdList)`**: It returns 0 entries in modern WoW. Search `_G` for `SLASH_*` globals instead.
- **Do not cache SavedVariables at file scope**: Use `ADDON_LOADED` to initialize the `db` reference.
- **Testing**: Enable Travel module, verify left-click uses hearthstone, right-click runs configured command, config persists across `/reload`.
