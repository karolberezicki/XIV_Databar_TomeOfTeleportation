--------------------------------------------------------------------------------
-- TOME OF TELEPORTATION - XIV_Databar Integration
-- Hooks into the Travel module's hearthstone button to add a right-click
-- handler that runs a configurable slash command (default: /tele).
-- The Travel module works normally; this addon only adds the right-click shortcut.
--------------------------------------------------------------------------------

local AceAddon = LibStub("AceAddon-3.0")
local xb = AceAddon:GetAddon("XIV_Databar_Continued", true)
        or AceAddon:GetAddon("XIV_Databar-Continued", true)

if not xb then
    print("|cFFFF0000XIV_Databar Tome of Teleportation:|r XIV_Databar Continued not found.")
    return
end

local TravelModule = xb:GetModule("TravelModule", true)
if not TravelModule then
    print("|cFFFF0000XIV_Databar Tome of Teleportation:|r Travel module not found.")
    return
end

local ADDON_NAME = "Tome of Teleportation"

-- db is set at ADDON_LOADED, before any hook fires (hooks fire at PLAYER_LOGIN)
local db

-- Execute a slash command string by finding its SLASH_* global in _G, then
-- calling the handler via SlashCmdList[key]. We search _G because modern WoW
-- makes SlashCmdList a metatable proxy that pairs() cannot iterate.
local function ExecuteSlashCommand(command)
    if not command or command == "" then return end
    command = strtrim(command)
    if command == "" then return end
    if command:sub(1, 1) ~= "/" then command = "/" .. command end
    local target = command:upper()

    for key, val in pairs(_G) do
        if type(key) == "string" and type(val) == "string"
           and key:sub(1, 6) == "SLASH_" and val:upper() == target then
            local cmdName = key:match("^SLASH_(.+)%d+$")
            if cmdName then
                local handler = SlashCmdList[cmdName]
                if handler then
                    handler("")
                    return
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- APPLY / REMOVE the right-click handler on the hearthstone button
--------------------------------------------------------------------------------

local function ApplyTomeHandler()
    if InCombatLockdown() or not TravelModule.hearthButton then return end
    TravelModule.hearthButton:SetAttribute('*type2', 'teleFunction')
    TravelModule.hearthButton.teleFunction = function()
        if InCombatLockdown() then return end
        ExecuteSlashCommand(db and db.command)
    end
end

local function RemoveTomeHandler()
    if InCombatLockdown() or not TravelModule.hearthButton then return end
    TravelModule.hearthButton:SetAttribute('*type2', nil)
    TravelModule.hearthButton.teleFunction = nil
end

--------------------------------------------------------------------------------
-- HOOKS — set up at file load, but callbacks only fire at PLAYER_LOGIN or later
--------------------------------------------------------------------------------

hooksecurefunc(TravelModule, "OnEnable", function()
    if db and db.enabled then ApplyTomeHandler() else RemoveTomeHandler() end
end)

hooksecurefunc(TravelModule, "ShowTooltip", function(self)
    if not db or not db.enabled then return end
    if not self.hearthButton or not self.hearthButton:IsMouseOver() then return end

    local r, g, b = unpack(xb:HoverColors())
    GameTooltip:AddDoubleLine(
        '<' .. xb.L["RIGHT_CLICK"] .. '>',
        db.command,
        r, g, b, 1, 1, 1
    )
    GameTooltip:Show()
end)

--------------------------------------------------------------------------------
-- INIT — ADDON_LOADED sets db, PLAYER_LOGIN injects config
--------------------------------------------------------------------------------

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event, arg1)

    if event == "ADDON_LOADED" and arg1 == "XIV_Databar_TomeOfTeleportation" then
        self:UnregisterEvent("ADDON_LOADED")
        XIVDatabarTomeOfTeleportationDB = XIVDatabarTomeOfTeleportationDB or {}
        db = XIVDatabarTomeOfTeleportationDB
        if db.command == nil then db.command = "/tele" end
        if db.enabled == nil then db.enabled = true end

    elseif event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        local AceConfigRegistry = LibStub("AceConfigRegistry-3.0", true)
        if not AceConfigRegistry then return end

        local modulesKey = (xb.name or "XIV_Databar_Continued") .. "_Modules"
        local ok, opts = pcall(AceConfigRegistry.GetOptionsTable, AceConfigRegistry,
                               modulesKey, "dialog", "AceConfigDialog-3.0")

        if not ok or not opts or not opts.args then return end

        opts.args.TomeOfTeleportation = {
            name = ADDON_NAME,
            type = "group",
            args = {
                enable = {
                    name = ENABLE,
                    order = 10,
                    type = "toggle",
                    get = function() return db.enabled end,
                    set = function(_, val)
                        db.enabled = val
                        if val then ApplyTomeHandler() else RemoveTomeHandler() end
                    end,
                    width = "full"
                },
                command = {
                    name = "Right-Click Command",
                    desc = "Slash command to run when right-clicking the hearthstone button (e.g., /tele, /porter)",
                    order = 20,
                    type = "input",
                    get = function() return db.command end,
                    set = function(_, val)
                        val = strtrim(val or "")
                        if val == "" then val = "/tele" end
                        if val:sub(1, 1) ~= "/" then val = "/" .. val end
                        db.command = val
                    end,
                    disabled = function() return not db.enabled end,
                    width = "full"
                }
            }
        }
        AceConfigRegistry:NotifyChange(modulesKey)
    end
end)
