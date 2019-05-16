local core_mainmenu = require("core_mainmenu")
local lib_helpers = require("solylib.helpers")
local lib_menu = require("solylib.menu")
local lib_items = require("solylib.items.items")
local lib_items_cfg = require("solylib.items.items_configuration")
local lib_items_list = require("solylib.items.items_list")
local lib_unitxt = require("solylib.unitxt")
local lib_characters = require("solylib.characters")
local cfg = require("Backpack.configuration")
local optionsLoaded, options = pcall(require, "Backpack.options")
local charsLoaded, chars = pcall(require, "Backpack.data.chars")
local totalsFileName = "addons/Backpack/data/totals.lua"
local charsFileName = "addons/Backpack/data/chars.lua"
local optionsFileName = "addons/Backpack/options.lua"
local Frame = 0
local ConfigurationWindow

if optionsLoaded then
    -- If options loaded, make sure we have all those we need
    options.configurationEnableWindow = lib_helpers.NotNilOrDefault(options.configurationEnableWindow, true)
    options.EnableWindow = lib_helpers.NotNilOrDefault(options.EnableWindow, true)
    options.HideWhenMenu = lib_helpers.NotNilOrDefault(options.HideWhenMenu, true)
    options.HideWhenSymbolChat = lib_helpers.NotNilOrDefault(options.HideWhenSymbolChat, true)
    options.HideWhenMenuUnavailable = lib_helpers.NotNilOrDefault(options.HideWhenMenuUnavailable, true)
    options.changed = lib_helpers.NotNilOrDefault(options.changed, true)
    options.Anchor = lib_helpers.NotNilOrDefault(options.Anchor, 1)
    options.X = lib_helpers.NotNilOrDefault(options.X, 50)
    options.Y = lib_helpers.NotNilOrDefault(options.Y, 50)
    options.W = lib_helpers.NotNilOrDefault(options.W, 500)
    options.H = lib_helpers.NotNilOrDefault(options.H, 500)
    options.NoTitleBar = lib_helpers.NotNilOrDefault(options.NoTitleBar, "")
    options.NoResize = lib_helpers.NotNilOrDefault(options.NoResize, "")
    options.NoMove = lib_helpers.NotNilOrDefault(options.NoMove, "")
    options.TransparentWindow = lib_helpers.NotNilOrDefault(options.TransparentWindow, false)
else
    options =
    {
        configurationEnableWindow = true,
        EnableWindow = true,
        HideWhenMenu = false,
        HideWhenSymbolChat = false,
        HideWhenMenuUnavailable = false,
        changed = true,
        Anchor = 1,
        X = 50,
        Y = 50,
        W = 500,
        H = 500,
        NoTitleBar = "",
        NoResize = "",
        NoMove = "",
        TransparentWindow = false,
    }
end

local function SaveOptions(options)
    local file = io.open(optionsFileName, "w")
    if file ~= nil then
        io.output(file)

        io.write("return\n")
        io.write("{\n")
        io.write(string.format("    configurationEnableWindow = %s,\n", tostring(options.configurationEnableWindow)))
        io.write(string.format("    EnableWindow = %s,\n", tostring(options.EnableWindow)))
        io.write(string.format("    HideWhenMenu = %s,\n", tostring(options.HideWhenMenu)))
        io.write(string.format("    HideWhenSymbolChat = %s,\n", tostring(options.HideWhenSymbolChat)))
        io.write(string.format("    HideWhenMenuUnavailable = %s,\n", tostring(options.HideWhenMenuUnavailable)))
        io.write(string.format("    Anchor = %i,\n", options.Anchor))
        io.write(string.format("    X = %i,\n", options.X))
        io.write(string.format("    Y = %i,\n", options.Y))
        io.write(string.format("    W = %i,\n", options.W))
        io.write(string.format("    H = %i,\n", options.H))
        io.write(string.format("    NoTitleBar = \"%s\",\n", options.NoTitleBar))
        io.write(string.format("    NoResize = \"%s\",\n", options.NoResize))
        io.write(string.format("    NoMove = \"%s\",\n", options.NoMove))
        io.write(string.format("    AlwaysAutoResize = \"%s\",\n", options.AlwaysAutoResize))
        io.write(string.format("    TransparentWindow = %s,\n", options.TransparentWindow))
        io.write("}\n")

        io.close(file)
    end
end

