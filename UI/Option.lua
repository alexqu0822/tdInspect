-- Option.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 9/5/2024, 1:39:10 PM
--
---@type ns
local ns = select(2, ...)

local L = ns.L
local tdOptions = LibStub('tdOptions')

---@class Addon
local Addon = ns.Addon

function Addon:SetupOptionFrame()
    local order = 0
    local function orderGen()
        order = order + 1
        return order
    end

    local function treeTitle(name)
        return {type = 'group', name = '|cffffd100' .. name .. '|r', order = orderGen(), args = {}, disabled = true}
    end

    local function treeItem(name)
        return function(args)
            return {type = 'group', name = '  |cffffffff' .. name .. '|r', order = orderGen(), args = args}
        end
    end

    local function inline(name)
        return function(args)
            return {type = 'group', name = name, inline = true, order = orderGen(), args = args}
        end
    end

    local function fullToggle(name)
        return {type = 'toggle', name = name, width = 'full', order = orderGen()}
    end

    local function keybinding(name)
        return {
            type = 'keybinding',
            name = name,
            order = orderGen(),
            width = 'double',
            get = function(item)
                return GetBindingKey(item[#item])
            end,
            set = function(item, value)
                local action = item[#item]
                for _, key in ipairs({GetBindingKey(action)}) do
                    SetBinding(key, nil)
                end
                SetBinding(value, action)
            end,
            confirm = function(item, value)
                local action = GetBindingAction(value)
                if action ~= '' and action ~= item[#item] then
                    return L['The key is bound to |cffffd100%s|r, are you sure you want to overwrite it?']:format(
                               _G['BINDING_NAME_' .. action] or action)
                end
            end,
        }
    end

    local options = {
        type = 'group',
        name = format('tdInspect - |cff00ff00%s|r', C_AddOns.GetAddOnMetadata('tdInspect', 'Version')),
        get = function(item)
            return ns.db.profile[item[#item]]
        end,
        set = function(item, value)
            local key = item[#item]
            ns.db.profile[key] = value
            ns.Events:Fire('TDINSPECT_OPTION_CHANGED', key, value)
        end,
        args = {
            gearListTitle = treeTitle(L['Gear List']),
            gearList = treeItem(L['Gear List']) {
                general = inline(GENERAL) {
                    showTalentBackground = fullToggle(L['Show talent background']),
                    showGem = fullToggle(L['Show gem']),
                    showEnchant = fullToggle(L['Show enchant']),
                    showLost = fullToggle(L['Show enchant/gem lost']),
                    showGemsFront = fullToggle(L['Show gems in front']),
                },
                characterGear = inline(L['Character Gear']) {
                    characterGear = fullToggle(L['Show character gear list']),
                    showOptionButtonInCharacter = fullToggle(L['Show option button in character gear list']),
                },
                inspectGear = inline(L['Inspect Gear']) {
                    inspectGear = fullToggle(L['Show inspect gear list']),
                    inspectCompare = fullToggle(L['Show inspect compare']),
                    closeCharacterFrameWhenInspect = fullToggle(L['Close character frame when inspect']),
                    showOptionButtonInInspect = fullToggle(L['Show option button in inspect gear list']),
                },
                characterList = inline(L['Character List']) {
                    showLowLevelCharacters = fullToggle(L['Show low level characters']),
                },
            },
            keybindingsTitle = treeTitle(SETTINGS_KEYBINDINGS_LABEL),
            keybindings = treeItem(SETTINGS_KEYBINDINGS_LABEL) {
                TDINSPECT_VIEW_TARGET = keybinding(L['View target hotkey']),
                TDINSPECT_VIEW_MOUSEOVER = keybinding(L['View mouseover hotkey']),
            },
            helpTitle = treeTitle(L['Help']),
            help = treeItem(L['Help']) {help = {type = 'description', name = L.HELP_SUMMARY, order = orderGen()}},
        },
    }

    tdOptions:Register('tdInspect', options)
end

function Addon:OpenOptionFrame()
    tdOptions:Open('tdInspect')
end
