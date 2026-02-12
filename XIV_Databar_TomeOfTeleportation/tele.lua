--------------------------------------------------------------------------------
-- TOME OF TELEPORTATION MODULE
-- Standalone companion addon for XIV_Databar Continued.
-- Adds a hearthstone module where left-click uses the hearthstone and
-- right-click opens Tome of Teleportation via /tele.
-- Disable the Travel module in XIV_Databar and enable this one to use.
--------------------------------------------------------------------------------

-- Find XIV_Databar by either naming convention (underscore or hyphen)
local AceAddon = LibStub("AceAddon-3.0")
local xb = AceAddon:GetAddon("XIV_Databar_Continued", true)
        or AceAddon:GetAddon("XIV_Databar-Continued", true)

if not xb then
    print("|cFFFF0000XIV_Databar Tome of Teleportation:|r XIV_Databar Continued not found.")
    return
end

local L = xb.L
local compat = xb.compat
local xbName = xb.name or "XIV_Databar_Continued"

local TeleModule = xb:NewModule("TeleModule", 'AceEvent-3.0')

-- Cache frequently used API functions
local GetItemInfo = C_Item.GetItemInfo
local GetItemCooldown = C_Container.GetItemCooldown
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellInfo = C_Spell.GetSpellInfo

-- Safe IsUsableItem wrapper with compatibility check
local function SafeIsUsableItem(id)
    if compat.isMists and not IsUsableItem then return false end
    return IsUsableItem(id)
end

-- Addon-specific strings (not in XIV_Databar's locale)
local TOME_NAME = "Tome of Teleportation"
local TOME_DESC = "When enabled, right-clicking the hearthstone will open Tome Of Teleportation instead of the default port menu. The port options button will be hidden."
local TOME_DETECTED = "Tome of Teleportation addon detected."
local TOME_NOT_DETECTED = "Tome of Teleportation addon not detected. Please install the addon."

--------------------------------------------------------------------------------
-- LATE INITIALIZATION
-- Since this addon loads after XIV_Databar's OnInitialize has already run,
-- the module iteration that collects GetDefaultOptions/GetConfig has already
-- completed. We inject our defaults and config at PLAYER_LOGIN.
--------------------------------------------------------------------------------

local lateInitFrame = CreateFrame("Frame")
lateInitFrame:RegisterEvent("PLAYER_LOGIN")
lateInitFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()

    -- Ensure DB defaults exist for our module
    if xb.defaults and xb.defaults.profile and xb.defaults.profile.modules then
        xb.defaults.profile.modules.tele = { enabled = false }
    end
    if xb.db and xb.db.profile and xb.db.profile.modules then
        if xb.db.profile.modules.tele == nil then
            xb.db.profile.modules.tele = { enabled = false }
        end
    end

    -- Inject our config into XIV_Databar's modules options table
    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
    local modulesKey = xbName .. "_Modules"
    local moduleOptions = AceConfigRegistry:GetOptionsTable(modulesKey, "dialog", "AceConfigDialog-3.0")
    if moduleOptions and moduleOptions.args then
        moduleOptions.args.TeleModule = TeleModule:GetConfig()
        AceConfigRegistry:NotifyChange(modulesKey)
    end

    -- Hook adjacent modules to recognize our travelFrame.
    -- Gold and System modules hardcode a check on travel.enabled to decide
    -- whether to anchor to travelFrame. We post-hook their Refresh to
    -- override their positioning when tele is active.
    local teleIsActive = function()
        return xb.db.profile.modules.tele
           and xb.db.profile.modules.tele.enabled
           and xb:GetFrame('travelFrame')
           and xb:GetFrame('travelFrame'):IsShown()
    end

    local GoldModule = xb:GetModule("GoldModule", true)
    if GoldModule and GoldModule.Refresh then
        hooksecurefunc(GoldModule, "Refresh", function(self)
            if not teleIsActive() then return end
            if not self.goldFrame or not self.goldFrame:IsShown() then return end
            local db = xb.db.profile
            self.goldFrame:ClearAllPoints()
            self.goldFrame:SetPoint('RIGHT', xb:GetFrame('travelFrame'), 'LEFT',
                                    -(db.general.moduleSpacing), 0)
        end)
    end

    local SystemModule = xb:GetModule("SystemModule", true)
    if SystemModule and SystemModule.Refresh then
        hooksecurefunc(SystemModule, "Refresh", function(self)
            if not teleIsActive() then return end
            if not self.systemFrame or not self.systemFrame:IsShown() then return end
            local db = xb.db.profile
            -- System anchors to gold if gold is visible, otherwise to travelFrame
            local goldFrame = xb:GetFrame('goldFrame')
            if goldFrame and goldFrame:IsShown() then return end -- gold handles chaining
            self.systemFrame:ClearAllPoints()
            self.systemFrame:SetPoint('RIGHT', xb:GetFrame('travelFrame'), 'LEFT',
                                      -(db.general.moduleSpacing - 5), 0)
        end)
    end

    -- Trigger a refresh of adjacent modules now that hooks are in place
    if teleIsActive() then
        if GoldModule and GoldModule.Refresh then GoldModule:Refresh() end
        if SystemModule and SystemModule.Refresh then SystemModule:Refresh() end
    end
end)