local function ProcessWeapon(item)
    local result = ""

    if item.weapon.wrapped or item.weapon.untekked then
        local tekText = ""
        if item.weapon.wrapped and item.weapon.untekked then
            tekText = "W|U"
        elseif item.weapon.wrapped then
            tekText = "W"
        elseif item.weapon.untekked then
            tekText = "U"
        end
        result = result .. string.format("[%s] ", tekText)
    end

    if item.weapon.isSRank then
        result = result .. string.format("S-RANK %s %s", item.name, item.weapon.nameSrank)

        if item.weapon.grind > 0 then
            result = result .. string.format("+%i", item.weapon.grind)
        end

        if item.weapon.specialSRank ~= 0 then
            result = result .. string.format(" [%s]", lib_unitxt.GetSRankSpecialName(item.weapon.specialSRank))
        end
    else

        result = result .. string.format("%s ", item.name)

        if item.weapon.grind > 0 then
            result = result .. string.format("+%i ", item.weapon.grind)
        end

        if item.weapon.special ~= 0 then
            result = result .. string.format("[%s] ", lib_unitxt.GetSpecialName(item.weapon.special))
        end

        result = result .. "["
        for i = 2, 5, 1 do
            local stat = item.weapon.stats[i]

            result = result .. string.format("%i", stat)

            if i < 5 then
                result = result .. "/"
            else
                result = result .. "|"
            end
        end

        result = result .. string.format("%i]", item.weapon.stats[6])

        if item.kills ~= 0 then
            result = result .. string.format(" [%iK]", item.kills)
        end
    end

    return result
end

local function ProcessFrame(item)
    local result = ""
    result = result .. string.format("%s [%i/%i | %i/%i] [%iS]", item.name, item.armor.dfp, item.armor.dfpMax, item.armor.evp, item.armor.evpMax, item.armor.slots)
    return result
end

local function ProcessBarrier(item)
    local result = ""
    result = result .. string.format("%s [%i/%i | %i/%i]", item.name, item.armor.dfp, item.armor.dfpMax, item.armor.evp, item.armor.evpMax)
    return result
end

local function ProcessUnit(item)
    local result = ""

    local nameStr = item.name

    if item.unit.mod == 0 then
    elseif item.unit.mod == -2 then
        nameStr = nameStr .. "--"
    elseif item.unit.mod == -1 then
        nameStr = nameStr .. "-"
    elseif item.unit.mod == 1 then
        nameStr = nameStr .. "+"
    elseif item.unit.mod == 2 then
        nameStr = nameStr .. "++"
    end

    result = result .. string.format("%s ", nameStr)

    if item.kills ~= 0 then
        result = result .. string.format("[%iK]", item.kills)
    end
    return result
end

local function ProcessMag(item)
    local result = ""
    result = result .. string.format("%s ", item.name)

    result = result .. string.format("[%s] ", lib_unitxt.GetMagColor(item.mag.color))

    result = result .. string.format("[%.2f/%.2f/%.2f/%.2f]", item.mag.def, item.mag.pow, item.mag.dex, item.mag.mind)

    return result
end

local function ProcessTool(item)
    local result = ""
    if item.data[2] == 2 then
        result = result .. string.format("%s Lv%i", item.name, item.tool.level)
    elseif item.hex ~= 0x030900 then
        result = result .. string.format("%s", item.name)
        if item.tool.count > 0 then
            result = result .. string.format(" x%i", item.tool.count)
        end
    end
    return result
end

local function ProcessItem(item)
    local itemStr = ""
    if item.data[1] == 0 then
        itemStr = itemStr .. ProcessWeapon(item)
    elseif item.data[1] == 1 then
        if item.data[2] == 1 then
            itemStr = itemStr .. ProcessFrame(item)
        elseif item.data[2] == 2 then
            itemStr = itemStr .. ProcessBarrier(item)
        elseif item.data[2] == 3 then
            itemStr = itemStr .. ProcessUnit(item)
        end
    elseif item.data[1] == 2 then
        itemStr = itemStr .. ProcessMag(item)
    elseif item.data[1] == 3 then
        itemStr = itemStr .. ProcessTool(item)
    end
    return itemStr
end

local function isScapeDoll(item)
    if item.hex == 0x030900 then
        return true
    end
    return false
end

local function isPhotonDrop(item)
    if item.hex == 0x031000 then
        return true
    end
    return false
end

