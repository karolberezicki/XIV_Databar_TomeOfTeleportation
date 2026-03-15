# XIV_Databar - Tome of Teleportation

A lightweight companion addon for [XIV_Databar Continued](https://www.curseforge.com/wow/addons/xiv-databar-continued) that adds a right-click shortcut on the hearthstone button to open [Tome of Teleportation](https://www.curseforge.com/wow/addons/tomeofteleportation) (or any other teleportation addon).

## What It Does

- **Left-click** the hearthstone button to use your hearthstone — handled entirely by the Travel module, nothing changes
- **Right-click** the hearthstone button to open Tome of Teleportation (or whichever addon you configure)
- **Hover** to see the configured right-click command in the Travel tooltip

## Features

- **Non-destructive** — the Travel module works completely unmodified with all its features (hearthstone, portals, mythic+ teleports, housing). This addon only adds a right-click action to the hearthstone button.
- **Configurable command** — change the right-click slash command from the settings (default: `/tele`). Works with any addon that registers a slash command (e.g., `/porter`, `/tele`, etc.)
- **Enable/disable toggle** — turn the right-click override on or off without uninstalling the addon
- **Zero maintenance** — no copied code from XIV_Databar. Future updates to XIV_Databar won't break this addon.
- **Combat-safe** — will not interfere with secure actions during combat

## Requirements

- [XIV_Databar Continued](https://www.curseforge.com/wow/addons/xiv-databar-continued) (required)
- A teleportation addon that registers a slash command, e.g., [Tome of Teleportation](https://www.curseforge.com/wow/addons/tomeofteleportation) (for the default `/tele` command)

## Setup

1. Install XIV_Databar Continued, Tome of Teleportation, and this addon
2. That's it — right-click the hearthstone button on the bar to open Tome of Teleportation

### Optional: Change the right-click command

1. Open XIV_Databar settings (`/xbc`)
2. Go to the **Modules** tab
3. Select **Tome of Teleportation**
4. Change the **Right-Click Command** to any slash command (e.g., `/porter`)

## What Changed in 2.0

Version 2.0 is a complete rewrite. Instead of replacing the Travel module entirely (which required disabling Travel and duplicated hundreds of lines of code), the addon now simply hooks into the existing Travel module's hearthstone button. This means:

- **No need to disable the Travel module** — portals, mythic+ teleports, and housing all continue to work
- **No duplicated hearthstone lists** — the Travel module handles everything
- **No layout chain hacks** — no more hooking Gold/System modules for positioning
- **Configurable command** — not limited to Tome of Teleportation anymore

## Why Use This?

XIV_Databar's Travel module has its own built-in teleport menu on the portal button. If you prefer using Tome of Teleportation (or another addon) instead — with its richer filtering, categories, and teleport management — this addon gives you one-click access from the hearthstone button.