--------------------------------------------------------------------------------
-- MODULE DEFINITION
--------------------------------------------------------------------------------

function TeleModule:GetName() return TOME_NAME; end

function TeleModule:OnInitialize()
    self.hearthstones = {
        556,       -- Astral Recall
        6948,      -- Hearthstone
        260221,    -- Naaru's Embrace (Classic)
        184871     -- Dark Portal (Classic)
    }
    if compat.isMainline then
        self.hearthstones = {
            246565, -- Cosmic Hearthstone
            245970, -- P.O.S.T. Master's Express Hearthstone
            236687, -- Explosive Hearthstone
            235016, -- Redeployment Module
            228940, -- Notorious Thread's Hearthstone
            200630, -- Ohn'ir Windsage's Hearthstone
            190196, -- Enlightened Hearthstone
            212337, -- Stone of the Hearth
            209035, -- Hearthstone of the Flame
            208704, -- Deepdweller's Earthen Hearthstone
            54452,  -- Ethereal Portal
            193588, -- Timewalker's Hearthstone
            190237, -- Broker Translocation Matrix
            188952, -- Dominated Hearthstone
            184353, -- Kyrian Hearthstone
            182773, -- Necrolord Hearthstone
            180290, -- Night Fae Hearthstone
            183716, -- Venthyr Sinstone
            172179, -- Eternal Travaler's Hearthstone
            6948,   -- Hearthstone
            64488,  -- Innkeeper's Daughter
            28585,  -- Ruby Slippers
            93672,  -- Dark Portal
            142542, -- Tome of Town Portal
            163045, -- Headless Horseman's Hearthstone
            162973, -- Greatfather Winter's Hearthstone
            165669, -- Lunar Elder's Hearthstone
            165670, -- Peddlefeet's Lovely Hearthstone
            165802, -- Noble Gardener's Hearthstone
            166746, -- Fire Eater's Hearthstone
            166747, -- Brewfest Reveler's Hearthstone
            40582,  -- Scourgestone (Death Knight Starting Campaign)
            172179, -- Eternal Traveler's Hearthstone
            142543, -- Scroll of Town Portal
            37118,  -- Scroll of Recall 1
            44314,  -- Scroll of Recall 2
            44315,  -- Scroll of Recall 3
            556,    -- Astral Recall
            168907, -- Holographic Digitalization Hearthstone
            142298, -- Astonishingly Scarlet Slippers
            210455, -- Draenic Hologem
            263489, -- Naaru's Embrace (Retail)
            260221, -- Naaru's Embrace (Classic)
            184871  -- Dark Portal (Classic)
        }
    end
end

function TeleModule:OnEnable()
    if not xb.db.profile.modules.tele or not xb.db.profile.modules.tele.enabled then
        self:Disable()
        return
    end

    -- Create and show frame
    if self.teleFrame == nil then
        self.teleFrame = CreateFrame('FRAME', "TeleModule", xb:GetFrame('bar'))
        xb:RegisterFrame('travelFrame', self.teleFrame)
    end

    self.teleFrame:Show()
    self:CreateFrames()
    self:RegisterFrameEvents()
    self:Refresh()
end

function TeleModule:OnDisable()
    if self.teleFrame then
        self.teleFrame:Hide()
    end
    self:UnregisterAllEvents()
end

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------

function TeleModule:IsUsable(id)
    return PlayerHasToy(id) or SafeIsUsableItem(id) or IsPlayerSpell(id)
end

function TeleModule:GetTransportName(id)
    if IsPlayerSpell(id) then
        local spellInfo = GetSpellInfo(id)
        if spellInfo and spellInfo.name then return spellInfo.name end
    end
    if PlayerHasToy(id) then
        local _, name = C_ToyBox.GetToyInfo(id)
        if name then return name end
    end
    if SafeIsUsableItem(id) then
        local name = GetItemInfo(id)
        if name then return name end
    end
    return nil
end