local function isPhotonCrystal(item)
    if item.hex == 0x031002 then
        return true
    end
    return false
end

local function isPhotonSphere(item)
    if item.hex == 0x031001 then
        return true
    end
    return false
end

local function isMonogrinder(item)
    if item.hex == 0x030A00 then
        return true
    end
    return false
end

local function isDigrinder(item)
    if item.hex == 0x030A01 then
        return true
    end
    return false
end

local function isTrigrinder(item)
    if item.hex == 0x030A02 then
        return true
    end
    return false
end

local function isHp(item)
    if item.hex == 0x030B03 then
        return true
    end
    return false
end

local function isTp(item)
    if item.hex == 0x030B04 then
        return true
    end
    return false
end

local function isPow(item)
    if item.hex == 0x030B00 then
        return true
    end
    return false
end

local function isMind(item)
    if item.hex == 0x030B01 then
        return true
    end
    return false
end

local function isLuck(item)
    if item.hex == 0x030B06 then
        return true
    end
    return false
end

local function isAddSlot(item)
    if item.hex == 0x030F00 then
        return true
    end
    return false
end

local function SaveChars(player)
    if charsLoaded and chars ~= nil then
        if chars[player] == nil then
            local file = io.open(charsFileName, "w")
            if file ~= nil then
                io.output(file)
                io.write("return\n")
                io.write("{\n")
                for key, value in pairs(chars) do
                    io.write(string.format("    [\"%s\"] = %s,\n", tostring(key), tostring(value)))
                end
                io.write(string.format("    [\"%s\"] = %s,\n", tostring(player), tostring(true)))
                io.write("}\n")

                io.close(file)
            end
        end
    else
        local file = io.open(charsFileName, "w")
        if file ~= nil then
            io.output(file)

            io.write("return\n")
            io.write("{\n")
            io.write(string.format("    [\"%s\"] = %s,\n", tostring(player), tostring(true)))
            io.write("}\n")

            io.close(file)
        end
    end
    package.loaded["Backpack.data.chars"] = nil
end

local function SaveItems(location, items)
    local scapes = 0
    local file = io.open(location, "w")
    if file ~= nil then
        io.output(file)
        io.write("return {\n")
        io.write(string.format("    \"Meseta x%i\",\n", tostring(items.meseta)))
        for key, value in pairs(items.items) do
            if isScapeDoll(value) then
                scapes = scapes + 1
            else
                io.write(string.format("    \"%s\",\n", string.gsub(ProcessItem(value), '["]', "'")))
            end
        end
        if scapes ~= 0 then
            io.write(string.format("    \"Scape Doll x%i\",\n", scapes))
        end
        io.write("}\n")
        io.close(file)
    end
end

local function ParseTotals(counts, item)
    if isScapeDoll(item) then
        counts.scapes = counts.scapes + 1
    elseif isPhotonDrop(item) then
        counts.pd = counts.pd + item.tool.count
    elseif isPhotonCrystal(item) then
        counts.pc = counts.pc + item.tool.count
    elseif isPhotonSphere(item) then
        counts.ps = counts.ps + item.tool.count
    elseif isAddSlot(item) then
        counts.as = counts.as + 1
    elseif isHp(item) then
        counts.hp = counts.hp + item.tool.count
    elseif isTp(item) then
        counts.tp = counts.tp + item.tool.count
    elseif isPow(item) then
        counts.pow = counts.pow + item.tool.count
    elseif isMind(item) then
        counts.mind = counts.mind + item.tool.count
    elseif isLuck(item) then
        counts.luck = counts.luck + item.tool.count
    elseif isMonogrinder(item) then
        counts.mg = counts.mg + item.tool.count
    elseif isDigrinder(item) then
        counts.dg = counts.dg + item.tool.count
    elseif isTrigrinder(item) then
        counts.tg = counts.tg + item.tool.count
    end
    return counts
end

local function DefaultTotals()
    return {
        scapes = 0,
        meseta = 0,
        pd = 0,
        pc = 0,
        ps = 0,
        as = 0,
        hp = 0,
        tp = 0,
        pow = 0,
        mind = 0,
        luck = 0,
        mg = 0,
        dg = 0,
        tg = 0,
    }
end

local function isSharedBank(bank)
    if bank.meseta > 999999 then
        return true
    end
    return false
end

