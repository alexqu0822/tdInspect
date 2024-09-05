-- Addon.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/18/2020, 11:25:23 AM
--
---@class ns
---@field Inspect Inspect
---@field Talent Talent
---@field Glyph Glyph
---@field ItemLevelCalculator ItemLevelCalculator
local ns = select(2, ...)

local ShowUIPanel = LibStub('LibShowUIPanel-1.0').ShowUIPanel

---@class UI
---@field BaseItem UI.BaseItem
---@field GearItem UI.GearItem
---@field GearFrame UI.GearFrame
---@field GemItem UI.GemItem
---@field EnchantItem UI.EnchantItem
---@field InspectFrame UI.InspectFrame
---@field InspectGearFrame UI.InspectGearFrame
---@field GlyphItem UI.GlyphItem
---@field TalentFrame UI.TalentFrame
---@field CharacterGearFrame UI.CharacterGearFrame
---@field GlyphFrame UI.GlyphFrame
---@field PaperDoll UI.PaperDoll
---@field InspectTalent UI.InspectTalent
ns.UI = {}
ns.L = LibStub('AceLocale-3.0'):GetLocale('tdInspect')

ns.VERSION = tonumber((GetAddOnMetadata('tdInspect', 'Version'):gsub('(%d+)%.?', function(x)
    return format('%02d', tonumber(x))
end))) or 0

_G.BINDING_HEADER_TDINSPECT = 'tdInspect'
_G.BINDING_NAME_TDINSPECT_VIEW_TARGET = ns.L['Inspect target']
_G.BINDING_NAME_TDINSPECT_VIEW_MOUSEOVER = ns.L['Inspect mouseover']

---@class Addon: AceAddon, LibClass-2.0, AceEvent-3.0
local Addon = LibStub('AceAddon-3.0'):NewAddon('tdInspect', 'LibClass-2.0', 'AceEvent-3.0')
ns.Addon = Addon

function Addon:OnInitialize()
    ---@class tdInspectProfile: table
    local profile = { --
        global = { --
            userCache = {},
        },
        profile = {},
    }

    ---@type tdInspectProfile | AceDB.Schema
    self.db = LibStub('AceDB-3.0'):New('TDDB_INSPECT2', profile, true)

    if not self.db.global.version or self.db.global.version < 20000 then
        wipe(self.db.global.userCache)
    end

    for k, v in pairs(self.db.global.userCache) do
        if not v.class then
            self.db.global.userCache[k] = nil
        end
    end

    self.db.global.version = ns.VERSION
end

function Addon:OnEnable()
    self:RegisterEvent('ADDON_LOADED')
    self:RegisterMessage('INSPECT_READY')
    self:RegisterMessage('INSPECT_TALENT_READY', 'INSPECT_READY')

    self.GearFrame = ns.UI.CharacterGearFrame:Create(PaperDollFrame)
    self.GearFrame:SetPoint('TOPLEFT', CharacterFrame, 'TOPRIGHT', -33, -12)
end

function Addon:OnModuleCreated(module)
    ns[module:GetName()] = module
end

function Addon:OnClassCreated(class, name)
    local uiName = name:match('^UI%.(.+)$')
    if uiName then
        ns.UI[uiName] = class
        LibStub('AceEvent-3.0'):Embed(class)
    else
        ns[name] = class
    end
end

function Addon:SetupUI()
    self.InspectFrame = ns.UI.InspectFrame:Bind(InspectFrame)
end

function Addon:ADDON_LOADED(_, addon)
    if addon ~= 'Blizzard_InspectUI' then
        return
    end

    self:SetupUI()
    self:UnregisterEvent('ADDON_LOADED')
end

function Addon:INSPECT_READY(_, unit, name)
    if not InspectFrame then
        return
    end
    if unit == ns.Inspect.unit or name == ns.Inspect.unitName then
        ShowUIPanel(self.InspectFrame)
    end
end