function TeleModule:FindUsableHearthstone()
    local selectedHearthstones = {}
    if xb.db.profile.selectedHearthstones then
        for hearthstoneId, isSelected in pairs(xb.db.profile.selectedHearthstones) do
            if isSelected then
                table.insert(selectedHearthstones, hearthstoneId)
            end
        end
    end

    local hearthstones = #selectedHearthstones > 0 and selectedHearthstones
                             or self.hearthstones

    local available = {}
    for _, id in ipairs(hearthstones) do
        if self:IsUsable(id) then
            local name = self:GetTransportName(id)
            if name then
                local macro = SafeIsUsableItem(id) and "/use item:" .. id
                                  or "/cast " .. name
                table.insert(available, {id = id, name = name, macro = macro})
            end
        end
    end

    if #available == 0 then return nil end
    if xb.db.profile.randomizeHs then
        return available[math.random(#available)]
    end
    return available[1]
end

function TeleModule:GetRemainingCooldown(id, isSpell)
    local startTime, duration
    if isSpell then
        local spellCooldownInfo = GetSpellCooldown(id)
        startTime = spellCooldownInfo.startTime
        duration = spellCooldownInfo.duration
    else
        startTime, duration = GetItemCooldown(id)
    end

    if type(startTime) == "number" and type(duration) == "number" and duration > 0 then
        return math.max(0, startTime + duration - GetTime())
    end
    return 0
end

function TeleModule:FormatCooldown(cdTime)
    if cdTime <= 0 then return L['Ready'] end
    local hours = string.format("%02.f", math.floor(cdTime / 3600))
    local minutes = string.format("%02.f",
                                  math.floor(cdTime / 60 - (hours * 60)))
    local seconds = string.format("%02.f", math.floor(
                                      cdTime - (hours * 3600) - (minutes * 60)))
    local retString = ''
    if tonumber(hours) ~= 0 then retString = hours .. ':' end
    if tonumber(minutes) ~= 0 or tonumber(hours) ~= 0 then
        retString = retString .. minutes .. ':'
    end
    return retString .. seconds
end

--------------------------------------------------------------------------------
-- FRAME CREATION & EVENTS
--------------------------------------------------------------------------------

function TeleModule:CreateFrames()
    self.hearthButton = self.hearthButton or
                            CreateFrame('BUTTON', 'teleHearthButton',
                                        self.teleFrame,
                                        'SecureActionButtonTemplate')
    self.hearthIcon = self.hearthIcon or
                          self.hearthButton:CreateTexture(nil, 'OVERLAY')
    self.hearthText = self.hearthText or
                          self.hearthButton:CreateFontString(nil, 'OVERLAY')
end

function TeleModule:RegisterFrameEvents()
    self:RegisterEvent('SPELLS_CHANGED', 'Refresh')
    self:RegisterEvent('BAG_UPDATE_DELAYED', 'Refresh')
    self:RegisterEvent('HEARTHSTONE_BOUND', 'Refresh')

    self.hearthButton:EnableMouse(true)
    self.hearthButton:RegisterForClicks('AnyUp', 'AnyDown')

    -- Left-click: use hearthstone (secure action)
    self.hearthButton:SetAttribute('*type1', 'macro')

    -- Right-click: open Tome of Teleportation (insecure action)
    self.hearthButton:SetAttribute('*type2', 'teleFunction')
    self.hearthButton.teleFunction = function()
        if SlashCmdList["TELEPORTER"] then
            SlashCmdList["TELEPORTER"]("")
        end
    end

    -- Hearthstone randomizer preclick
    if xb.db.profile.randomizeHs then
        self.hearthButton:SetScript('PreClick', function()
            TeleModule:UpdateHearthstone()
        end)
    end

    -- Hover handlers
    self.hearthButton:SetScript('OnEnter', function()
        TeleModule:UpdateHearthstone()
        self.hearthText:SetTextColor(unpack(xb:HoverColors()))
        if not InCombatLockdown() then
            self:ShowTooltip()
        end
    end)

    self.hearthButton:SetScript('OnLeave', function()
        TeleModule:UpdateHearthstone()
        if self.tooltipTimer then
            self.tooltipTimer:Cancel()
            self.tooltipTimer = nil
        end
        GameTooltip:Hide()
    end)
end

function TeleModule:UpdateHearthstone()
    if InCombatLockdown() then return end

    local transport = self:FindUsableHearthstone()
    local db = xb.db.profile

    if transport then
        self.hearthButton:SetAttribute("macrotext", transport.macro)
    end

    if self.hearthButton:IsMouseOver() then
        self.hearthText:SetTextColor(unpack(xb:HoverColors()))
    elseif transport then
        self.hearthIcon:SetVertexColor(xb:GetColor('normal'))
        self.hearthText:SetTextColor(xb:GetColor('normal'))
    else
        self.hearthIcon:SetVertexColor(db.color.inactive.r, db.color.inactive.g,
                                       db.color.inactive.b, db.color.inactive.a)
        self.hearthText:SetTextColor(db.color.inactive.r, db.color.inactive.g,
                                     db.color.inactive.b, db.color.inactive.a)
    end
end

--------------------------------------------------------------------------------
-- TOOLTIP
--------------------------------------------------------------------------------

function TeleModule:ShowTooltip()
    GameTooltip:SetOwner(self.hearthButton, 'ANCHOR_' .. xb.miniTextPosition)
    GameTooltip:ClearLines()
    local r, g, b, _ = unpack(xb:HoverColors())
    GameTooltip:AddLine("|cFFFFFFFF[|r" .. TOME_NAME .. "|cFFFFFFFF]|r", r, g, b)

    -- Hearthstone cooldown
    local hearthCooldown = self:GetRemainingCooldown(6948, false)
    local hearthCdString = self:FormatCooldown(hearthCooldown)
    GameTooltip:AddDoubleLine(L['Hearthstone'], hearthCdString, r, g, b, 1, 1, 1)

    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine('<' .. L['Left-Click'] .. '>',
                              L['Hearthstone'], r, g, b, 1, 1, 1)
    GameTooltip:AddDoubleLine('<' .. L['Right-Click'] .. '>',
                              TOME_NAME, r, g, b, 1, 1, 1)
    GameTooltip:Show()

    if not self.tooltipTimer then
        self.tooltipTimer = C_Timer.NewTicker(1, function()
            if GameTooltip:IsOwned(self.hearthButton) then
                self:ShowTooltip()
            else
                self.tooltipTimer:Cancel()
                self.tooltipTimer = nil
            end
        end)
    end
end

--------------------------------------------------------------------------------
-- REFRESH
--------------------------------------------------------------------------------

function TeleModule:Refresh()
    if self.teleFrame == nil then return end

    if not xb.db.profile.modules.tele or not xb.db.profile.modules.tele.enabled then
        self:Disable()
        return
    end

    local db = xb.db.profile
    local iconSize = db.text.fontSize + db.general.barPadding

    if InCombatLockdown() then
        if not select(1, self.hearthText:GetFont()) then
            self.hearthText:SetFont(xb:GetFont(db.text.fontSize))
        end
        self.hearthText:SetText(GetBindLocation())
        self:UpdateHearthstone()
        return
    end

    -- Update hearthstone macro
    self:UpdateHearthstone()

    if xb.db.profile.randomizeHs then
        self.hearthButton:SetScript('PreClick', function()
            TeleModule:UpdateHearthstone()
        end)
    else
        self.hearthButton:SetScript('PreClick', nil)
    end

    -- Layout hearthstone button
    self.hearthText:SetFont(xb:GetFont(db.text.fontSize))
    self.hearthText:SetText(GetBindLocation())

    self.hearthButton:SetSize(self.hearthText:GetWidth() + iconSize +
                                  db.general.barPadding, xb:GetHeight())
    self.hearthButton:SetPoint("RIGHT")

    self.hearthText:SetPoint("RIGHT")

    self.hearthIcon:SetTexture(xb.constants.mediaPath .. 'datatexts\\hearth')
    self.hearthIcon:SetSize(iconSize, iconSize)
    self.hearthIcon:SetPoint("RIGHT", self.hearthText, "LEFT",
                             -(db.general.barPadding), 0)

    if not self.hearthButton:IsVisible() then
        self.hearthButton:Show()
        self.hearthText:Show()
    end

    -- Size the container frame
    local totalWidth = self.hearthButton:GetWidth() + db.general.barPadding
    self.teleFrame:SetSize(totalWidth, xb:GetHeight())
    self.teleFrame:SetPoint("RIGHT", -(db.general.barPadding), 0)
    self.teleFrame:Show()
end

--------------------------------------------------------------------------------
-- CONFIG (returned by GetConfig, injected into XIV_Databar at PLAYER_LOGIN)
--------------------------------------------------------------------------------

function TeleModule:GetConfig()
    return {
        name = self:GetName(),
        type = "group",
        args = {
            enable = {
                name = ENABLE,
                order = 10,
                type = "toggle",
                get = function()
                    return xb.db.profile.modules.tele
                       and xb.db.profile.modules.tele.enabled
                end,
                set = function(_, val)
                    xb.db.profile.modules.tele = xb.db.profile.modules.tele or {}
                    xb.db.profile.modules.tele.enabled = val
                    if val then
                        self:Enable()
                    else
                        self:Disable()
                    end
                end,
                width = "full"
            },
            description = {
                order = 20,
                name = TOME_DESC,
                type = 'description',
            },
            tomeStatus = {
                order = 30,
                name = function()
                    if SlashCmdList["TELEPORTER"] then
                        return "|cFF00FF00" .. TOME_DETECTED .. "|r"
                    else
                        return "|cFFFF0000" .. TOME_NOT_DETECTED .. "|r"
                    end
                end,
                type = 'description',
            }
        }
    }
end