local function writeTotals(player, counts)
    io.write(string.format("    [\"%s\"] = {\n", tostring(player)))

    for key, value in pairs(counts) do
        io.write(string.format("        %s = %s,\n", key, value))
    end

    io.write("    },\n")
end

local function buildTotals(player, items, bank)
    local _totals = DefaultTotals()
    _totals.meseta = items.meseta
    for key, value in pairs(items.items) do
        _totals = ParseTotals(_totals, value)
    end
    writeTotals(player, _totals)
    if isSharedBank(bank) == false then
        _totals = DefaultTotals()
        _totals.meseta = _totals.meseta + bank.meseta
        for key, value in pairs(bank.items) do
            _totals = ParseTotals(_totals, value)
        end
        writeTotals(player .. '~Bank', _totals)
    end
    if isSharedBank(bank) then
        _totals = DefaultTotals()
        _totals.meseta = _totals.meseta + bank.meseta
        for key, value in pairs(bank.items) do
            _totals = ParseTotals(_totals, value)
        end

        writeTotals('shared', _totals)
    end
end

local function SaveTotals(player, items, bank)
    local totalsLoaded, totals = pcall(require, "Backpack.data.totals")
    if totalsLoaded and totals ~= nil then
        local file = io.open(totalsFileName, "w")
        if file ~= nil then
            io.output(file)
            io.write("return\n")
            io.write("{\n")
            for key, value in pairs(totals) do
                if key ~= player and ((isSharedBank(bank) == false and key ~= player .. '~Bank') or (isSharedBank(bank) and key ~= 'shared')) then
                    io.write(string.format("    [\"%s\"] = {\n", tostring(key)))
                    for k, v in pairs(value) do
                        io.write(string.format("        %s = %s,\n", k, v))
                    end
                    io.write("},\n")
                end
            end

            buildTotals(player, items, bank)

            io.write("}\n")

            io.close(file)
        end
    else
        local file = io.open(totalsFileName, "w")
        if file ~= nil then
            io.output(file)

            io.write("return\n")
            io.write("{\n")
            buildTotals(player, items, bank)
            io.write("}\n")

            io.close(file)
        end
    end
end

local function AddTotals(_totals, table)

    _totals.scapes = _totals.scapes + table.scapes
    _totals.meseta = _totals.meseta + table.meseta
    _totals.pd = _totals.pd + table.pd
    _totals.pc = _totals.pc + table.pc
    _totals.ps = _totals.ps + table.ps
    _totals.as = _totals.as + table.as
    _totals.hp = _totals.hp + table.hp
    _totals.tp = _totals.tp + table.tp
    _totals.pow = _totals.pow + table.pow
    _totals.mind = _totals.mind + table.mind
    _totals.luck = _totals.luck + table.luck
    _totals.mg = _totals.mg + table.mg
    _totals.dg = _totals.dg + table.dg
    _totals.tg = _totals.tg + table.tg

    return _totals
end

local function SaveInvAndBank(player)
    local charInv = 'addons/Backpack/data/' .. player .. '_inv.lua'
    local inv = lib_items.GetInventory(lib_items.Me)
    SaveItems(charInv, inv)
    package.loaded['Backpack.data.' .. player .. '_inv'] = nil
    local charBank = 'addons/Backpack/data/' .. player .. '_bank.lua'
    local bank = lib_items.GetBank()
    if isSharedBank(bank) then
        charBank = 'addons/Backpack/data/shared_bank.lua'
    end
    SaveItems(charBank, bank)
    if isSharedBank(bank) then
        package.loaded['Backpack.data.shared_bank'] = nil
    else
        package.loaded['Backpack.data.' .. player .. '_bank'] = nil
    end
    SaveTotals(player, inv, bank)
    package.loaded['Backpack.data.totals'] = nil
end

