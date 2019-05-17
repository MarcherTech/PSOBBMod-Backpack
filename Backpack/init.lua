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
local totalsFileName = "addons/Backpack/data/totals.lua"
local charsFileName = "addons/Backpack/data/chars.lua"
local optionsFileName = "addons/Backpack/options.lua"
local Frame, ConfigurationWindow, bankIsShared
local _SideMessage = pso.base_address + 0x006AECC8

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

-- read side message from memory buffer
local function get_side_text()
    local ptr = pso.read_u32(_SideMessage)
    if ptr ~= 0 then
        local text = pso.read_wstr(ptr + 0x14, 0xFF)
        return text
    end
    return ""
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

local function isSRank(item)
    if item.data[1] == 0 and item.weapon.isSRank then
        return true
    end
    return false
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
    local charsLoaded, chars = pcall(require, "Backpack.data.chars")
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

local function SRankSpecialPdValue(item)
    local special = lib_unitxt.GetSRankSpecialName(item.weapon.specialSRank)
    if special == "HP Regeneration" or special == "TP Regeneration" then
        return 20
    elseif special == "Blizzard" or special == "Burning" or special == "Tempest" then
        return 30
    elseif special == "Spirit" or special == "Berserk" or special == "Chaos" or special == "King's" or special == "Geist" or special == "Gush" then
        return 40
    elseif special == "Hell" or special == "Demon's" or special == "Arrest" then
        return 50
    elseif special == "Jellen" or special == "Zalure" then
        return 60
    end
    return 0
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
    elseif isSRank(item) then
        counts.es = counts.es + 1
        counts.espd = counts.espd + SRankSpecialPdValue(item)
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
        meseta = 0,
        scapes = 0,
        pd = 0,
        pc = 0,
        ps = 0,
        es = 0,
        espd = 0,
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

local function writeTotals(player, counts)
    io.write(string.format("    [\"%s\"] = {\n", tostring(player)))

    for key, value in pairs(counts) do
        io.write(string.format("        %s = %s,\n", key, value))
    end

    io.write("    },\n")
end
local function BuildAndSaveTotals(items, key)
    local _totals = DefaultTotals()
    _totals.meseta = items.meseta
    for key, value in pairs(items.items) do
        _totals = ParseTotals(_totals, value)
    end
    writeTotals(key, _totals)
end

local function BuildTotals(player, items, bank)
    BuildAndSaveTotals(items, player)
    local bankFile = player .. '~Bank'
    if bankIsShared then
        bankFile = 'shared'
    end
    BuildAndSaveTotals(bank, bankFile)
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
                if key ~= player and ((bankIsShared == false and key ~= player .. '~Bank') or (bankIsShared and key ~= 'shared')) then
                    io.write(string.format("    [\"%s\"] = {\n", tostring(key)))
                    for k, v in pairs(value) do
                        io.write(string.format("        %s = %s,\n", k, v))
                    end
                    io.write("},\n")
                end
            end

            BuildTotals(player, items, bank)

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
    for key, value in pairs(_totals) do
        if table[key] ~= nil then
            _totals[key] = value + table[key]
        end
    end
    return _totals
end

local function SaveInvAndBank(player)
    local charInv = 'addons/Backpack/data/' .. player .. '_inv.lua'
    local inv = lib_items.GetInventory(lib_items.Me)
    SaveItems(charInv, inv)
    package.loaded['Backpack.data.' .. player .. '_inv'] = nil
    local charBank = 'addons/Backpack/data/' .. player .. '_bank.lua'
    local bank = lib_items.GetBank()
    if bankIsShared then
        charBank = 'addons/Backpack/data/shared_bank.lua'
    end
    SaveItems(charBank, bank)
    if bankIsShared then
        package.loaded['Backpack.data.shared_bank'] = nil
    else
        package.loaded['Backpack.data.' .. player .. '_bank'] = nil
    end
    SaveTotals(player, inv, bank)
    package.loaded['Backpack.data.totals'] = nil
end

local TotalsText = {
    meseta = "Meseta: %i",
    scapes = "Scape Doll: %i",
    pd = "Photon Drop: %i",
    pc = "Photon Crystal: %i",
    ps = "Photon Sphere: %i",
    es = "S-Rank Count: %i",
    espd = "S-Rank Specials: %iPD",
    as = "AddSlot: %i",
    hp = "HP Material: %i",
    tp = "TP Material: %i",
    pow = "Power Material: %i",
    mind = "Mind Material: %i",
    luck = "Luck Material: %i",
    mg = "Monogrinder: %i",
    dg = "Digrinder: %i",
    tg = "Trigrinder: %i",
}

local TotalsOrdered = {
    "meseta",
    "scapes",
    "pd",
    "pc",
    "ps",
    "es",
    "espd",
    "as",
    "hp",
    "tp",
    "pow",
    "mind",
    "luck",
    "mg",
    "dg",
    "tg",
}

local function PresentBackpack()
    local player = lib_characters.GetSelf()
    local charLoaded, name = pcall(lib_characters.GetPlayerName, player)

    local location = pso.read_u32(0x00AAFC9C + 0x04)
    if charLoaded and name ~= nil then
        local class = lib_characters.GetPlayerClass(player)
        local classLoaded, className = pcall(lib_unitxt.GetClassName, class)
        local sectionId = lib_characters.GetPlayerSectionID(player)
        local sectionIdLoaded, sectionIdName = pcall(lib_unitxt.GetSectionIDName, sectionId)
        if classLoaded and sectionIdLoaded and className ~= nil and sectionIdName ~= nil then
            local char = tostring(name .. '~~~' .. className .. '~~~' .. sectionIdName);
            if Frame >= 30 then
                SaveChars(char)
                SaveInvAndBank(char);
                Frame = 0
            end
            Frame = Frame + 1
        end
    elseif location == 0 then
        if Frame >= 150 then
            bankIsShared = false
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
            for k, v in ipairs(TotalsOrdered) do
                if _totals[v] ~= nil then
                    imgui.Text(string.format(TotalsText[v], _totals[v]))
                end
            end
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
    local charsLoaded, chars = pcall(require, "Backpack.data.chars")
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
    local side = get_side_text()
    if string.find(side, "Bank: Shared") ~= nil then
        bankIsShared = true
    elseif string.find(side, "Bank: Character") ~= nil then
        bankIsShared = false
    end

    if (options.EnableWindow == true)
            and (options.HideWhenMenu == false or lib_menu.IsMenuOpen() == true)
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
    Frame = 0
    bankIsShared = false
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