local function PresentBackpack()
    local player = lib_characters.GetSelf()
    local charLoaded, name = pcall(lib_characters.GetPlayerName, player)
    if charLoaded and name ~= nil then
        if Frame >= 30 then
            local char = tostring(name ..
                    '~~~' .. lib_unitxt.GetClassName(lib_characters.GetPlayerClass(player)) ..
                    '~~~' .. lib_unitxt.GetSectionIDName(lib_characters.GetPlayerSectionID(player)));
            SaveChars(char)
            SaveInvAndBank(char);
            Frame = 0
        end
        Frame = Frame + 1
    end
    local totalsLoaded, totals = pcall(require, "Backpack.data.totals")
    if totalsLoaded and totals ~= nil then
        if imgui.TreeNodeEx("Total Wealth") then
            local _totals = DefaultTotals()
            for key, table in pairs(totals) do
                _totals = AddTotals(_totals, table)
            end
            imgui.Text("Meseta: " .. _totals.meseta)
            imgui.Text("Scape Doll: " .. _totals.scapes)
            imgui.Text("Photon Drop: " .. _totals.pd)
            imgui.Text("Photon Crystal: " .. _totals.pc)
            imgui.Text("Photon Sphere: " .. _totals.ps)
            imgui.Text("AddSlot: " .. _totals.as)
            imgui.Text("HP Material: " .. _totals.hp)
            imgui.Text("TP Material: " .. _totals.tp)
            imgui.Text("Power Material: " .. _totals.pow)
            imgui.Text("Mind Material: " .. _totals.mind)
            imgui.Text("Luck Material: " .. _totals.luck)
            imgui.Text("Monogrinder: " .. _totals.mg)
            imgui.Text("Digrinder: " .. _totals.dg)
            imgui.Text("Trigrinder: " .. _totals.tg)
            imgui.TreePop()
        end
    end
    local sharedBankLoaded, sharedBank = pcall(require, "Backpack.data.shared_bank")
    if sharedBankLoaded and sharedBank ~= nil then
        if imgui.TreeNodeEx("Shared Bank") then
            for idx, item in pairs(sharedBank) do
                imgui.Text(item)
            end
            imgui.TreePop()
        end
    end
    if charsLoaded and chars ~= nil then
        for key, value in pairs(chars) do
            if imgui.TreeNodeEx(string.gsub(key, '~~~', ', ') .. " - Inventory") then
                local charInvLoaded, charInv = pcall(require, "Backpack.data." .. key .. '_inv')
                if charInvLoaded and charInv ~= nil then
                    for idx, item in pairs(charInv) do
                        imgui.Text(item)
                    end
                end
                imgui.TreePop()
            end
            if imgui.TreeNodeEx(string.gsub(key, '~~~', ', ') .. " - Bank") then
                local charBankLoaded, charBank = pcall(require, "Backpack.data." .. key .. '_bank')
                if charBankLoaded and charBank ~= nil then
                    for idx, item in pairs(charBank) do
                        imgui.Text(item)
                    end
                end
                imgui.TreePop()
            end
        end
    end
end


local function present()
    -- If the addon has never been used, open the config window
    -- and disable the config window setting
    if options.configurationEnableWindow then
        ConfigurationWindow.open = true
        options.configurationEnableWindow = false
    end
    ConfigurationWindow.Update()

    if ConfigurationWindow.changed then
        ConfigurationWindow.changed = false
        SaveOptions(options)
    end

    if (options.EnableWindow == true)
            and (options.HideWhenMenu == false or lib_menu.IsMenuOpen() == false)
            and (options.HideWhenSymbolChat == false or lib_menu.IsSymbolChatOpen() == false)
            and (options.HideWhenMenuUnavailable == false or lib_menu.IsMenuUnavailable() == false) then
        local windowName = "Backpack"

        if options.TransparentWindow == true then
            imgui.PushStyleColor("WindowBg", 0.0, 0.0, 0.0, 0.0)
        end


        imgui.SetNextWindowSizeConstraints(0, 0, options.W, options.H)

        if imgui.Begin(windowName,
            nil,
            {
                options.NoTitleBar,
                options.NoResize,
                options.NoMove,
                "AlwaysAutoResize",
            }) then
            PresentBackpack()

            lib_helpers.WindowPositionAndSize(windowName,
                options.X,
                options.Y,
                options.W,
                options.H,
                options.Anchor,
                "AlwaysAutoResize",
                options.changed)
        end
        imgui.End()

        if options.TransparentWindow == true then
            imgui.PopStyleColor()
        end

        options.changed = false
    end
end

local function init()
    ConfigurationWindow = cfg.ConfigurationWindow(options)

    local function mainMenuButtonHandler()
        ConfigurationWindow.open = not ConfigurationWindow.open
    end

    core_mainmenu.add_button("Backpack", mainMenuButtonHandler)

    return
    {
        name = "Backpack",
        version = "1.0.0",
        author = "MarcherTech",
        description = "Shows Inventory and Bank across characters",
        present = present,
    }
end

return
{
    __addon =
    {
        init = init
    }
}
