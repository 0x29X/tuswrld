local function spawnWeaponByName(name, amount)
    if MachoResourceInjectable('ox_inventory') then
        MachoInjectResourceRaw('ox_inventory', '_G.RemoveAllPedWeapons = function() end')
    end

    local setWeapon = GetHashKey(name)
    local ammo = amount or 250

    if MachoResourceInjectable('ReaperV4') then
        local hooked = false

        MachoHookNative(0x0A6DB4965674D243, function(...)
            if GetCurrentResourceName() ~= 'ReaperV4' then return true end
            hooked = true
            return false, setWeapon
        end)

        MachoHookNative(0x8483E98E8B888AE2, function(...)
            if GetCurrentResourceName() ~= 'ReaperV4' then return true end
            hooked = true
            return false, setWeapon
        end)

        MachoHookNative(0x3A87E44BB9A01D54, function(...)
            if GetCurrentResourceName() ~= 'ReaperV4' then return true end
            hooked = true
            return false, false, setWeapon
        end)

        MachoHookNative(0x8DECB02F88F428BC, function(...)
            if GetCurrentResourceName() ~= 'ReaperV4' then return true end
            hooked = true
            return false, false
        end)

        CreateThread(function()
            local timer = GetGameTimer()
            while not hooked and (GetGameTimer() - timer) < 5000 do
                Wait(50)
            end
            local ped = PlayerPedId()
            GiveWeaponToPed(ped, setWeapon, ammo, false, true)
            SetPedAmmo(ped, setWeapon, ammo)
        end)
    else
        local ped = PlayerPedId()
        GiveWeaponToPed(ped, setWeapon, ammo, false, true)
        SetPedAmmo(ped, setWeapon, ammo)
    end
end

Ascent_Menu_Config = {
    Debug = false,
    Version = "1.0",
}

Event_Randomizer = function(length)
    local res = {}
    local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    for i = 1, length do res[i] = chars:sub(math.random(#chars), math.random(#chars)) end
    return table.concat(res)
end

LoadAnimDict = function(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

function DrawText3Ds(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, true)
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    if onScreen then
        SetTextScale(0.0 * scale, 0.35 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(1, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

local AscentConfig1337 = {
    Name    = "Ascent",
    OwnerID = "NYERJoti0k",
    Secret  = "5c358e20c72f883d742b52cc96c7721b3071e8f8cc4fdad4195582e08a39f71e",
    Version = "1.0",
}

local function keyauthLog(color, msg)
    print(string.format("^%s[ASCENT][KeyAuth] %s", color, tostring(msg)))
end

local function urlEncode(str)
    if not str then return "" end
    return (string.gsub(tostring(str), "([^%w%-_.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local function extractJsonString(body, field)
    if not body then return nil end
    return body:match('"' .. field .. '"%s*:%s*"([^"]*)"')
end

local function isSuccess(body)
    if not body then return false end
    return body:match('"success"%s*:%s*true') ~= nil
end

if type(MachoMenuNotification) == "function" then
    pcall(MachoMenuNotification, "Info", "Loading...", "Loading & Authenticating key...", 4000)
end
Wait(1000)

local CurrentKey = (type(_G.AscentLicense) == "string" and #_G.AscentLicense > 20 and _G.AscentLicense)
    or (type(MachoAuthenticationKey) == "function" and MachoAuthenticationKey())
    or "INVALID"

local Key_Authorized = false
local User_Name = "Ascent"
local Key_Auth = tostring(CurrentKey)
local Key_Admin = false
local Key_Expires = "Lifetime"
local Username = "Angelica"
local ExpDate = "Lifetime"

local function authenticateWithKeyAuth()
    if type(MachoWebRequest) ~= "function" then
        keyauthLog("1", "Executor missing MachoWebRequest.")
        return false, "Missing MachoWebRequest function"
    end

    local initUrl = string.format(
        "https://keyauth.win/api/1.2/?type=init&name=%s&ownerid=%s&ver=%s",
        urlEncode(AscentConfig1337.Name),
        urlEncode(AscentConfig1337.OwnerID),
        urlEncode(AscentConfig1337.Version)
    )

    local okInit, initRes = pcall(MachoWebRequest, initUrl)
    if not okInit or not initRes or initRes == "" then
        keyauthLog("1", "KeyAuth init connection failed.")
        return false, "Failed to connect to KeyAuth"
    end

    if not isSuccess(initRes) then
        local msg = extractJsonString(initRes, "message") or "Init failed"
        keyauthLog("1", "KeyAuth init error: " .. msg)
        return false, msg
    end

    local sessionId = extractJsonString(initRes, "sessionid")
    if not sessionId or sessionId == "" then
        return false, "No session ID returned"
    end

    local userHWID = tostring(CurrentKey)
    if #userHWID < 20 then
        userHWID = userHWID .. string.rep("_", 20 - #userHWID)
    end

    local authUrl = string.format(
        "https://keyauth.win/api/1.2/?type=license&key=%s&hwid=%s&sessionid=%s&name=%s&ownerid=%s",
        urlEncode(CurrentKey),
        urlEncode(userHWID),
        urlEncode(sessionId),
        urlEncode(AscentConfig1337.Name),
        urlEncode(AscentConfig1337.OwnerID)
    )

    local okAuth, authRes = pcall(MachoWebRequest, authUrl)
    if not okAuth or not authRes or authRes == "" then
        return false, "Failed to verify key with KeyAuth"
    end

    if not isSuccess(authRes) then
        local msg = extractJsonString(authRes, "message") or "Invalid or expired key"
        return false, msg
    end

    local infoUser = extractJsonString(authRes, "username") or "Angelica"
    local expiryTimestamp = authRes:match('"expiry"%s*:%s*([0-9]+)') or authRes:match('"expiry"%s*:%s*"([0-9]+)"')
    local formattedExpiry = "Lifetime"

    if expiryTimestamp then
        local expNum = tonumber(expiryTimestamp)
        if expNum and expNum > 0 then
            local now = os.time()
            local diff = expNum - now
            if diff > 0 then
                local days = math.floor(diff / 86400)
                local hours = math.floor((diff % 86400) / 3600)
                local minutes = math.floor((diff % 3600) / 60)
                if days > 0 then
                    formattedExpiry = string.format("%d Days, %dh left", days, hours)
                elseif hours > 0 then
                    formattedExpiry = string.format("%dh %dm left", hours, minutes)
                else
                    formattedExpiry = string.format("%d min left", minutes)
                end
            else
                formattedExpiry = "Expired"
            end
        end
    end

    return true, "Success", infoUser, formattedExpiry
end

local isAuth, authMessage, authUser, authExp

if _G.AscentExpires and _G.Angelica then
    isAuth = true
    authUser = _G.Angelica
    authExp = _G.AscentExpires
    authMessage = "Success"
else
    isAuth, authMessage, authUser, authExp = authenticateWithKeyAuth()
end

if isAuth then
    Key_Authorized = true
    User_Name = authUser or "Angelica"
    Username = User_Name
    Key_Expires = authExp or "Lifetime"
    ExpDate = Key_Expires

    if type(MachoMenuNotification) == "function" then
        pcall(MachoMenuNotification, "success", "Ascent MENU", "Welcome, " .. User_Name .. "! Sub: " .. Key_Expires, 4000)
    end
    print("^2[ASCENT] Authenticated via KeyAuth successfully! User: " .. User_Name .. " | Subscription: " .. Key_Expires .. "^7")
    Wait(500)
    print("Thank You For Using Ascent Menu")
    Wait(500)
    print("Enjoy Using Ascent Menu")
    Wait(500)
else
    Key_Authorized = false
    if type(MachoMenuNotification) == "function" then
        pcall(MachoMenuNotification, "error", "Ascent MENU", "KEYAUTH ACCESS DENIED: " .. tostring(authMessage), 5000)
    end
    keyauthLog("1", "Authentication Failed: " .. tostring(authMessage))

    CreateThread(function()
        while true do
            Wait(0)
            HideHudAndRadarThisFrame()
            DrawRect(0.5, 0.5, 1.0, 1.0, 180, 20, 20, 255)
            SetTextFont(4)
            SetTextScale(0.7, 0.7)
            SetTextColour(255, 255, 255, 255)
            SetTextCentre(true)
            SetTextEntry("STRING")
            AddTextComponentString("[!] \n\nKEYAUTH AUTHENTICATION FAILED\n\n" .. tostring(authMessage) .. "\n\nPlease enter a valid KeyAuth key.")
            DrawText(0.5, 0.4)
        end
    end)

    return
end

if not Key_Admin and type(MachoLockLogger) == "function" then
    MachoLockLogger()
end

local Ascent = {}
local IsVisible = false
local DUI = nil
local HoveredIndex = 1
local ActiveMenu = {}
local CurrentMenu = ActiveMenu
local CurrentCategories = nil
local CurrentCategoryIndex = 1
local MenuStack = {}
local MenuLabelStack = {}
local LastUIState = nil
local MenuKey = "Insert"
local MenuOpenable = true
local MenuKeybinds = {}
local ShiftHolding = false
local CPlayers = {}
local SearchedPlayerId = nil
local WeaponsLabels = { [GetHashKey('weapon_unarmed')] = 'Fists', [GetHashKey('weapon_knife')] = 'Knife', [GetHashKey('weapon_nightstick')] = 'Nightstick', [GetHashKey('weapon_hammer')] = 'Hammer', [GetHashKey('weapon_bat')] = 'Baseball Bat', [GetHashKey('weapon_golfclub')] = 'Golf Club', [GetHashKey('weapon_crowbar')] = 'Crowbar', [GetHashKey('weapon_pistol')] = 'Pistol', [GetHashKey('weapon_pistol_mk2')] = 'Pistol Mk II', [GetHashKey('weapon_snspistol_mk2')] = 'SNS Pistol Mk II', [GetHashKey('weapon_ceramicpistol')] = 'Ceramic Pistol', [GetHashKey('weapon_revolver_mk2')] = 'Heavy Revolver Mk II', [GetHashKey('weapon_doubleaction')] = 'Double-Action Revolver', [GetHashKey('weapon_gadgetpistol')] = 'Gadget Pistol', [GetHashKey('weapon_pistolxm3')] = 'WM 29 Pistol', [GetHashKey('weapon_combatpistol')] = 'Combat Pistol', [GetHashKey('weapon_appistol')] = 'AP Pistol', [GetHashKey('weapon_pistol50')] = 'Pistol .50', [GetHashKey('weapon_microsmg')] = 'Micro SMG', [GetHashKey('weapon_smg')] = 'SMG', [GetHashKey('weapon_assaultsmg')] = 'Assault SMG', [GetHashKey('weapon_assaultrifle')] = 'Assault Rifle', [GetHashKey('weapon_assaultrifle_mk2')] = 'Assault Rifle Mk II', [GetHashKey('weapon_specialcarbine_mk2')] = 'Special Carbine Mk II', [GetHashKey('weapon_bullpuprifle_mk2')] = 'Bullpup Rifle Mk II', [GetHashKey('weapon_militaryrifle')] = 'Military Rifle', [GetHashKey('weapon_tacticalrifle')] = 'Service Carbine', [GetHashKey('weapon_battlerifle')] = 'Battle Rifle', [GetHashKey('weapon_carbinerifle')] = 'Carbine Rifle', [GetHashKey('weapon_advancedrifle')] = 'Advanced Rifle', [GetHashKey('weapon_mg')] = 'MG', [GetHashKey('weapon_combatmg')] = 'Combat MG', [GetHashKey('weapon_pumpshotgun')] = 'Pump Shotgun', [GetHashKey('weapon_sawnoffshotgun')] = 'Sawed-Off Shotgun', [GetHashKey('weapon_assaultshotgun')] = 'Assault Shotgun', [GetHashKey('weapon_bullpupshotgun')] = 'Bullpup Shotgun', [GetHashKey('weapon_hackingdevice')] = 'Hacking Device', [GetHashKey('weapon_stungun')] = 'Stun Gun', [GetHashKey('weapon_stungun_mp')] = 'Stun Gun MP', [GetHashKey('weapon_sniperrifle')] = 'Sniper Rifle', [GetHashKey('weapon_heavysniper')] = 'Heavy Sniper', [GetHashKey('weapon_grenadelauncher')] = 'Grenade Launcher', [GetHashKey('weapon_rpg')] = 'RPG', [GetHashKey('weapon_minigun')] = 'Minigun', [GetHashKey('weapon_grenade')] = 'Grenade', [GetHashKey('weapon_stickybomb')] = 'Sticky Bomb', [GetHashKey('weapon_smokegrenade')] = 'Smoke Grenade', [GetHashKey('weapon_bzgas')] = 'BZ Gas', [GetHashKey('weapon_molotov')] = 'Molotov Cocktail', [GetHashKey('weapon_fireextinguisher')] = 'Fire Extinguisher', [GetHashKey('weapon_petrolcan')] = 'Jerry Can', [GetHashKey('weapon_ball')] = 'Baseball', [GetHashKey('weapon_snspistol')] = 'SNS Pistol', [GetHashKey('weapon_bottle')] = 'Broken Bottle', [GetHashKey('weapon_gusenberg')] = 'Gusenberg Sweeper', [GetHashKey('weapon_specialcarbine')] = 'Special Carbine', [GetHashKey('weapon_heavypistol')] = 'Heavy Pistol', [GetHashKey('weapon_bullpuprifle')] = 'Bullpup Rifle', [GetHashKey('weapon_dagger')] = 'Dagger', [GetHashKey('weapon_vintagepistol')] = 'Vintage Pistol', [GetHashKey('weapon_firework')] = 'Firework Launcher', [GetHashKey('weapon_musket')] = 'Musket', [GetHashKey('weapon_heavyshotgun')] = 'Heavy Shotgun', [GetHashKey('weapon_marksmanrifle')] = 'Marksman Rifle', [GetHashKey('weapon_hominglauncher')] = 'Homing Launcher', [GetHashKey('weapon_proxmine')] = 'Proximity Mines', [GetHashKey('weapon_snowball')] = 'Snowball', [GetHashKey('weapon_flaregun')] = 'Flare Gun', [GetHashKey('weapon_garbagebag')] = 'Garbage Bag', [GetHashKey('weapon_handcuffs')] = 'Handcuffs', [GetHashKey('weapon_combatpdw')] = 'Combat PDW', [GetHashKey('weapon_marksmanpistol')] = 'Marksman Pistol', [GetHashKey('weapon_knuckle')] = 'Knuckle Dusters', [GetHashKey('weapon_hatchet')] = 'Hatchet', [GetHashKey('weapon_railgun')] = 'Railgun', [GetHashKey('weapon_machinepistol')] = 'Machine Pistol', [GetHashKey('weapon_switchblade')] = 'Switchblade', [GetHashKey('weapon_revolver')] = 'Heavy Revolver', [GetHashKey('weapon_heavyrifle')] = 'Heavy Rifle', [GetHashKey('weapon_dbshotgun')] = 'Double Barrel Shotgun', [GetHashKey('weapon_compactrifle')] = 'Compact Rifle', [GetHashKey('weapon_battleaxe')] = 'Battle Axe', [GetHashKey('weapon_compactlauncher')] = 'Compact Grenade Launcher', [GetHashKey('weapon_minismg')] = 'Mini SMG', [GetHashKey('weapon_pipebomb')] = 'Pipe Bomb', [GetHashKey('weapon_poolcue')] = 'Pool Cue', [GetHashKey('weapon_wrench')] = 'Wrench', [GetHashKey('weapon_autoshotgun')] = 'Sweeper Shotgun', [GetHashKey('weapon_bread')] = 'Piece of Bread', [GetHashKey('weapon_stone_hatchet')] = 'Stone Hatchet', [GetHashKey('weapon_rayminigun')] = 'Unholy Hellbringer', [GetHashKey('weapon_raycarbine')] = 'Widowmaker', [GetHashKey('weapon_compactgrenadelauncher')] = 'Compact Grenade Launcher', [GetHashKey('weapon_smugglerpistol')] = 'Up-n-Atomizer', [GetHashKey('weapon_raypistol')] = 'Up-n-Atomizer', [GetHashKey('weapon_perico_pistol')] = 'Ceramic Pistol', [GetHashKey('weapon_carbinerifle_mk2')] = 'Carbine Rifle Mk II', [GetHashKey('weapon_combatmg_mk2')] = 'Combat MG Mk II', [GetHashKey('weapon_heavysniper_mk2')] = 'Heavy Sniper Mk II', [GetHashKey('weapon_marksmanrifle_mk2')] = 'Marksman Rifle Mk II', [GetHashKey('weapon_pumpshotgun_mk2')] = 'Pump Shotgun Mk II', [GetHashKey('weapon_smg_mk2')] = 'SMG Mk II', [GetHashKey('weapon_raycarbine_mk2')] = 'Widowmaker Mk II', [GetHashKey('weapon_machete')] = 'Machete', [GetHashKey('weapon_flashlight')] = 'Flashlight', [GetHashKey('weapon_hazardousknife')] = 'Hazardous Knife', [GetHashKey('weapon_navyrevolver')] = 'Navy Revolver', [GetHashKey('weapon_golfball')] = 'Golf Ball' }

local FreecamEnabled = false
local LastWeaponFired = nil
local CurrentWeaponIndex = 1
local CurrentVehicleIndex = 1
local CurrentMapDestroyerIndex = 1
local CurrentSpawnObjectIndex = 1
local FreecamWeaponList = { "WEAPON_APPISTOL", "WEAPON_PISTOL", "WEAPON_SMG", "WEAPON_ASSAULTRIFLE", "WEAPON_RPG", "WEAPON_PERMKILL", "WEAPON_AIRSTRIKE_ROCKET" }
local FreecamVehicleList = { "Adder", "Zentorno", "Comet", "Banshee", "Trash", "Dump" }
local FreecamMapDestroyerList = { "City", "Docks", "Playa Vista", "Mountain", "Pink Cage", "Vespucci", "Mega Mall", "Platform", "Big Ring", "Tube", "Dessert", "Goal", "Big Statue 2", "House" }
local FreecamSpawnObjectList = { "Big Tires", "Dome", "Black Surface", "Spinning Object", "Arena Fire", "Landmine", "Big Wheels", "Cnt Arena", "Arena Skull", "Arena Bomb", "Waste Rims" }
local FreecamOptions = { "Default", "Teleport", "Shoot Weapon", "Shoot Vehicle", "Map Destroyer", "Spawn Object", "Helicopter Attack" }
local FreecamHoveredIndex = 1
local fgawjFmaDjdALaO = false
local fovEnabled = false
local fovShow = false
local fovRadius = 100
local MappedKeys = {
    [27] = "Escape", [112] = "F1", [113] = "F2",
    [114] = "F3", [115] = "F4", [116] = "F5",
    [117] = "F6", [118] = "F7", [119] = "F8",
    [120] = "F9", [121] = "F10", [122] = "F11",
    [123] = "F12", [192] = "`",
    [49] = "1", [50] = "2", [51] = "3",
    [52] = "4", [53] = "5", [54] = "6",
    [55] = "7", [56] = "8", [57] = "9",
    [48] = "0", [189] = "-", [187] = "=",
    [8] = "Backspace", [9] = "Tab", [45] = "Insert", [81] = "Q",
    [87] = "W", [69] = "E", [82] = "R",
    [84] = "T", [89] = "Y", [85] = "U",
    [73] = "I", [79] = "O", [80] = "P",
    [219] = "[", [221] = "]", [220] = "\\",
    [20] = "CapsLock", [65] = "A", [83] = "S",
    [68] = "D", [70] = "F", [71] = "G",
    [72] = "H", [74] = "J", [75] = "K",
    [76] = "L", [186] = ";", [222] = "'",
    [13] = "Enter", [16] = "Shift", [90] = "Z",
    [88] = "X", [67] = "C", [86] = "V",
    [66] = "B", [78] = "N", [77] = "M",
    [188] = ",", [190] = ".", [191] = "/",
    [17] = "Control", [46] = "Delete", [33] = "PageUp",
    [34] = "PageDown", [35] = "End", [36] = "Home",
    [38] = "ArrowUp", [40] = "ArrowDown", [37] = "ArrowLeft", [39] = "ArrowRight"
}

local VK_TO_FIVEM = {
    [27] = 322,
    [112] = 288,
    [113] = 289,
    [114] = 170,
    [115] = 167,
    [116] = 166,
    [117] = 168,
    [118] = 169,
    [119] = 170,
    [120] = 56,
    [121] = 57,
    [122] = 344,
    [123] = 345,
    [192] = 243,
    [49] = 157,
    [50] = 158,
    [51] = 160,
    [52] = 164,
    [53] = 165,
    [54] = 159,
    [55] = 161,
    [56] = 162,
    [57] = 163,
    [48] = 82,
    [189] = 84,
    [187] = 83,
    [8] = 177,
    [9] = 37,
    [45] = 121,
    [81] = 44,
    [87] = 32,
    [69] = 46,
    [82] = 45,
    [84] = 245,
    [89] = 246,
    [85] = 303,
    [73] = 74,
    [79] = 199,
    [80] = 7,
    [219] = 39,
    [221] = 40,
    [220] = 36,
    [20] = 137,
    [65] = 34,
    [83] = 33,
    [68] = 30,
    [70] = 49,
    [71] = 47,
    [72] = 74,
    [74] = 311,
    [75] = 311,
    [76] = 7,
    [186] = 81,
    [222] = 82,
    [13] = 18,
    [16] = 21,
    [90] = 20,
    [88] = 73,
    [67] = 26,
    [86] = 0,
    [66] = 29,
    [78] = 249,
    [77] = 244,
    [188] = 82,
    [190] = 81,
    [191] = 83,
    [17] = 36,
    [46] = 178,
    [33] = 10,
    [34] = 11,
    [35] = 213,
    [36] = 213,
    [38] = 27,
    [40] = 173,
    [37] = 174,
    [39] = 175
}

local WeaponList = {
    ["weapon_unarmed"] = {label = "Unarmed", hash = GetHashKey("weapon_unarmed")},
    ["weapon_knife"] = {label = "Knife", hash = GetHashKey("weapon_knife")},
    ["weapon_dagger"] = {label = "Dagger", hash = GetHashKey("weapon_dagger")},
    ["weapon_bat"] = {label = "Baseball Bat", hash = GetHashKey("weapon_bat")},
    ["weapon_bottle"] = {label = "Broken Bottle", hash = GetHashKey("weapon_bottle")},
    ["weapon_crowbar"] = {label = "Crowbar", hash = GetHashKey("weapon_crowbar")},
    ["weapon_golfclub"] = {label = "Golf Club", hash = GetHashKey("weapon_golfclub")},
    ["weapon_hammer"] = {label = "Hammer", hash = GetHashKey("weapon_hammer")},
    ["weapon_hatchet"] = {label = "Hatchet", hash = GetHashKey("weapon_hatchet")},
    ["weapon_machete"] = {label = "Machete", hash = GetHashKey("weapon_machete")},
    ["weapon_switchblade"] = {label = "Switchblade", hash = GetHashKey("weapon_switchblade")},
    ["weapon_nightstick"] = {label = "Nightstick", hash = GetHashKey("weapon_nightstick")},
    ["weapon_wrench"] = {label = "Wrench", hash = GetHashKey("weapon_wrench")},
    ["weapon_pistol"] = {label = "Pistol", hash = GetHashKey("weapon_pistol")},
    ["weapon_pistol_mk2"] = {label = "Pistol Mk II", hash = GetHashKey("weapon_pistol_mk2")},
    ["weapon_combatpistol"] = {label = "Combat Pistol", hash = GetHashKey("weapon_combatpistol")},
    ["weapon_appistol"] = {label = "AP Pistol", hash = GetHashKey("weapon_appistol")},
    ["weapon_stungun"] = {label = "Taser", hash = GetHashKey("weapon_stungun")},
    ["weapon_pistol50"] = {label = "Pistol .50", hash = GetHashKey("weapon_pistol50")},
    ["weapon_snspistol"] = {label = "SNS Pistol", hash = GetHashKey("weapon_snspistol")},
    ["weapon_heavypistol"] = {label = "Heavy Pistol", hash = GetHashKey("weapon_heavypistol")},
    ["weapon_vintagepistol"] = {label = "Vintage Pistol", hash = GetHashKey("weapon_vintagepistol")},
    ["weapon_flaregun"] = {label = "Flare Gun", hash = GetHashKey("weapon_flaregun")},
    ["weapon_microsmg"] = {label = "Micro SMG", hash = GetHashKey("weapon_microsmg")},
    ["weapon_smg"] = {label = "SMG", hash = GetHashKey("weapon_smg")},
    ["weapon_smg_mk2"] = {label = "SMG Mk II", hash = GetHashKey("weapon_smg_mk2")},
    ["weapon_assaultsmg"] = {label = "Assault SMG", hash = GetHashKey("weapon_assaultsmg")},
    ["weapon_machinepistol"] = {label = "Machine Pistol", hash = GetHashKey("weapon_machinepistol")},
    ["weapon_minismg"] = {label = "Mini SMG", hash = GetHashKey("weapon_minismg")},
    ["weapon_combatpdw"] = {label = "Combat PDW", hash = GetHashKey("weapon_combatpdw")},
    ["weapon_assaultrifle"] = {label = "Assault Rifle", hash = GetHashKey("weapon_assaultrifle")},
    ["weapon_assaultrifle_mk2"] = {label = "Assault Rifle Mk II", hash = GetHashKey("weapon_assaultrifle_mk2")},
    ["weapon_carbinerifle"] = {label = "Carbine Rifle", hash = GetHashKey("weapon_carbinerifle")},
    ["weapon_carbinerifle_mk2"] = {label = "Carbine Rifle Mk II", hash = GetHashKey("weapon_carbinerifle_mk2")},
    ["weapon_advancedrifle"] = {label = "Advanced Rifle", hash = GetHashKey("weapon_advancedrifle")},
    ["weapon_specialcarbine"] = {label = "Special Carbine", hash = GetHashKey("weapon_specialcarbine")},
    ["weapon_bullpuprifle"] = {label = "Bullpup Rifle", hash = GetHashKey("weapon_bullpuprifle")},
    ["weapon_bullpuprifle_mk2"] = {label = "Bullpup Rifle Mk II", hash = GetHashKey("weapon_bullpuprifle_mk2")},
    ["weapon_compactrifle"] = {label = "Compact Rifle", hash = GetHashKey("weapon_compactrifle")},
    ["weapon_marksmanrifle"] = {label = "Marksman Rifle", hash = GetHashKey("weapon_marksmanrifle")},
    ["weapon_pumpshotgun"] = {label = "Pump Shotgun", hash = GetHashKey("weapon_pumpshotgun")},
    ["weapon_pumpshotgun_mk2"] = {label = "Pump Shotgun Mk II", hash = GetHashKey("weapon_pumpshotgun_mk2")},
    ["weapon_sawnoffshotgun"] = {label = "Sawed-Off Shotgun", hash = GetHashKey("weapon_sawnoffshotgun")},
    ["weapon_assaultshotgun"] = {label = "Assault Shotgun", hash = GetHashKey("weapon_assaultshotgun")},
    ["weapon_bullpupshotgun"] = {label = "Bullpup Shotgun", hash = GetHashKey("weapon_bullpupshotgun")},
    ["weapon_heavyshotgun"] = {label = "Heavy Shotgun", hash = GetHashKey("weapon_heavyshotgun")},
    ["weapon_autoshotgun"] = {label = "Auto Shotgun", hash = GetHashKey("weapon_autoshotgun")},
    ["weapon_sniperrifle"] = {label = "Sniper Rifle", hash = GetHashKey("weapon_sniperrifle")},
    ["weapon_heavysniper"] = {label = "Heavy Sniper", hash = GetHashKey("weapon_heavysniper")},
    ["weapon_heavysniper_mk2"] = {label = "Heavy Sniper Mk II", hash = GetHashKey("weapon_heavysniper_mk2")},
    ["weapon_marksmanrifle_mk2"] = {label = "Marksman Rifle Mk II", hash = GetHashKey("weapon_marksmanrifle_mk2")},
    ["weapon_grenade"] = {label = "Grenade", hash = GetHashKey("weapon_grenade")},
    ["weapon_stickybomb"] = {label = "Sticky Bomb", hash = GetHashKey("weapon_stickybomb")},
    ["weapon_molotov"] = {label = "Molotov Cocktail", hash = GetHashKey("weapon_molotov")},
    ["weapon_pipebomb"] = {label = "Pipe Bomb", hash = GetHashKey("weapon_pipebomb")},
    ["weapon_proxmine"] = {label = "Proximity Mine", hash = GetHashKey("weapon_proxmine")},
    ["weapon_rpg"] = {label = "RPG", hash = GetHashKey("weapon_rpg")},
    ["weapon_grenadelauncher"] = {label = "Grenade Launcher", hash = GetHashKey("weapon_grenadelauncher")},
    ["weapon_hominglauncher"] = {label = "Homing Launcher", hash = GetHashKey("weapon_hominglauncher")},
    ["weapon_minigun"] = {label = "Minigun", hash = GetHashKey("weapon_minigun")},
    ["weapon_railgun"] = {label = "Railgun", hash = GetHashKey("weapon_railgun")},
    ["weapon_ball"] = {label = "Baseball", hash = GetHashKey("weapon_ball")},
    ["weapon_smokegrenade"] = {label = "Smoke Grenade", hash = GetHashKey("weapon_smokegrenade")},
    ["weapon_flare"] = {label = "Flare", hash = GetHashKey("weapon_flare")},
    ["weapon_petrolcan"] = {label = "Jerry Can", hash = GetHashKey("weapon_petrolcan")},
    ["weapon_bzgas"] = {label = "BZ Gas", hash = GetHashKey("weapon_bzgas")}
}

local InjectionType = GetResourceState("WaveShield") == "started" and "Raw" or "Default"
local Injection = InjectionType == "Raw" and MachoInjectResourceRaw or MachoInjectResource

local targetRes = (GetResourceState("lunar_fishing") == "started" and "lunar_fishing") or (GetResourceState("jg-advancedgarages") == "started" and "jg-advancedgarages") or (GetResourceState("jg-dealerships") == "started" and "jg-dealerships") or (GetResourceState("cd_garage") == "started" and "cd_garage") or (GetResourceState("cfx-bg-garages") == "started" and "cfx-bg-garages") or (GetResourceState("es_extended") == "started" and "es_extended") or "any"
local targetSafeRes = (GetResourceState("es_extended") == "started" and "es_extended") or (GetResourceState("ox_lib") == "started" and "ox_lib") or "any"

local IsDetections = GetResourceState("seph") == 'started' or GetResourceState("sxph_idsystem") == 'started'

function Ascent:Debug(color, text)
    if not Ascent_Menu_Config.Debug then return end
    local debugColors = { ["red"] = "^1", ["yellow"] = "^3", ["green"] = "^2", ["info"] = "^5" }
    print((debugColors[color] or "^5") .. "[ASCENT] " .. tostring(text) .. "^7")
end

function Ascent:SendMessage(data)
    if not DUI or not data or type(data) ~= "table" then
        return
    end
    MachoSendDuiMessage(DUI, json.encode(data))
end

function Ascent:Notify(type, title, desc, duration)
    self:SendMessage({ action = "showNotification", type = type, title = title, desc = desc, duration = duration })
end

function Ascent:GetMenuPath()
    local path = {}
    for i = 1, #MenuLabelStack do
        table.insert(path, MenuLabelStack[i])
    end
    return path
end

function Ascent:UpdateElements(elements)
    if not elements or type(elements) ~= "table" then
        return
    end

    local payload = {
        action = "updateElements",
        elements = elements,
        index = HoveredIndex - 1,
        path = self:GetMenuPath()
    }

    if CurrentCategories and type(CurrentCategories) == "table" and #CurrentCategories > 0 then
        payload.categories = CurrentCategories
        payload.categoryIndex = (CurrentCategoryIndex or 1) - 1
    end

    self:SendMessage(payload)
end

function Ascent:Initialize()
    MenuOpenable = false

    DUI = MachoCreateDui("https://tuswrld.xyz/ascent/asc.html")
    if DUI then
        self:Debug("yellow", "Creating & Initializing DUI...")
        MachoShowDui(DUI)
        self:Debug("green", "DUI Created & Initialized Successfully!")

        Wait(500)
        self:SendMessage({ action = "startInjection" })
        self:SendMessage({ action = "setBannerImage", url = "https://file.garden/atTpdg76zTCB65gN/ascentxxx.png" })

        Wait(5800)
        MenuOpenable = true
        self:Debug("green", "Ascent Menu Ready.")
    else
        MenuOpenable = false
        self:Debug("red", "Failed to Create DUI")
    end
end

function Ascent:HideUI(keepState)
    if keepState then
        LastUIState = {
            currentMenu = CurrentMenu,
            hoveredIndex = HoveredIndex,
            menuStack = MenuStack,
            menuLabelStack = MenuLabelStack,
            currentCategories = CurrentCategories,
            currentCategoryIndex = CurrentCategoryIndex
        }
    else
        LastUIState = nil
    end

    IsVisible = false
    self:SendMessage({ action = "keydown", index = 0 })
    self:SendMessage({ action = "showUI", visible = false, index = 0 })
end

function Ascent:ShowUI()
    IsVisible = true

    if LastUIState then
        CurrentMenu = LastUIState.currentMenu
        HoveredIndex = LastUIState.hoveredIndex
        MenuStack = LastUIState.menuStack
        MenuLabelStack = LastUIState.menuLabelStack
        CurrentCategories = LastUIState.currentCategories
        CurrentCategoryIndex = LastUIState.currentCategoryIndex
        LastUIState = nil
    else
        HoveredIndex = 1
        CurrentMenu = ActiveMenu
        CurrentCategories = nil
        CurrentCategoryIndex = 1
        MenuStack = {}
        MenuLabelStack = {}
    end

    local payload = {
        action = "showUI",
        visible = true,
        elements = CurrentMenu,
        index = HoveredIndex - 1,
        path = self:GetMenuPath(),
        username = Username or "AscentBypass",
        expiration = ExpDate or "N/A"
    }

    if CurrentCategories and #CurrentCategories > 0 then
        payload.categories = CurrentCategories
        payload.categoryIndex = CurrentCategoryIndex - 1
    end

    self:SendMessage(payload)
end

function Ascent:IsShiftHeld()
    return ShiftHolding
end

MachoOnKeyDown(function(vk)
    if vk == 0x10 or vk == 0xA0 or vk == 0xA1 then
        ShiftHolding = true
    end
end)

MachoOnKeyUp(function(vk)
    if vk == 0x10 or vk == 0xA0 or vk == 0xA1 then
        ShiftHolding = false
    end
end)

local CurrentKeyboardInput = nil

local function KeyboardInput(Title, Value, OnConfirm, InputType)
    if CurrentKeyboardInput then
        Ascent:Notify("error", "Ascent", "Close current input first", 2000)
        return
    end

    CurrentKeyboardInput = {
        title = Title,
        buffer = Value or "",
        maxLength = 32,
        onConfirm = OnConfirm,
        type = InputType or "typeable",
        closeable = InputType == "keybind" and false or true,
        active = true
    }

    MachoSendDuiMessage(DUI, json.encode({
        action = "updateKeyboard",
        visible = true,
        title = Title,
        value = CurrentKeyboardInput.buffer
    }))

    if GetResourceState("rryban_secure") == "started" then

    elseif GetResourceState("Eminence") == "started" then

    elseif GetResourceState("AegisX") == "started" then

    elseif GetResourceState("cfx-praryo-kernel") == "started" then

    elseif GetResourceState("amari-utils") == "started" then

    elseif GetResourceState("VynxAC") == "started" then

    else
        MachoInjectResourceRaw("monitor", [[ SetNuiFocus(true, false) sendMenuMessage('setDebugMode') ]])
    end

    Wait(250)
    Ascent:HideUI(true)
    MenuOpenable = false
end

MachoOnKeyDown(function(vk)
    if not CurrentKeyboardInput or not CurrentKeyboardInput.active then return end

    if vk == 0x0D then
        CurrentKeyboardInput.active = false
        MachoSendDuiMessage(DUI, json.encode({ action = "updateKeyboard", visible = false }))
        if CurrentKeyboardInput.onConfirm then
            CurrentKeyboardInput.onConfirm(CurrentKeyboardInput.buffer)
        end

        if GetResourceState("rryban_secure") == "started" then

        elseif GetResourceState("Eminence") == "started" then

        elseif GetResourceState("AegisX") == "started" then

        elseif GetResourceState("cfx-praryo-kernel") == "started" then

        elseif GetResourceState("amari-utils") == "started" then

        elseif GetResourceState("VynxAC") == "started" then

        else
            MachoInjectResourceRaw("monitor", [[ SetNuiFocus(false, false) sendMenuMessage('setGameName') ]])
        end

        CurrentKeyboardInput = nil
        MenuOpenable = true
        return
    elseif vk == 0x08 then
        if CurrentKeyboardInput.type == "typeable" then
            CurrentKeyboardInput.buffer = CurrentKeyboardInput.buffer:sub(1, -2)
        else
            CurrentKeyboardInput.buffer = ""
        end
    elseif vk == 0x1B then
        if not CurrentKeyboardInput.closeable then
            return
        end

        if GetResourceState("rryban_secure") == "started" then

        elseif GetResourceState("Eminence") == "started" then

        elseif GetResourceState("AegisX") == "started" then

        elseif GetResourceState("cfx-praryo-kernel") == "started" then

        elseif GetResourceState("amari-utils") == "started" then

        elseif GetResourceState("VynxAC") == "started" then

        else
            MachoInjectResourceRaw("monitor", [[ SetNuiFocus(false, false) sendMenuMessage('setGameName') ]])
        end

        CurrentKeyboardInput.active = false
        MachoSendDuiMessage(DUI, json.encode({ action = "updateKeyboard", visible = false }))
        CurrentKeyboardInput = nil
        MenuOpenable = true
        return
    else
        if CurrentKeyboardInput.type == "keybind" then
            local keyName = MappedKeys[vk]
            if keyName then
                if CurrentKeyboardInput.buffer ~= keyName then
                    CurrentKeyboardInput.buffer = keyName
                end
            end
        elseif CurrentKeyboardInput.type == "typeable" then
            local AllowedChars = {
                [0x30] = "0", [0x31] = "1", [0x32] = "2", [0x33] = "3", [0x34] = "4",
                [0x35] = "5", [0x36] = "6", [0x37] = "7", [0x38] = "8", [0x39] = "9",
                [0x41] = "A", [0x42] = "B", [0x43] = "C", [0x44] = "D", [0x45] = "E",
                [0x46] = "F", [0x47] = "G", [0x48] = "H", [0x49] = "I", [0x4A] = "J",
                [0x4B] = "K", [0x4C] = "L", [0x4D] = "M", [0x4E] = "N", [0x4F] = "O",
                [0x50] = "P", [0x51] = "Q", [0x52] = "R", [0x53] = "S", [0x54] = "T",
                [0x55] = "U", [0x56] = "V", [0x57] = "W", [0x58] = "X", [0x59] = "Y",
                [0x5A] = "Z", [0xBD] = "-", [0xBB] = "=", [0xBC] = ",", [0xBE] = ".",
                [0xBA] = ";", [0xDE] = "'", [0xBF] = "/", [0xC0] = "`", [0x20] = " "
            }

            local char = AllowedChars[vk]
            if char and #CurrentKeyboardInput.buffer < CurrentKeyboardInput.maxLength then
                if Ascent:IsShiftHeld() then
                    if char:match("%a") then
                        char = char:upper()
                    elseif char == "-" then
                        char = "_"
                    end
                else
                    if char:match("%a") then
                        char = char:lower()
                    end
                end
                CurrentKeyboardInput.buffer = CurrentKeyboardInput.buffer .. char
            end
        end
    end

    if CurrentKeyboardInput then
        MachoSendDuiMessage(DUI, json.encode({
            action = "updateKeyboard",
            visible = true,
            title = CurrentKeyboardInput.title,
            value = CurrentKeyboardInput.buffer
        }))
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        if CurrentKeyboardInput ~= nil then
            if GetResourceState("rryban_secure") == "started" then

            elseif GetResourceState("Eminence") == "started" then

            elseif GetResourceState("AegisX") == "started" then

            elseif GetResourceState("cfx-praryo-kernel") == "started" then

            elseif GetResourceState("amari-utils") == "started" then

            elseif GetResourceState("VynxAC") == "started" then

            else
                MachoInjectResourceRaw("monitor", [[ SetNuiFocus(true, false) sendMenuMessage('setDebugMode') ]])
            end
            SetPauseMenuActive(false)

            for i = 0, 357 do
                if i < 0x30 or i > 0x5A then
                    DisableControlAction(0, i, true)
                end
            end
        else
            Wait(500)
        end
    end
end)

function Ascent:ScrollOne(direction)
    if not direction or #CurrentMenu == 0 then
        return
    end

    local attempts = 0
    repeat
        if direction == "Up" then
            HoveredIndex = HoveredIndex - 1
            if HoveredIndex < 1 then HoveredIndex = #CurrentMenu end
        elseif direction == "Down" then
            HoveredIndex = HoveredIndex + 1
            if HoveredIndex > #CurrentMenu then HoveredIndex = 1 end
        end
        attempts = attempts + 1
        if attempts > 200 then break end
    until CurrentMenu[HoveredIndex] and CurrentMenu[HoveredIndex].type ~= "divider"

    if DUI then
        self:SendMessage({ action = "keydown", index = HoveredIndex - 1 })
    end
end

function Ascent:ScrollTwo(direction)
    local hoveredTab = CurrentMenu[HoveredIndex]
    if not hoveredTab then return end

    if (hoveredTab.type == "scrollable" or hoveredTab.type == "scrollable-checkbox")
        and hoveredTab.values and #hoveredTab.values > 0 then

        hoveredTab.value = hoveredTab.value or 1

        if direction == "Left" then
            hoveredTab.value = hoveredTab.value - 1
            if hoveredTab.value < 1 then hoveredTab.value = #hoveredTab.values end
        elseif direction == "Right" then
            hoveredTab.value = hoveredTab.value + 1
            if hoveredTab.value > #hoveredTab.values then hoveredTab.value = 1 end
        end

        self:UpdateElements(CurrentMenu)

        if hoveredTab.scrollType == "onScroll" and hoveredTab.onSelect then
            if hoveredTab.type == "scrollable-checkbox" then
                hoveredTab.onSelect(hoveredTab.values[hoveredTab.value], hoveredTab.checked or false)
            else
                hoveredTab.onSelect(hoveredTab.values[hoveredTab.value])
            end
        end
    elseif hoveredTab.type == "slider" or hoveredTab.type == "slider-checkbox" then
        hoveredTab.value = hoveredTab.value or hoveredTab.min or 0
        local step = hoveredTab.step or 1

        if direction == "Left" then
            hoveredTab.value = math.max((hoveredTab.min or 0), hoveredTab.value - step)
        elseif direction == "Right" then
            hoveredTab.value = math.min((hoveredTab.max or 100), hoveredTab.value + step)
        end

        for _, data in pairs(MenuKeybinds) do
            if data.type == "slider-checkbox" and data.value ~= nil and data.label == hoveredTab.label then
                if direction == "Left" then
                    data.value = math.max((hoveredTab.min or 0), hoveredTab.value - step)
                elseif direction == "Right" then
                    data.value = math.min((hoveredTab.max or 100), hoveredTab.value + step)
                else
                    return
                end
            end
        end

        self:UpdateElements(CurrentMenu)

        if hoveredTab.scrollType == "onScroll" and hoveredTab.onSelect then
            if hoveredTab.type == "slider-checkbox" then
                hoveredTab.onSelect(hoveredTab.value, hoveredTab.checked or false)
            else
                hoveredTab.onSelect(hoveredTab.value)
            end
        end
    end
end

function Ascent:Enter()
    if not CurrentMenu or #CurrentMenu == 0 then return end
    local current = CurrentMenu[HoveredIndex]
    if not current then return end
    if not MenuOpenable then return end

    if current.type == "subMenu" then
        table.insert(MenuStack, { menu = CurrentMenu, categories = CurrentCategories, categoryIndex = CurrentCategoryIndex })
        table.insert(MenuLabelStack, current.label or "Submenu")

        if current.label == "Online Options" then
            Ascent:UpdateListMenu()
        end

        if current.categories and type(current.categories) == "table" and #current.categories > 0 then
            CurrentCategories = current.categories
            CurrentCategoryIndex = 1
            CurrentMenu = CurrentCategories[CurrentCategoryIndex].tabs or {}
            HoveredIndex = 1
            self:UpdateElements(CurrentMenu)
            return
        end

        if current.subTabs and type(current.subTabs) == "table" and #current.subTabs > 0 then
            CurrentCategories = nil
            CurrentCategoryIndex = 1
            CurrentMenu = current.subTabs
            HoveredIndex = 1
            self:UpdateElements(CurrentMenu)
            return
        end

        return
    end

    if current.type == "button" and current.onSelect and type(current.onSelect) == "function" then
        local ok, err = pcall(current.onSelect)
        if not ok then self:Debug("red", "onSelect error: " .. tostring(err)) end
        return
    end

    if current.type == "checkbox" or current.type == "scrollable-checkbox" or current.type == "slider-checkbox" then
        if current.locked then
            Ascent:Notify("error", "Ascent", "This module has been disabled due to high detection rates!", 3000)
            return
        end

        if type(current.checked) ~= "boolean" then
            current.checked = true
        else
            current.checked = not current.checked
        end

        if current.onSelect and type(current.onSelect) == "function" then
            if current.type == "scrollable-checkbox" then
                local ok, err = pcall(current.onSelect, current.values[current.value], current.checked)
                if not ok then self:Debug("red", "scrollable-checkbox onSelect error: " .. tostring(err)) end
            elseif current.type == "slider-checkbox" then
                local ok, err = pcall(current.onSelect, current.value, current.checked)
                if not ok then self:Debug("red", "slider-checkbox onSelect error: " .. tostring(err)) end
            else
                local ok, err = pcall(current.onSelect, current.checked)
                if not ok then self:Debug("red", "checkbox onSelect error: " .. tostring(err)) end
            end
        end

        self:UpdateElements(CurrentMenu)
        return
    end

    if current.type == "scrollable" or current.type == "scrollable-checkbox" then
        if current.values and type(current.values) == "table" and #current.values > 0 then
            if current.onSelect then
                current.onSelect(current.values[current.value])
            end
        end
        return
    end

    if current.type == "slider" or current.type == "slider-checkbox" then
        if current.scrollType == "onEnter" and current.onSelect then
            if current.type == "slider-checkbox" then
                current.onSelect(current.value, current.checked or false)
            else
                current.onSelect(current.value)
            end
        end
        return
    end
end

function Ascent:Backspace()
    if #MenuStack > 0 then
        local last = table.remove(MenuStack)
        table.remove(MenuLabelStack)
        CurrentMenu = last.menu or ActiveMenu
        CurrentCategories = last.categories
        CurrentCategoryIndex = last.categoryIndex or 1
        HoveredIndex = 1
        self:UpdateElements(CurrentMenu)
    else
        self:HideUI()
    end
end

function Ascent:PrevCategory()
    if not CurrentCategories or #CurrentCategories == 0 then return end
    CurrentCategoryIndex = CurrentCategoryIndex - 1
    if CurrentCategoryIndex < 1 then CurrentCategoryIndex = #CurrentCategories end
    CurrentMenu = CurrentCategories[CurrentCategoryIndex].tabs or {}
    HoveredIndex = 1
    self:UpdateElements(CurrentMenu)
    self:SendMessage({ action = "keydown", index = HoveredIndex - 1 })
end

function Ascent:NextCategory()
    if not CurrentCategories or #CurrentCategories == 0 then return end
    CurrentCategoryIndex = CurrentCategoryIndex + 1
    if CurrentCategoryIndex > #CurrentCategories then CurrentCategoryIndex = 1 end
    CurrentMenu = CurrentCategories[CurrentCategoryIndex].tabs or {}
    HoveredIndex = 1
    self:UpdateElements(CurrentMenu)
    self:SendMessage({ action = "keydown", index = HoveredIndex - 1 })
end

local setHooks = {}
local hookedNatives = {}
local safeLoadedScripts = {}

local function CreateHook(hookType, cb)
    setHooks[hookType] = cb
end

local function HookNative(setHash, callback)
    hookedNatives[#hookedNatives + 1] = MachoHookNative(setHash, function(...)
        if GetCurrentResourceName() == 'lb-phone' or GetCurrentResourceName() == 'illenium-appearance' then
            return true
        end
        return callback(...)
    end)
end

HookNative(0x68EDDA28A5976D07, function() return false, false end)

HookNative(0xA571D46727E2B718, function(padIndex)
    if padIndex == 0 then return false, false end
    return true
end)

HookNative(0x1CEA6BFDF248E5D9, function(padIndex, control)
    if control == 1 or control == 2 then
        return false, true
    end
    return true
end)

HookNative(0xB15162CB5826E9E8, function() return false, true end)
HookNative(0xD9D2CFFF49FAB35F, function() return false, true end)
HookNative(0x036F97C908C2B52C, function() return false, true end)
HookNative(0xF5F1E89A970B7796, function() return false, true end)
HookNative(0xCA9D2AA3E326D720, function() return false, true end)
HookNative(0x19CAFA3C87F7C2FF, function() return false, 3 end)

HookNative(0x0C515FAB3FF9EA92, function(propType, data)
    if menuInjected and propType and data then
        if propType == 'SetClient_LoadedSafeFuncs' then
            safeLoadedScripts[data] = true
        elseif propType == 'Ascent.Hook' then
            data = json.decode(data)
            if data then
                local hookData = data.HookData
                if hookData then
                    local setHook = setHooks[hookData.HookType]
                    if setHook then
                        CreateThread(function()
                            setHook(table.unpack(hookData.SetArgs))
                        end)
                    end
                end
            end
        end
    end
    return true
end)

local stoppedResources = {}
local MainAPI = {}
MainAPI.StopResource = function(resource)
    stoppedResources[resource] = true
    MachoResourceStop(resource)
    MainAPI.Debug('Stopped resource', resource)
end

MainAPI.StartResource = function(resource)
    stoppedResources[resource] = nil
    MachoResourceStart(resource)
    MainAPI.Debug('Started resource', resource)
end

MainAPI.ResourceLoop = function(resource, pattern, w1, w2)
    CreateThread(function()
        while true do
            if pattern == "stop" then
                MachoResourceStop(resource)
                Wait(w1)
            elseif pattern == "stop_start" then
                MachoResourceStop(resource)
                Wait(w1)
                MachoResourceStart(resource)
                Wait(w2)
            else
                MachoResourceStart(resource)
                Wait(w1)
                MachoResourceStop(resource)
                Wait(w2)
            end
        end
    end)
end

local function executeCode(resource, code)
    local IsRyban = GetResourceState("rryban_secure") == "started"

    if IsRyban then
        local setCode = [[
            local Ascent = {}
            Ascent.SafeRunNative = function(setFunc, ...)
                return setFunc(...)
            end
            ]] .. code .. [[
        ]]
        MachoInjectResourceScriptOverride(1, resource, setCode, '@citizen:/scripting/lua/scheduler.lua', 1, 999)
        return
    end

    code = [[
        local Ascent = {}

        Ascent.RunId = 'RUN_ID'

        Ascent.StringFind = string.find
        Ascent.StringChar = string.char
        Ascent.StringLower = string.lower
        Ascent.TableUnpack = table.unpack

        Ascent.EXT_FUNCREF = 10

        Ascent.PackValueExt = function(tag, data)
            local len = #data
            if len == 1 then
                return Ascent.StringChar(0xD4, tag)..data
            elseif len == 2 then
                return Ascent.StringChar(0xD5, tag)..data
            elseif len == 4 then
                return Ascent.StringChar(0xD6, tag)..data
            elseif len == 8 then
                return Ascent.StringChar(0xD7, tag)..data
            elseif len == 16 then
                return Ascent.StringChar(0xD8, tag)..data
            elseif len <= 255 then
                return Ascent.StringChar(0xC7, len, tag)..data
            elseif len <= 65535 then
                return Ascent.StringChar(0xC8, math.floor(len / 256), len % 256, tag)..data
            end
        end

        Ascent.PackValue = function(val)
            local t = val ~= nil and type(val)
            if val == nil then
                return Ascent.StringChar(0xC0)
            elseif t == 'boolean' then
                return Ascent.StringChar(val and 0xC3 or 0xC2)
            elseif t == 'number' then
                if val % 1 == 0 then
                    if val >= 0 and val <= 127 then
                        return Ascent.StringChar(val)
                    elseif val < 0 and val >= -32 then
                        return Ascent.StringChar(0x100 + val)
                    elseif val >= 0 and val <= 0xFF then
                        return Ascent.StringChar(0xCC, val)
                    elseif val >= 0 and val <= 0xFFFF then
                        return Ascent.StringChar(0xCD, math.floor(val / 256), val % 256)
                    elseif val >= -128 and val < 0 then
                        return Ascent.StringChar(0xD0, 0x100 + val)
                    elseif val >= -32768 and val < 0 then
                        local v = 0x10000 + val
                        return Ascent.StringChar(0xD1, math.floor(v / 256), v % 256)
                    end
                end
                local buf = string.pack('>d', val)
                return Ascent.StringChar(0xCB) .. buf
            elseif t == 'string' then
                local len = #val
                if len <= 31 then
                    return Ascent.StringChar(0xA0 + len) .. val
                elseif len <= 255 then
                    return Ascent.StringChar(0xD9, len) .. val
                elseif len <= 65535 then
                    return Ascent.StringChar(0xDA, math.floor(len / 256), len % 256) .. val
                end
            elseif t == 'function' then
                local ref = Citizen.GetFunctionReference(val)
                if ref then
                    return Ascent.PackValueExt(Ascent.EXT_FUNCREF, ref)
                else
                    error('Cannot pack non-referenced function')
                end
            elseif t == 'table' then
                local cfxRef = rawget(val, '__cfx_functionReference')
                if cfxRef then
                    local ref = Citizen.GetFunctionReference(val)
                    if ref then
                        return Ascent.PackValueExt(Ascent.EXT_FUNCREF, ref)
                    end
                end
                local n = #val
                local header
                if n <= 15 then
                    header = Ascent.StringChar(0x90 + n)
                elseif n <= 65535 then
                    header = Ascent.StringChar(0xDC, math.floor(n / 256), n % 256)
                end
                local parts = { header }
                for i = 1, n do
                    parts[#parts + 1] = Ascent.PackValue(val[i])
                end
                return table.concat(parts)
            end
        end

        Ascent.RawSafeRunNative = function(native, ...)
            local funcRef = msgpack.unpack(Ascent.PackValue(native))
            return funcRef(...)
        end

        Ascent.SetSafeStateBag = function(bag, key, value, synced)
            if value == nil then return end
            local payload = Ascent.PackValue(value)
            if payload == nil then return end
            Ascent.RawSafeRunNative(SetStateBagValue, bag, key, payload, #payload, synced)
        end

        Ascent.SetSafeLocalState = function(key, value, synced)
            return Ascent.SetSafeStateBag('player:'..GetPlayerServerId(PlayerId()), key, value, synced or false)
        end

        Ascent.CachedSafeFuncs = {}

        Ascent.GetSafeFunc = function(func)
            local safeFunc = Ascent.CachedSafeFuncs[func]
            if safeFunc then return safeFunc end
            local serverId = GetPlayerServerId(PlayerId())
            local bag = 'player:'..serverId
            local key = '__cfx_stateBag::'..Ascent.RunId..'::'..math.random(999999)..'::'..GetGameTimer()
            Ascent.SetSafeStateBag(bag, key, func, false)
            safeFunc = Player(serverId).state[key]
            Ascent.CachedSafeFuncs[func] = safeFunc
            return safeFunc
        end

        Ascent.SafeRunNative = function(setNative, ...)
            local safeFunc = Ascent.GetSafeFunc(setNative)
            return safeFunc(...)
        end

        Ascent.SafeCall = function(cb, ...)
            local callArgs = {...}
            local createThread = Ascent.GetSafeFunc(Citizen.CreateThreadNow)
            local safeCb = Ascent.GetSafeFunc(cb)
            createThread(function()
                safeCb(Ascent.TableUnpack(callArgs))
            end)
        end

        Ascent.DeleteTrackedThread = function(threadName)
            if _G.SetClient_TrackedSafeThreads then
                local setThreadCb = _G.SetClient_TrackedSafeThreads[threadName]
                if setThreadCb then setThreadCb() end
            end
        end

        Ascent.DeleteAllTrackedThreads = function()
            if _G.SetClient_TrackedSafeThreads then
                local setTrackedThreads = {}
                for threadName, setThreadCb in pairs(_G.SetClient_TrackedSafeThreads) do
                    if setThreadCb then setTrackedThreads[#setTrackedThreads + 1] = setThreadCb end
                end
                _G.SetClient_TrackedSafeThreads = nil
                for i = 1, #setTrackedThreads do
                    Ascent.SafeCall(setTrackedThreads[i])
                end
            end
        end

        Ascent.CreateTrackedThread = function(threadName, setHandlers)
            Ascent.DeleteTrackedThread(threadName)
            Ascent.SafeCall(function()
                setHandlers.isActive = true
                _G.SetClient_TrackedSafeThreads = _G.SetClient_TrackedSafeThreads or {}
                _G.SetClient_TrackedSafeThreads[threadName] = function()
                    setHandlers.isActive = false
                    if _G.SetClient_TrackedSafeThreads then
                        _G.SetClient_TrackedSafeThreads[threadName] = nil
                    end
                    if setHandlers.onRemove then setHandlers:onRemove() end
                end
                setHandlers:thread()
            end)
        end

        Ascent.GetEntityParent = function(entity)
            local selfPed = entity or PlayerPedId()
            local selfVehicle = GetVehiclePedIsIn(selfPed, false)
            local selfEntity = selfPed
            if selfVehicle and selfVehicle > 0 and selfPed == GetPedInVehicleSeat(selfVehicle, -1) then
                selfEntity = selfVehicle
            end
            return selfEntity
        end

        Ascent.SafeWrapValue = function(setVal)
            return function(...)
                local Promise = promise.new()
                local setArgs = {...}
                Ascent.SafeCall(function()
                    Promise:resolve(setVal(Ascent.TableUnpack(setArgs)))
                end)
                return Citizen.Await(Promise)
            end
        end

        local AreStringsEqual = Ascent.SafeWrapValue(AreStringsEqual)

        Ascent.GetSafeArgs = function(setArgs)
            for setKey, setValue in pairs(setArgs) do
                local setType = type(setValue)
                if setType == 'function' then
                    setValue = tostring(setValue)
                elseif setType == 'table' then
                    setValue = Ascent.GetSafeArgs(setValue)
                end
                setArgs[setKey] = setValue
            end
            return setArgs
        end

        Ascent.SendToHook = function(hookType, ...)
            Ascent.SafeRunNative(AreStringsEqual, 'Ascent.Hook', json.encode({
                HookData = {
                    HookType = hookType,
                    SetArgs = Ascent.GetSafeArgs({...})
                }
            }))
        end

        ]]..code..[[
    ]]

    code = code:gsub('RUN_ID', math.random(999999)..'-'..GetGameTimer())
    MachoInjectResourceScriptOverride(1, resource, code, '@citizen:/scripting/lua/scheduler.lua', 1, 9999)
end

local selectedVehicle = nil
local isVehicleFlying = false
local Control_Vehicle_Thread = nil
local Control_Vehicle = false

function IsEntityPositionFrozen(entity)
    if not entity or not DoesEntityExist(entity) then return false end
    return GetEntitySpeed(entity) <= 0.01
end

function ToggleFreezeVehicle(vehicle)
    if vehicle and DoesEntityExist(vehicle) then
        local isFrozen = IsEntityPositionFrozen(vehicle)
        FreezeEntityPosition(vehicle, not isFrozen)
        if not isFrozen then
            Ascent:Notify("success", "Ascent", "Vehicle Frozen.", 3000)
        else
            Ascent:Notify("error", "Ascent", "Vehicle Unfrozen.", 3000)
        end
    else
        Ascent:Notify("error", "Ascent", "No vehicle selected.", 3000)
    end
end

function DrawVehicleOutline(vehicle)
    if vehicle and DoesEntityExist(vehicle) then
        SetEntityDrawOutline(vehicle, true)
        SetEntityDrawOutlineColor(88, 57, 59, 255)
    end
end

function GetClosestVehicle()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestVehicle = nil
    local closestDistance = 10.0
    for vehicle in EnumerateVehicles() do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(playerCoords - vehicleCoords)
        if distance < closestDistance then
            closestVehicle = vehicle
            closestDistance = distance
        end
    end
    return closestVehicle
end

function EnumerateVehicles() return coroutine.wrap(function() local vehiclePool = GetGamePool('CVehicle') for i = 1, #vehiclePool do coroutine.yield(vehiclePool[i]) end end) end

function Ascent:ToggleFreecam(state, speed)
    if type(state) ~= "boolean" then return end

    if state then
        FreecamEnabled = true
        MachoSendDuiMessage(DUI, json.encode({ action = "displayFreecam", visible = true, weaponIndex = CurrentWeaponIndex, vehicleIndex = CurrentVehicleIndex, mapIndex = CurrentMapDestroyerIndex, objectIndex = CurrentSpawnObjectIndex }))

        if GetResourceState("dre-scripts") == "started" then
            executeCode('dre-scripts', [[
                Ascent.SafeRunNative(TriggerServerEvent, "dre-freecam:sv:fiveguardbypasson")
            ]])
        elseif GetResourceState("xevi-freecam") == "started" then
            executeCode('xevi-freecam', [[
                Ascent.SafeRunNative(TriggerServerEvent, "xevi-freecam:sv:setFreecamState", true)
                Ascent.SafeRunNative(TriggerServerEvent, "xevi-freecam:sv:fiveguardbypasson")
            ]])
        elseif GetResourceState("dre-freecam") == "started" then
            executeCode('dre-freecam', [[
                Ascent.SafeRunNative(TriggerServerEvent, "catdev_freecam:sv:fiveguardbypasson")
            ]])
        end

        executeCode(targetSafeRes, [[
            _G.AscentFreecamSpeed = ]] .. speed .. [[

            if not _G.AscentFreecamThreadRunning then
                _G.AscentFreecamEnabled = true
                _G.AscentFreecamThreadRunning = true

                function _G.hNative(nativeName, newFunction)
                    local originalNative = _G[nativeName]
                    if not originalNative or type(originalNative) ~= "function" then return end
                    _G[nativeName] = function(...) return newFunction(originalNative, ...) end
                end

                local function RotationToDirection(rot)
                    local z = math.rad(rot.z)
                    local x = math.rad(rot.x)
                    local num = math.abs(math.cos(x))
                    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                end

                local function GetRightVector(rot)
                    local z = math.rad(rot.z)
                    return vector3(math.cos(z), math.sin(z), 0.0)
                end

                local function Clamp(val, min, max)
                    if val < min then return min end
                    if val > max then return max end
                    return val
                end

                _G.RotationToDirection = RotationToDirection
                _G.GetRightVector = GetRightVector
                _G.Clamp = Clamp

                _G.hNative("RotationToDirection", function(o, ...) return o(...) end)
                _G.hNative("GetRightVector", function(o, ...) return o(...) end)
                _G.hNative("Clamp", function(o, ...) return o(...) end)
                _G.hNative("CreateThread", function(o, ...) return o(...) end)
                _G.hNative("Wait", function(o, ...) return o(...) end)
                _G.hNative("IsVehicleSeatFree", function(o, ...) return o(...) end)
                _G.hNative("PlayerPedId", function(o, ...) return o(...) end)
                _G.hNative("GetEntityCoords", function(o, ...) return o(...) end)
                _G.hNative("CreateCam", function(o, ...) return o(...) end)
                _G.hNative("DoesCamExist", function(o, ...) return o(...) end)
                _G.hNative("SetCamCoord", function(o, ...) return o(...) end)
                _G.hNative("SetCamRot", function(o, ...) return o(...) end)
                _G.hNative("RenderScriptCams", function(o, ...) return o(...) end)
                _G.hNative("DestroyCam", function(o, ...) return o(...) end)
                _G.hNative("SetFocusEntity", function(o, ...) return o(...) end)
                _G.hNative("GetCamCoord", function(o, ...) return o(...) end)
                _G.hNative("GetCamRot", function(o, ...) return o(...) end)
                _G.hNative("IsControlPressed", function(o, ...) return o(...) end)
                _G.hNative("GetDisabledControlNormal", function(o, ...) return o(...) end)
                _G.hNative("TaskStandStill", function(o, ...) return o(...) end)
                _G.hNative("SetFocusPosAndVel", function(o, ...) return o(...) end)
                _G.hNative("StartExpensiveSynchronousShapeTestLosProbe", function(o, ...) return o(...) end)
                _G.hNative("GetShapeTestResult", function(o, ...) return o(...) end)
                _G.hNative("IsControlJustPressed", function(o, ...) return o(...) end)
                _G.hNative("IsDisabledControlJustPressed", function(o, ...) return o(...) end)
                _G.hNative("IsEntityAVehicle", function(o, ...) return o(...) end)
                _G.hNative("TaskWarpPedIntoVehicle", function(o, ...) return o(...) end)
                _G.hNative("SetEntityCoords", function(o, ...) return o(...) end)
                _G.hNative("GiveWeaponToPed", function(o, ...) return o(...) end)
                _G.hNative("SetCurrentPedWeapon", function(o, ...) return o(...) end)
                _G.hNative("ShootSingleBulletBetweenCoords", function(o, ...) return o(...) end)

                local rendering = Ascent.SafeRunNative(GetRenderingCam)
                local camPos, camRot, camFov
                if rendering ~= -1 and rendering ~= nil then
                    camPos = Ascent.SafeRunNative(GetCamCoord, rendering)
                    camRot = Ascent.SafeRunNative(GetCamRot, rendering, 2)
                    camFov = Ascent.SafeRunNative(GetCamFov, rendering)
                else
                    camPos = Ascent.SafeRunNative(GetGameplayCamCoord)
                    camRot = Ascent.SafeRunNative(GetGameplayCamRot, 2)
                    camFov = Ascent.SafeRunNative(GetGameplayCamFov)
                end

                _G.AscentFreecamObject = Ascent.SafeRunNative(CreateCam, "DEFAULT_SCRIPTED_CAMERA", true)
                Ascent.SafeRunNative(SetCamCoord, _G.AscentFreecamObject, camPos.x, camPos.y, camPos.z)
                Ascent.SafeRunNative(SetCamRot, _G.AscentFreecamObject, camRot.x, camRot.y, camRot.z, 2)
                Ascent.SafeRunNative(SetCamFov, _G.AscentFreecamObject, camFov)
                Ascent.SafeRunNative(RenderScriptCams, true, false, 0, true, true)

                local targetFov = 70.0
                local duration = 100
                local startFov = camFov
                local startTime = Ascent.SafeRunNative(GetGameTimer)

                Ascent.SafeRunNative(CreateThread, function()
                    while true do
                        local now = Ascent.SafeRunNative(GetGameTimer)
                        local progress = (now - startTime) / duration
                        if progress >= 1.0 then
                            Ascent.SafeRunNative(SetCamFov, _G.AscentFreecamObject, targetFov)
                            break
                        end
                        local eased = 1 - (1 - progress) * (1 - progress)
                        Ascent.SafeRunNative(SetCamFov, _G.AscentFreecamObject, startFov + (targetFov - startFov) * eased)
                        Ascent.SafeRunNative(Wait, 0)
                    end
                end)

                Ascent.SafeRunNative(CreateThread, function()
                    while _G.AscentFreecamThreadRunning do
                        Ascent.SafeRunNative(Wait, 0)
                        if _G.AscentFreecamObject then
                            local coords = Ascent.SafeRunNative(GetCamCoord, _G.AscentFreecamObject)
                            local rot = Ascent.SafeRunNative(GetCamRot, _G.AscentFreecamObject, 2)
                            local beforeSpeed = _G.AscentFreecamSpeed or 0.25
                            local speed = Ascent.SafeRunNative(IsControlPressed, 0, 21) and beforeSpeed + 1.0 or beforeSpeed
                            local forward = _G.RotationToDirection(rot)
                            local right = _G.GetRightVector(rot)
                            local moveX, moveY, moveZ = 0, 0, 0

                            Ascent.SafeRunNative(TaskStandStill, Ascent.SafeRunNative(PlayerPedId), 10)
                            Ascent.SafeRunNative(SetFocusPosAndVel, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)

                            if Ascent.SafeRunNative(IsControlPressed, 0, 32) then moveX = moveX + forward.x * speed moveY = moveY + forward.y * speed moveZ = moveZ + forward.z * speed end
                            if Ascent.SafeRunNative(IsControlPressed, 0, 33) then moveX = moveX - forward.x * speed moveY = moveY - forward.y * speed moveZ = moveZ - forward.z * speed end
                            if Ascent.SafeRunNative(IsControlPressed, 0, 34) then moveX = moveX - right.x * speed moveY = moveY - right.y * speed end
                            if Ascent.SafeRunNative(IsControlPressed, 0, 35) then moveX = moveX + right.x * speed moveY = moveY + right.y * speed end
                            if Ascent.SafeRunNative(IsControlPressed, 0, 22) then moveZ = moveZ + speed end
                            if Ascent.SafeRunNative(IsControlPressed, 0, 36) then moveZ = moveZ - speed end

                            Ascent.SafeRunNative(SetCamCoord, _G.AscentFreecamObject, coords.x + moveX, coords.y + moveY, coords.z + moveZ)

                            local x = Ascent.SafeRunNative(GetDisabledControlNormal, 0, 1)
                            local y = Ascent.SafeRunNative(GetDisabledControlNormal, 0, 2)
                            local newPitch = _G.Clamp(rot.x - y * 5, -89.0, 89.0)
                            local newYaw = rot.z - x * 5
                            Ascent.SafeRunNative(SetCamRot, _G.AscentFreecamObject, newPitch, rot.y, newYaw, 2)
                        end
                    end
                end)
            else
                _G.AscentFreecamEnabled = true
            end
        ]])
    else
        FreecamEnabled = false
        MachoSendDuiMessage(DUI, json.encode({ action = "displayFreecam", visible = false }))
        if GetResourceState("dre-scripts") == "started" then
            executeCode('dre-scripts', [[ Ascent.SafeRunNative(TriggerServerEvent, "dre-freecam:sv:deactivate") ]])
        elseif GetResourceState("xevi-freecam") == "started" then
            executeCode('xevi-freecam', [[
                Ascent.SafeRunNative(TriggerServerEvent, "xevi-freecam:sv:setFreecamState", false)
                Ascent.SafeRunNative(TriggerServerEvent, "xevi-freecam:sv:fiveguardbypassoff")
            ]])
        elseif GetResourceState("dre-freecam") == "started" then
            executeCode('dre-freecam', [[ Ascent.SafeRunNative(TriggerServerEvent, "catdev_freecam:sv:fiveguardbypassoff") ]])
        end
        executeCode(targetSafeRes, [[
            _G.AscentFreecamEnabled = false
            _G.AscentFreecamThreadRunning = false

            if _G.AscentFreecamObject then
                Ascent.SafeRunNative(RenderScriptCams, false, false, 0, true, true)
                Ascent.SafeRunNative(DestroyCam, _G.AscentFreecamObject, false)
                _G.AscentFreecamObject = nil
            end
            Ascent.SafeRunNative(SetFocusEntity, PlayerPedId())
        ]])
    end
end

function Ascent:EnableInfiniteAmmo(checked)
    if checked then
        if not _G.InfiniteAmmo then
            _G.InfiniteAmmo = true
            CreateThread(function()
                while _G.InfiniteAmmo do
                    Wait(0)
                    local ped = PlayerPedId()
                    local _, weapon = GetCurrentPedWeapon(ped, true)
                    if weapon and weapon ~= 0 then
                        local w1, w2 = GetMaxAmmoInClip(ped, weapon, true)
                        local maxClip = type(w2) == "number" and w2 or (type(w1) == "number" and w1 or 999)
                        if maxClip > 0 then
                            SetAmmoInClip(ped, weapon, maxClip)
                        end
                        SetPedAmmo(ped, weapon, 999999)
                        if IsPedShooting(ped) then
                            local ammo = GetAmmoInPedWeapon(ped, weapon)
                            SetPedAmmo(ped, weapon, (type(ammo) == "number" and ammo or 999) + 1)
                        end
                    end
                end
            end)
        end
    else
        _G.InfiniteAmmo = false
    end
end

function Ascent:SpawnSelectedObject(playerIds, modelOverride)
    if not playerIds or #playerIds == 0 then
        Ascent:Notify("error", "Ascent", "No players selected!", 3000)
        return
    end
    local model = modelOverride or self:GetSelectedObjectModel()
    if not model or #model == 0 then
        Ascent:Notify("error", "Ascent", "Invalid object model!", 3000)
        return
    end
    for _, playerId in ipairs(playerIds) do
        MachoInjectResource(targetSafeRes, string.format([[
            Citizen.CreateThread(function()
                local sid = %d
                local modelName = %q
                local model = GetHashKey(modelName)
                RequestModel(model)
                local timeout = GetGameTimer() + 5000
                while not HasModelLoaded(model) and GetGameTimer() < timeout do
                    Wait(10)
                end
                if not HasModelLoaded(model) then return end

                local targetPed = 0
                for _, pid in ipairs(GetActivePlayers()) do
                    if GetPlayerServerId(pid) == sid then
                        targetPed = GetPlayerPed(pid)
                        break
                    end
                end

                if targetPed ~= 0 and DoesEntityExist(targetPed) then
                    local coords = GetEntityCoords(targetPed)
                    local obj = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
                    if obj ~= 0 and DoesEntityExist(obj) then
                        SetEntityAsMissionEntity(obj, true, true)
                        FreezeEntityPosition(obj, true)
                        AttachEntityToEntity(obj, targetPed, 0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0, false, false, true, false, 0, true)
                    end
                end
                SetModelAsNoLongerNeeded(model)
            end)
        ]], playerId, model))
    end
end

function Ascent:SpawnSelectedObjects(playerIds, modelOverride)
    if not playerIds or #playerIds == 0 then
        Ascent:Notify("error", "Ascent", "No players selected!", 3000)
        return
    end
    local model = modelOverride or self:GetSelectedObjectModel()
    if not model or #model == 0 then
        Ascent:Notify("error", "Ascent", "Invalid object model!", 3000)
        return
    end
    for _, playerId in ipairs(playerIds) do
        MachoInjectResource(targetSafeRes, string.format([[
            Citizen.CreateThread(function()
                local sid = %d
                local modelName = %q
                local model = GetHashKey(modelName)
                RequestModel(model)
                local timeout = GetGameTimer() + 5000
                while not HasModelLoaded(model) and GetGameTimer() < timeout do
                    Wait(10)
                end
                if not HasModelLoaded(model) then return end

                local targetPed = 0
                for _, pid in ipairs(GetActivePlayers()) do
                    if GetPlayerServerId(pid) == sid then
                        targetPed = GetPlayerPed(pid)
                        break
                    end
                end

                if targetPed ~= 0 and DoesEntityExist(targetPed) then
                    local coords = GetEntityCoords(targetPed)
                    local obj = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
                    if obj ~= 0 and DoesEntityExist(obj) then
                        SetEntityAsMissionEntity(obj, true, true)
                        FreezeEntityPosition(obj, true)
                    end
                end
                SetModelAsNoLongerNeeded(model)
            end)
        ]], playerId, model))
    end
end

local isSpectatorListVisible = false
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if isSpectatorListVisible then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local updatedSpecs = {}
            local players = GetActivePlayers()
            for _, playerId in ipairs(players) do
                local ped = GetPlayerPed(playerId)
                if DoesEntityExist(ped) and playerId ~= PlayerId() then
                    local isVisible = IsEntityVisible(ped)
                    local dist = #(playerCoords - GetEntityCoords(ped))
                    if not isVisible and dist < 500.0 then
                        table.insert(updatedSpecs, {
                            id = GetPlayerServerId(playerId),
                            name = GetPlayerName(playerId),
                            distance = string.format("%.0fm", dist)
                        })
                    end
                end
            end
            Ascent:SendMessage({
                action = "displaySpectators",
                visible = true,
                spectators = updatedSpecs
            })
        end
    end
end)

local targetResource = nil
if GetResourceState("es_extended") == "started" and GetResourceState("timeless-emotes") == "started" then
    targetResource = "es_extended"
elseif GetResourceState("core") == "started" and GetResourceState("timeless-emotes") == "started" then
    targetResource = "core"
end

function Ascent:GodemodeState(checked)
    if GetResourceState('VynxAC') == 'started' then
        local ped = PlayerPedId()
        SetEntityInvincible(ped, checked)
    else
        executeCode('any', string.format([[
            local setPed = PlayerPedId()
            Ascent.SafeRunNative(SetEntityInvincible, setPed, %s)
        ]], tostring(checked)))
    end
end

function Ascent:EnableInvisibility(checked)
    if GetResourceState('VynxAC') == 'started' then
        local ped = PlayerPedId()
        SetEntityVisible(ped, not checked, false)
    else
        executeCode('any', string.format([[
            local selfPed = PlayerPedId()
            Ascent.SafeRunNative(SetEntityVisible, selfPed, not %s, false)
        ]], tostring(checked)))
    end
end

function Ascent:HandleAttackClonePlayer(playerIds)
    if not playerIds or #playerIds == 0 then return end

    local playerIdsStr = table.concat(playerIds, ",")
    MachoHookNative(0x240A18690AE96513, function(modelHash)
        return true, modelHash
    end)

    MachoHookNative(0xD49F9B0955C367DE, function(model, x, y, z, heading, isNetwork, thisScriptCheck)
        return true, model, x, y, z, heading, isNetwork, thisScriptCheck
    end)

    MachoInjectResourceRaw(targetSafeRes, string.format([[
        local function decode(tbl)
            local s = ""
            for i = 1, #tbl do s = s .. string.char(tbl[i]) end
            return s
        end
        local function g(n)
            return _G[decode(n)]
        end
        local function wait(n)
            return Citizen.Wait(n)
        end
        local function findClientIdByServerId(sid)
            local players = g({71,101,116,65,99,116,105,118,101,80,108,97,121,101,114,115})()
            for _, pid in ipairs(players) do
                if g({71,101,116,80,108,97,121,101,114,83,101,114,118,101,114,73,100})(pid) == sid then
                    return pid
                end
            end
            return nil
        end
        local function copyPedAppearance(sourcePed, targetPed)
            for i = 0, 11 do
                local drawable = g({71,101,116,80,101,100,68,114,97,119,97,98,108,101,86,97,114,105,97,116,105,111,110})(sourcePed, i)
                local texture = g({71,101,116,80,101,100,84,101,120,116,117,114,101,86,97,114,105,97,116,105,111,110})(sourcePed, i)
                g({83,101,116,80,101,100,67,111,109,112,111,110,101,110,116,86,97,114,105,97,116,105,111,110})(targetPed, i, drawable, texture, 2)
            end
            for i = 0, 7 do
                local propIndex = g({71,101,116,80,101,100,80,114,111,112,73,110,100,101,120})(sourcePed, i)
                local propTexture = g({71,101,116,80,101,100,80,114,111,112,84,101,120,116,117,114,101,73,110,100,101,120})(sourcePed, i)
                if propIndex ~= -1 then
                    g({83,101,116,80,101,100,80,114,111,112})(targetPed, i, propIndex, propTexture)
                else
                    g({67,108,101,97,114,80,101,100,80,114,111,112})(targetPed, i)
                end
            end
            local headBlendData = {g({71,101,116,80,101,100,72,101,97,100,66,108,101,110,100,68,97,116,97})(sourcePed)}
            if headBlendData[1] then
                g({83,101,116,80,101,100,72,101,97,100,66,108,101,110,100,68,97,116,97})(
                    targetPed,
                    headBlendData[2], headBlendData[3], headBlendData[4],
                    headBlendData[5], headBlendData[6], headBlendData[7],
                    headBlendData[8], headBlendData[9], headBlendData[10]
                )
            end
        end
        local function clonePed(ped)
            local coords = g({71,101,116,69,110,116,105,116,121,67,111,111,114,100,115})(ped)
            local heading = g({71,101,116,69,110,116,105,116,121,72,101,97,100,105,110,103})(ped)
            local modelHash = g({71,101,116,69,110,116,105,116,121,77,111,100,101,108})(ped)
            g({82,101,113,117,101,115,116,77,111,100,101,108})(modelHash)
            local timeout = 0
            while not g({72,97,115,77,111,100,101,108,76,111,97,100,101,100})(modelHash) and timeout < 500 do
                wait(10)
                timeout = timeout + 1
            end
            if not g({72,97,115,77,111,100,101,108,76,111,97,100,101,100})(modelHash) then return end
            local spawnRadius = 2.0
            local spawnX = coords.x + (math.random() * 2 - 1) * spawnRadius
            local spawnY = coords.y + (math.random() * 2 - 1) * spawnRadius
            local spawnZ = coords.z
            local clone = g({67,114,101,97,116,101,80,101,100})(4, modelHash, spawnX, spawnY, spawnZ, heading, true, true)
            if clone and g({68,111,101,115,69,110,116,105,116,121,69,120,105,115,116})(clone) then
                copyPedAppearance(ped, clone)
                g({83,101,116,69,110,116,105,116,121,65,115,77,105,115,115,105,111,110,69,110,116,105,116,121})(clone, true, true)
                g({83,101,116,77,111,100,101,108,65,115,78,111,76,111,110,103,101,114,78,101,101,100,101,100})(modelHash)
                local cloneGroup = g({65,100,100,82,101,108,97,116,105,111,110,115,104,105,112,71,114,111,117,112})("HOSTILE_CLONE_" .. tostring(clone))
                g({83,101,116,80,101,100,82,101,108,97,116,105,111,110,115,104,105,112,71,114,111,117,112,72,97,115,104})(clone, cloneGroup)
                g({83,101,116,82,101,108,97,116,105,111,110,115,104,105,112,66,101,116,119,101,101,110,71,114,111,117,112,115})(5, cloneGroup, g({71,101,116,72,97,115,104,75,101,121})("PLAYER"))
                g({83,101,116,82,101,108,97,116,105,111,110,115,104,105,112,66,101,116,119,101,101,110,71,114,111,117,112,115})(5, g({71,101,116,72,97,115,104,75,101,121})("PLAYER"), cloneGroup)

                local weaponHash = g({71,101,116,72,97,115,104,75,101,121})(decode({87,69,65,80,79,78,95,83,84,85,78,71,85,78}))
                g({71,105,118,101,87,101,97,112,111,110,84,111,80,101,100})(clone, weaponHash, 1000, false, true)
                local weaponEntity = g({71,101,116,67,117,114,114,101,110,116,80,101,100,87,101,97,112,111,110,69,110,116,105,116,121,73,110,100,101,120})(clone)
                if weaponEntity and g({68,111,101,115,69,110,116,105,116,121,69,120,105,115,116})(weaponEntity) then
                    g({83,101,116,69,110,116,105,116,121,65,115,77,105,115,115,105,111,110,69,110,116,105,116,121})(weaponEntity, true, true)
                end
                g({83,101,116,80,101,100,68,114,111,112,115,87,101,97,112,111,110,115,87,104,101,110,68,101,97,100})(clone, false)
                g({83,101,116,80,101,100,67,97,110,83,119,105,116,99,104,87,101,97,112,111,110})(clone, false)
                g({84,97,115,107,67,111,109,98,97,116,80,101,100})(clone, ped, 0, 16)
                g({83,101,116,80,101,100,67,111,109,98,97,116,65,116,116,114,105,98,117,116,101,115})(clone, 0, true)
                g({83,101,116,80,101,100,70,108,101,101,65,116,116,114,105,98,117,116,101,115})(clone, 0, false)
                g({83,101,116,69,110,116,105,116,121,73,110,118,105,110,99,105,98,108,101})(clone, true)
                g({83,101,116,80,101,100,67,97,110,82,97,103,100,111,108,108})(clone, false)
            end
        end
        local playerIds = {%s}
        for _, targetServerId in ipairs(playerIds) do
            local clientId = findClientIdByServerId(targetServerId)
            local ped = clientId and g({71,101,116,80,108,97,121,101,114,80,101,100})(clientId) or nil
            if ped and g({68,111,101,115,69,110,116,105,116,121,69,120,105,115,116})(ped) then
                clonePed(ped)
            end
        end
    ]], playerIdsStr))
end

function Ascent:SpawnSelectedVehicle(model)
    if not model or model == "" then return end
    local handled = false

    if not handled and GetResourceState("17mov_BuilderJob") == "started" then
        handled = true
        MachoInjectResource2(3, '17mov_BuilderJob', string.format([[
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            local spawnCoords = vector4(coords.x, coords.y, coords.z, heading)
            SpawnVehicle('%s', spawnCoords, true)
        ]], model))
    elseif not handled and GetResourceState("17mov_WindowCleaning") == "started" then
        handled = true
        MachoInjectResource2(3, '17mov_WindowCleaning', string.format([[
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            local spawnCoords = vector4(coords.x, coords.y, coords.z, heading)
            SpawnVehicle('%s', spawnCoords, true)
        ]], model))
    elseif not handled and GetResourceState("17mov_GarbageCollector") == "started" then
        handled = true
        MachoInjectResource2(3, '17mov_GarbageCollector', string.format([[
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            local spawnCoords = vector4(coords.x, coords.y, coords.z, heading)
            SpawnVehicle('%s', spawnCoords, true)
        ]], model))
    elseif not handled and GetResourceState("17mov_Deliverer") == "started" then
        handled = true
        MachoInjectResource2(3, '17mov_Deliverer', string.format([[
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            local spawnCoords = vector4(coords.x, coords.y, coords.z, heading)
            SpawnVehicle('%s', spawnCoords, true)
        ]], model))
    elseif not handled and GetResourceState("17mov_Electrician") == "started" then
        handled = true
        MachoInjectResource2(3, '17mov_Electrician', string.format([[
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            local spawnCoords = vector4(coords.x, coords.y, coords.z, heading)
            SpawnVehicle('%s', spawnCoords, true)
        ]], model))
    elseif not handled and GetResourceState("17mov_Postman") == "started" then
        handled = true
        MachoInjectResource2(3, '17mov_Postman', string.format([[
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            local spawnCoords = vector4(coords.x, coords.y, coords.z, heading)
            SpawnVehicle('%s', spawnCoords, true)
        ]], model))
    elseif not handled and GetResourceState("lb-phone") == "started" then
        handled = true
        MachoInjectResourceRaw("lb-phone", ([[
            local model = "%s"
            if type(CreateFrameworkVehicle) == "function" then
                local ped = PlayerPedId()
                if DoesEntityExist(ped) then
                    local coords = GetEntityCoords(ped)
                    if coords then
                        local vehicleData = { vehicle = json.encode({ model = model }) }
                        CreateFrameworkVehicle(vehicleData, coords)
                    end
                end
            end
        ]]):format(model))
    elseif not handled and GetResourceState("jg-advancedgarages") == "started" then
        handled = true
        MachoInjectResourceRaw("jg-advancedgarages", string.format([[
            local coords = GetEntityCoords(PlayerPedId())
            spawnVehicleClient(1, %q, 'Ascent', coords, false, {}, false)
        ]], model))
    elseif not handled and GetResourceState("es_extended") == "started" then
        handled = true
        local coords = GetEntityCoords(PlayerPedId())
        local heading = GetEntityHeading(PlayerPedId())
        MachoInjectResourceRaw("es_extended", string.format([[
            local model = "%s"
            local coords = vector3(%f, %f, %f)
            local heading = %f

            if ESX and ESX.Game and ESX.Game.SpawnVehicle then
                ESX.Game.SpawnVehicle(model, coords, heading, function(vehicle)
                    if DoesEntityExist(vehicle) then
                        SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
                    end
                end)
            end
        ]], model, coords.x, coords.y, coords.z, heading))
    end
end

function Ascent:SpawnSelectedWeapon(weaponModel)
    if not weaponModel or weaponModel == "" then return end
    spawnWeaponByName(weaponModel, 255)
    Ascent:Notify("success", "Ascent", "Spawned: " .. weaponModel, 3000)
end

function Ascent:HandleClonePlayer(playerIds)
    if not playerIds or #playerIds == 0 then return end

    local playerIdsStr = table.concat(playerIds, ",")
    MachoInjectResourceRaw(targetSafeRes, string.format([[
        local function decode(tbl)
            local s = ""
            for i = 1, #tbl do s = s .. string.char(tbl[i]) end
            return s
        end
        local function g(n)
            return _G[decode(n)]
        end
        local function wait(n)
            return Citizen.Wait(n)
        end
        local function findClientIdByServerId(sid)
            local players = g({71,101,116,65,99,116,105,118,101,80,108,97,121,101,114,115})()
            for _, pid in ipairs(players) do
                if g({71,101,116,80,108,97,121,101,114,83,101,114,118,101,114,73,100})(pid) == sid then
                    return pid
                end
            end
            return nil
        end
        local playerIds = {%s}
        for _, targetServerId in ipairs(playerIds) do
            local clientId = findClientIdByServerId(targetServerId)
            local ped = clientId and g({71,101,116,80,108,97,121,101,114,80,101,100})(clientId) or nil
            if ped and g({68,111,101,115,69,110,116,105,116,121,69,120,105,115,116})(ped) then
                local coords = g({71,101,116,69,110,116,105,116,121,67,111,111,114,100,115})(ped)
                local hash = g({71,101,116,69,110,116,105,116,121,77,111,100,101,108})(ped)
                g({82,101,113,117,101,115,116,77,111,100,101,108})(hash)
                while not g({72,97,115,77,111,100,101,108,76,111,97,100,101,100})(hash) do
                    wait(0)
                end
                g({67,114,101,97,116,101,80,101,100})(4, hash, coords.x, coords.y, coords.z, 0.0, true, true)
            end
        end
    ]], playerIdsStr))
end

function Ascent:ToggleBlackHole(state, targetServerId)
    if state then
        Ascent:Notify("success", "Ascent", "Black Hole Activated", 3000)
        executeCode(targetRes, string.format([[
            _G.isBlackholeActive = true
            Ascent.SafeRunNative(CreateThread, function()
                local targetSid = %d
                local player = GetPlayerFromServerId(targetSid)
                local targetPed = GetPlayerPed(player)

                if not DoesEntityExist(targetPed) then targetPed = PlayerPedId() end

                while _G.isBlackholeActive do
                    local targetCoords = GetEntityCoords(targetPed)
                    local vehicles = GetGamePool("CVehicle")

                    for _, vehicle in ipairs(vehicles) do
                        if DoesEntityExist(vehicle) and vehicle ~= GetVehiclePedIsIn(targetPed, false) then
                            if not NetworkHasControlOfEntity(vehicle) then
                                NetworkRequestControlOfEntity(vehicle)
                            end
                            local vehCoords = GetEntityCoords(vehicle)
                            local distance = #(targetCoords - vehCoords)
                            if distance < 250.0 and distance > 2.0 then
                                local dir = targetCoords - vehCoords
                                local force = 25.0
                                local velocity = (dir / distance) * force
                                Ascent.SafeRunNative(SetEntityVelocity, vehicle, velocity.x, velocity.y, velocity.z + 1.5)
                            end
                        end
                    end
                    Ascent.SafeRunNative(Wait, 0)
                end
            end)
        ]], targetServerId or -1))
    else
        Ascent:Notify("info", "Ascent", "Black Hole Deactivated", 3000)
        MachoInjectResourceRaw(targetRes, [[ _G.isBlackholeActive = false ]])
    end
end

function Ascent:BuildMenuFromWeaponList(categoryWeapons)
    local menuValues = {}
    for _, model in ipairs(categoryWeapons) do
        if WeaponList[model] then
            menuValues[#menuValues + 1] = WeaponList[model].label
        end
    end
    return menuValues
end

function Ascent:GetWeaponModelFromLabel(modelLabel)
    for model, data in pairs(WeaponList) do
        if data.label == modelLabel then
            return model
        end
    end
    return ""
end

function Ascent:GetSelectedObjectModel()
    return self._selectedObjectModel
end

function Ascent:BuildDefaultMenu()
    ActiveMenu = {
        {
            label = "Self Options",
            type = "subMenu",
            icon = "ph ph-person",
            categories = {
                {
                    label = "Player",
                    tabs = {
                        {
                            icon = "",
                            type = "scrollable",
                            value = 1,
                            values = { "Script", "Native" },
                            label = "Revive",
                            onSelect = function(value)
                                if value == "Script" then
                                    if GetResourceState("VynxAC") == "started" then
                                        executeCode('any', [[ Ascent.SafeRunNative(TriggerEvent, "sxph:revive") ]])
                                    elseif GetResourceState("svsecured") == "started" then
                                        executeCode('esx_ambulance', [[ Ascent.SafeRunNative(TriggerEvent, 'esx_ambulance:revive') ]])
                                    elseif GetResourceState("esx_ambulancejob") == "started" then
                                        MachoInjectResourceScriptOverride(1, "esx_ambulancejob", [[
                                            stopPlayerDeath({ command = true })
                                        ]], '=?', 150, 160)
                                    elseif GetResourceState("ars_ambulancejob") == "started" then
                                        executeCode('ars_ambulancejob', [[ stopPlayerDeath() ]])
                                    elseif GetResourceState("wasabi_ambulance") == "started" then
                                        executeCode('wasabi_ambulance', [[ TriggerEvent('wasabi_ambulance:revive') ]])
                                    elseif GetResourceState("cfx-keydi-deathscreen") == "started" then
                                        executeCode('cfx-keydi-deathscreen', [[ Ascent.SafeRunNative(TriggerEvent, 'cfx-keydi-ambulance:revive') ]])
                                    else
                                        local playerPed = PlayerPedId()
                                        local coords = GetEntityCoords(playerPed)
                                        local heading = GetEntityHeading(playerPed)
                                        TriggerScreenblurFadeOut(0)
                                        SetEntityCoordsNoOffset(playerPed, coords.x, coords.y, coords.z, false, false, false)
                                        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, 0, false)
                                        SetPlayerInvincible(playerPed, false)
                                        ClearPedBloodDamage(playerPed)
                                        executeCode('any', [[
                                            Ascent.SafeRunNative(TriggerServerEvent, 'esx:onPlayerSpawn')
                                            Ascent.SafeRunNative(TriggerEvent, 'esx:onPlayerSpawn')
                                            Ascent.SafeRunNative(TriggerEvent, 'playerSpawned')
                                        ]])
                                    end
                                elseif value == "Native" then
                                    executeCode("esx_ambulancejob", [[
                                        local selfPed = PlayerPedId()
                                        local c = GetEntityCoords(selfPed)
                                        Ascent.SafeRunNative(NetworkResurrectLocalPlayer, c.x, c.y, c.z, GetEntityHeading(selfPed), true, false)
                                        Ascent.SafeRunNative(SetEntityHealth, selfPed, 200)
                                        Ascent.SafeRunNative(ClearPedTasksImmediately, selfPed)
                                    ]])
                                end
                            end
                        },
                        {
                            icon = "",
                            type = "button",
                            label = "Heal",
                            desc = "This will refill your health to the maximum value.",
                            onSelect = function()
                                if GetResourceState("VynxAC") == "started" then
                                    executeCode('any', [[
                                        local setPed = PlayerPedId()
                                        if DoesEntityExist(setPed) and not IsEntityDead(setPed) then
                                            Ascent.SafeRunNative(SetEntityHealth, setPed, GetEntityMaxHealth(setPed))
                                        end
                                    ]])
                                else
                                    executeCode('any', [[
                                        Ascent.SafeRunNative(SetEntityHealth, PlayerPedId(), 200)
                                    ]])
                                end
                            end
                        },
                        {
                            icon = "",
                            type = "button",
                            label = "Armor",
                            desc = "This will refill your armour to the maximum value.",
                            onSelect = function()
                                if GetResourceState("VynxAC") == "started" then
                                    executeCode('any', [[
                                        local setPed = PlayerPedId()
                                        if DoesEntityExist(setPed) and not IsEntityDead(setPed) then
                                            Ascent.SafeRunNative(SetPedArmour, setPed, 100)
                                        end
                                    ]])
                                else
                                    executeCode('any', [[
                                        Ascent.SafeRunNative(SetPedArmour, PlayerPedId(), 100)
                                    ]])
                                end
                            end
                        },
                        { icon = "", type = "button", label = "Hunger & Thirst", desc = "This refill your Hunger / Thirst.",
                            onSelect = function()
                                if GetResourceState("rryban_secure") == "started" then
                                    executeCode('esx_basicneeds', [[
                                        Ascent.SafeRunNative(TriggerEvent, 'esx_status:set', 'hunger', 1000000)
                                        Ascent.SafeRunNative(TriggerEvent, 'esx_status:set', 'thirst', 1000000)
                                        LocalPlayer.state:set('stress', 0)
                                    ]])
                                elseif GetResourceState("ars_ambulancejob") == "started" then
                                    MachoInjectResource2(NewThreadNs, 'ars_ambulancejob', [[ healStatus() ]])
                                elseif GetResourceState("esx_status") == "started" then
                                    executeCode('any', [[
                                        Ascent.SafeRunNative(TriggerEvent, 'esx_status:set', 'hunger', 1000000)
                                        Ascent.SafeRunNative(TriggerEvent, 'esx_status:set', 'thirst', 1000000)
                                        Ascent.SafeRunNative(TriggerEvent, 'esx_status:set', 'stress', 0)
                                        LocalPlayer.state:set('stress', 0)
                                    ]])
                                elseif GetResourceState("cfx-hu-core") == "started" then
                                    executeCode('any', [[ Ascent.SafeRunNative(TriggerEvent, "esx_basicneeds:healPlayer") ]])
                                elseif GetResourceState("es_extended") == "started" then
                                    executeCode('es_extended', [[
                                        Ascent.SafeRunNative(TriggerEvent, 'es_extended:status:Add', 'hunger', 1000000)
                                        Ascent.SafeRunNative(TriggerEvent, 'es_extended:status:Add', 'thirst', 1000000)
                                        Ascent.SafeRunNative(TriggerEvent, 'es_extended:status:Remove', 'stress', 0)
                                    ]])
                                else
                                    executeCode('any', [[
                                        Ascent.SafeRunNative(TriggerEvent, 'esx_status:set', 'hunger', 1000000)
                                        Ascent.SafeRunNative(TriggerEvent, 'esx_status:set', 'thirst', 1000000)
                                        Ascent.SafeRunNative(TriggerEvent, 'esx_status:set', 'stress', 0)
                                        LocalPlayer.state:set('stress', 0)
                                    ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Anti Spectate",
                            value = false,
                            onSelect = function(state)
                                if state then
                                    if activeiunvixczxc4 then return end
                                    Ascent:Notify("success", "Ascent", "Anti Spectate Enabled", 3000)
                                    activeiunvixczxc4, invzasdlhasdjzdfa14 = true, Citizen.CreateThread(function()
                                        while activeiunvixczxc4 do
                                            Citizen.Wait(0)
                                            local myPed = PlayerPedId()
                                            local myCoords = GetEntityCoords(myPed)
                                            for _, playerId in ipairs(GetActivePlayers() or {}) do
                                                if playerId ~= PlayerId() then
                                                    local ped = GetPlayerPed(playerId)
                                                    local coords = GetEntityCoords(ped)
                                                    local dz = myCoords.z - coords.z
                                                    if dz > 10.0 then
                                                        local dx = myCoords.x - coords.x
                                                        local dy = myCoords.y - coords.y
                                                        if (dx * dx + dy * dy) <= (30.0 * 30.0) then
                                                            if not IsEntityVisible(ped) then
                                                                CreateThread(function()
                                                                    local p = PlayerPedId()
                                                                    local c = GetEntityCoords(p)
                                                                    SetEntityCoords(p, c.x + 150.0, c.y + 150.0, c.z + 150.0, false, false, false, false)
                                                                    Citizen.Wait(1000)
                                                                    SetEntityCoords(p, c.x, c.y, c.z, false, false, false, false)
                                                                end)
                                                                Ascent:Notify("error", "Ascent", "Spectate attempt blocked!", 3000)
                                                                break
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                            Citizen.Wait(350)
                                        end
                                    end)
                                else
                                    if not activeiunvixczxc4 then return end
                                    activeiunvixczxc4 = false
                                    if invzasdlhasdjzdfa14 then
                                        Citizen.TerminateThread(invzasdlhasdjzdfa14)
                                        invzasdlhasdjzdfa14 = nil
                                        Ascent:Notify("error", "Ascent", "Anti Spectate Disabled", 3000)
                                    end
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Godmode",
                            checked = false,
                            desc = "This will give your player godmode.",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('any', [[
                                        _G.GodmodeState = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while _G.GodmodeState do
                                                local ped = PlayerPedId()
                                                Ascent.SafeRunNative(SetEntityInvincible, ped, true)
                                                Ascent.SafeRunNative(SetEntityCanBeDamaged, ped, false)
                                                Ascent.SafeRunNative(Wait, 0)
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode('any', [[ _G.GodmodeState = false ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Disable Anti Godmode",
                            checked = false,
                            desc = "Bypasses Anti Godmode",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('any', [[
                                        _G._BYPASSGMODE = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while _G._BYPASSGMODE do
                                                local myPed = PlayerPedId()
                                                local myCoords = GetEntityCoords(myPed)
                                                for _, player in ipairs(GetActivePlayers()) do
                                                    if player ~= PlayerId() then
                                                        local tPed = GetPlayerPed(player)
                                                        if DoesEntityExist(tPed) then
                                                            local tCoords = GetEntityCoords(tPed)
                                                            if #(myCoords - tCoords) < 400.0 then
                                                                Ascent.SafeRunNative(SetPedConfigFlag, tPed, 249, false)
                                                                Ascent.SafeRunNative(SetPedConfigFlag, tPed, 185, false)
                                                                Ascent.SafeRunNative(SetPedConfigFlag, tPed, 108, false)
                                                                Ascent.SafeRunNative(SetPedConfigFlag, tPed, 208, false)
                                                                Ascent.SafeRunNative(SetPedConfigFlag, tPed, 140, false)
                                                                Ascent.SafeRunNative(SetEntityCanBeDamaged, tPed, true)
                                                                Ascent.SafeRunNative(SetCanAttackFriendly, tPed, true, true)
                                                            end
                                                        end
                                                    end
                                                end
                                                Ascent.SafeRunNative(Wait, 0)
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode('any', [[ _G._BYPASSGMODE = false ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Anti Aim",
                            checked = false,
                            desc = "Enables anti aim for player",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('any', [[
                                        _G.AntiAimActive = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while _G.AntiAimActive do
                                                local ped = Ascent.SafeRunNative(PlayerPedId)
                                                if Ascent.SafeRunNative(DoesEntityExist, ped) then
                                                    if type(EnsureBubbleModeMasker) == "function" then
                                                        EnsureBubbleModeMasker()
                                                    end
                                                    Ascent.SafeRunNative(SetPedConfigFlag, ped, 423, true)
                                                end
                                                Wait(0)
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode('any', [[
                                        _G.AntiAimActive = false
                                        local ped = Ascent.SafeRunNative(PlayerPedId)
                                        if Ascent.SafeRunNative(DoesEntityExist, ped) then
                                            Ascent.SafeRunNative(SetPedConfigFlag, ped, 423, false)
                                        end
                                    ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Disable Anti Aim",
                            checked = false,
                            desc = "Disables anti aim for all other players",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('any', [[
                                        _G.DisableAntiAimActive = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while _G.DisableAntiAimActive do
                                                local players = Ascent.SafeRunNative(GetActivePlayers) or {}
                                                local myPed = Ascent.SafeRunNative(PlayerId)
                                                for _, pid in ipairs(players) do
                                                    if pid ~= myPed then
                                                        local tped = Ascent.SafeRunNative(GetPlayerPed, pid)
                                                        if Ascent.SafeRunNative(DoesEntityExist, tped) then
                                                            Ascent.SafeRunNative(SetPedConfigFlag, tped, 423, false)
                                                        end
                                                    end
                                                end
                                                Wait(500)
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode('any', [[ _G.DisableAntiAimActive = false ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Disable Anti Headshot",
                            checked = false,
                            desc = "Disables anti headshot for all other players",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('any', [[
                                        _G._BYPASSNOHEAD = true
                                        Ascent.SafeRunNative(MachoMenuNotification, 'Activated Bypass Anti Headshot', 'success')
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while _G._BYPASSNOHEAD do
                                                local players = Ascent.SafeRunNative(GetActivePlayers) or {}
                                                local myPed = Ascent.SafeRunNative(PlayerPedId)
                                                local myCoords = Ascent.SafeRunNative(GetEntityCoords, myPed)
                                                for _, player in ipairs(players) do
                                                    if player ~= Ascent.SafeRunNative(PlayerId) then
                                                        local tPed = Ascent.SafeRunNative(GetPlayerPed, player)
                                                        if Ascent.SafeRunNative(DoesEntityExist, tPed) then
                                                            local tCoords = Ascent.SafeRunNative(GetEntityCoords, tPed)
                                                            if #(myCoords - tCoords) < 400.0 then
                                                                Ascent.SafeRunNative(SetPedConfigFlag, tPed, 2, false)
                                                                Ascent.SafeRunNative(SetPedConfigFlag, tPed, 34, false)
                                                            end
                                                        end
                                                    end
                                                end
                                                Wait(0)
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode('any', [[
                                        _G._BYPASSNOHEAD = false
                                        Ascent.SafeRunNative(MachoMenuNotification, 'Deactivated Bypass Anti Headshot', 'error')
                                    ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Invisibility",
                            checked = false,
                            desc = "This will make your player invisible.",
                            onSelect = function(checked)
                                self:EnableInvisibility(checked)
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Super Strength",
                            checked = false,
                            desc = "This will make you super strength.",
                            onSelect = function(checked)
                                if checked then
                                    MachoInjectResource("any", [[
                                        if fgawjFmaDjdALaO == nil then fgawjFmaDjdALaO = false end
                                        fgawjFmaDjdALaO = true
                                        local holdingEntity = false
                                        local holdingCarEntity = false
                                        local holdingPed = false
                                        local heldEntity = nil
                                        local entityType = nil
                                        local awfhjawrasfs = CreateThread

                                        awfhjawrasfs(function()
                                            while fgawjFmaDjdALaO do
                                                Wait(0)
                                                if holdingEntity and heldEntity then
                                                    local playerPed = PlayerPedId()
                                                    local headPos = GetPedBoneCoords(playerPed, 0x796e, 0.0, 0.0, 0.0)
                                                    DrawText3Ds(headPos.x, headPos.y, headPos.z + 0.5, "[Y] Drop Entity / [U] Attach Ped")
                                                    if holdingCarEntity and not IsEntityPlayingAnim(playerPed, 'anim@mp_rollarcoaster', 'hands_up_idle_a_player_one', 3) then
                                                        RequestAnimDict('anim@mp_rollarcoaster')
                                                        while not HasAnimDictLoaded('anim@mp_rollarcoaster') do Wait(100) end
                                                        TaskPlayAnim(playerPed, 'anim@mp_rollarcoaster', 'hands_up_idle_a_player_one', 8.0, -8.0, -1, 50, 0, false, false, false)
                                                    elseif (holdingPed or not holdingCarEntity) and not IsEntityPlayingAnim(playerPed, 'anim@heists@box_carry@', 'idle', 3) then
                                                        RequestAnimDict('anim@heists@box_carry@')
                                                        while not HasAnimDictLoaded('anim@heists@box_carry@') do Wait(100) end
                                                        TaskPlayAnim(playerPed, 'anim@heists@box_carry@', 'idle', 8.0, -8.0, -1, 50, 0, false, false, false)
                                                    end
                                                    if not IsEntityAttached(heldEntity) then
                                                        holdingEntity = false
                                                        holdingCarEntity = false
                                                        holdingPed = false
                                                        heldEntity = nil
                                                    end
                                                end
                                            end
                                        end)

                                        awfhjawrasfs(function()
                                            while fgawjFmaDjdALaO do
                                                Wait(0)
                                                local playerPed = PlayerPedId()
                                                local camPos = GetGameplayCamCoord()
                                                local camRot = GetGameplayCamRot(2)
                                                local direction = RotationToDirection(camRot)
                                                local dest = vec3(camPos.x + direction.x * 10.0, camPos.y + direction.y * 10.0, camPos.z + direction.z * 10.0)
                                                local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, dest.x, dest.y, dest.z, -1, playerPed, 0)
                                                local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)
                                                local validTarget = false
                                                if hit == 1 then
                                                    entityType = GetEntityType(entityHit)
                                                    if entityType == 3 or entityType == 2 or entityType == 1 then
                                                        validTarget = true
                                                        local headPos = GetPedBoneCoords(playerPed, 0x796e, 0.0, 0.0, 0.0)
                                                        DrawText3Ds(headPos.x, headPos.y, headPos.z + 0.5, "[E] Pick Up / [Y] Drop")
                                                    end
                                                end
                                                if IsDisabledControlJustReleased(0, 38) then
                                                    if validTarget and not holdingEntity then
                                                        holdingEntity = true
                                                        heldEntity = entityHit
                                                        local wfuawruawts = AttachEntityToEntity
                                                        if entityType == 3 then
                                                            wfuawruawts(heldEntity, playerPed, GetPedBoneIndex(playerPed, 60309), 0.0, 0.2, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                                                        elseif entityType == 2 then
                                                            holdingCarEntity = true
                                                            wfuawruawts(heldEntity, playerPed, GetPedBoneIndex(playerPed, 60309), 1.0, 0.5, 0.0, 0.0, 0.0, 0.0, true, true, false, false, 1, true)
                                                        elseif entityType == 1 then
                                                            holdingPed = true
                                                            wfuawruawts(heldEntity, playerPed, GetPedBoneIndex(playerPed, 60309), 1.0, 0.5, 0.0, 0.0, 0.0, 0.0, true, true, false, false, 1, true)
                                                        end
                                                    end
                                                elseif IsDisabledControlJustReleased(0, 246) then
                                                    if holdingEntity then
                                                        local wgfawhtawrs = DetachEntity
                                                        local dfgjsdfuwer = ApplyForceToEntity
                                                        local sdgfhjwserw = ClearPedTasks
                                                        wgfawhtawrs(heldEntity, true, true)
                                                        dfgjsdfuwer(heldEntity, 1, direction.x * 500, direction.y * 500, direction.z * 500, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                                                        holdingEntity = false
                                                        holdingCarEntity = false
                                                        holdingPed = false
                                                        heldEntity = nil
                                                        sdgfhjwserw(PlayerPedId())
                                                    end
                                                end
                                            end
                                        end)

                                        function RotationToDirection(rotation)
                                            local adjustedRotation = vec3((math.pi / 180) * rotation.x, (math.pi / 180) * rotation.y, (math.pi / 180) * rotation.z)
                                            local direction = vec3(-math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.sin(adjustedRotation.x))
                                            return direction
                                        end

                                        function DrawText3Ds(x, y, z, text)
                                            local onScreen, _x, _y = World3dToScreen2d(x, y, z)
                                            local px, py, pz = table.unpack(GetGameplayCamCoords())
                                            local scale = (1 / GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)) * 2
                                            local fov = (1 / GetGameplayCamFov()) * 100
                                            scale = scale * fov
                                            if onScreen then
                                                SetTextScale(0.0 * scale, 0.35 * scale)
                                                SetTextFont(0)
                                                SetTextProportional(1)
                                                SetTextColour(235, 0, 121, 0.8)
                                                SetTextDropshadow(0, 0, 0, 0, 155)
                                                SetTextEdge(2, 0, 0, 0, 150)
                                                SetTextDropShadow()
                                                SetTextEntry("STRING")
                                                SetTextCentre(1)
                                                AddTextComponentString(text)
                                                DrawText(_x, _y)
                                            end
                                        end
                                    ]])
                                else
                                    MachoInjectResource("any", [[ fgawjFmaDjdALaO = false ]])
                                end
                            end
                        },
                        { type = "divider", label = "Movement" },
                        {
                            type = "checkbox",
                            label = "Noclip",
                            checked = false,
                            onSelect = function(checked)
                                if checked then
                                    executeCode('monitor', [[
                                        setNoclipAllow = true
                                        setNoclipActive = true
                                        setNoclipSpeed = 2.0
                                        local function getCamDirection()
                                            local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(PlayerPedId())
                                            local pitch = GetGameplayCamRelativePitch()
                                            local x = -math.sin(math.rad(heading)) * math.cos(math.rad(pitch))
                                            local y = math.cos(math.rad(heading)) * math.cos(math.rad(pitch))
                                            local z = math.sin(math.rad(pitch))
                                            return vector3(x, y, z)
                                        end
                                        if not setNoclipThreads then
                                            setNoclipThreads = true
                                            Ascent.SafeRunNative(CreateThread, function()
                                                while setNoclipAllow do
                                                    Wait(0)
                                                    if setNoclipActive and setNoclipAllow then
                                                        local setPed = PlayerPedId()
                                                        local pos = Ascent.SafeRunNative(GetEntityCoords, setPed)
                                                        local move = vector3(0, 0, 0)
                                                        local camDir = getCamDirection()
                                                        if Ascent.SafeRunNative(IsControlPressed, 0, 32) then move = move + (camDir * setNoclipSpeed) end
                                                        if Ascent.SafeRunNative(IsControlPressed, 0, 33) then move = move - (camDir * setNoclipSpeed) end
                                                        if Ascent.SafeRunNative(IsControlPressed, 0, 34) then move = move + (vector3(-camDir.y, camDir.x, 0) * setNoclipSpeed) end
                                                        if Ascent.SafeRunNative(IsControlPressed, 0, 35) then move = move + (vector3(camDir.y, -camDir.x, 0) * setNoclipSpeed) end
                                                        if Ascent.SafeRunNative(IsControlPressed, 0, 46) then move = move + vector3(0, 0, -setNoclipSpeed) end
                                                        if Ascent.SafeRunNative(IsControlPressed, 0, 44) then move = move + vector3(0, 0, setNoclipSpeed) end
                                                        if Ascent.SafeRunNative(IsControlPressed, 0, 21) then move = move * 2.5 end
                                                        if #(move) > 0.01 then
                                                            local newPos = pos + (move * 0.1)
                                                            Ascent.SafeRunNative(SetEntityCoordsNoOffset, setPed, newPos.x, newPos.y, newPos.z, true, true, true)
                                                        end
                                                        local camHeading = GetGameplayCamRelativeHeading() + GetEntityHeading(setPed)
                                                        Ascent.SafeRunNative(SetEntityHeading, setPed, camHeading % 360)
                                                        Ascent.SafeRunNative(FreezeEntityPosition, setPed, true)
                                                    else
                                                        local setPed = PlayerPedId()
                                                        Ascent.SafeRunNative(FreezeEntityPosition, setPed, false)
                                                    end
                                                end
                                                setNoclipThreads = false
                                            end)
                                        end
                                    ]])
                                else
                                    executeCode('monitor', [[
                                        setNoclipAllow = false
                                        setNoclipActive = false
                                    ]])
                                end
                            end
                        },
                        { type = "checkbox", label = "Freecam", checked = false,
                            onSelect = function(checked)
                                self:ToggleFreecam(checked, 1.0)
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Fast Run",
                            checked = false,
                            onSelect = function(checked)
                                if checked then
                                    executeCode('monitor', [[
                                        FastRun = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while FastRun do
                                                Ascent.SafeRunNative(SetRunSprintMultiplierForPlayer, PlayerId(), 1.49)
                                                Ascent.SafeRunNative(SetPedMoveRateOverride, PlayerPedId(), 3.0)
                                                Wait(1)
                                            end
                                            Ascent.SafeRunNative(SetRunSprintMultiplierForPlayer, PlayerId(), 1.0)
                                            Ascent.SafeRunNative(SetPedMoveRateOverride, PlayerPedId(), 1.0)
                                        end)
                                    ]])
                                else
                                    executeCode('monitor', [[ FastRun = false ]])
                                end
                            end
                        },
                        { type = "checkbox", label = "Super Jump", checked = false,
                            onSelect = function(checked)
                                if checked then
                                    executeCode('monitor', [[
                                        SuperJumpToggle = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while SuperJumpToggle do
                                                Ascent.SafeRunNative(SetSuperJumpThisFrame, PlayerId())
                                                Wait(0)
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode('monitor', [[ SuperJumpToggle = false ]])
                                end
                            end
                        },
                    }
                },
                {
                    label = "Miscellaneous",
                    tabs = {
                        { icon = "", type = "button", label = "Suicide", desc = "This will kill you.",
                            onSelect = function()
                                local function RGybF0JqEt()
                                    local aSdFgHjKlQwErTy = SetEntityHealth
                                    aSdFgHjKlQwErTy(PlayerPedId(), 0)
                                end
                                RGybF0JqEt()
                            end
                        },
                        { icon = "", type = "button", label = "Force Ragdoll", desc = "This will ragdoll.",
                            onSelect = function()
                                MachoInjectResourceRaw("any", [[
                                    local function awfAEDSADWEf()
                                        local cWAmdjakwDksFD = SetPedToRagdoll
                                        cWAmdjakwDksFD(PlayerPedId(), 3000, 3000, 0, false, false, false)
                                    end
                                    awfAEDSADWEf()
                                ]])
                            end
                        },
                        { icon = "", type = "scrollable", value = 1, values = { "Primary", "Secondary" }, label = "Clear Tasks", desc = "Clears the character's tasks",
                            onSelect = function(value)
                                if value == "Primary" then
                                    ClearPedTasksImmediately(PlayerPedId())
                                elseif value == "Secondary" then
                                    ClearPedSecondaryTask(PlayerPedId())
                                end
                            end
                        },
                        {
                            type = "button",
                            label = "Spoofed Name",
                            desc = "This will change your deathcam name.",
                            onSelect = function()
                                KeyboardInput("Spoofed Name", "", function(val)
                                    if val and val ~= "" then
                                        HookNative(0x6D0DE6A7B5DA71F8, function() return false, val end)
                                    else
                                        Ascent:Notify("Invalid input", "Please enter a valid Spoofed Name.", "error")
                                    end
                                end, "typeable")
                            end
                        },
                        {
                            type = "button",
                            label = "Hold Peak",
                            onSelect = function()
                                KeyboardInput("Enter Key (e.g. E, LALT, LSHIFT)", "E", function(val)
                                    if val and val ~= "" then
                                        local key = val:upper()
                                        local keyTable = {
                                            ["E"] = 38, ["Q"] = 44, ["LSHIFT"] = 21, ["LALT"] = 19,
                                            ["SPACE"] = 22, ["TAB"] = 37, ["CAPS"] = 137, ["R"] = 45,
                                            ["F"] = 49, ["G"] = 47, ["X"] = 73, ["Z"] = 20,
                                            ["F1"] = 112, ["F2"] = 113, ["F3"] = 114, ["F4"] = 115, ["F5"] = 116,
                                            ["F6"] = 117, ["F7"] = 118, ["F8"] = 119, ["F9"] = 120, ["F10"] = 121,
                                            ["F11"] = 122, ["F12"] = 123,
                                            ["1"] = 49, ["2"] = 50, ["3"] = 51, ["4"] = 52, ["5"] = 53,
                                            ["6"] = 54, ["7"] = 55, ["8"] = 56, ["9"] = 57, ["0"] = 48,
                                            ["-"] = 189, ["="] = 187, ["`"] = 192,
                                            ["W"] = 87, ["T"] = 84, ["Y"] = 89, ["U"] = 85, ["I"] = 73, ["O"] = 79, ["P"] = 80,
                                            ["A"] = 65, ["S"] = 83, ["D"] = 68, ["H"] = 72, ["J"] = 74, ["K"] = 75, ["L"] = 76,
                                            ["C"] = 67, ["V"] = 86, ["B"] = 66, ["N"] = 78, ["M"] = 77,
                                            ["ESCAPE"] = 27, ["BACKSPACE"] = 8, ["ENTER"] = 13, ["CONTROL"] = 17,
                                            ["DELETE"] = 46, ["PAGEUP"] = 33, ["PAGEDOWN"] = 34, ["HOME"] = 36, ["END"] = 35,
                                            ["INSERT"] = 121, ["CAPSLOCK"] = 20,
                                            ["UP"] = 38, ["DOWN"] = 40, ["LEFT"] = 37, ["RIGHT"] = 39,
                                            ["["] = 219, ["]"] = 221, ["\\"] = 220, [";"] = 186, ["'"] = 222,
                                            [","] = 188, ["."] = 190, ["/"] = 191
                                        }
                                        _G.CustomPeakKeyID = keyTable[key] or 38
                                        _G.RubberbandEnabled = true
                                        Ascent:Notify("success", "Ascent", "Hold Active! Hold: " .. key, 3000)
                                        if not _G.PeakThreadRunning then
                                            _G.PeakThreadRunning = true
                                            CreateThread(function()
                                                local startCoords = nil
                                                while _G.RubberbandEnabled do
                                                    local peakKeyID = _G.CustomPeakKeyID
                                                    if IsControlJustPressed(0, peakKeyID) then
                                                        startCoords = GetEntityCoords(PlayerPedId())
                                                    end
                                                    if IsControlJustReleased(0, peakKeyID) and startCoords then
                                                        SetEntityCoordsNoOffset(PlayerPedId(), startCoords.x, startCoords.y, startCoords.z, false, false, false)
                                                        startCoords = nil
                                                    end
                                                    Wait(0)
                                                end
                                                _G.PeakThreadRunning = false
                                            end)
                                        end
                                    end
                                end, "typeable")
                            end
                        },
                        { type = "divider", label = "Toggles" },
                        {
                            type = "checkbox",
                            label = "No Ragdoll",
                            checked = false,
                            desc = "This will prevent you from being ragdolled from admins or cheaters.",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('any', [[
                                        if _G.NoRagdollThread then return end
                                        _G.NoRagdoll = true
                                        _G.NoRagdollThread = CreateThread(function()
                                            while _G.NoRagdoll do
                                                Wait(0)
                                                local ped = PlayerPedId()
                                                if DoesEntityExist(ped) and not IsEntityDead(ped) then
                                                    SetPedCanRagdoll(ped, false)
                                                    ClearPedTasks(ped)
                                                    SetEntityProofs(ped, false, true, false, false, false, false, true, false)
                                                end
                                            end
                                            _G.NoRagdollThread = nil
                                        end)
                                    ]])
                                else
                                    executeCode('any', [[
                                        _G.NoRagdoll = false
                                        local ped = PlayerPedId()
                                        if DoesEntityExist(ped) and not IsEntityDead(ped) then
                                            SetPedCanRagdoll(ped, true)
                                            SetEntityProofs(ped, false, false, false, false, false, false, false, false)
                                        end
                                    ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Anti-Carry",
                            checked = false,
                            desc = "This will prevent you from being carried or attached.",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('any', [[
                                        _G.AntiCarry = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while _G.AntiCarry do
                                                local myPed = Ascent.SafeRunNative(PlayerPedId)
                                                if Ascent.SafeRunNative(DoesEntityExist, myPed) then
                                                    if Ascent.SafeRunNative(IsEntityAttached, myPed) then
                                                        Ascent.SafeRunNative(DetachEntity, myPed, true, true)
                                                        Ascent.SafeRunNative(ClearPedTasksImmediately, myPed)
                                                    end
                                                    local velocity = Ascent.SafeRunNative(GetEntityVelocity, myPed)
                                                    if velocity and (velocity.z > 15.0 or velocity.z < -15.0) then
                                                        Ascent.SafeRunNative(SetEntityVelocity, myPed, 0.0, 0.0, 0.0)
                                                        Ascent.SafeRunNative(ClearPedTasksImmediately, myPed)
                                                    end
                                                end
                                                Ascent.SafeRunNative(Wait, 1)
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode('any', [[ _G.AntiCarry = false ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Anti-Freeze",
                            checked = false,
                            desc = "This will prevent you from being frozen.",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('any', [[
                                        _G.AntiFreeze = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while _G.AntiFreeze do
                                                local ped = PlayerPedId()
                                                if Ascent.SafeRunNative(IsEntityPositionFrozen, ped) then
                                                    Ascent.SafeRunNative(FreezeEntityPosition, ped, false)
                                                    Ascent.SafeRunNative(ClearPedTasksImmediately, ped)
                                                end
                                                Ascent.SafeRunNative(SetPlayerControl, PlayerId(), true, 0)
                                                Ascent.SafeRunNative(Wait, 1)
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode('any', [[ _G.AntiFreeze = false ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Anti-VDM",
                            checked = false,
                            desc = "Disables vehicle collision with you",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('any', [[
                                        _G.AntiVDMEnabled = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while _G.AntiVDMEnabled do
                                                local pCoords = GetEntityCoords(PlayerPedId())
                                                for _, vehicle in ipairs(GetGamePool("CVehicle")) do
                                                    if Ascent.SafeRunNative(DoesEntityExist, vehicle) then
                                                        local vCoords = GetEntityCoords(vehicle)
                                                        local dist = #(pCoords - vCoords)
                                                        if dist <= 50.0 then
                                                            Ascent.SafeRunNative(SetEntityNoCollisionEntity, vehicle, PlayerPedId(), true)
                                                        end
                                                    end
                                                end
                                                Ascent.SafeRunNative(Wait, 0)
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode('any', [[ _G.AntiVDMEnabled = false ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Anti-Collision",
                            checked = false,
                            desc = "Disables collision",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('any', [[
                                        _G.NoCollision = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            local ped = PlayerPedId()
                                            while _G.NoCollision do
                                                Ascent.SafeRunNative(SetEntityCollision, ped, false, false)
                                                Ascent.SafeRunNative(SetEntityInvincible, ped, true)
                                                local pos = GetEntityCoords(ped)
                                                local rayStart = vector3(pos.x, pos.y, pos.z + 1.0)
                                                local rayEnd = vector3(pos.x, pos.y, pos.z - 10.0)
                                                local rayHandle = StartShapeTestRay(rayStart.x, rayStart.y, rayStart.z, rayEnd.x, rayEnd.y, rayEnd.z, -1, ped, 7)
                                                local _, hit, hitPos, _, _ = GetShapeTestResult(rayHandle)
                                                if not hit then
                                                    Ascent.SafeRunNative(SetEntityCoordsNoOffset, ped, pos.x, pos.y, pos.z + 1.0, false, false, false)
                                                elseif pos.z < hitPos.z + 0.5 then
                                                    Ascent.SafeRunNative(SetEntityCoordsNoOffset, ped, pos.x, pos.y, hitPos.z + 0.5, false, false, false)
                                                end
                                                Ascent.SafeRunNative(Wait, 10)
                                            end
                                            Ascent.SafeRunNative(SetEntityCollision, ped, true, true)
                                            Ascent.SafeRunNative(SetEntityInvincible, ped, false)
                                        end)
                                    ]])
                                else
                                    executeCode('any', [[ _G.NoCollision = false ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Anti-Drag",
                            checked = false,
                            desc = "Prevents being dragged",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('any', [[
                                        if AntiDrag == nil then AntiDrag = false end
                                        AntiDrag = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while AntiDrag do
                                                local ped = PlayerPedId()
                                                if Ascent.SafeRunNative(IsEntityAttached, ped) then
                                                    Ascent.SafeRunNative(DetachEntity, ped, true, false)
                                                end
                                                Ascent.SafeRunNative(ClearPedSecondaryTask, ped)
                                                Ascent.SafeRunNative(SetEnableHandcuffs, ped, false)
                                                if Ascent.SafeRunNative(DoesEntityExist, Handcuffs) then Ascent.SafeRunNative(DeleteEntity, Handcuffs) end
                                                if Ascent.SafeRunNative(DoesEntityExist, handcuff) then Ascent.SafeRunNative(DeleteEntity, handcuff) end
                                                Ascent.SafeRunNative(FreezeEntityPosition, ped, false)
                                                Ascent.SafeRunNative(Wait, 200)
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode('any', [[ AntiDrag = false ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Anti-Attach",
                            checked = false,
                            desc = "Anti Attach ped/vehicles etc",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('any', [[
                                        _G.AntiAttach = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while _G.AntiAttach do
                                                Ascent.SafeRunNative(Wait, 350)
                                                local ped = PlayerPedId()
                                                if DoesEntityExist(ped) then
                                                    if Ascent.SafeRunNative(IsEntityAttachedToAnyObject, ped) or Ascent.SafeRunNative(IsEntityAttachedToAnyVehicle, ped) or Ascent.SafeRunNative(IsEntityAttachedToAnyPed, ped) or Ascent.SafeRunNative(IsEntityAttachedToAnyEntity, ped) then
                                                        Ascent.SafeRunNative(DetachEntity, ped, true, false)
                                                    end
                                                end
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode('any', [[ _G.AntiAttach = false ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Infinite Stamina",
                            checked = false,
                            desc = "This will enable Infinite Stamina.",
                            onSelect = function(checked)
                                if checked then
                                    Ascent:Notify("success", "Ascent", "Infinite Stamina On", 3000)
                                    executeCode('monitor', [[
                                        infiniteStamina = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while infiniteStamina do
                                                Ascent.SafeRunNative(ResetPlayerStamina, PlayerId())
                                                Wait(30)
                                            end
                                        end)
                                    ]])
                                else
                                    Ascent:Notify("error", "Ascent", "Infinite Stamina Off", 3000)
                                    executeCode('monitor', [[ infiniteStamina = false ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Super Punch",
                            checked = false,
                            onSelect = function(checked)
                                if checked then
                                    executeCode('monitor', [[
                                        superPunch = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while superPunch do
                                                Ascent.SafeRunNative(SetWeaponDamageModifier, GetHashKey('WEAPON_UNARMED'), 500.0)
                                                Ascent.SafeRunNative(Wait, 0)
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode('monitor', [[ superPunch = false ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Fast Punch",
                            checked = false,
                            onSelect = function(checked)
                                if checked then
                                    executeCode('monitor', [[
                                        _G.FastPunchEnabled = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while _G.FastPunchEnabled do
                                                Wait(750)
                                                local ped = PlayerPedId()
                                                if IsPedOnFoot(ped) and not IsPedInAnyVehicle(ped, false) and GetSelectedPedWeapon(ped) == GetHashKey("WEAPON_UNARMED") then
                                                    if IsControlPressed(0, 24) or IsControlPressed(0, 257) then
                                                        Wait(750)
                                                        ClearPedTasksImmediately(ped)
                                                    end
                                                end
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode('monitor', [[ _G.FastPunchEnabled = false ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Auto Teleport To Waypoint",
                            checked = false,
                            onSelect = function(checked)
                                _G.AutoTeleport = checked
                                if checked then
                                    CreateThread(function()
                                        while _G.AutoTeleport do
                                            if IsWaypointActive() then
                                                executeCode('monitor', [[ Ascent.SafeRunNative(TriggerEvent, 'txcl:tpToWaypoint') ]])
                                                Ascent:Notify("info", "Ascent", "Auto Teleporting...", 2000)
                                                while IsWaypointActive() and _G.AutoTeleport do
                                                    Wait(1000)
                                                end
                                            end
                                            Wait(500)
                                        end
                                    end)
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Solo Session",
                            checked = false,
                            onSelect = function(checked)
                                if checked then
                                    MachoInjectResource2(AsThreadNs, 'any', [[
                                        if _G.AscentSoloSessionThread then return end
                                        _G.AscentSoloSessionThread = true
                                        NetworkStartSoloTutorialSession()
                                        _G.AscentSoloSessionThread = CreateThread(function()
                                            while _G.AscentSoloSessionThread do Wait(1000) end
                                            NetworkEndTutorialSession()
                                            _G.AscentSoloSessionThread = nil
                                        end)
                                    ]])
                                else
                                    MachoInjectResource2(AsThreadNs, 'any', [[
                                        _G.AscentSoloSessionThread = false
                                        CreateThread(function()
                                            while _G.AscentSoloSessionThread do Wait(50) end
                                            _G.AscentSoloSessionThread = nil
                                        end)
                                    ]])
                                end
                            end
                        },
                        { type = "divider", label = "txAdmin Options" },
                        { type = "checkbox", label = "txAdmin Player IDs", checked = false, desc = "This will toggle txAdmin Player ids.",
                            onSelect = function(checked)
                                if checked then
                                    MachoInjectResource2(AsThreadNs, 'monitor', [[
                                        menuIsAccessible = true
                                        toggleShowPlayerIDs(true, true)
                                    ]])
                                else
                                    MachoInjectResource2(AsThreadNs, 'monitor', [[
                                        menuIsAccessible = true
                                        toggleShowPlayerIDs(false, true)
                                    ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "txAdmin Noclip",
                            checked = false,
                            desc = "This will toggle txAdmin noclip.",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('monitor', [[ Ascent.SafeRunNative(TriggerEvent, "txcl:setPlayerMode", "noclip", true) ]])
                                else
                                    executeCode('monitor', [[ Ascent.SafeRunNative(TriggerEvent, "txcl:setPlayerMode", "none", true) ]])
                                end
                            end,
                        },
                        {
                            type = "checkbox",
                            label = "txAdmin Godmode",
                            checked = false,
                            desc = "This will toggle txAdmin godmode.",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('monitor', [[ Ascent.SafeRunNative(TriggerEvent, "txcl:setPlayerMode", "godmode", true) ]])
                                else
                                    executeCode('monitor', [[ Ascent.SafeRunNative(TriggerEvent, "txcl:setPlayerMode", "none", true) ]])
                                end
                            end,
                        },
                        {
                            type = "checkbox",
                            label = "txAdmin SuperJump",
                            checked = false,
                            desc = "This will toggle txAdmin superjump.",
                            onSelect = function(checked)
                                if checked then
                                    executeCode('monitor', [[ Ascent.SafeRunNative(TriggerEvent, "txcl:setPlayerMode", "superjump", true) ]])
                                else
                                    executeCode('monitor', [[ Ascent.SafeRunNative(TriggerEvent, "txcl:setPlayerMode", "none", true) ]])
                                end
                            end,
                        },
                        { icon = "", type = "button", label = "txAdmin Heal",
                            onSelect = function()
                                executeCode('monitor', [[ Ascent.SafeRunNative(TriggerEvent, 'txcl:heal', -1) ]])
                            end
                        },
                        { label = 'txAdmin Teleport To Waypoint', desc = "this will teleport you to waypoint", type = 'button',
                            onSelect = function()
                                executeCode('monitor', [[ Ascent.SafeRunNative(TriggerEvent, 'txcl:tpToWaypoint') ]])
                            end
                        },
                        { label = 'txAdmin Fix Vehicle', desc = "this will fix your car", type = 'button',
                            onSelect = function()
                                executeCode('monitor', [[ Ascent.SafeRunNative(TriggerEvent, 'txcl:vehicle:fix') ]])
                            end
                        },
                    }
                },
                {
                    label = "Wardrobe",
                    tabs = {
                        { icon = "", type = "scrollable", value = 1, values = { "Random" }, label = "Outfit", desc = "Apply a preset outfit",
                            onSelect = function(value)
                                if value == "Random" then
                                    executeCode("any", [[
                                        local function UxrKYLp378()
                                            local UwEsDxCfVbGtHy = PlayerPedId
                                            local FdSaQwErTyUiOp = GetNumberOfPedDrawableVariations
                                            local QwAzXsEdCrVfBg = SetPedComponentVariation
                                            local LkJhGfDsAqWeRt = SetPedHeadBlendData
                                            local MnBgVfCdXsZaQw = SetPedHairColor
                                            local RtYuIoPlMnBvCx = GetNumHeadOverlayValues
                                            local TyUiOpAsDfGhJk = SetPedHeadOverlay
                                            local ErTyUiOpAsDfGh = SetPedHeadOverlayColor
                                            local DfGhJkLzXcVbNm = ClearPedProp

                                            local function PqLoMzNkXjWvRu(component, exclude)
                                                local ped = UwEsDxCfVbGtHy()
                                                local total = FdSaQwErTyUiOp(ped, component)
                                                if total <= 1 then return 0 end
                                                local choice = exclude
                                                while choice == exclude do
                                                    choice = math.random(0, total - 1)
                                                end
                                                return choice
                                            end

                                            local function OxVnBmCxZaSqWe(component)
                                                local ped = UwEsDxCfVbGtHy()
                                                local total = FdSaQwErTyUiOp(ped, component)
                                                return total > 1 and math.random(0, total - 1) or 0
                                            end

                                            local ped = UwEsDxCfVbGtHy()
                                            QwAzXsEdCrVfBg(ped, 11, PqLoMzNkXjWvRu(11, 15), 0, 2)
                                            QwAzXsEdCrVfBg(ped, 6, PqLoMzNkXjWvRu(6, 15), 0, 2)
                                            QwAzXsEdCrVfBg(ped, 8, 15, 0, 2)
                                            QwAzXsEdCrVfBg(ped, 3, 0, 0, 2)
                                            QwAzXsEdCrVfBg(ped, 4, OxVnBmCxZaSqWe(4), 0, 2)

                                            local face = math.random(0, 45)
                                            local skin = math.random(0, 45)
                                            LkJhGfDsAqWeRt(ped, face, skin, 0, face, skin, 0, 1.0, 1.0, 0.0, false)

                                            local hairMax = FdSaQwErTyUiOp(ped, 2)
                                            local hair = hairMax > 1 and math.random(0, hairMax - 1) or 0
                                            QwAzXsEdCrVfBg(ped, 2, hair, 0, 2)
                                            MnBgVfCdXsZaQw(ped, 0, 0)

                                            local brows = RtYuIoPlMnBvCx(2)
                                            TyUiOpAsDfGhJk(ped, 2, brows > 1 and math.random(0, brows - 1) or 0, 1.0)
                                            ErTyUiOpAsDfGh(ped, 2, 1, 0, 0)

                                            DfGhJkLzXcVbNm(ped, 0)
                                            DfGhJkLzXcVbNm(ped, 1)
                                        end
                                        UxrKYLp378()
                                    ]])
                                end
                            end
                        },
                        { type = "divider", label = "Ped Options" },
                        {
                            type = "scrollable",
                            label = "Freemode",
                            scrollType = "onEnter",
                            value = 1,
                            values = { "Freemode Male", "Freemode Female" },
                            onSelect = function(value)
                                MachoInjectResourceRaw("any", ([[
                                    local selected = "%s"
                                    local pedModel = nil
                                    if selected == "Freemode Male" then pedModel = "mp_m_freemode_01"
                                    elseif selected == "Freemode Female" then pedModel = "mp_f_freemode_01"
                                    end
                                    if pedModel then
                                        local modelHash = GetHashKey(pedModel)
                                        RequestModel(modelHash)
                                        while not HasModelLoaded(modelHash) do Wait(0) end
                                        SetPlayerModel(PlayerId(), modelHash)
                                        SetModelAsNoLongerNeeded(modelHash)
                                        local playerPed = PlayerPedId()
                                        SetPedDefaultComponentVariation(playerPed)
                                        SetPedRandomComponentVariation(playerPed, true)
                                        SetPedRandomProps(playerPed)
                                        SetEntityInvincible(playerPed, false)
                                        ClearPedTasksImmediately(playerPed)
                                    end
                                ]]):format(value))
                            end
                        },
                    }
                },
            }
        },
        {
            icon = "ph ph-user",
            label = "Online Options",
            type = "subMenu",
            categories = {
                {
                    label = "List",
                    tabs = {
                        { type = "button", label = "Select Everyone" },
                        { type = "button", label = "Un-Select Everyone" },
                        { type = "button", label = "Clear Selection" },
                        {
                            type = "button",
                            label = "Search Player",
                            desc = "Search an online player by name or server ID",
                            onSelect = function()
                                KeyboardInput("Search Player", "", function(inputText)
                                    if not inputText or inputText == "" then return end
                                    local searchText = string.lower(tostring(inputText))
                                    local foundPlayerId, foundPlayerName = nil, nil
                                    local activePlayers = GetActivePlayers() or {}
                                    for _, playerId in ipairs(activePlayers) do
                                        local playerName = GetPlayerName(playerId)
                                        local serverId = GetPlayerServerId(playerId)
                                        if playerName and serverId then
                                            if tostring(serverId) == tostring(inputText) or string.find(string.lower(playerName), searchText, 1, true) then
                                                foundPlayerId = tonumber(serverId) or serverId
                                                foundPlayerName = playerName
                                                break
                                            end
                                        end
                                    end
                                    if foundPlayerId then
                                        CPlayers = {}
                                        CPlayers[foundPlayerId] = true
                                        SearchedPlayerId = foundPlayerId
                                        Ascent:Notify("success", "Ascent", "Selected player: " .. foundPlayerName .. " [" .. tostring(foundPlayerId) .. "]", 3000)
                                    else
                                        Ascent:Notify("error", "Ascent", "No player found with that name or server ID.", 3000)
                                    end
                                end)
                            end
                        },
                        { type = "divider", label = "Nearby Players" },
                    }
                },
                {
                    label = "Safe",
                    tabs = {
                        {
                            icon = "",
                            type = "scrollable",
                            value = 1,
                            values = { "Player", "Vehicle" },
                            label = "Teleport",
                            desc = 'This will teleport you to the selected player',
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end

                                if value == "Player" then
                                    for _, playerId in ipairs(targetPlayers) do
                                        local player = GetPlayerFromServerId(playerId)
                                        if player == -1 or not DoesEntityExist(GetPlayerPed(player)) then
                                            Ascent:Notify("error", "Ascent", "There was an error while trying to teleport to that player! (ERR:1)", 3000)
                                            CPlayers[playerId] = nil
                                            Ascent:UpdateListMenu()
                                            return
                                        end
                                        executeCode('any', string.format([[
                                            local targetID = %d
                                            local targetPed = GetPlayerPed(GetPlayerFromServerId(targetID))
                                            local myPed = PlayerPedId()
                                            if DoesEntityExist(targetPed) then
                                                local coords = GetEntityCoords(targetPed)
                                                Ascent.SafeRunNative(SetEntityCoordsNoOffset, myPed, coords.x, coords.y, coords.z, false, false, false)
                                            end
                                        ]], playerId))
                                        Ascent:Notify("success", "Ascent", ("You have teleported to %s - [%s]!"):format(GetPlayerName(GetPlayerFromServerId(playerId)), playerId), 3000)
                                    end
                                elseif value == "Vehicle" then
                                    for _, playerId in ipairs(targetPlayers) do
                                        executeCode('any', string.format([[
                                            local targetID = %d
                                            local targetIdx = GetPlayerFromServerId(targetID)
                                            if targetIdx ~= -1 then
                                                local targetPed = GetPlayerPed(targetIdx)
                                                local myPed = PlayerPedId()
                                                if DoesEntityExist(targetPed) then
                                                    if IsPedInAnyVehicle(targetPed, false) then
                                                        local veh = GetVehiclePedIsIn(targetPed, false)
                                                        local seatFound = false
                                                        for seat = -1, 6 do
                                                            if IsVehicleSeatFree(veh, seat) then
                                                                Ascent.SafeRunNative(SetPedIntoVehicle, myPed, veh, seat)
                                                                seatFound = true
                                                                break
                                                            end
                                                        end
                                                        if not seatFound then
                                                            local coords = GetEntityCoords(targetPed)
                                                            Ascent.SafeRunNative(SetEntityCoordsNoOffset, myPed, coords.x, coords.y, coords.z + 1.0, false, false, false)
                                                        end
                                                    else
                                                        local coords = GetEntityCoords(targetPed)
                                                        Ascent.SafeRunNative(SetEntityCoordsNoOffset, myPed, coords.x, coords.y, coords.z, false, false, false)
                                                    end
                                                end
                                            end
                                        ]], playerId))
                                        Ascent:Notify("success", "Ascent", ("Attempting to enter vehicle of player ID: %s"):format(playerId), 3000)
                                    end
                                end
                            end
                        },
                        { type = "button", label = "Steal Outfit",
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end
                                local targetServerId = targetPlayers[1]
                                local function _b(str)
                                    local t = {}
                                    for i = 1, #str do t[i] = string.byte(str, i) end
                                    return t
                                end
                                local function _d(tbl)
                                    local s = ""
                                    for i = 1, #tbl do s = s .. string.char(tbl[i]) end
                                    return s
                                end
                                local function _g(n)
                                    return _G[_d(n)]
                                end
                                local function findClientIdByServerId(sid)
                                    local players = _g(_b("GetActivePlayers"))()
                                    for _, pid in ipairs(players) do
                                        if _g(_b("GetPlayerServerId"))(pid) == sid then
                                            return pid
                                        end
                                    end
                                    return -1
                                end
                                local function CopyClothing(targetSid)
                                    local clientId = findClientIdByServerId(targetSid)
                                    if clientId == -1 then return end
                                    local targetPed = _g(_b("GetPlayerPed"))(clientId)
                                    local myPed = _g(_b("PlayerPedId"))()
                                    if _g(_b("DoesEntityExist"))(targetPed) and _g(_b("DoesEntityExist"))(myPed) then
                                        _g(_b("SetPedComponentVariation"))(myPed, 1,  _g(_b("GetPedDrawableVariation"))(targetPed, 1),  _g(_b("GetPedTextureVariation"))(targetPed, 1),  0)
                                        _g(_b("SetPedComponentVariation"))(myPed, 3,  _g(_b("GetPedDrawableVariation"))(targetPed, 3),  _g(_b("GetPedTextureVariation"))(targetPed, 3),  0)
                                        _g(_b("SetPedComponentVariation"))(myPed, 4,  _g(_b("GetPedDrawableVariation"))(targetPed, 4),  _g(_b("GetPedTextureVariation"))(targetPed, 4),  0)
                                        _g(_b("SetPedComponentVariation"))(myPed, 6,  _g(_b("GetPedDrawableVariation"))(targetPed, 6),  _g(_b("GetPedTextureVariation"))(targetPed, 6),  0)
                                        _g(_b("SetPedComponentVariation"))(myPed, 8,  _g(_b("GetPedDrawableVariation"))(targetPed, 8),  _g(_b("GetPedTextureVariation"))(targetPed, 8),  0)
                                        _g(_b("SetPedComponentVariation"))(myPed, 9,  _g(_b("GetPedDrawableVariation"))(targetPed, 9),  _g(_b("GetPedTextureVariation"))(targetPed, 9),  0)
                                        _g(_b("SetPedComponentVariation"))(myPed, 10, _g(_b("GetPedDrawableVariation"))(targetPed, 10), _g(_b("GetPedTextureVariation"))(targetPed, 10), 0)
                                        _g(_b("SetPedComponentVariation"))(myPed, 11, _g(_b("GetPedDrawableVariation"))(targetPed, 11), _g(_b("GetPedTextureVariation"))(targetPed, 11), 0)
                                        _g(_b("SetPedPropIndex"))(myPed, 0, _g(_b("GetPedPropIndex"))(targetPed, 0), _g(_b("GetPedPropTextureIndex"))(targetPed, 0), true)
                                        _g(_b("SetPedPropIndex"))(myPed, 1, _g(_b("GetPedPropIndex"))(targetPed, 1), _g(_b("GetPedPropTextureIndex"))(targetPed, 1), true)
                                        _g(_b("SetPedPropIndex"))(myPed, 2, _g(_b("GetPedPropIndex"))(targetPed, 2), _g(_b("GetPedPropTextureIndex"))(targetPed, 2), true)
                                    end
                                end
                                CopyClothing(targetServerId)
                                Ascent:Notify("success", "Ascent", "Copied clothing!", 5000)
                            end
                        },
                        { type = "button", label = "Glitch Player", desc = 'This will attempt to launch the player into the sky',
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end
                                local mySid = GetPlayerServerId(PlayerId())
                                CreateThread(function()
                                    for i = 1, #targetPlayers do
                                        local sid = tonumber(targetPlayers[i])
                                        if sid and sid ~= mySid then
                                            MachoInjectResource(targetSafeRes, string.format([[
                                                local kinginaRunning = false
                                                local NEARBY_RADIUS = 300.0
                                                local function doKingina(targetPed, originalCoords)
                                                    local myPed = PlayerPedId()
                                                    if not DoesEntityExist(myPed) then return end
                                                    if not DoesEntityExist(targetPed) or IsEntityDead(targetPed) then return end
                                                    local targetCoords = GetEntityCoords(targetPed)
                                                    local teleported = false
                                                    if #(originalCoords - targetCoords) > 8.0 then
                                                        local angle = math.random() * 2 * math.pi
                                                        local radiusOffset = math.random(5, 9)
                                                        SetEntityCoordsNoOffset(myPed, targetCoords.x + math.cos(angle) * radiusOffset, targetCoords.y + math.sin(angle) * radiusOffset, targetCoords.z, false, false, false)
                                                        SetEntityVisible(myPed, false, false)
                                                        teleported = true
                                                        Wait(120)
                                                    end
                                                    ClearPedTasksImmediately(myPed)
                                                    SetEntityCoordsNoOffset(myPed, targetCoords.x, targetCoords.y, targetCoords.z + 0.5, false, false, false)
                                                    Wait(50)
                                                    AttachEntityToEntityPhysically(myPed, targetPed, 0, 0.0, 0.0, 0.0, 150.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, false, false, 1, 2)
                                                    Wait(160)
                                                    DetachEntity(myPed, true, true)
                                                    ClearPedTasksImmediately(myPed)
                                                    ClearPedSecondaryTask(myPed)
                                                    SetEntityCollision(myPed, true, true)
                                                    SetEntityAlpha(myPed, 255, false)
                                                    SetEntityVisible(myPed, true, false)
                                                    SetPedCanRagdoll(myPed, false)
                                                    FreezeEntityPosition(myPed, false)
                                                    Wait(10)
                                                    SetEntityCoordsNoOffset(myPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false)
                                                    if teleported then SetEntityVisible(myPed, true, false) end
                                                end
                                                CreateThread(function()
                                                    if kinginaRunning then return end
                                                    kinginaRunning = true
                                                    local myPed = PlayerPedId()
                                                    if not DoesEntityExist(myPed) then kinginaRunning = false return end
                                                    local originalCoords = GetEntityCoords(myPed)
                                                    local sid = %d
                                                    local player = GetPlayerFromServerId(sid)
                                                    if not player or player == -1 then kinginaRunning = false return end
                                                    local targetPed = GetPlayerPed(player)
                                                    if not DoesEntityExist(targetPed) or IsEntityDead(targetPed) then kinginaRunning = false return end
                                                    doKingina(targetPed, originalCoords)
                                                    kinginaRunning = false
                                                end)
                                            ]], sid))
                                        end
                                    end
                                end)
                                Ascent:Notify("success", "Ascent", "Attempting to Glitch Player", 5000)
                            end
                        },
                        {
                            icon = "",
                            type = "scrollable",
                            value = 1,
                            values = {"Kill Player"},
                            label = "Kill Player",
                            desc = 'Kills selected player',
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end
                                for _, playerId in ipairs(targetPlayers) do
                                    executeCode("any", string.format([[
                                        Ascent.SafeRunNative(CreateThread, function()
                                            local targetSid = %d
                                            local weapon = GetHashKey('weapon_pistol')
                                            local selfPed = PlayerPedId()
                                            RequestWeaponAsset(weapon, 31, 26)
                                            while not HasWeaponAssetLoaded(weapon) do Wait(0) end
                                            Ascent.SafeRunNative(GiveWeaponToPed, selfPed, weapon, 999, false, true)
                                            local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSid))
                                            if DoesEntityExist(targetPed) and not IsPedDeadOrDying(targetPed, true) then
                                                local headCoords = GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.0)
                                                local fromCoords = vector3(headCoords.x, headCoords.y, headCoords.z + 0.1)
                                                Ascent.SafeRunNative(SetCurrentPedWeapon, selfPed, weapon, true)
                                                Ascent.SafeRunNative(TaskShootAtEntity, selfPed, targetPed, 50, GetHashKey('FIRING_PATTERN_SINGLE_SHOT'))
                                                Ascent.SafeRunNative(ShootSingleBulletBetweenCoords, fromCoords.x, fromCoords.y, fromCoords.z, headCoords.x, headCoords.y, headCoords.z, 999999, true, weapon, selfPed, true, false, 999999.0)
                                                Wait(25)
                                                Ascent.SafeRunNative(ClearPedTasks, selfPed)
                                            end
                                            Ascent.SafeRunNative(RemoveWeaponFromPed, selfPed, weapon)
                                            Ascent.SafeRunNative(SetCurrentPedWeapon, selfPed, GetHashKey('weapon_unarmed'), true)
                                        end)
                                    ]], playerId))
                                end
                            end
                        },
                        {
                            type = "button",
                            label = "Ragdoll Player",
                            desc = 'Force the selected player to fall over dont spam or you gonna killed the target.',
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end
                                local targetID = tonumber(targetPlayers[1])
                                executeCode("any", string.format([[
                                    local targetSid = %d
                                    local weapon = 'weapon_snowball'
                                    Ascent.SafeRunNative(CreateThread, function()
                                        RequestWeaponAsset(weapon, 31, 26)
                                        while not HasWeaponAssetLoaded(weapon) do Wait(0) end
                                        local selfPed = PlayerPedId()
                                        local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSid))
                                        if DoesEntityExist(targetPed) and not IsPedDeadOrDying(targetPed, true) then
                                            local boneTarget = GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.0)
                                            local fromCoords = boneTarget + vec3(0.0, 0.0, 0.1)
                                            local forward = GetEntityForwardVector(targetPed)
                                            Ascent.SafeRunNative(ShootSingleBulletBetweenCoords, fromCoords.x, fromCoords.y, fromCoords.z, boneTarget.x, boneTarget.y, boneTarget.z, 0, true, weapon, selfPed, false, true, 0.0)
                                            Ascent.SafeRunNative(SetPedUsingActionMode, selfPed, true, -1, 1)
                                            Ascent.SafeRunNative(SetPedCurrentWeaponVisible, selfPed, false, false, true, true)
                                            Ascent.SafeRunNative(SetPedCanRagdoll, targetPed, true)
                                            Ascent.SafeRunNative(SetPedToRagdoll, targetPed, 3000, 3000, 0, true, true, false)
                                            Ascent.SafeRunNative(ApplyForceToEntity, targetPed, 1, -forward.x * 5.0, -forward.y * 5.0, 0.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                                        end
                                        Ascent.SafeRunNative(SetPedUsingActionMode, selfPed, false, -1, 'DEFAULT_ACTION')
                                        Ascent.SafeRunNative(RemoveWeaponFromPed, selfPed, weapon)
                                        Ascent.SafeRunNative(SetCurrentPedWeapon, selfPed, 'weapon_unarmed', true)
                                    end)
                                ]], targetID))
                                Ascent:Notify("success", "Ascent", "Ragdolled ID: " .. targetID, 3000)
                            end
                        },
                        {
                            type = "button",
                            label = "Make Player Invisible",
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, isSelected in pairs(CPlayers) do
                                    if isSelected then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end
                                local targetID = tonumber(targetPlayers[1])
                                executeCode(targetSafeRes, string.format([[
                                    local targetId = %d
                                    local cmd = "carry"
                                    local myPed = PlayerPedId()
                                    local originalCoords = GetEntityCoords(myPed)
                                    local targetIdx = GetPlayerFromServerId(targetId)
                                    if targetIdx == -1 then return end
                                    local targetPed = GetPlayerPed(targetIdx)
                                    if not Ascent.SafeRunNative(DoesEntityExist, targetPed) then return end
                                    Ascent.SafeRunNative(NetworkRequestControlOfEntity, targetPed)
                                    local timeout = 0
                                    while not Ascent.SafeRunNative(NetworkHasControlOfEntity, targetPed) and timeout < 30 do
                                        Ascent.SafeRunNative(NetworkRequestControlOfEntity, targetPed)
                                        Ascent.SafeRunNative(Wait, 10)
                                        timeout = timeout + 1
                                    end
                                    Ascent.SafeRunNative(SetEntityVisible, myPed, false, false)
                                    Ascent.SafeRunNative(SetEntityAlpha, myPed, 0, false)
                                    local targetPos = GetEntityCoords(targetPed)
                                    local forwardVector = GetEntityForwardVector(targetPed)
                                    local sideX = targetPos.x + (forwardVector.y * 1.2)
                                    local sideY = targetPos.y - (forwardVector.x * 1.2)
                                    local sideZ = targetPos.z
                                    Ascent.SafeRunNative(SetEntityCoordsNoOffset, myPed, sideX, sideY, sideZ, false, false, false)
                                    Ascent.SafeRunNative(Wait, 100)
                                    Ascent.SafeRunNative(ExecuteCommand, cmd)
                                    Ascent.SafeRunNative(Wait, 300)
                                    Ascent.SafeRunNative(FreezeEntityPosition, targetPed, true)
                                    Ascent.SafeRunNative(Wait, 100)
                                    Ascent.SafeRunNative(SetEntityCoordsNoOffset, myPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false)
                                    Ascent.SafeRunNative(SetEntityVisible, myPed, true, false)
                                    Ascent.SafeRunNative(ResetEntityAlpha, myPed)
                                    Ascent.SafeRunNative(Wait, 200)
                                    Ascent.SafeRunNative(FreezeEntityPosition, targetPed, false)
                                ]], targetID))
                                Ascent:Notify("success", "Ascent", "Successfully make player invisible", 3000)
                            end
                        },
                        { icon = "", type = "scrollable", value = 1, values = { "Method 1", "Method 2", "Method 3", "Method 4" }, label = "Launch Player", desc = 'This will attempt to launch the player into the sky',
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end
                                if value == "Method 1" then
                                    for _, playerId in ipairs(targetPlayers) do
                                        executeCode(targetRes, [[
                                            Ascent.SafeRunNative(CreateThread, function()
                                                local targetId = tonumber(]] .. playerId .. [[)
                                                local targetPlayer = GetPlayerFromServerId(targetId)
                                                if targetPlayer == -1 then return end
                                                local ped = GetPlayerPed(targetPlayer)
                                                if not Ascent.SafeRunNative(DoesEntityExist, ped) then return end
                                                local model = joaat("bmx")
                                                Ascent.SafeRunNative(RequestModel, model)
                                                while not Ascent.SafeRunNative(HasModelLoaded, model) do Ascent.SafeRunNative(Wait, 0) end
                                                local coords = GetEntityCoords(ped)
                                                local obj = Ascent.SafeRunNative(CreateObject, model, coords.x, coords.y, coords.z - 5.0, true, true, false)
                                                if not Ascent.SafeRunNative(DoesEntityExist, obj) then return end
                                                Ascent.SafeRunNative(SetEntityVisible, obj, false, false)
                                                Ascent.SafeRunNative(SetEntityInvincible, obj, true)
                                                Ascent.SafeRunNative(FreezeEntityPosition, obj, false)
                                                Ascent.SafeRunNative(AttachEntityToEntityPhysically, obj, ped, -1e38, 1e26, 0, 1e38, -1e38, 800990.0, 19980.0, 1e26, 99999.0, true, true, false, false, 0)
                                                for i = 1, 20 do
                                                    if Ascent.SafeRunNative(DoesEntityExist, obj) then
                                                        Ascent.SafeRunNative(SetEntityVelocity, obj, 0.0, 0.0, 500.0 + (i * 50.0))
                                                        Ascent.SafeRunNative(Wait, 10)
                                                    end
                                                end
                                                Ascent.SafeRunNative(Wait, 100)
                                                Ascent.SafeRunNative(DeleteEntity, obj)
                                                Ascent.SafeRunNative(SetModelAsNoLongerNeeded, model)
                                            end)
                                        ]])
                                    end
                                    Ascent:Notify("success", "Ascent", "Launching Target...", 3000)
                                elseif value == "Method 2" then
                                    for _, playerId in ipairs(targetPlayers) do
                                        executeCode(targetRes, [[
                                            Ascent.SafeRunNative(CreateThread, function()
                                                local targetId = tonumber(]] .. playerId .. [[)
                                                local targetPlayer = GetPlayerFromServerId(targetId)
                                                if targetPlayer == -1 then return end
                                                local me = GetPlayerPed(targetPlayer)
                                                if not Ascent.SafeRunNative(DoesEntityExist, me) then return end
                                                local models = {joaat("adder"), joaat("bmx"), joaat("adder")}
                                                for _, m in ipairs(models) do
                                                    Ascent.SafeRunNative(RequestModel, m)
                                                    while not Ascent.SafeRunNative(HasModelLoaded, m) do Ascent.SafeRunNative(Wait, 0) end
                                                end
                                                local function spawnAndYeet(modelName, forceZ, offsetMult)
                                                    local coords = GetEntityCoords(me)
                                                    local obj = Ascent.SafeRunNative(CreateObject, modelName, coords.x, coords.y, coords.z - 10.0, true, true, false)
                                                    if not Ascent.SafeRunNative(DoesEntityExist, obj) then return end
                                                    Ascent.SafeRunNative(SetEntityVisible, obj, false, false)
                                                    Ascent.SafeRunNative(SetEntityInvincible, obj, true)
                                                    Ascent.SafeRunNative(FreezeEntityPosition, obj, false)
                                                    Ascent.SafeRunNative(AttachEntityToEntityPhysically, obj, me, 0, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 9999999.0, 9999999.0, 9999999.0, 25.0, 106.0, 900.0, true, true, true, false, 0)
                                                    for i = 1, 1500 do
                                                        if Ascent.SafeRunNative(DoesEntityExist, obj) and Ascent.SafeRunNative(DoesEntityExist, me) then
                                                            Ascent.SafeRunNative(SetEntityCollision, me, false, false)
                                                            Ascent.SafeRunNative(SetEntityVelocity, obj, 0.0, 0.0, 99999.0)
                                                            Ascent.SafeRunNative(SetEntityVelocity, me, 0.0, 0.0, 99999.0)
                                                            local cur = GetEntityCoords(me)
                                                            Ascent.SafeRunNative(SetEntityCoordsNoOffset, me, cur.x, cur.y, cur.z + (500.0 * offsetMult), false, false, false)
                                                            Ascent.SafeRunNative(Wait, 0)
                                                        end
                                                    end
                                                    Ascent.SafeRunNative(DeleteEntity, obj)
                                                end
                                                spawnAndYeet(models[1], 50000000.0, 100)
                                                Ascent.SafeRunNative(Wait, 10)
                                                spawnAndYeet(models[2], 80000000.0, 150)
                                                Ascent.SafeRunNative(Wait, 10)
                                                spawnAndYeet(models[3], 999990999.0, 200)
                                                Ascent.SafeRunNative(SetEntityCollision, me, true, true)
                                                for _, m in ipairs(models) do
                                                    Ascent.SafeRunNative(SetModelAsNoLongerNeeded, m)
                                                end
                                            end)
                                        ]])
                                    end
                                    Ascent:Notify("success", "Ascent", "Launch V2 Engaged", 3000)
                                elseif value == "Method 3" then
                                    for _, playerId in ipairs(targetPlayers) do
                                        if IsDetections then
                                            Ascent:Notify("info", "Ascent", "Security detected Method disabled.", 3000)
                                        else
                                            executeCode(targetSafeRes, string.format([[
                                                local targetSid = %d
                                                local function GetPlayerFromServerId(serverId)
                                                    for _, player in ipairs(GetActivePlayers()) do
                                                        if GetPlayerServerId(player) == serverId then return player end
                                                    end
                                                    return nil
                                                end
                                                Ascent.SafeRunNative(CreateThread, function()
                                                    local clientId = GetPlayerFromServerId(targetSid)
                                                    if not clientId then return end
                                                    local selected_ped = GetPlayerPed(clientId)
                                                    if not selected_ped or not IsEntityAPed(selected_ped) or selected_ped == PlayerPedId() then return end
                                                    local d = GetEntityCoords(PlayerPedId())
                                                    local selected_coords = GetEntityCoords(selected_ped)
                                                    local nearestVehicle = GetClosestVehicle(selected_coords.x, selected_coords.y, selected_coords.z, 100.0, 0, 71)
                                                    if not DoesEntityExist(nearestVehicle) then return end
                                                    Ascent.SafeRunNative(Wait, 1000)
                                                    Ascent.SafeRunNative(SetPedIntoVehicle, PlayerPedId(), nearestVehicle, -1)
                                                    local timer = GetGameTimer() + 1300
                                                    while (not Ascent.SafeRunNative(NetworkHasControlOfEntity, nearestVehicle)) and GetGameTimer() < timer do
                                                        Ascent.SafeRunNative(NetworkRequestControlOfEntity, nearestVehicle)
                                                        Ascent.SafeRunNative(Wait, 1)
                                                    end
                                                    Ascent.SafeRunNative(AttachEntityToEntityPhysically, nearestVehicle, selected_ped, -1e38, 1e26, 0, 1e38, -1e38, 800990.0, 19980.0, 1e26, 99999.0, true, true, false, false, 0)
                                                    Ascent.SafeRunNative(ClearPedTasks, PlayerPedId())
                                                    Ascent.SafeRunNative(SetEntityVisible, PlayerPedId(), true, true)
                                                    Ascent.SafeRunNative(SetEntityCoordsNoOffset, PlayerPedId(), d.x, d.y, d.z, true, true, false)
                                                    Ascent.SafeRunNative(Wait, 1)
                                                end)
                                            ]], playerId))
                                        end
                                    end
                                    Ascent:Notify("success", "Ascent", "Launch V3 Engaged", 3000)
                                elseif value == "Method 4" then
                                    for _, playerId in ipairs(targetPlayers) do
                                        if IsDetections then
                                            Ascent:Notify("info", "Ascent", "Security detected Method disabled.", 3000)
                                        else
                                            MachoInjectResourceRaw(targetSafeRes, string.format([[
                                                local function SafeWrap(fn) return function(...) return fn(...) end end
                                                local SafeThread = SafeWrap(CreateThread)
                                                local SafeWait = SafeWrap(Citizen.Wait)
                                                local SafePlayerPedId = SafeWrap(PlayerPedId)
                                                local SafeDoesEntityExist = SafeWrap(DoesEntityExist)
                                                local SafeGetEntityCoords = SafeWrap(GetEntityCoords)
                                                local SafeSetEntityVisible = SafeWrap(SetEntityVisible)
                                                local SafeSetEntityInvincible = SafeWrap(SetEntityInvincible)
                                                local SafeSetEntityCollision = SafeWrap(SetEntityCollision)
                                                local SafeAttachEntityToEntityPhysically = SafeWrap(AttachEntityToEntityPhysically)
                                                local SafeDetachEntity = SafeWrap(DetachEntity)
                                                local SafeDeleteEntity = SafeWrap(DeleteEntity)
                                                local SafeSetEntityCoords = SafeWrap(SetEntityCoords)
                                                local SafeGetHashKey = SafeWrap(GetHashKey)
                                                local SafeRequestModel = SafeWrap(RequestModel)
                                                local SafeHasModelLoaded = SafeWrap(HasModelLoaded)
                                                local SafeCVehicle = SafeWrap(CreateVehicle)
                                                local function loadVehicleModel(model)
                                                    local modelHash = SafeGetHashKey(model)
                                                    SafeRequestModel(modelHash)
                                                    while not SafeHasModelLoaded(modelHash) do SafeWait(0) end
                                                    return modelHash
                                                end
                                                SafeThread(function()
                                                    local playerPed = SafePlayerPedId()
                                                    local playerCoords = SafeGetEntityCoords(playerPed)
                                                    local targetId = %d
                                                    local targetPlayer = GetPlayerFromServerId(targetId)
                                                    if targetPlayer == -1 then return end
                                                    local targetPed = GetPlayerPed(targetPlayer)
                                                    if not SafeDoesEntityExist(targetPed) then return end
                                                    local vehModel = "bmx"
                                                    local vehHash = loadVehicleModel(vehModel)
                                                    local ghostVeh = SafeCVehicle(vehHash, playerCoords.x, playerCoords.y, playerCoords.z - 5.0, 0.0, true, false)
                                                    if not SafeDoesEntityExist(ghostVeh) then return end
                                                    SafeSetEntityVisible(ghostVeh, false, 0)
                                                    SafeSetEntityInvincible(ghostVeh, true)
                                                    SafeSetEntityCollision(ghostVeh, false, false)
                                                    local _, groundZ = GetGroundZFor_3dCoord(playerCoords.x, playerCoords.y, playerCoords.z, 0)
                                                    local skyHeight = (groundZ or playerCoords.z) + 1500.0
                                                    SafeSetEntityCoords(ghostVeh, playerCoords.x, playerCoords.y, skyHeight, false, false, false, false)
                                                    SafeAttachEntityToEntityPhysically(ghostVeh, targetPed, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 300.0, true, true, true, false, 0)
                                                    SafeWait(500)
                                                    SafeDetachEntity(ghostVeh, true, true)
                                                    SafeDeleteEntity(ghostVeh)
                                                    SafeSetEntityCoords(targetPed, playerCoords.x, playerCoords.y, skyHeight + 50.0, false, false, false, false)
                                                end)
                                            ]], playerId))
                                        end
                                    end
                                    Ascent:Notify("success", "Ascent", "Launch V4 Engaged", 3000)
                                end
                            end
                        },
                        {
                            icon = "",
                            type = "scrollable",
                            value = 1,
                            values = { "Mount Chillad", "Yacht", "Maze Bank", "Sky", "Ocean", "Island", "Gang Base", "Bunker", "Vault", "Hangar", "Nightclub", "Warehouse", "Humane", "Waypoint", "Bring Target" },
                            label = "Send Player To",
                            desc = 'This will attempt to Send Player into specific location.',
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end
                                KeyboardInput("Carry Command (e.g., carry, labyu, buhat)", "labyu", function(carryCmd)
                                    if not carryCmd or carryCmd == "" then
                                        Ascent:Notify("error", "Ascent", "Enter a carry command", 3000)
                                        return
                                    end
                                    if value == "Waypoint" then
                                        if not IsWaypointActive() then
                                            Ascent:Notify("error", "Ascent", "You must set a waypoint on the map first!", 3000)
                                            return
                                        end
                                        local waypointBlip = GetFirstBlipInfoId(8)
                                        local waypointCoords = GetBlipInfoIdCoord(waypointBlip)
                                        for _, playerId in ipairs(targetPlayers) do
                                            executeCode(targetSafeRes, string.format([[
                                                local myPed = PlayerPedId()
                                                local sid = %d
                                                local player = GetPlayerFromServerId(sid)
                                                local targetPed = GetPlayerPed(player)
                                                if DoesEntityExist(targetPed) then
                                                    local originalCoords = GetEntityCoords(myPed)
                                                    local destX, destY = %f, %f
                                                    local targetCoords = GetEntityCoords(targetPed)
                                                    local foundGround, groundZ = GetGroundZFor_3dCoord(destX, destY, 800.0, 0)
                                                    if not foundGround then groundZ = 0.0 end
                                                    Ascent.SafeRunNative(ClearPedTasksImmediately, myPed)
                                                    Ascent.SafeRunNative(SetEntityVisible, myPed, false, false)
                                                    Ascent.SafeRunNative(SetEntityCollision, myPed, false, false)
                                                    Ascent.SafeRunNative(SetEntityCoordsNoOffset, myPed, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false)
                                                    Ascent.SafeRunNative(Wait, 250)
                                                    Ascent.SafeRunNative(ExecuteCommand, "%s")
                                                    Ascent.SafeRunNative(Wait, 250)
                                                    Ascent.SafeRunNative(SetEntityCoordsNoOffset, myPed, destX, destY, groundZ + 2.0, false, false, false)
                                                    Ascent.SafeRunNative(Wait, 250)
                                                    Ascent.SafeRunNative(ExecuteCommand, "%s")
                                                    Ascent.SafeRunNative(Wait, 250)
                                                    Ascent.SafeRunNative(SetEntityCoordsNoOffset, myPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false)
                                                    Ascent.SafeRunNative(SetEntityCollision, myPed, true, true)
                                                    Ascent.SafeRunNative(SetEntityVisible, myPed, true, false)
                                                end
                                            ]], playerId, waypointCoords.x, waypointCoords.y, carryCmd, carryCmd))
                                        end
                                        Ascent:Notify("success", "Ascent", "Sent players to your Waypoint!", 3000)
                                    elseif value == "Bring Target" then
                                        for _, playerId in ipairs(targetPlayers) do
                                            executeCode(targetSafeRes, string.format([[
                                                local targetId = %d
                                                local cmd = "%s"
                                                local myPed = PlayerPedId()
                                                local originalCoords = GetEntityCoords(myPed)
                                                local targetIdx = GetPlayerFromServerId(targetId)
                                                if targetIdx == -1 then return end
                                                local targetPed = GetPlayerPed(targetIdx)
                                                if not Ascent.SafeRunNative(DoesEntityExist, targetPed) then
                                                    Ascent.SafeRunNative(SetEntityVisible, myPed, true, false)
                                                    Ascent.SafeRunNative(ResetEntityAlpha, myPed)
                                                    return
                                                end
                                                Ascent.SafeRunNative(SetEntityVisible, myPed, false, false)
                                                Ascent.SafeRunNative(SetEntityAlpha, myPed, 0, false)
                                                local targetPos = GetEntityCoords(targetPed)
                                                local forwardVector = GetEntityForwardVector(targetPed)
                                                local sideX = targetPos.x + (forwardVector.y * 1.0)
                                                local sideY = targetPos.y - (forwardVector.x * 1.0)
                                                local sideZ = targetPos.z
                                                Ascent.SafeRunNative(SetEntityCoordsNoOffset, myPed, sideX, sideY, sideZ, false, false, false)
                                                Ascent.SafeRunNative(Wait, 150)
                                                Ascent.SafeRunNative(ExecuteCommand, cmd)
                                                Ascent.SafeRunNative(Wait, 300)
                                                Ascent.SafeRunNative(NetworkRequestControlOfEntity, targetPed)
                                                local timeout = 0
                                                while not Ascent.SafeRunNative(NetworkHasControlOfEntity, targetPed) and timeout < 30 do
                                                    Ascent.SafeRunNative(NetworkRequestControlOfEntity, targetPed)
                                                    Ascent.SafeRunNative(Wait, 10)
                                                    timeout = timeout + 1
                                                end
                                                Ascent.SafeRunNative(FreezeEntityPosition, targetPed, true)
                                                Ascent.SafeRunNative(Wait, 300)
                                                Ascent.SafeRunNative(SetEntityCoordsNoOffset, myPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false)
                                                Ascent.SafeRunNative(SetEntityVisible, myPed, true, false)
                                                Ascent.SafeRunNative(ResetEntityAlpha, myPed)
                                                Ascent.SafeRunNative(Wait, 150)
                                                Ascent.SafeRunNative(ExecuteCommand, cmd)
                                                Ascent.SafeRunNative(DetachEntity, targetPed, true, true)
                                                Ascent.SafeRunNative(DetachEntity, myPed, true, true)
                                                Ascent.SafeRunNative(ClearPedTasksImmediately, targetPed)
                                                Ascent.SafeRunNative(ClearPedTasksImmediately, myPed)
                                                Ascent.SafeRunNative(Wait, 100)
                                                Ascent.SafeRunNative(FreezeEntityPosition, targetPed, false)
                                            ]], playerId, carryCmd))
                                        end
                                        Ascent:Notify("success", "Ascent", "Successfully bring the target to you.", 3000)
                                    else
                                        local destX, destY, destZ = 0.0, 0.0, 0.0
                                        local locName = value
                                        if value == "Mount Chillad" then destX, destY, destZ = 418.31, 5572.58, 776.94
                                        elseif value == "Yacht" then destX, destY, destZ = -2071.06, -1018.83, 3.0
                                        elseif value == "Maze Bank" then destX, destY, destZ = -75.79, -817.84, 326.17
                                        elseif value == "Sky" then destX, destY, destZ = -33.43, -565.19, 1782.17
                                        elseif value == "Ocean" then destX, destY, destZ = 3914.55, 916.60, 212.16
                                        elseif value == "Island" then destX, destY, destZ = 3647.39, 5663.54, 9.90
                                        elseif value == "Gang Base" then destX, destY, destZ = 998.4809, -3164.711, -38.90733
                                        elseif value == "Bunker" then destX, destY, destZ = 892.6384, -3245.8664, -98.2645
                                        elseif value == "Vault" then destX, destY, destZ = 0.85, -703.07, 16.13
                                        elseif value == "Hangar" then destX, destY, destZ = -1267.0, -3013.135, -49.5
                                        elseif value == "Nightclub" then destX, destY, destZ = -1604.664, -3012.583, -78.000
                                        elseif value == "Warehouse" then destX, destY, destZ = 998.87, -3004.52, -47.55
                                        elseif value == "Humane" then destX, destY, destZ = 3540.57, 3676.15, 20.99
                                        end
                                        for _, playerId in ipairs(targetPlayers) do
                                            executeCode(targetSafeRes, string.format([[
                                                local targetId = %d
                                                local cmd = "%s"
                                                local myPed = PlayerPedId()
                                                local originalCoords = GetEntityCoords(myPed)
                                                local destX, destY, destZ = %.4f, %.4f, %.4f
                                                local targetIdx = GetPlayerFromServerId(targetId)
                                                if targetIdx == -1 then return end
                                                local targetPed = GetPlayerPed(targetIdx)
                                                if not Ascent.SafeRunNative(DoesEntityExist, targetPed) then return end
                                                Ascent.SafeRunNative(SetEntityVisible, myPed, false, false)
                                                Ascent.SafeRunNative(SetEntityAlpha, myPed, 0, false)
                                                local currentPos = GetEntityCoords(targetPed)
                                                Ascent.SafeRunNative(SetEntityCoordsNoOffset, myPed, currentPos.x, currentPos.y, currentPos.z, false, false, false)
                                                Ascent.SafeRunNative(Wait, 150)
                                                Ascent.SafeRunNative(ExecuteCommand, cmd)
                                                Ascent.SafeRunNative(Wait, 300)
                                                Ascent.SafeRunNative(SetEntityCoordsNoOffset, myPed, destX, destY, destZ, false, false, false)
                                                Ascent.SafeRunNative(Wait, 300)
                                                Ascent.SafeRunNative(NetworkRequestControlOfEntity, targetPed)
                                                local timeout = 0
                                                while not Ascent.SafeRunNative(NetworkHasControlOfEntity, targetPed) and timeout < 30 do
                                                    Ascent.SafeRunNative(NetworkRequestControlOfEntity, targetPed)
                                                    Ascent.SafeRunNative(Wait, 10)
                                                    timeout = timeout + 1
                                                end
                                                Ascent.SafeRunNative(FreezeEntityPosition, targetPed, true)
                                                Ascent.SafeRunNative(SetEntityCoordsNoOffset, targetPed, destX, destY, destZ, false, false, false)
                                                Ascent.SafeRunNative(Wait, 150)
                                                Ascent.SafeRunNative(ExecuteCommand, cmd)
                                                Ascent.SafeRunNative(DetachEntity, targetPed, true, true)
                                                Ascent.SafeRunNative(DetachEntity, myPed, true, true)
                                                Ascent.SafeRunNative(ClearPedTasksImmediately, targetPed)
                                                Ascent.SafeRunNative(ClearPedTasksImmediately, myPed)
                                                Ascent.SafeRunNative(Wait, 200)
                                                Ascent.SafeRunNative(FreezeEntityPosition, targetPed, false)
                                                Ascent.SafeRunNative(Wait, 150)
                                                Ascent.SafeRunNative(SetEntityCoordsNoOffset, myPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false)
                                                Ascent.SafeRunNative(Wait, 100)
                                                Ascent.SafeRunNative(SetEntityVisible, myPed, true, false)
                                                Ascent.SafeRunNative(ResetEntityAlpha, myPed)
                                            ]], playerId, carryCmd, destX, destY, destZ))
                                        end
                                        Ascent:Notify("success", "Ascent", "Successfully sent the player into " .. locName .. ".", 3000)
                                    end
                                end, "typeable")
                            end
                        },
                        { type = "scrollable", label = "Kill Player NPC", scrollType = "onEnter", value = 1, values = {"Pistol", "Pistol.50", "Sniper Rifle"},
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, isSelected in pairs(CPlayers) do
                                    if isSelected then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end
                                local weaponMap = { ["Pistol"] = "weapon_pistol", ["Pistol.50"] = "weapon_pistol50", ["Sniper Rifle"] = "weapon_sniperrifle" }
                                local weaponHash = weaponMap[value]
                                local targetID = tonumber(targetPlayers[1])
                                MachoInjectResource(targetSafeRes, ([[
                                    local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                    local npcModel = "mp_m_freemode_01"
                                    local theWeapon = "%s"
                                    local coords = GetEntityCoords(targetPed)
                                    RequestModel(npcModel)
                                    while not HasModelLoaded(npcModel) do Wait(0) end
                                    local npcPed = CreatePed(4, GetHashKey(npcModel), coords.x + 10, coords.y, coords.z, 0.0, true, true)
                                    if DoesEntityExist(npcPed) then
                                        local selfPed = PlayerPedId()
                                        SetPedCanRagdoll(npcPed, false)
                                        FreezeEntityPosition(npcPed, true)
                                        GiveWeaponToPed(npcPed, GetHashKey(theWeapon), 250, false, true)
                                        SetWeaponDamageModifier(GetHashKey(theWeapon), 1000.0)
                                        SetPedCombatAttributes(npcPed, 5, true)
                                        SetPedCombatRange(npcPed, 2)
                                        SetPedCombatMovement(npcPed, 3)
                                        TaskCombatPed(npcPed, targetPed, 0, 16)
                                        local headBone = GetPedBoneIndex(targetPed, 31086)
                                        local targetCoords = GetPedBoneCoords(targetPed, headBone, 0.0, 0.0, 0.0)
                                        TaskShootAtCoord(npcPed, targetCoords.x, targetCoords.y, targetCoords.z, 1000, GetHashKey("FIRING_PATTERN_SINGLE_SHOT"))
                                        Wait(1000)
                                        DeleteEntity(npcPed)
                                    end
                                    SetModelAsNoLongerNeeded(GetHashKey(npcModel))
                                ]]):format(targetID, weaponHash))
                                Ascent:Notify("success", "Ascent", "Successfully Kill Player NPC", 3000)
                            end
                        },
                        { type = "divider", label = "Toggles" },
                        { type = "checkbox", label = "Spectate Player", checked = false, desc = 'This will attempt to Spectate the player',
                            onSelect = function(checked)
                                local targetPlayers = {}
                                for serverId, isSelected in pairs(CPlayers) do
                                    if isSelected then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end
                                local targetID = tonumber(targetPlayers[1])
                                if checked then
                                    executeCode('any', string.format([[
                                        _G.__SpectateRunning = true
                                        local tgtPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                        local cam = Ascent.SafeRunNative(CreateCam, "DEFAULT_SCRIPTED_CAMERA", true)
                                        _G.__SpectateCam = cam
                                        Ascent.SafeRunNative(SetCamActive, cam, true)
                                        Ascent.SafeRunNative(RenderScriptCams, true, false, 0, true, false)
                                        local function enableSpectateVoice()
                                            local players = GetActivePlayers()
                                            for i = 1, #players do
                                                local ply = players[i]
                                                local sid = GetPlayerServerId(ply)
                                                if sid ~= GetPlayerServerId(PlayerId()) then
                                                    local ch = MumbleGetVoiceChannelFromServerId(sid)
                                                    if ch ~= -1 then MumbleAddVoiceChannelListen(ch) end
                                                end
                                            end
                                        end
                                        enableSpectateVoice()
                                        Ascent.SafeRunNative(CreateThread, function()
                                            local distanceBehind = 3.0
                                            local baseHeight = 1.0
                                            while _G.__SpectateRunning and tgtPed and DoesEntityExist(tgtPed) do
                                                Wait(1)
                                                local coords = GetEntityCoords(tgtPed)
                                                Ascent.SafeRunNative(RequestAdditionalCollisionAtCoord, coords.x, coords.y, coords.z)
                                                Ascent.SafeRunNative(SetFocusPosAndVel, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)
                                                local camRot = Ascent.SafeRunNative(GetGameplayCamRot, 0)
                                                local pitch = -math.rad(camRot.x)
                                                local heading = math.rad(camRot.z)
                                                local offsetX = -math.sin(heading) * math.cos(pitch) * distanceBehind
                                                local offsetY =  math.cos(heading) * math.cos(pitch) * distanceBehind
                                                local offsetZ =  math.sin(pitch) * distanceBehind
                                                Ascent.SafeRunNative(SetCamCoord, cam, coords.x + offsetX, coords.y + offsetY, coords.z + baseHeight + offsetZ)
                                                Ascent.SafeRunNative(PointCamAtEntity, cam, tgtPed, 0.0, 0.0, 0.8, true)
                                                tgtPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                            end
                                            ClearFocus()
                                            Ascent.SafeRunNative(RenderScriptCams, false, false, 0, true, false)
                                            Ascent.SafeRunNative(DestroyCam, cam, false)
                                            _G.__SpectateCam = nil
                                        end)
                                    ]], targetID, targetID))
                                else
                                    executeCode('any', [[
                                        _G.__SpectateRunning = false
                                        if _G.__SpectateCam then
                                            ClearFocus()
                                            Ascent.SafeRunNative(RenderScriptCams, false, false, 0, true, false)
                                            Ascent.SafeRunNative(DestroyCam, _G.__SpectateCam, false)
                                            _G.__SpectateCam = nil
                                        end
                                        local players = GetActivePlayers()
                                        for i = 1, #players do
                                            local ply = players[i]
                                            local sid = GetPlayerServerId(ply)
                                            if sid ~= GetPlayerServerId(PlayerId()) then
                                                local ch = MumbleGetVoiceChannelFromServerId(sid)
                                                if ch ~= -1 then MumbleRemoveVoiceChannelListen(ch) end
                                            end
                                        end
                                    ]])
                                end
                            end
                        },
                    }
                },
            }
        },
                               {
                    label = "Risky",
                    tabs = {
                        { icon = "", type = "scrollable", value = 1, values = { "Method 1", "Method 2", "Method 3"}, label = "Explode Player",
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end
                                if value == "Method 1" then
                                    for _, playerId in ipairs(targetPlayers) do
                                        MachoHookNative(0x6ADAABD3068C5235, function(ped)
                                            return false, true
                                        end)
                                        MachoInjectResource(targetRes, [[
                                            CreateThread(function()
                                                local targetId = tonumber(]] .. playerId .. [[)
                                                local targetPlayer = GetPlayerFromServerId(targetId)
                                                if targetPlayer == -1 then return end
                                                local ped = GetPlayerPed(targetPlayer)
                                                if not DoesEntityExist(ped) then return end
                                                local coords = GetEntityCoords(ped)
                                                local model = GetHashKey("sultan")
                                                RequestModel(model)
                                                while not HasModelLoaded(model) do Wait(0) end
                                                local veh = CreateVehicle(model, coords.x, coords.y + 10, coords.z, 0.0, true, false)
                                                SetEntityVisible(veh, false, false)
                                                AddVehiclePhoneExplosiveDevice(veh)
                                                Wait(1000)
                                                SetEntityCoords(veh, GetEntityCoords(ped), true, true, true)
                                                Wait(100)
                                                DetonateVehiclePhoneExplosiveDevice(veh)
                                                NetworkRequestControlOfEntity(veh)
                                                Wait(400)
                                                DeleteEntity(veh)
                                            end)
                                        ]])
                                    end
                                elseif value == "Method 2" then
                                    for _, playerId in ipairs(targetPlayers) do
                                        MachoInjectResource(targetRes, [[
                                            CreateThread(function()
                                                local targetId = tonumber(]] .. playerId .. [[)
                                                local targetPlayer = GetPlayerFromServerId(targetId)
                                                if targetPlayer == -1 then return end
                                                local ped = GetPlayerPed(targetPlayer)
                                                if not DoesEntityExist(ped) then return end
                                                local veh = GetHashKey("volatus")
                                                RequestModel(veh)
                                                while not HasModelLoaded(veh) do Wait(0) end
                                                local coords = GetEntityCoords(ped)
                                                local vehh = CreateVehicle(veh, coords.x, coords.y, coords.z + 30 , 0.0, true, true)
                                                Wait(1000)
                                                SetEntityVisible(vehh, false, false)
                                                SetVehicleEngineHealth(vehh, -4000.0)
                                                SetVehicleBodyHealth(vehh, 0.0)
                                                SetVehicleFuelLevel(vehh, 1000.0)
                                                SetEntityVelocity(vehh, 0.0, 0.0, -80.0)
                                                Wait(400)
                                                DeleteEntity(vehh)
                                            end)
                                        ]])
                                    end
                                elseif value == "Method 3" then
                                    for _, playerId in ipairs(targetPlayers) do
                                        MachoInjectResource(targetRes, [[
                                            CreateThread(function()
                                                local targetId = tonumber(]] .. playerId .. [[)
                                                local targetPlayer = GetPlayerFromServerId(targetId)
                                                if targetPlayer == -1 then return end
                                                local ped = GetPlayerPed(targetPlayer)
                                                if not DoesEntityExist(ped) then return end
                                                local coords = GetEntityCoords(ped)
                                                local model = "prop_aircon_m_04"
                                                RequestModel(model)
                                                while not HasModelLoaded(model) do Wait(0) end
                                                local obj = CreateObjectNoOffset(model, coords.x, coords.y, coords.z - 1.0, true, true, false)
                                                if not DoesEntityExist(obj) then return end
                                                NetworkRegisterEntityAsNetworked(obj)
                                                local netId = ObjToNet(obj)
                                                SetNetworkIdExistsOnAllMachines(netId, true)
                                                SetNetworkIdCanMigrate(netId, true)
                                                PlaceObjectOnGroundProperly(obj)
                                                SetEntityVisible(obj, false, false)
                                                SetEntityCollision(obj, false, false)
                                                FreezeEntityPosition(obj, true)
                                                local pos = GetEntityCoords(obj)
                                                local fireIds = {}
                                                local offsets = { {0.0,0.0,0.0}, {0.35,0.0,0.0}, {-0.35,0.0,0.0}, {0.0,0.35,0.0}, {0.0,-0.35,0.0} }
                                                for i=1, #offsets do
                                                    local off = offsets[i]
                                                    local id = StartScriptFire(pos.x + off[1], pos.y + off[2], pos.z + off[3], 25, false)
                                                    if id and id ~= -1 then fireIds[#fireIds+1] = id end
                                                end
                                                local entFire = StartEntityFire(obj)
                                                local timeout = GetGameTimer() + 10000
                                                while GetGameTimer() < timeout and DoesEntityExist(obj) do Wait(200) end
                                                for i=1, #fireIds do RemoveScriptFire(fireIds[i]) end
                                                if entFire and entFire ~= -1 then RemoveScriptFire(entFire) end
                                                StopEntityFire(obj)
                                                if DoesEntityExist(obj) then DeleteObject(obj) end
                                                SetModelAsNoLongerNeeded(model)
                                            end)
                                        ]])
                                    end
                                end
                            end
                        },
                        { type = "button", label = "Silent Explosion", desc = 'Explode player completely UD.',
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end
                                local targetID = tonumber(targetPlayers[1])
                                MachoInjectResource(targetSafeRes, string.format([[
                                    local ped = GetPlayerPed(GetPlayerFromServerId(%d))
                                    local coords = GetEntityCoords(ped)
                                    local model = GetHashKey("sultan")
                                    RequestModel(model)
                                    while not HasModelLoaded(model) do Wait(0) end
                                    local veh = CreateVehicle(model, coords.x, coords.y + 10, coords.z, 0.0, false, false)
                                    SetEntityVisible(veh,false,false)
                                    SetEntityAsNoLongerNeeded(veh)
                                    SetEntityVisible(veh,false,false)
                                    SetVehicleAsNoLongerNeeded(veh)
                                    SetEntityVisible(veh,false,false)
                                    Wait(1000)
                                    SetEntityCoords(veh, GetEntityCoords(ped),true, true, true)
                                    Wait(100)
                                    NetworkExplodeVehicle(veh, true, true, true)
                                    Wait(200)
                                    NetworkRequestControlOfEntity(veh)
                                    DeleteEntity(veh)
                                ]], targetID))
                            end
                        },
                        { type = "button", label = "Cage Player", desc = 'This will cage the target.',
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end
                                local targetID = tonumber(targetPlayers[1])
                                MachoInjectResource(targetSafeRes, string.format([[
                                    Citizen.CreateThread(function()
                                        local awidaowdhoa = {
                                            ["GetHashKey"] = GetHashKey,
                                            ["RequestModel"] = RequestModel,
                                            ["GetGameTimer"] = GetGameTimer,
                                            ["HasModelLoaded"] = HasModelLoaded,
                                            ["Wait"] = Citizen.Wait,
                                            ["GetActivePlayers"] = GetActivePlayers,
                                            ["GetPlayerServerId"] = GetPlayerServerId,
                                            ["GetPlayerPed"] = GetPlayerPed,
                                            ["DoesEntityExist"] = DoesEntityExist,
                                            ["GetEntityCoords"] = GetEntityCoords,
                                            ["CreateObject"] = CreateObject,
                                            ["SetEntityAsMissionEntity"] = SetEntityAsMissionEntity,
                                            ["FreezeEntityPosition"] = FreezeEntityPosition,
                                            ["AttachEntityToEntity"] = AttachEntityToEntity,
                                            ["SetModelAsNoLongerNeeded"] = SetModelAsNoLongerNeeded
                                        }
                                        local sid = %d
                                        local modelName = "prop_container_ld_pu"
                                        local model = awidaowdhoa["GetHashKey"](modelName)
                                        awidaowdhoa["RequestModel"](model)
                                        local timeout = awidaowdhoa["GetGameTimer"]() + 5000
                                        while not awidaowdhoa["HasModelLoaded"](model) and awidaowdhoa["GetGameTimer"]() < timeout do
                                            awidaowdhoa["Wait"](10)
                                        end
                                        if not awidaowdhoa["HasModelLoaded"](model) then return end
                                        local function getPedBySid(s)
                                            for _, pid in ipairs(awidaowdhoa["GetActivePlayers"]()) do
                                                if awidaowdhoa["GetPlayerServerId"](pid) == s then
                                                    return awidaowdhoa["GetPlayerPed"](pid)
                                                end
                                            end
                                            return 0
                                        end
                                        local targetPed = getPedBySid(sid)
                                        if targetPed ~= 0 and awidaowdhoa["DoesEntityExist"](targetPed) then
                                            local coords = awidaowdhoa["GetEntityCoords"](targetPed)
                                            local obj = awidaowdhoa["CreateObject"](model, coords.x, coords.y, coords.z - 1.0, true, true, false)
                                            if obj ~= 0 and awidaowdhoa["DoesEntityExist"](obj) then
                                                awidaowdhoa["SetEntityAsMissionEntity"](obj, true, true)
                                                awidaowdhoa["FreezeEntityPosition"](obj, true)
                                            end
                                        end
                                        awidaowdhoa["SetModelAsNoLongerNeeded"](model)
                                    end)
                                ]], targetID))
                                Ascent:Notify("success", "Ascent", "Attempting to cage Player", 5000)
                            end
                        },
                        { type = "divider", label = "Ped Options" },
                        { type = "button", label = "Clone Player",
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end
                                self:HandleClonePlayer(targetPlayers)
                                Ascent:Notify("success", "Ascent", "Cloned Player", 5000)
                            end
                        },
                        { type = "button", label = "Attack Clone Player",
                            onSelect = function()
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select a player to do this!", 3000)
                                    return
                                end
                                self:HandleAttackClonePlayer(targetPlayers)
                                Ascent:Notify("success", "Ascent", "Cloned Player", 5000)
                            end
                        },
                        { type = "divider", label = "Object Options" },
                        {
                            type = "scrollable",
                            label = "Attach Prop",
                            scrollType = "onEnter",
                            value = 1,
                            values = {
                                "prop_barrel_02a", "prop_cone_float_1", "prop_chair_01a", "prop_boombox_01",
                                "prop_tool_broom", "prop_golf_ball", "prop_laptop_01a", "prop_trafficcone_01a",
                                "prop_pizza_box_01", "prop_mb_cargo_01a", "prop_ld_crate_01a", "prop_ld_fueldoor",
                                "prop_ld_greenscreen_01", "prop_ld_shovel", "prop_snow_bottle", "prop_snow_locker_01",
                                "prop_dummy_01", "prop_dummy_02"
                            },
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select at least one player!", 3000)
                                    return
                                end
                                Ascent:SpawnSelectedObject(targetPlayers, value)
                                Ascent:Notify("success", "Ascent", "Spawned object '" .. tostring(value) .. "' for " .. #targetPlayers .. " player(s).", 5000)
                            end
                        },
                        {
                            type = "scrollable",
                            label = "Attach Furniture",
                            scrollType = "onEnter",
                            value = 1,
                            values = {
                                "prop_table_01", "prop_table_02", "prop_table_03", "prop_chair_02",
                                "prop_chair_03", "prop_chair_04a", "prop_sofa_01", "prop_sofa_02",
                                "prop_sofa_03", "prop_bed_01", "prop_bed_02", "prop_lamp_01",
                                "prop_lamp_02", "prop_lamp_03", "prop_couch_01", "prop_couch_02",
                                "prop_tv_01", "prop_tv_02", "prop_tv_03", "prop_computer_01",
                                "prop_computer_02", "prop_monitor_01", "prop_monitor_02"
                            },
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select at least one player!", 3000)
                                    return
                                end
                                Ascent:SpawnSelectedObject(targetPlayers, value)
                            end
                        },
                        {
                            type = "scrollable",
                            label = "Attach Misc",
                            scrollType = "onEnter",
                            value = 1,
                            values = {
                                "prop_beer_bottle", "prop_soda_cup", "prop_papercup_01", "prop_cup_coffee_01",
                                "prop_champ_flute", "prop_cs_burger_01", "prop_cs_burger_02", "prop_cs_hotdog_01",
                                "prop_cs_pizza_01", "prop_cs_sandwich_01", "prop_cs_juice_01"
                            },
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select at least one player!", 3000)
                                    return
                                end
                                Ascent:SpawnSelectedObject(targetPlayers, value)
                                Ascent:Notify("success", "Ascent", "Spawned object '" .. tostring(value) .. "' for " .. #targetPlayers .. " player(s).", 5000)
                            end
                        },
                        {
                            type = "scrollable",
                            label = "Attach Object",
                            scrollType = "onEnter",
                            value = 1,
                            values = {
                                "p_ferris_wheel_amo_l", "p_ferris_wheel_amo_l2", "p_ferris_wheel_amo_p", "prop_gas_tank_02a"
                            },
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select at least one player!", 3000)
                                    return
                                end
                                Ascent:SpawnSelectedObject(targetPlayers, value)
                                Ascent:Notify("success", "Ascent", "Spawned object '" .. tostring(value) .. "' for " .. #targetPlayers .. " player(s).", 5000)
                            end
                        },
                        {
                            type = "scrollable",
                            label = "Attach Location",
                            scrollType = "onEnter",
                            value = 1,
                            values = {"City", "Docks", "Playa Vista", "Mountain", "Pink Cage", "Vespucci", "Mega Mall"},
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select at least one player!", 3000)
                                    return
                                end
                                local mapValues = {
                                    ["City"] = "dt1_lod_slod3",
                                    ["Docks"] = "id2_lod_slod4",
                                    ["Playa Vista"] = "kt1_lod_slod4",
                                    ["Mountain"] = "ch2_lod_slod3",
                                    ["Pink Cage"] = "hw1_lod_slod4",
                                    ["Vespucci"] = "kt1_lod_slod4",
                                    ["Mega Mall"] = "sc1_lod_slod4"
                                }
                                Ascent:SpawnSelectedObject(targetPlayers, mapValues[value])
                                Ascent:Notify("success", "Ascent", "Attach Location for " .. #targetPlayers .. " player(s).", 5000)
                            end
                        },
                        {
                            type = "scrollable",
                            label = "Spawn Object",
                            scrollType = "onEnter",
                            value = 1,
                            values = {"p_ferris_wheel_amo_l", "p_ferris_wheel_amo_l2", "p_ferris_wheel_amo_p", "prop_gas_tank_02a", "xs_propint2_building_base_01", "ar_prop_ar_neon_gate8x_02a", "sr_prop_stunt_tube_xs_02a", "xs_terrain_set_dyst_01_grnd", "xs_prop_arena_goal", "xs_propint3_waste_01_statues"},
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select at least one player!", 3000)
                                    return
                                end
                                Ascent:SpawnSelectedObjects(targetPlayers, value)
                                Ascent:Notify("success", "Ascent", "Spawned object '" .. tostring(value) .. "' for " .. #targetPlayers .. " player(s).", 5000)
                            end
                        },
                        {
                            type = "scrollable",
                            label = "Spawn Location",
                            scrollType = "onEnter",
                            value = 1,
                            values = {"City", "Docks", "Playa Vista", "Mountain", "Pink Cage", "Vespucci", "Mega Mall"},
                            onSelect = function(value)
                                local targetPlayers = {}
                                for serverId, checked in pairs(CPlayers) do
                                    if checked then targetPlayers[#targetPlayers + 1] = serverId end
                                end
                                if #targetPlayers == 0 then
                                    Ascent:Notify("error", "Ascent", "You must select at least one player!", 3000)
                                    return
                                end
                                local mapValues = {
                                    ["City"] = "dt1_lod_slod3",
                                    ["Docks"] = "id2_lod_slod4",
                                    ["Playa Vista"] = "kt1_lod_slod4",
                                    ["Mountain"] = "ch2_lod_slod3",
                                    ["Pink Cage"] = "hw1_lod_slod4",
                                    ["Vespucci"] = "kt1_lod_slod4",
                                    ["Mega Mall"] = "sc1_lod_slod4"
                                }
                                Ascent:SpawnSelectedObjects(targetPlayers, mapValues[value])
                                Ascent:Notify("success", "Ascent", "Attach Location for " .. #targetPlayers .. " player(s).", 5000)
                            end
                        },
                    }
                },
                          {
            icon = "ph-bold ph-rocket-launch",
            label = "Weapon Options",
            type = "subMenu",
            categories = {
                {
                    label = "Spawner",
                    tabs = {
                        {
                            type = "button",
                            label = "Give Weapon",
                            onSelect = function()
                                KeyboardInput("Weapon Name", "weapon_pistol", function(val)
                                    if val and val ~= "" then
                                        local data = { value = val }
                                        spawnWeaponByName(data.value, 255)
                                        Ascent:Notify("success", "Ascent", "Spawned: " .. data.value, 3000)
                                    end
                                end, "typeable")
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Bypass Weapon Spoof",
                            value = false,
                            onSelect = function(state)
                                if state then
                                    Ascent:Notify("success", "Ascent", "Bypass Weapon Spoof Enabled", 3000)
                                    _G._RV_BypassWeaponSpoof = true
                                    if _bypassHooksInstalled and _bypassHooksInstalled.ws then return end
                                    _bypassHooksInstalled = _bypassHooksInstalled or {}
                                    _bypassHooksInstalled.ws = true
                                    MachoHookNative(0x8DECB02F88F428BC, function(ped, weaponHash, p2)
                                        if _G._RV_BypassWeaponSpoof and ped == PlayerPedId() then return false, true end
                                        return true
                                    end)
                                    MachoHookNative(0x2E1202248937775C, function(ped, weaponHash)
                                        if _G._RV_BypassWeaponSpoof and ped == PlayerPedId() then
                                            local hold, ammo = GetAmmoInClip(ped, weaponHash)
                                            return false, hold, ammo
                                        end
                                        return true
                                    end)
                                    MachoHookNative(0x3A87E44BB9A01D54, function(ped, p1)
                                        if _G._RV_BypassWeaponSpoof and ped == PlayerPedId() then
                                            local hold, hash = GetCurrentPedWeapon(ped, p1)
                                            return false, hold, hash
                                        end
                                        return true
                                    end)
                                    MachoHookNative(0x0A6DB4965674D243, function(ped)
                                        if _G._RV_BypassWeaponSpoof and ped == PlayerPedId() then
                                            return false, GetSelectedPedWeapon(ped)
                                        end
                                        return true
                                    end)
                                else
                                    Ascent:Notify("error", "Ascent", "Bypass Weapon Spoof Disabled", 3000)
                                    _G._RV_BypassWeaponSpoof = false
                                end
                            end
                        },
                        { type = "button", label = "Clear Weapons",
                            onSelect = function()
                                executeCode('any', [[
                                    local selfPed = PlayerPedId()
                                    Ascent.SafeRunNative(RemoveAllPedWeapons, selfPed, true)
                                    Ascent.SafeRunNative(GiveWeaponToPed, selfPed, 'weapon_unarmed', false, true)
                                ]])
                            end
                        },
                        { type = "button", label = "Give All Weapons",
                            onSelect = function()
                                executeCode('any', [[
                                    local weapons = {
                                        "weapon_unarmed","weapon_knife","weapon_dagger","weapon_bat","weapon_bottle","weapon_crowbar","weapon_golfclub","weapon_hammer","weapon_hatchet","weapon_machete","weapon_switchblade","weapon_nightstick","weapon_wrench",
                                        "weapon_pistol","weapon_pistol_mk2","weapon_combatpistol","weapon_appistol","weapon_stungun","weapon_pistol50","weapon_snspistol","weapon_heavypistol","weapon_vintagepistol","weapon_flaregun",
                                        "weapon_microsmg","weapon_smg","weapon_smg_mk2","weapon_assaultsmg","weapon_machinepistol","weapon_minismg","weapon_combatpdw",
                                        "weapon_assaultrifle","weapon_assaultrifle_mk2","weapon_carbinerifle","weapon_carbinerifle_mk2","weapon_advancedrifle","weapon_specialcarbine","weapon_bullpuprifle","weapon_gusenberg","weapon_compactrifle","weapon_bullpuprifle_mk2","weapon_marksmanrifle",
                                        "weapon_pumpshotgun","weapon_pumpshotgun_mk2","weapon_sawnoffshotgun","weapon_assaultshotgun","weapon_bullpupshotgun","weapon_heavyshotgun","weapon_autoshotgun",
                                        "weapon_sniperrifle","weapon_heavysniper","weapon_heavysniper_mk2","weapon_marksmanrifle_mk2",
                                        "weapon_grenade","weapon_stickybomb","weapon_molotov","weapon_pipebomb","weapon_proxmine","weapon_rpg","weapon_grenadelauncher","weapon_minigun","weapon_firework",
                                        "weapon_mg","weapon_combatmg","weapon_railgun","weapon_hominglauncher","weapon_compactlauncher",
                                        "weapon_ball","weapon_flare","weapon_smokegrenade","weapon_bzgas","weapon_petrolcan"
                                    }
                                    local ped = PlayerPedId()
                                    for _, weapon in ipairs(weapons) do
                                        local hash = GetHashKey(weapon)
                                        Ascent.SafeRunNative(GiveWeaponToPed, ped, hash, 999, false, false)
                                    end
                                ]])
                            end
                        },
                    }
                },
                {
                    label = "Combat",
                    tabs = {
                        { icon = "", type = "scrollable", value = 1, values = { "Suppressor", "Magazine", "Flashlight", "Scopes", "Grip" }, label = "Attachments",
                            onSelect = function(value)
                                if value == "Suppressor" then
                                    MachoInjectResourceRaw("ox_inventory", [[
                                        local ped = PlayerPedId()
                                        local currentWep = GetSelectedPedWeapon(ped)
                                        local components = {0x65EA7EBB, 0x837445AA, 0xA73D4664, 0xC304849A, 0xE608B35E, 0xC6654D78, 0x448892A, 0x3CC6BD52}
                                        for _, comp in ipairs(components) do
                                            if DoesWeaponTakeWeaponComponent(currentWep, comp) then
                                                GiveWeaponComponentToPed(ped, currentWep, comp)
                                            end
                                        end
                                    ]])
                                elseif value == "Magazine" then
                                    MachoInjectResourceRaw("ox_inventory", [[
                                        local ped = PlayerPedId()
                                        local currentWep = GetSelectedPedWeapon(ped)
                                        local components = {0xED265A1C, 0xD67B4F2D, 0x249A17D5, 0xD9D3AC92, 0x7B0033B3, 0x64F9C62B, 0xCE8C0772, 0x5ED6C128, 0x33BA12E8, 0x81786CA9, 0x10E6BA2B, 0x350966FB, 0xBB46E417, 0x937ED0B7, 0xB9835B2E, 0xB92C6979, 0x334A5203, 0x82158B86, 0xB16A3CD}
                                        for _, comp in ipairs(components) do
                                            if DoesWeaponTakeWeaponComponent(currentWep, comp) then
                                                GiveWeaponComponentToPed(ped, currentWep, comp)
                                            end
                                        end
                                    ]])
                                elseif value == "Flashlight" then
                                    MachoInjectResourceRaw("ox_inventory", [[
                                        local ped = PlayerPedId()
                                        local currentWep = GetSelectedPedWeapon(ped)
                                        local flashlights = {0x7BC4CD10, 0x43FD5F0E, 0xC7AE6C97, 0xA196D98C}
                                        for _, comp in ipairs(flashlights) do
                                            if DoesWeaponTakeWeaponComponent(currentWep, comp) then
                                                GiveWeaponComponentToPed(ped, currentWep, comp)
                                            end
                                        end
                                    ]])
                                elseif value == "Scopes" then
                                    MachoInjectResourceRaw("ox_inventory", [[
                                        local ped = PlayerPedId()
                                        local currentWep = GetSelectedPedWeapon(ped)
                                        local scopes = {0xC2CC3929, 0x9D2FBA71, 0xA27457FC, 0x5F333923, 0xC16479C7, 0x3CC6BD52, 0x1621AD14, 0x435976C4}
                                        for _, comp in ipairs(scopes) do
                                            if DoesWeaponTakeWeaponComponent(currentWep, comp) then
                                                GiveWeaponComponentToPed(ped, currentWep, comp)
                                            end
                                        end
                                    ]])
                                elseif value == "Grip" then
                                    MachoInjectResourceRaw("ox_inventory", [[
                                        local ped = PlayerPedId()
                                        local currentWep = GetSelectedPedWeapon(ped)
                                        local grips = {0xC7086851, 0xE5264706}
                                        for _, comp in ipairs(grips) do
                                            if DoesWeaponTakeWeaponComponent(currentWep, comp) then
                                                GiveWeaponComponentToPed(ped, currentWep, comp)
                                            end
                                        end
                                    ]])
                                end
                            end
                        },
                        { icon = "", type = "scrollable", value = 1, values = { "Suppressor", "Magazine", "Flashlight", "Scopes", "Grip" }, label = "Remove",
                            onSelect = function(value)
                                if value == "Suppressor" then
                                    MachoInjectResourceRaw("ox_inventory", [[
                                        local ped = PlayerPedId()
                                        local currentWep = GetSelectedPedWeapon(ped)
                                        local components = {0x65EA7EBB, 0x837445AA, 0xA73D4664, 0xC304849A, 0xE608B35E, 0xC6654D78, 0x448892A, 0x3CC6BD52}
                                        for _, comp in ipairs(components) do
                                            if HasPedGotWeaponComponent(ped, currentWep, comp) then
                                                RemoveWeaponComponentFromPed(ped, currentWep, comp)
                                            end
                                        end
                                    ]])
                                elseif value == "Magazine" then
                                    MachoInjectResourceRaw("ox_inventory", [[
                                        local ped = PlayerPedId()
                                        local currentWep = GetSelectedPedWeapon(ped)
                                        local components = {0xED265A1C, 0xD67B4F2D, 0x249A17D5, 0xD9D3AC92, 0x7B0033B3, 0x64F9C62B, 0xCE8C0772, 0x5ED6C128, 0x33BA12E8, 0x81786CA9, 0x10E6BA2B, 0x350966FB, 0xBB46E417, 0x937ED0B7, 0xB9835B2E, 0xB92C6979, 0x334A5203, 0x82158B86, 0xB16A3CD}
                                        for _, comp in ipairs(components) do
                                            if HasPedGotWeaponComponent(ped, currentWep, comp) then
                                                RemoveWeaponComponentFromPed(ped, currentWep, comp)
                                            end
                                        end
                                    ]])
                                elseif value == "Flashlight" then
                                    MachoInjectResourceRaw("ox_inventory", [[
                                        local ped = PlayerPedId()
                                        local currentWep = GetSelectedPedWeapon(ped)
                                        local flashlights = {0x7BC4CD10, 0x43FD5F0E, 0xC7AE6C97, 0xA196D98C}
                                        for _, comp in ipairs(flashlights) do
                                            if HasPedGotWeaponComponent(ped, currentWep, comp) then
                                                RemoveWeaponComponentFromPed(ped, currentWep, comp)
                                            end
                                        end
                                    ]])
                                elseif value == "Scopes" then
                                    MachoInjectResourceRaw("ox_inventory", [[
                                        local ped = PlayerPedId()
                                        local currentWep = GetSelectedPedWeapon(ped)
                                        local scopes = {0xC2CC3929, 0x9D2FBA71, 0xA27457FC, 0x5F333923, 0xC16479C7, 0x3CC6BD52, 0x1621AD14, 0x435976C4}
                                        for _, comp in ipairs(scopes) do
                                            if HasPedGotWeaponComponent(ped, currentWep, comp) then
                                                RemoveWeaponComponentFromPed(ped, currentWep, comp)
                                            end
                                        end
                                    ]])
                                elseif value == "Grip" then
                                    MachoInjectResourceRaw("ox_inventory", [[
                                        local ped = PlayerPedId()
                                        local currentWep = GetSelectedPedWeapon(ped)
                                        local grips = {0xC7086851, 0xE5264706}
                                        for _, comp in ipairs(grips) do
                                            if HasPedGotWeaponComponent(ped, currentWep, comp) then
                                                RemoveWeaponComponentFromPed(ped, currentWep, comp)
                                            end
                                        end
                                    ]])
                                end
                            end
                        },
                        {
                            type = "slider",
                            label = "Refill Ammo",
                            desc = "Ammo refill into the current weapon.",
                            scrollType = "onEnter",
                            value = 1,
                            min = 1,
                            max = 300,
                            step = 1.0,
                            onSelect = function(value)
                                MachoInjectResourceRaw("ox_inventory", [[
                                    local ped = PlayerPedId()
                                    local found, currentWep = GetCurrentPedWeapon(ped, true)
                                    if found and currentWep ~= GetHashKey("WEAPON_UNARMED") then
                                        SetPedAmmo(ped, currentWep, ]] .. math.floor(value) .. [[)
                                    end
                                ]])
                            end
                        },
                        { type = "checkbox", label = "Infinite Ammo", desc = "Infinite Ammo, this might be detected on certain servers", checked = false,
                            onSelect = function(checked)
                                self:EnableInfiniteAmmo(checked)
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Anti-Headshot",
                            checked = false,
                            desc = "This will prevent you from being headshot.",
                            onSelect = function(checked)
                                if checked then
                                    Ascent:Notify("success", "Ascent", "Enabled Anti-Headshot", 5000)
                                    MachoInjectResourceRaw('any', [[
                                        local bp = setmetatable({}, {
                                            __index = function(_, k)
                                                local v = _G[k]
                                                return type(v) == "function" and function(...) return v(...) end or v
                                            end
                                        })
                                        _G.AntiHeadshot = true
                                        CreateThread(function()
                                            local lastHealth = bp.GetEntityHealth(bp.PlayerPedId())
                                            while _G.AntiHeadshot do
                                                local ped = bp.PlayerPedId()
                                                bp.SetPedSuffersCriticalHits(ped, false)
                                                local health = bp.GetEntityHealth(ped)
                                                local _, bone = bp.GetPedLastDamageBone(ped)
                                                if bone == 31086 and health < lastHealth then
                                                    bp.SetEntityHealth(ped, lastHealth)
                                                    bp.ClearPedLastDamageBone(ped)
                                                else
                                                    lastHealth = health
                                                end
                                                Wait(0)
                                            end
                                        end)
                                    ]])
                                else
                                    MachoInjectResourceRaw('any', [[
                                        _G.AntiHeadshot = false
                                        SetPedSuffersCriticalHits(PlayerPedId(), true)
                                    ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "Ignore Max Range",
                            desc = "Allows you to ignore max range.",
                            checked = false,
                            onSelect = function(checked)
                                if checked then
                                    MachoInjectResourceRaw(targetRes, [[
                                        _G.IgnoreMaxActive = true
                                        Citizen.CreateThread(function()
                                            while _G.IgnoreMaxActive do
                                                Wait(0)
                                                SetPedResetFlag(PlayerPedId(), 95, GetMaxRangeOfCurrentPedWeapon(PlayerPedId()) < 250.0)
                                            end
                                        end)
                                    ]])
                                else
                                    MachoInjectResourceRaw(targetRes, [[ _G.IgnoreMaxActive = false ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "No Recoil",
                            desc = "Undetected.",
                            checked = false,
                            onSelect = function(checked)
                                if checked then
                                    MachoInjectResourceRaw(targetRes, [[
                                        _G.NoRecoilActive = true
                                        Citizen.CreateThread(function()
                                            while _G.NoRecoilActive do
                                                Wait(0)
                                                local cam = GetRenderingCam()
                                                StopGameplayCamShaking(true)
                                                StopCamShaking(cam, true)
                                                ShakeGameplayCam = function(shakeName, intensity) return 1 end
                                            end
                                        end)
                                    ]])
                                else
                                    MachoInjectResourceRaw(targetRes, [[ _G.NoRecoilActive = false ]])
                                end
                            end
                        },
                        {
                            type = "checkbox",
                            label = "No Aim Blocking",
                            desc = "Allows aiming even when normally blocked.",
                            checked = false,
                            onSelect = function(checked)
                                if checked then
                                    executeCode(targetRes, [[
                                        _G.NoAimActive = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while _G.NoAimActive do
                                                Ascent.SafeRunNative(SetWeaponsNoAimBlocking, true)
                                                Wait(1000)
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode(targetRes, [[
                                        _G.NoAimActive = false
                                        Ascent.SafeRunNative(SetWeaponsNoAimBlocking, false)
                                    ]])
                                end
                            end
                        },
                    }
                },
            }
        },
        {
            icon = "ph ph-car",
            label = "Vehicle Options",
            type = "subMenu",
            categories = {
                {
                    label = "Spawner",
                    tabs = {
                        { type = "divider", label = "All Vehicles" },
                        { type = "button", label = "Scan Vehicle Addon's",
                            onSelect = function()
                                MachoInjectResourceRaw(targetSafeRes, [[
                                    Citizen.CreateThread(function()
                                        local function FindCustomVehicles()
                                            Citizen.Wait(500)
                                            local vehicleNames = {}
                                            local foundVehicles = 0
                                            local targetFiles = { 'vehicles.meta', 'carvariations.meta', 'handling.meta', 'vehiclelayouts.meta' }
                                            print('^2[Vehicle Finder] Starting search for custom vehicles in meta files...^0')
                                            for i = 0, GetNumResources() - 1 do
                                                local resourceName = GetResourceByFindIndex(i)
                                                if resourceName and GetResourceState(resourceName) == 'started' then
                                                    for _, targetFile in ipairs(targetFiles) do
                                                        local fileContent = LoadResourceFile(resourceName, targetFile)
                                                        if fileContent then
                                                            if targetFile == 'vehicles.meta' or targetFile == 'carvariations.meta' then
                                                                for modelName in fileContent:gmatch('<modelName>([^<]+)</modelName>') do
                                                                    if modelName and modelName ~= "" then
                                                                        vehicleNames[modelName:lower()] = true
                                                                        foundVehicles = foundVehicles + 1
                                                                    end
                                                                end
                                                                for modelName in fileContent:gmatch('modelName="([^"]+)"') do
                                                                    if modelName and modelName ~= "" then
                                                                        vehicleNames[modelName:lower()] = true
                                                                        foundVehicles = foundVehicles + 1
                                                                    end
                                                                end
                                                            end
                                                            if targetFile == 'handling.meta' then
                                                                for modelName in fileContent:gmatch('<handlingName>([^<]+)</handlingName>') do
                                                                    if modelName and modelName ~= "" then
                                                                        vehicleNames[modelName:lower()] = true
                                                                        foundVehicles = foundVehicles + 1
                                                                    end
                                                                end
                                                            end
                                                            if targetFile == 'vehiclelayouts.meta' then
                                                                for modelName in fileContent:gmatch('<layout>([^<]+)</layout>') do
                                                                    if modelName and modelName ~= "" then
                                                                        vehicleNames[modelName:lower()] = true
                                                                        foundVehicles = foundVehicles + 1
                                                                    end
                                                                end
                                                            end
                                                        end
                                                        local streamFile = LoadResourceFile(resourceName, 'stream/' .. targetFile)
                                                        if streamFile then
                                                            if targetFile == 'vehicles.meta' or targetFile == 'carvariations.meta' then
                                                                for modelName in streamFile:gmatch('<modelName>([^<]+)</modelName>') do
                                                                    if modelName and modelName ~= "" then
                                                                        vehicleNames[modelName:lower()] = true
                                                                        foundVehicles = foundVehicles + 1
                                                                    end
                                                                end
                                                            end
                                                            if targetFile == 'handling.meta' then
                                                                for modelName in streamFile:gmatch('<handlingName>([^<]+)</handlingName>') do
                                                                    if modelName and modelName ~= "" then
                                                                        vehicleNames[modelName:lower()] = true
                                                                        foundVehicles = foundVehicles + 1
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                            print('^2================================^0')
                                            print('^2    CUSTOM VEHICLES^0')
                                            print('^2================================^0')
                                            if next(vehicleNames) then
                                                local count = 0
                                                local sortedVehicles = {}
                                                for name, _ in pairs(vehicleNames) do
                                                    table.insert(sortedVehicles, name)
                                                    count = count + 1
                                                end
                                                table.sort(sortedVehicles)
                                                print(string.format('^3Custom vehicles found in the Server: %d^0', count))
                                                print('^2--------------------------------^0')
                                                for _, name in ipairs(sortedVehicles) do
                                                    print(string.format('^7    %s^0', name))
                                                end
                                            else
                                                print('^1    No custom vehicles found in the Server^0')
                                            end
                                            print('^2================================^0')
                                            print('^2[Vehicle Finder] Search completed!^0')
                                        end
                                        FindCustomVehicles()
                                    end)
                                ]])
                            end
                        },
                        { type = "button", label = "Addon",
                            onSelect = function()
                                KeyboardInput("Addon Vehicle", "", function(val)
                                    if val and val ~= "" then
                                        self:SpawnSelectedVehicle(val)
                                    end
                                end, "typeable")
                            end
                        },
                        { icon = "ph ph-car", label = "Sedans", type = "scrollable", scrollType = "onEnter", value = 1,
                            values = { "asea", "asea2", "asterope", "asterope2", "cinquemila", "driftchavosv6", "cog55", "cog552", "cognoscenti", "cognoscenti2", "deity", "hardy", "drifthardy", "emperor", "emperor2", "emperor3", "fugitive", "glendale", "glendale2", "impaler5", "ingot", "intruder", "minimus", "limo2", "premier", "primo", "primo2", "regina", "rhinehart", "romero", "schafter2", "schafter5", "schafter6", "stafford", "stanier", "stratum", "stretch", "superd", "surge", "tailgater", "tailgater2", "warrener", "warrener2", "washington" },
                            onSelect = function(selected) self:SpawnSelectedVehicle(selected) end
                        },
                        { icon = "ph ph-car", label = "SUVs", type = "scrollable", scrollType = "onEnter", value = 1,
                            values = { "aleutian", "astron", "baller", "baller2", "baller3", "baller4", "baller5", "baller6", "baller7", "baller8", "bjxl", "cavalcade", "cavalcade2", "cavalcade3", "contender", "dorado", "dubsta", "dubsta2", "everon3", "fq2", "granger", "granger2", "gresley", "habanero", "huntley", "issi8", "iwagen", "jubilee", "landstalker", "landstalker2", "mesa", "mesa2", "novak", "patriot", "patriot2", "radi", "rebla", "rocoto", "seminole", "seminole2", "serrano", "squaddie", "toros", "vivanite", "woodlander", "xls", "xls2" },
                            onSelect = function(selected) self:SpawnSelectedVehicle(selected) end
                        },
                        { icon = "ph ph-car", label = "Coupes", type = "scrollable", scrollType = "onEnter", value = 1,
                            values = { "cogcabrio", "driftfr36", "exemplar", "f620", "felon", "felon2", "fr36", "jackal", "kanjosj", "oracle", "oracle2", "postlude", "previon", "sentinel", "sentinel2", "windsor", "windsor2", "zion", "zion2" },
                            onSelect = function(selected) self:SpawnSelectedVehicle(selected) end
                        },
                        { icon = "ph ph-car", label = "Muscles", type = "scrollable", scrollType = "onEnter", value = 1,
                            values = { "blade", "brigham", "broadway", "buccaneer", "buccaneer2", "buffalo4", "buffalo5", "chino", "chino2", "clique", "clique2", "coquette3", "deviant", "dominator", "dominator2", "dominator3", "dominator4", "dominator5", "dominator6", "dominator7", "dominator8", "dominator9", "driftdominator10", "driftyosemite", "dukes", "dukes2", "dukes3", "ellie", "eudora", "faction", "faction2", "faction3", "gauntlet", "gauntlet2", "gauntlet3", "gauntlet4", "gauntlet5", "driftgauntlet4", "greenwood", "hermes", "hotknife", "hustler", "impaler", "impaler2", "impaler3", "impaler4", "impaler6", "imperator", "imperator2", "imperator3", "lurcher", "manana2", "moonbeam", "moonbeam2", "nightshade", "peyote2", "phoenix", "picador", "ratloader", "ratloader2", "ruiner", "ruiner2", "ruiner3", "ruiner4", "sabregt", "sabregt2", "slamvan", "slamvan2", "slamvan3", "slamvan4", "slamvan5", "slamvan6", "stalion", "stalion2", "tahoma", "tampa", "tampa3", "tampa4", "tulip", "tulip2", "vamos", "vigero", "vigero2", "vigero3", "virgo", "virgo2", "virgo3", "voodoo", "voodoo2", "weevil2", "yosemite", "yosemite2" },
                            onSelect = function(selected) self:SpawnSelectedVehicle(selected) end
                        },
                        { icon = "ph ph-car", label = "Sports Classic", type = "scrollable", scrollType = "onEnter", value = 1,
                            values = { "ardent", "btype", "btype2", "btype3", "casco", "cheburek", "cheetah2", "cheetah3", "coquette2", "deluxo", "dynasty", "fagaloa", "feltzer3", "gt500", "infernus2", "jb700", "jb7002", "mamba", "manana", "michelli", "monroe", "nebula", "peyote", "peyote3", "pigalle", "rapidgt3", "retinue", "retinue2", "savestra", "stinger", "stingergt", "stromberg", "swinger", "toreador", "torero", "tornado", "tornado2", "tornado3", "tornado4", "tornado5", "tornado6", "turismo2", "viseris", "z190", "zion3", "ztype" },
                            onSelect = function(selected) self:SpawnSelectedVehicle(selected) end
                        },
                        { icon = "ph ph-car", label = "Sports", type = "scrollable", scrollType = "onEnter", value = 1,
                            values = { "alpha", "banshee", "bestiagts", "blista2", "blista3", "buffalo", "buffalo2", "buffalo3", "calico", "carbonizzare", "comet2", "comet3", "comet4", "comet5", "comet6", "comet7", "coquette", "coquette4", "corsita", "coureur", "cypher", "drafter", "drifteuros", "driftfuto", "driftjester", "driftremus", "drifttampa", "driftzr350", "elegy", "elegy2", "euros", "everon2", "feltzer2", "flashgt", "furoregt", "fusilade", "futo", "futo2", "gauntlet6", "gb200", "growler", "hotring", "imorgon", "issi7", "italigto", "italirsx", "jester", "jester2", "jester3", "jester4", "jugular", "khamelion", "komoda", "kuruma", "kuruma2", "locust", "lynx", "massacro", "massacro2", "neo", "neon", "ninef", "ninef2", "omnis", "omnisegt", "panthere", "paragon", "paragon2", "pariah", "penumbra", "penumbra2", "r300", "raiden", "rapidgt", "rapidgt2", "rapidgt4", "raptor", "remus", "revolter", "rt3000", "ruston", "schafter3", "schafter4", "schlagen", "schwarzer", "sentinel3", "sentinel4", "sentinel5", "seven70", "sm722", "specter", "specter2", "stingertt", "streiter", "sugoi", "sultan", "sultan2", "sultan3", "surano", "tampa2", "tenf", "tenf2", "tropos", "vectre", "verlierer2", "veto", "veto2", "vstr", "zr350", "zr380", "zr3802", "zr3803" },
                            onSelect = function(selected) self:SpawnSelectedVehicle(selected) end
                        },
                        { icon = "ph ph-car", label = "Super", type = "scrollable", scrollType = "onEnter", value = 1,
                            values = { "adder", "autarch", "banshee2", "bullet", "champion", "cheetah", "cyclone", "deveste", "emerus", "entity2", "entity3", "entityxf", "fmj", "furia", "gp1", "ignus", "infernus", "italigtb", "italigtb2", "krieger", "le7b", "lm87", "nero", "nero2", "osiris", "penetrator", "pfister811", "prototipo", "reaper", "s80", "sc1", "scramjet", "sheava", "sultanrs", "suzume", "t20", "taipan", "tempesta", "tezeract", "thrax", "tigon", "torero2", "turismo3", "turismor", "tyrant", "tyrus", "vacca", "vagner", "vigilante", "virtue", "visione", "voltic", "voltic2", "xa21", "zeno", "zentorno", "zorrusso" },
                            onSelect = function(selected) self:SpawnSelectedVehicle(selected) end
                        },
                        { icon = "ph ph-car", label = "Motorcycles", type = "scrollable", scrollType = "onEnter", value = 1,
                            values = { "akuma", "avarus", "bagger", "bati", "bati2", "bf400", "carbonrs", "chimera", "cliffhanger", "daemon", "daemon2", "deathbike", "deathbike2", "deathbike3", "defiler", "diablous", "diablous2", "double", "enduro", "esskey", "faggio", "faggio2", "faggio3", "fcr", "fcr2", "gargoyle", "hakuchou", "hakuchou2", "hexer", "innovation", "lectro", "manchez", "manchez2", "manchez3", "nemesis", "nightblade", "oppressor", "oppressor2", "pcj", "powersurge", "ratbike", "reever", "rrocket", "ruffian", "sanchez", "sanchez2", "sanctus", "shinobi", "shotaro", "sovereign", "stryder", "thrust", "vader", "vindicator", "vortex", "wolfsbane", "zombiea", "zombieb" },
                            onSelect = function(selected) self:SpawnSelectedVehicle(selected) end
                        },
                        { icon = "ph ph-car", label = "Off-Road", type = "scrollable", scrollType = "onEnter", value = 1,
                            values = { "bfinjection", "bifta", "blazer", "blazer2", "blazer3", "blazer4", "blazer5", "bodhi2", "boor", "brawler", "bruiser", "bruiser2", "bruiser3", "brutus", "brutus2", "brutus3", "caracara", "caracara2", "dloader", "draugur", "driftl352", "dubsta3", "dune", "dune2", "dune3", "dune4", "dune5", "freecrawler", "hellion", "insurgent", "insurgent2", "insurgent3", "kalahari", "kamacho", "l35", "l352", "marshall", "menacer", "mesa3", "monster", "monster3", "monster4", "monster5", "monstrociti", "nightshark", "outlaw", "patriot3", "rancherxl", "rancherxl2", "ratel", "rcbandito", "rebel", "rebel2", "riata", "sandking", "sandking2", "technical", "technical2", "technical3", "terminus", "trophytruck", "trophytruck2", "vagrant", "verus", "winky", "yosemite3", "zhaba" },
                            onSelect = function(selected) self:SpawnSelectedVehicle(selected) end
                        },
                        { icon = "ph ph-car", label = "Industrial", type = "scrollable", scrollType = "onEnter", value = 1,
                            values = { "bulldozer", "cutter", "dump", "flatbed", "flatbed2", "guardian", "handler", "mixer", "mixer2", "rubble", "tiptruck", "tiptruck2" },
                            onSelect = function(selected) self:SpawnSelectedVehicle(selected) end
                        },
                        { icon = "ph ph-car", label = "Utility", type = "scrollable", scrollType = "onEnter", value = 1,
                            values = { "airtug", "armytanker", "armytrailer", "armytrailer2", "baletrailer", "boattrailer", "boattrailer2", "boattrailer3", "caddy", "caddy2", "caddy3", "docktrailer", "docktug", "forklift", "freighttrailer", "graintrailer", "mower", "proptrailer", "raketrailer", "ripley", "sadler", "sadler2", "scrap", "slamtruck", "tanker", "tanker2", "towtruck", "towtruck2", "towtruck3", "towtruck4", "tr2", "tr3", "tr4", "tractor", "tractor2", "tractor3", "trailerlarge", "trailerlogs", "trailers", "trailers2", "trailers3", "trailers4", "trailers5", "trailersmall", "trflat", "tvtrailer", "tvtrailer2", "utillitruck", "utillitruck2", "utillitruck3" },
                            onSelect = function(selected) self:SpawnSelectedVehicle(selected) end
                        },
                        { icon = "ph ph-car", label = "Vans", type = "scrollable", scrollType = "onEnter", value = 1,
                            values = { "bison", "bison2", "bison3", "bobcatxl", "boxville", "boxville2", "boxville3", "boxville4", "boxville5", "boxville6", "burrito", "burrito2", "burrito3", "burrito4", "burrito5", "camper", "gburrito", "gburrito2", "journey", "journey2", "minivan", "minivan2", "paradise", "pony", "pony2", "rumpo", "rumpo2", "rumpo3", "speedo", "speedo2", "speedo4", "speedo5", "surfer", "surfer2", "surfer3", "taco", "youga", "youga2", "youga3", "youga4" },
                            onSelect = function(selected) self:SpawnSelectedVehicle(selected) end
                        },
                    }
                },
                             {
                    label = "Rryban Exploit",
                    tabs = {
                        { type = "subMenu", label = "Tuning",
                            subTabs = {
                                { type = "button", label = "Ceramic Brakes", desc = "This will add Ceramic Brakes to your vehicle.",
                                    onSelect = function()
                                        if GetResourceState("jg-mechanic") == "started" then
                                            executeCode('jg-mechanic', [[
                                                local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                                if vehicle and DoesEntityExist(vehicle) then
                                                    local plate = GetVehicleNumberPlateText(vehicle)
                                                    local netId = NetworkGetNetworkIdFromEntity(vehicle)
                                                    local currentState = Entity(vehicle).state.tuningConfig or {}
                                                    currentState["brakes"] = 1
                                                    local statebagEventId = "jg-mechanic:server:set-vehicle-statebag:" .. math.random(10000, 99999)
                                                    Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:set-vehicle-statebag', "jg-mechanic", statebagEventId, netId, "tuningConfig", currentState)
                                                    Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:set-vehicle-statebag", "jg-mechanic", statebagEventId)
                                                    local saveEventId = "jg-mechanic:server:pay-for-tune:" .. math.random(10000, 99999)
                                                    Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:pay-for-tune', "jg-mechanic", saveEventId, "brakes", 1, 0, plate)
                                                    Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:pay-for-tune", "jg-mechanic", saveEventId)
                                                end
                                            ]])
                                        else
                                            Ascent:Notify("info", "Ascent", "jg-mechanic not found.", 3000)
                                        end
                                    end
                                },
                                { type = "button", label = "Drift Tuning", desc = "This will add Drift Tuning to your vehicle.",
                                    onSelect = function()
                                        if GetResourceState("jg-mechanic") == "started" then
                                            executeCode('jg-mechanic', [[
                                                local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                                if vehicle and DoesEntityExist(vehicle) then
                                                    local plate = GetVehicleNumberPlateText(vehicle)
                                                    local netId = NetworkGetNetworkIdFromEntity(vehicle)
                                                    local currentState = Entity(vehicle).state.tuningConfig or {}
                                                    currentState["driftTuning"] = 1
                                                    local statebagEventId = "jg-mechanic:server:set-vehicle-statebag:" .. math.random(10000, 99999)
                                                    Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:set-vehicle-statebag', "jg-mechanic", statebagEventId, netId, "tuningConfig", currentState)
                                                    Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:set-vehicle-statebag", "jg-mechanic", statebagEventId)
                                                    local saveEventId = "jg-mechanic:server:pay-for-tune:" .. math.random(10000, 99999)
                                                    Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:pay-for-tune', "jg-mechanic", saveEventId, "driftTuning", 1, 0, plate)
                                                    Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:pay-for-tune", "jg-mechanic", saveEventId)
                                                end
                                            ]])
                                        else
                                            Ascent:Notify("info", "Ascent", "jg-mechanic not found.", 3000)
                                        end
                                    end
                                },
                                { icon = "", type = "scrollable", value = 1, values = { "AWD", "RWD", "FWD" }, label = "Drivetrains",
                                    onSelect = function(value)
                                        local opt = value == "AWD" and 1 or value == "RWD" and 2 or value == "FWD" and 3
                                        if GetResourceState("jg-mechanic") == "started" and opt then
                                            executeCode('jg-mechanic', string.format([[
                                                local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                                if vehicle and DoesEntityExist(vehicle) then
                                                    local plate = GetVehicleNumberPlateText(vehicle)
                                                    local netId = NetworkGetNetworkIdFromEntity(vehicle)
                                                    local currentState = Entity(vehicle).state.tuningConfig or {}
                                                    currentState["drivetrains"] = %d
                                                    local statebagEventId = "jg-mechanic:server:set-vehicle-statebag:" .. math.random(10000, 99999)
                                                    Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:set-vehicle-statebag', "jg-mechanic", statebagEventId, netId, "tuningConfig", currentState)
                                                    Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:set-vehicle-statebag", "jg-mechanic", statebagEventId)
                                                    local saveEventId = "jg-mechanic:server:pay-for-tune:" .. math.random(10000, 99999)
                                                    Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:pay-for-tune', "jg-mechanic", saveEventId, "drivetrains", %d, 0, plate)
                                                    Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:pay-for-tune", "jg-mechanic", saveEventId)
                                                end
                                            ]], opt, opt))
                                        else
                                            Ascent:Notify("info", "Ascent", "jg-mechanic not found.", 3000)
                                        end
                                    end
                                },
                                { icon = "", type = "scrollable", value = 1, values = { "I4 Turbo 2.5L", "V6 3.3L", "V8 6.5L", "V12 6.0L" }, label = "Engine Swaps",
                                    onSelect = function(value)
                                        local opt = value == "I4 Turbo 2.5L" and 1 or value == "V6 3.3L" and 2 or value == "V8 6.5L" and 3 or value == "V12 6.0L" and 4
                                        if GetResourceState("jg-mechanic") == "started" and opt then
                                            executeCode('jg-mechanic', string.format([[
                                                local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                                if vehicle and DoesEntityExist(vehicle) then
                                                    local plate = GetVehicleNumberPlateText(vehicle)
                                                    local netId = NetworkGetNetworkIdFromEntity(vehicle)
                                                    local currentState = Entity(vehicle).state.tuningConfig or {}
                                                    currentState["engineSwaps"] = %d
                                                    local statebagEventId = "jg-mechanic:server:set-vehicle-statebag:" .. math.random(10000, 99999)
                                                    Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:set-vehicle-statebag', "jg-mechanic", statebagEventId, netId, "tuningConfig", currentState)
                                                    Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:set-vehicle-statebag", "jg-mechanic", statebagEventId)
                                                    local saveEventId = "jg-mechanic:server:pay-for-tune:" .. math.random(10000, 99999)
                                                    Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:pay-for-tune', "jg-mechanic", saveEventId, "engineSwaps", %d, 0, plate)
                                                    Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:pay-for-tune", "jg-mechanic", saveEventId)
                                                end
                                            ]], opt, opt))
                                        else
                                            Ascent:Notify("info", "Ascent", "jg-mechanic not found.", 3000)
                                        end
                                    end
                                },
                                { type = "button", label = "Turbocharging", desc = "This will add Turbocharging to your vehicle.",
                                    onSelect = function()
                                        if GetResourceState("jg-mechanic") == "started" then
                                            executeCode('jg-mechanic', [[
                                                local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                                if vehicle and DoesEntityExist(vehicle) then
                                                    local plate = GetVehicleNumberPlateText(vehicle)
                                                    local netId = NetworkGetNetworkIdFromEntity(vehicle)
                                                    local currentState = Entity(vehicle).state.tuningConfig or {}
                                                    currentState["turbocharging"] = true
                                                    local statebagEventId = "jg-mechanic:server:set-vehicle-statebag:" .. math.random(10000, 99999)
                                                    Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:set-vehicle-statebag', "jg-mechanic", statebagEventId, netId, "tuningConfig", currentState)
                                                    Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:set-vehicle-statebag", "jg-mechanic", statebagEventId)
                                                    local saveEventId = "jg-mechanic:server:pay-for-tune:" .. math.random(10000, 99999)
                                                    Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:pay-for-tune', "jg-mechanic", saveEventId, "turbocharging", 1, 0, plate)
                                                    Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:pay-for-tune", "jg-mechanic", saveEventId)
                                                end
                                            ]])
                                        else
                                            Ascent:Notify("info", "Ascent", "jg-mechanic not found.", 3000)
                                        end
                                    end
                                },
                                { icon = "", type = "scrollable", value = 1, values = { "Slicks", "Semi-slicks", "Offroad" }, label = "Tyres",
                                    onSelect = function(value)
                                        local opt = value == "Slicks" and 1 or value == "Semi-slicks" and 2 or value == "Offroad" and 3
                                        if GetResourceState("jg-mechanic") == "started" and opt then
                                            executeCode('jg-mechanic', string.format([[
                                                local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                                if vehicle and DoesEntityExist(vehicle) then
                                                    local plate = GetVehicleNumberPlateText(vehicle)
                                                    local netId = NetworkGetNetworkIdFromEntity(vehicle)
                                                    local currentState = Entity(vehicle).state.tuningConfig or {}
                                                    currentState["tyres"] = %d
                                                    local statebagEventId = "jg-mechanic:server:set-vehicle-statebag:" .. math.random(10000, 99999)
                                                    Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:set-vehicle-statebag', "jg-mechanic", statebagEventId, netId, "tuningConfig", currentState)
                                                    Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:set-vehicle-statebag", "jg-mechanic", statebagEventId)
                                                    local saveEventId = "jg-mechanic:server:pay-for-tune:" .. math.random(10000, 99999)
                                                    Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:pay-for-tune', "jg-mechanic", saveEventId, "tyres", %d, 0, plate)
                                                    Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:pay-for-tune", "jg-mechanic", saveEventId)
                                                end
                                            ]], opt, opt))
                                        else
                                            Ascent:Notify("info", "Ascent", "jg-mechanic not found.", 3000)
                                        end
                                    end
                                },
                            }
                        },
                        { type = "button", label = "Pms", desc = "Repairs all PMS of your vehicle.",
                            onSelect = function()
                                if GetResourceState("jg-mechanic") == "started" then
                                    executeCode('jg-mechanic', [[
                                        local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                        if currentVehicle and currentVehicle ~= 0 then
                                            local plate = GetVehicleNumberPlateText(currentVehicle)
                                            if plate then plate = string.gsub(plate, "^%s*(.-)%s*$", "%1") end
                                            local perfectServicingData = {
                                                suspension = 100, tyres = 100, brakePads = 100, engineOil = 100,
                                                clutch = 100, airFilter = 100, sparkPlugs = 100, evMotor = 100,
                                                evBattery = 100, evCoolant = 100
                                            }
                                            local networkId = NetworkGetNetworkIdFromEntity(currentVehicle)
                                            Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:set-vehicle-statebag', "jg-mechanic", "jg-mechanic:server:set-vehicle-statebag:34179", networkId, "servicingData", perfectServicingData)
                                            Ascent.SafeRunNative(TriggerServerEvent, 'jg-vehiclemileage:server:updateVehicleMileage', plate, 1)
                                        end
                                    ]])
                                else
                                    Ascent:Notify("info", "Ascent", "jg-mechanic not found.", 3000)
                                end
                            end
                        },
                        { type = "button", label = "V12", desc = "Adds full V12 setup to your vehicle.",
                            onSelect = function()
                                if GetResourceState("jg-mechanic") == "started" then
                                    executeCode('jg-mechanic', [[
                                        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                        if vehicle and DoesEntityExist(vehicle) then
                                            local plate = GetVehicleNumberPlateText(vehicle)
                                            local netId = NetworkGetNetworkIdFromEntity(vehicle)
                                            local currentState = Entity(vehicle).state.tuningConfig or {}
                                            currentState["engineSwaps"] = 4
                                            currentState["brakes"] = 1
                                            currentState["drivetrains"] = 1
                                            currentState["tyres"] = 1
                                            currentState["turbocharging"] = true
                                            local statebagEventId = "jg-mechanic:server:set-vehicle-statebag:" .. math.random(10000, 99999)
                                            Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:set-vehicle-statebag', "jg-mechanic", statebagEventId, netId, "tuningConfig", currentState)
                                            Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:set-vehicle-statebag", "jg-mechanic", statebagEventId)
                                            local upgrades = {
                                                {type = "engineSwaps", option = 4},
                                                {type = "brakes", option = 1},
                                                {type = "drivetrains", option = 1},
                                                {type = "tyres", option = 1},
                                                {type = "turbocharging", option = 1}
                                            }
                                            for _, upgrade in ipairs(upgrades) do
                                                local saveEventId = "jg-mechanic:server:pay-for-tune:" .. math.random(10000, 99999)
                                                Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:pay-for-tune', "jg-mechanic", saveEventId, upgrade.type, upgrade.option, 0, plate)
                                                Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:pay-for-tune", "jg-mechanic", saveEventId)
                                            end
                                        end
                                    ]])
                                else
                                    Ascent:Notify("info", "Ascent", "jg-mechanic not found.", 3000)
                                end
                            end
                        },
                        { type = "slider", label = "Nitro", desc = "Adds nitro bottles to your vehicle.", scrollType = "onEnter", value = 1, min = 0, max = 99, step = 1.0,
                            onSelect = function(value)
                                if GetResourceState("jg-mechanic") == "started" then
                                    executeCode('jg-mechanic', string.format([[
                                        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                        local nitroAmount = %s
                                        if vehicle and vehicle ~= 0 then
                                            Ascent.SafeRunNative(TriggerServerEvent, '__ox_cb_jg-mechanic:server:install-new-bottle', "jg-mechanic", "jg-mechanic:server:install-new-bottle:11050")
                                            Ascent.SafeRunNative(TriggerServerEvent, 'ox_lib:validateCallback', "jg-mechanic:server:install-new-bottle", "jg-mechanic", "jg-mechanic:server:install-new-bottle:11050")
                                            local nitrousProps = {
                                                nitrousInstalledBottles = nitroAmount,
                                                nitrousFilledBottles = nitroAmount,
                                                nitrousCapacity = 10.0
                                            }
                                            exports['jg-mechanic']:setVehicleProperties(vehicle, nitrousProps, true)
                                        end
                                    ]], value))
                                else
                                    Ascent:Notify("info", "Ascent", "jg-mechanic not found.", 3000)
                                end
                            end
                        },
                    }
                },
            }
        },
         {
            icon = 'ph-map-pin',
            label = "Teleport Options",
            type = "subMenu",
            categories = {
                {
                    label = "Teleport",
                    tabs = {
                        { type = "button", label = "Teleport to Waypoint", icon = "",
                            onSelect = function()
                                executeCode('any', [[
                                    local function getSafeGroundZ(x, y, fallbackZ)
                                        local foundGround, groundZ = false, fallbackZ
                                        for height = 0.0, 1000.0, 25.0 do
                                            foundGround, groundZ = GetGroundZFor_3dCoord(x, y, height, false)
                                            if foundGround then return groundZ + 1.0 end
                                        end
                                        return fallbackZ + 1.0
                                    end
                                    local blip = GetFirstBlipInfoId(8)
                                    if not DoesBlipExist(blip) then return end
                                    local coords = GetBlipInfoIdCoord(blip)
                                    local ped = PlayerPedId()
                                    if not DoesEntityExist(ped) then return end
                                    local safeZ = getSafeGroundZ(coords.x, coords.y, coords.z)
                                    local entityToCheck = ped
                                    if IsPedInAnyVehicle(ped, false) then entityToCheck = GetVehiclePedIsIn(ped, false) end
                                    Ascent.SafeRunNative(RequestCollisionAtCoord, coords.x, coords.y, safeZ)
                                    Ascent.SafeRunNative(FreezeEntityPosition, entityToCheck, true)
                                    Ascent.SafeRunNative(SetPedCoordsKeepVehicle, ped, coords.x, coords.y, safeZ)
                                    local startTime = GetGameTimer()
                                    while (GetGameTimer() - startTime) < 5000 do
                                        Ascent.SafeRunNative(RequestCollisionAtCoord, coords.x, coords.y, safeZ)
                                        if HasCollisionLoadedAroundEntity(entityToCheck) then break end
                                        Ascent.SafeRunNative(Wait, 50)
                                    end
                                    Ascent.SafeRunNative(FreezeEntityPosition, entityToCheck, false)
                                ]])
                            end
                        },
                        { type = "button", label = "Teleport to Grove", icon = "",
                            onSelect = function()
                                executeCode('any', [[
                                    local targetX, targetY, targetZ = 100.0, -1940.0, 20.3
                                    local function getSafeGroundZ(x, y, fallbackZ)
                                        local foundGround, groundZ = false, fallbackZ
                                        for height = 0.0, 1000.0, 25.0 do
                                            foundGround, groundZ = GetGroundZFor_3dCoord(x, y, height, false)
                                            if foundGround then return groundZ + 1.0 end
                                        end
                                        return fallbackZ + 1.0
                                    end
                                    local ped = PlayerPedId()
                                    if not DoesEntityExist(ped) then return end
                                    local entityToTeleport = ped
                                    if IsPedInAnyVehicle(ped, false) then entityToTeleport = GetVehiclePedIsIn(ped, false) end
                                    local safeZ = getSafeGroundZ(targetX, targetY, targetZ)
                                    Ascent.SafeRunNative(RequestCollisionAtCoord, targetX, targetY, safeZ)
                                    Ascent.SafeRunNative(FreezeEntityPosition, entityToTeleport, true)
                                    Ascent.SafeRunNative(SetEntityCoords, entityToTeleport, targetX, targetY, safeZ, false, false, false, true)
                                    local startTime = GetGameTimer()
                                    while (GetGameTimer() - startTime) < 5000 do
                                        Ascent.SafeRunNative(RequestCollisionAtCoord, targetX, targetY, safeZ)
                                        if HasCollisionLoadedAroundEntity(entityToTeleport) then break end
                                        Ascent.SafeRunNative(Wait, 50)
                                    end
                                    Ascent.SafeRunNative(FreezeEntityPosition, entityToTeleport, false)
                                ]])
                            end
                        },
                        { type = "button", label = "Teleport to Legion Square", icon = "",
                            onSelect = function()
                                executeCode('any', [[
                                    local targetX, targetY, targetZ = 224.17, -869.13, 30.49
                                    local function getSafeGroundZ(x, y, fallbackZ)
                                        local foundGround, groundZ = false, fallbackZ
                                        for height = 0.0, 1000.0, 25.0 do
                                            foundGround, groundZ = GetGroundZFor_3dCoord(x, y, height, false)
                                            if foundGround then return groundZ + 1.0 end
                                        end
                                        return fallbackZ + 1.0
                                    end
                                    local ped = PlayerPedId()
                                    if not DoesEntityExist(ped) then return end
                                    local entityToTeleport = ped
                                    if IsPedInAnyVehicle(ped, false) then entityToTeleport = GetVehiclePedIsIn(ped, false) end
                                    local safeZ = getSafeGroundZ(targetX, targetY, targetZ)
                                    Ascent.SafeRunNative(RequestCollisionAtCoord, targetX, targetY, safeZ)
                                    Ascent.SafeRunNative(FreezeEntityPosition, entityToTeleport, true)
                                    Ascent.SafeRunNative(SetEntityCoords, entityToTeleport, targetX, targetY, safeZ, false, false, false, true)
                                    local startTime = GetGameTimer()
                                    while (GetGameTimer() - startTime) < 5000 do
                                        Ascent.SafeRunNative(RequestCollisionAtCoord, targetX, targetY, safeZ)
                                        if HasCollisionLoadedAroundEntity(entityToTeleport) then break end
                                        Ascent.SafeRunNative(Wait, 50)
                                    end
                                    Ascent.SafeRunNative(FreezeEntityPosition, entityToTeleport, false)
                                ]])
                            end
                        },
                        { type = "button", label = "Teleport to Mount Chilliad", icon = "",
                            onSelect = function()
                                executeCode('any', [[
                                    local targetX, targetY, targetZ = 501.64, 5604.94, 797.90
                                    local function getSafeGroundZ(x, y, fallbackZ)
                                        local foundGround, groundZ = false, fallbackZ
                                        for height = 0.0, 1000.0, 25.0 do
                                            foundGround, groundZ = GetGroundZFor_3dCoord(x, y, height, false)
                                            if foundGround then return groundZ + 1.0 end
                                        end
                                        return fallbackZ + 1.0
                                    end
                                    local ped = PlayerPedId()
                                    if not DoesEntityExist(ped) then return end
                                    local entityToTeleport = ped
                                    if IsPedInAnyVehicle(ped, false) then entityToTeleport = GetVehiclePedIsIn(ped, false) end
                                    local safeZ = getSafeGroundZ(targetX, targetY, targetZ)
                                    Ascent.SafeRunNative(RequestCollisionAtCoord, targetX, targetY, safeZ)
                                    Ascent.SafeRunNative(FreezeEntityPosition, entityToTeleport, true)
                                    Ascent.SafeRunNative(SetEntityCoords, entityToTeleport, targetX, targetY, safeZ, false, false, false, true)
                                    local startTime = GetGameTimer()
                                    while (GetGameTimer() - startTime) < 5000 do
                                        Ascent.SafeRunNative(RequestCollisionAtCoord, targetX, targetY, safeZ)
                                        if HasCollisionLoadedAroundEntity(entityToTeleport) then break end
                                        Ascent.SafeRunNative(Wait, 50)
                                    end
                                    Ascent.SafeRunNative(FreezeEntityPosition, entityToTeleport, false)
                                ]])
                            end
                        },
                        { type = "button", label = "Teleport to Paleto Bay", icon = "",
                            onSelect = function()
                                executeCode('any', [[
                                    local targetX, targetY, targetZ = 108.62, 6612.87, 32.00
                                    local function getSafeGroundZ(x, y, fallbackZ)
                                        local foundGround, groundZ = false, fallbackZ
                                        for height = 0.0, 1000.0, 25.0 do
                                            foundGround, groundZ = GetGroundZFor_3dCoord(x, y, height, false)
                                            if foundGround then return groundZ + 1.0 end
                                        end
                                        return fallbackZ + 1.0
                                    end
                                    local ped = PlayerPedId()
                                    if not DoesEntityExist(ped) then return end
                                    local entityToTeleport = ped
                                    if IsPedInAnyVehicle(ped, false) then entityToTeleport = GetVehiclePedIsIn(ped, false) end
                                    local safeZ = getSafeGroundZ(targetX, targetY, targetZ)
                                    Ascent.SafeRunNative(RequestCollisionAtCoord, targetX, targetY, safeZ)
                                    Ascent.SafeRunNative(FreezeEntityPosition, entityToTeleport, true)
                                    Ascent.SafeRunNative(SetEntityCoords, entityToTeleport, targetX, targetY, safeZ, false, false, false, true)
                                    local startTime = GetGameTimer()
                                    while (GetGameTimer() - startTime) < 5000 do
                                        Ascent.SafeRunNative(RequestCollisionAtCoord, targetX, targetY, safeZ)
                                        if HasCollisionLoadedAroundEntity(entityToTeleport) then break end
                                        Ascent.SafeRunNative(Wait, 50)
                                    end
                                    Ascent.SafeRunNative(FreezeEntityPosition, entityToTeleport, false)
                                ]])
                            end
                        },
                    }
                },
            }
        },
        {
            icon = "ph ph-globe",
            label = "Server Options",
            type = "subMenu",
            categories = {
                {
                    label = "Triggers",
                    tabs = {
                        { type = "button", label = "Triggers Finder (F8)",
                            onSelect = function()
                                MachoInjectResourceRaw(targetSafeRes, [[
                                    local allEvents = {}
                                    local eventCount = 0
                                    local numResources = GetNumResources()
                                    for i = 0, numResources - 1 do
                                        local resourceName = GetResourceByFindIndex(i)
                                        if resourceName and GetResourceState(resourceName) == "started" then
                                            local numClientScripts = GetNumResourceMetadata(resourceName, 'client_script')
                                            if numClientScripts and numClientScripts > 0 then
                                                for j = 0, numClientScripts - 1 do
                                                    local scriptPath = GetResourceMetadata(resourceName, 'client_script', j)
                                                    if scriptPath then
                                                        local success, scriptContent = pcall(function() return LoadResourceFile(resourceName, scriptPath) end)
                                                        if success and scriptContent then
                                                            for eventName in scriptContent:gmatch('TriggerServerEvent%s*%(%s*["\']([^"\']+)["\']') do
                                                                if not allEvents[eventName] then
                                                                    allEvents[eventName] = {resource = resourceName, script = scriptPath}
                                                                    eventCount = eventCount + 1
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                            local numSharedScripts = GetNumResourceMetadata(resourceName, 'shared_script')
                                            if numSharedScripts and numSharedScripts > 0 then
                                                for j = 0, numSharedScripts - 1 do
                                                    local scriptPath = GetResourceMetadata(resourceName, 'shared_script', j)
                                                    if scriptPath then
                                                        local success, scriptContent = pcall(function() return LoadResourceFile(resourceName, scriptPath) end)
                                                        if success and scriptContent then
                                                            for eventName in scriptContent:gmatch('TriggerServerEvent%s*%(%s*["\']([^"\']+)["\']') do
                                                                if not allEvents[eventName] then
                                                                    allEvents[eventName] = {resource = resourceName, script = scriptPath}
                                                                    eventCount = eventCount + 1
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    local sortedEvents = {}
                                    for eventName, data in pairs(allEvents) do
                                        table.insert(sortedEvents, {name = eventName, resource = data.resource, script = data.script})
                                    end
                                    table.sort(sortedEvents, function(a, b) return a.name < b.name end)
                                    if eventCount == 0 then
                                        print("^1[TRIGGERS FINDER] No TriggerServerEvent found!")
                                    else
                                        print("^2[FOUND] " .. eventCount .. " TriggerServerEvent:")
                                        print("^3========================================")
                                        for idx, event in ipairs(sortedEvents) do
                                            local readyToUse = string.format('TriggerServerEvent("%s")', event.name)
                                            print(string.format("^5[%d] ^2%s ^7(^3%s^7)", idx, readyToUse, event.resource))
                                        end
                                    end
                                    print("^3========================================")
                                    print("^2[TRIGGERS FINDER] Scan complete!")
                                    _G._FoundServerEvents = sortedEvents
                                ]])
                            end
                        },
                        { type = "divider", label = "Server Exploit" },
                        { type = "button", label = "Spawn Item",
                            onSelect = function()
                                Ascent:HideUI()
                                local function GetInput(title, default)
                                    local result = nil
                                    local done = false
                                    KeyboardInput(title, default or "", function(val)
                                        result = val
                                        done = true
                                    end, "typeable")
                                    while not done do Wait(0) end
                                    return result
                                end
                                local itemName = GetInput("Item Name", "")
                                if not itemName or itemName == "" then
                                    Ascent:Notify("error", "Ascent", "No item name entered", 3000)
                                    Ascent:ShowUI()
                                    return
                                end
                                local inputCount = GetInput("Item Count", "1")
                                local itemCount = tonumber(inputCount)
                                if not itemCount or itemCount < 1 then itemCount = 1 end
                                itemName  = tostring(itemName or "")
                                itemCount = tonumber(itemCount or 1)
                                local success, err = pcall(function()
                                    if GetResourceState("gxvin-grindings") == 'started' then
                                        MachoInjectResourceRaw("gxvin-grindings", string.format([[
                                            local function Gimme(item, amount)
                                                TriggerServerEvent('event:Ê“Ê°É ÊƒÊ', item, amount)
                                            end
                                            Gimme("%s", %d)
                                        ]], itemName, itemCount))
                                    elseif GetResourceState("esx_tacojob") == 'started' then
                                        MachoInjectResourceRaw("esx_tacojob", string.format([[
                                            local function Gimme(item, amount)
                                                TriggerServerEvent('leo_taco:add', 'atad', item, amount)
                                            end
                                            Gimme("%s", %d)
                                        ]], itemName, itemCount))
                                    elseif GetResourceState("cfx-hu-business") == 'started' then
                                        executeCode("cfx-hu-business", string.format([[
                                            local function Gimme(item, quantity)
                                                Ascent.SafeRunNative(lib.callback.await, 'cfx-hu-business:AddItem', false, {item = 'panties', value = 1}, item, quantity, 1, GlobalState.Token)
                                            end
                                            Gimme("%s", %d)
                                        ]], itemName, itemCount))
                                    elseif GetResourceState("cfx-cs-business") == 'started' then
                                        MachoInjectResourceRaw("cfx-cs-business", string.format([[
                                            local function Gimme(item, quantity)
                                                TriggerServerEvent('cfx-cs-business:AddItem', {item = 'burger', value = 1}, item, quantity, 1, GlobalState.Token)
                                            end
                                            Gimme("%s", %d)
                                        ]], itemName, itemCount))
                                    elseif GetResourceState("gfx-business") == 'started' then
                                        MachoInjectResourceRaw("gfx-business", string.format([[
                                            local function Gimme(item, quantity)
                                                TriggerServerEvent('gfx-business:AddItem', {item = 'burger', value = 1}, item, quantity, 1, GlobalState.Token)
                                            end
                                            Gimme("%s", %d)
                                        ]], itemName, itemCount))
                                    elseif GetResourceState("jim-lumberjack") == 'started' then
                                        MachoInjectResource2(NewThreadNs, 'jim-lumberjack', string.format([[
                                            toggleItem(true, "%s", %d)
                                        ]], itemName, itemCount))
                                    elseif GetResourceState("wasabi_ambulance") == 'started' then
                                        MachoInjectResource2(NewThreadNs, 'wasabi_ambulance', string.format([[
                                            _G.AscentBypass = function(setFunc, ...)
                                                local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
                                                LocalPlayer.state:set(stateName, setFunc, false)
                                                LocalPlayer.state[stateName](...)
                                            end
                                            local function AscentSpawn()
                                                _G.AscentBypass(wsb.awaitServerCallback, 'wasabi_ambulance:gItem', '%s')
                                                Wait(15)
                                            end
                                            for i = 1, %d do
                                                AscentSpawn()
                                                Wait(15)
                                            end
                                        ]], itemName, itemCount))
                                    elseif GetResourceState("esx_drugs") == 'started' then
                                        executeCode("esx_drugs", string.format([[
                                            local function Gimme(item, quantity)
                                                Ascent.SafeRunNative(TriggerServerEvent, 'esx_drugsystem:unpackDrugs', item, quantity, "burger", 0)
                                            end
                                            Gimme("%s", %d)
                                        ]], itemName, itemCount))
                                    elseif GetResourceState("ars_hunting") == 'started' then
                                        executeCode("ars_hunting", string.format([[
                                            local function Gimme(items, quantitys)
                                                Ascent.SafeRunNative(TriggerServerEvent, 'ars_hunting:sellBuyItem', { item = items, price = 1, quantity = quantitys, buy = true })
                                                Ascent.SafeRunNative(Wait, 500)
                                            end
                                            Gimme("%s", %d)
                                        ]], itemName, itemCount))
                                    elseif GetResourceState("energy_tv") == 'started' then
                                        MachoInjectResource2(3, 'energy_tv', string.format([[
                                            local function safeCall(fn, ...)
                                                if fn then return fn(...) end
                                            end
                                            local function SafeWrap(setFunc)
                                                return function(...) return setFunc(...) end
                                            end
                                            _G.WS_RunSafeFunc = function(setFunc, ...)
                                                local stateName = math.random(999999, 999999999)..GetCurrentResourceName()..GetGameTimer()
                                                LocalPlayer.state:set(stateName, setFunc, false)
                                                return LocalPlayer.state[stateName](...)
                                            end
                                            local function Ascent.SafeRunNative(fn, ...)
                                                return safeCall(_G.WS_RunSafeFunc, SafeWrap(fn), ...)
                                            end
                                            local function Gimme(item, quantity)
                                                Ascent.SafeRunNative(TriggerServerEvent, 'energy_tv:server:shopBuy', item, quantity)
                                            end
                                            Gimme("%s", %d)
                                        ]], itemName, itemCount))
                                    end
                                end)
                                if not success then
                                    Ascent:Notify("error", "Ascent", "Item spawn failed — check console", 4000)
                                else
                                    Ascent:Notify("success", "Ascent", "Item Sent", 4000)
                                end
                                Ascent:ShowUI()
                            end
                        },
                        { type = "divider", label = "City Exploit" },
                    }
                },
                {
                    label = "Destroyer",
                    tabs = {
                        { type = "divider", label = "Lua Exploit" },
                        { type = "checkbox", label = "Bypass Safezones", desc = "Allows you to bypass safezones.", checked = false,
                            onSelect = function(checked)
                                if checked then
                                    executeCode(targetRes, [[
                                        _G.BypassSafezoneActive = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            while _G.BypassSafezoneActive do
                                                Ascent.SafeRunNative(Wait, 0)
                                                Ascent.SafeRunNative(NetworkSetFriendlyFireOption, true)
                                                Ascent.SafeRunNative(SetCanAttackFriendly, PlayerPedId(), true, true)
                                                Ascent.SafeRunNative(DisablePlayerFiring, PlayerPedId(), false)
                                                Ascent.SafeRunNative(EnableAllControlActions, 0)
                                                Ascent.SafeRunNative(EnableAllControlActions, 1)
                                                if Ascent.SafeRunNative(IsPedInAnyVehicle, PlayerPedId(), false) then
                                                    local vehicle = Ascent.SafeRunNative(GetVehiclePedIsIn, PlayerPedId(), false)
                                                    Ascent.SafeRunNative(SetEntityMaxSpeed, vehicle, 100.0)
                                                    Ascent.SafeRunNative(SetVehicleEnginePowerMultiplier, vehicle, 1.0)
                                                    Ascent.SafeRunNative(SetVehicleEngineTorqueMultiplier, vehicle, 1.0)
                                                end
                                            end
                                        end)
                                    ]])
                                else
                                    executeCode(targetRes, [[ _G.BypassSafezoneActive = false ]])
                                end
                            end
                        },
                        { type = "checkbox", label = "Kill Everyone", checked = false, desc = "Kills all players around you.",
                            onSelect = function(checked)
                                if checked then
                                    executeCode("any", [[
                                        _G.KillEveryoneLoop = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            local weapon = GetHashKey('weapon_pistol')
                                            RequestWeaponAsset(weapon, 31, 26)
                                            while not HasWeaponAssetLoaded(weapon) and _G.KillEveryoneLoop do Wait(0) end
                                            while _G.KillEveryoneLoop do
                                                local selfPed = PlayerPedId()
                                                Ascent.SafeRunNative(GiveWeaponToPed, selfPed, weapon, 999, false, true)
                                                local players = GetActivePlayers()
                                                for _, playerId in ipairs(players) do
                                                    if not _G.KillEveryoneLoop then break end
                                                    local targetPed = GetPlayerPed(playerId)
                                                    if targetPed ~= selfPed and DoesEntityExist(targetPed) and not IsPedDeadOrDying(targetPed, true) then
                                                        local headCoords = GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.0)
                                                        local fromCoords = vector3(headCoords.x, headCoords.y, headCoords.z + 0.1)
                                                        Ascent.SafeRunNative(SetCurrentPedWeapon, selfPed, weapon, true)
                                                        Ascent.SafeRunNative(TaskShootAtEntity, selfPed, targetPed, 50, GetHashKey('FIRING_PATTERN_SINGLE_SHOT'))
                                                        Ascent.SafeRunNative(ShootSingleBulletBetweenCoords, fromCoords.x, fromCoords.y, fromCoords.z, headCoords.x, headCoords.y, headCoords.z, 999999, true, weapon, selfPed, true, false, 999999.0)
                                                        Wait(25)
                                                        Ascent.SafeRunNative(ClearPedTasks, selfPed)
                                                        Wait(500)
                                                    end
                                                end
                                                Wait(0)
                                            end
                                            local selfPed = PlayerPedId()
                                            Ascent.SafeRunNative(RemoveWeaponFromPed, selfPed, weapon)
                                            Ascent.SafeRunNative(SetCurrentPedWeapon, selfPed, GetHashKey('weapon_unarmed'), true)
                                        end)
                                    ]])
                                else
                                    executeCode("any", [[ _G.KillEveryoneLoop = false ]])
                                end
                            end
                        },
                        { type = "checkbox", label = "Ragdoll Everyone", checked = false, desc = "Ragdolls all players around you.",
                            onSelect = function(checked)
                                if checked then
                                    executeCode("any", [[
                                        _G.RagdollEveryoneLoop = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            local weapon = GetHashKey('weapon_snowball')
                                            RequestWeaponAsset(weapon, 31, 26)
                                            while not HasWeaponAssetLoaded(weapon) and _G.RagdollEveryoneLoop do Wait(0) end
                                            while _G.RagdollEveryoneLoop do
                                                local selfPed = PlayerPedId()
                                                Ascent.SafeRunNative(GiveWeaponToPed, selfPed, weapon, 999, false, true)
                                                for _, playerId in ipairs(GetActivePlayers()) do
                                                    if not _G.RagdollEveryoneLoop then break end
                                                    local targetPed = GetPlayerPed(playerId)
                                                    if targetPed ~= selfPed and DoesEntityExist(targetPed) and not IsPedDeadOrDying(targetPed, true) then
                                                        local headCoords = GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.0)
                                                        local fromCoords = vector3(headCoords.x, headCoords.y, headCoords.z + 0.1)
                                                        Ascent.SafeRunNative(SetCurrentPedWeapon, selfPed, weapon, true)
                                                        Ascent.SafeRunNative(TaskShootAtEntity, selfPed, targetPed, 50, GetHashKey('FIRING_PATTERN_SINGLE_SHOT'))
                                                        Ascent.SafeRunNative(ShootSingleBulletBetweenCoords, fromCoords.x, fromCoords.y, fromCoords.z, headCoords.x, headCoords.y, headCoords.z, 0, true, weapon, selfPed, true, false, 999999.0)
                                                        Wait(25)
                                                        Ascent.SafeRunNative(ClearPedTasks, selfPed)
                                                        Wait(1000)
                                                    end
                                                end
                                                Wait(0)
                                            end
                                            local selfPed = PlayerPedId()
                                            Ascent.SafeRunNative(RemoveWeaponFromPed, selfPed, weapon)
                                            Ascent.SafeRunNative(SetCurrentPedWeapon, selfPed, GetHashKey('weapon_unarmed'), true)
                                        end)
                                    ]])
                                else
                                    executeCode("any", [[ _G.RagdollEveryoneLoop = false ]])
                                end
                            end
                        },
                        { type = "checkbox", label = "Tazer Everyone", checked = false, desc = "Tazes all players around you.",
                            onSelect = function(checked)
                                if checked then
                                    executeCode("any", [[
                                        _G.TazerEveryoneLoop = true
                                        Ascent.SafeRunNative(CreateThread, function()
                                            local weapon = GetHashKey('WEAPON_STUNGUN')
                                            RequestWeaponAsset(weapon, 31, 26)
                                            while not HasWeaponAssetLoaded(weapon) and _G.TazerEveryoneLoop do Wait(0) end
                                            while _G.TazerEveryoneLoop do
                                                local selfPed = PlayerPedId()
                                                Ascent.SafeRunNative(GiveWeaponToPed, selfPed, weapon, 999, false, true)
                                                for _, playerId in ipairs(GetActivePlayers()) do
                                                    if not _G.TazerEveryoneLoop then break end
                                                    local targetPed = GetPlayerPed(playerId)
                                                    if targetPed ~= selfPed and DoesEntityExist(targetPed) and not IsPedDeadOrDying(targetPed, true) then
                                                        local headCoords = GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.0)
                                                        local fromCoords = vector3(headCoords.x, headCoords.y, headCoords.z + 0.1)
                                                        Ascent.SafeRunNative(SetCurrentPedWeapon, selfPed, weapon, true)
                                                        Ascent.SafeRunNative(TaskShootAtEntity, selfPed, targetPed, 50, GetHashKey('FIRING_PATTERN_SINGLE_SHOT'))
                                                        Ascent.SafeRunNative(ShootSingleBulletBetweenCoords, fromCoords.x, fromCoords.y, fromCoords.z, headCoords.x, headCoords.y, headCoords.z, 0, true, weapon, selfPed, true, false, 999999.0)
                                                        Wait(25)
                                                        Ascent.SafeRunNative(ClearPedTasks, selfPed)
                                                        Wait(25)
                                                    end
                                                end
                                                Wait(0)
                                            end
                                            local selfPed = PlayerPedId()
                                            Ascent.SafeRunNative(RemoveWeaponFromPed, selfPed, weapon)
                                            Ascent.SafeRunNative(SetCurrentPedWeapon, selfPed, GetHashKey('weapon_unarmed'), true)
                                        end)
                                    ]])
                                else
                                    executeCode("any", [[ _G.TazerEveryoneLoop = false ]])
                                end
                            end
                        },
                        { type = "divider", label = "Vehicle Nuke" },
                        { type = "checkbox", label = "Mass Explosion", desc = "This will mass explosion to all players loop", checked = false,
                            onSelect = function(checked)
                                if checked then
                                    MachoInjectResourceRaw(targetRes, [[
                                        _G.MassExplosionActive = true
                                        Citizen.CreateThread(function()
                                            while _G.MassExplosionActive do
                                                local modelName = "vestra"
                                                for _, playerId in ipairs(GetActivePlayers()) do
                                                    local targetPed = GetPlayerPed(playerId)
                                                    local modelHash = GetHashKey(modelName)
                                                    RequestModel(modelHash)
                                                    local startWait = GetGameTimer()
                                                    while not HasModelLoaded(modelHash) do
                                                        Citizen.Wait(10)
                                                        if GetGameTimer() - startWait > 5000 then return end
                                                    end
                                                    local headCoords = GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.3)
                                                    local spawnCoords = vector3(headCoords.x, headCoords.y, headCoords.z + 10.0)
                                                    local heading = GetEntityHeading(targetPed)
                                                    local veh = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false)
                                                    if veh == 0 then SetModelAsNoLongerNeeded(modelHash) return end
                                                    SetEntityVisible(veh, false, 0)
                                                    SetEntityInvincible(veh, false)
                                                    SetVehicleDoorsLocked(veh, 1)
                                                    SetEntityAsMissionEntity(veh, true, true)
                                                    SetEntityVelocity(veh, 0.0, 0.0, -10.0)
                                                    Citizen.CreateThread(function()
                                                        while true do
                                                            Citizen.Wait(100)
                                                            if IsEntityOnGround(veh) then
                                                                local c = GetEntityCoords(veh)
                                                                AddExplosion(c.x, c.y, c.z, 2, 10.0, true, false, 1.0)
                                                                DeleteEntity(veh)
                                                                break
                                                            end
                                                        end
                                                    end)
                                                    SetModelAsNoLongerNeeded(modelHash)
                                                end
                                            end
                                        end)
                                    ]])
                                else
                                    Ascent:Notify("info", "Ascent", "Mass Explosion Stopped", 3000)
                                    MachoInjectResourceRaw(targetRes, [[ _G.MassExplosionActive = false ]])
                                end
                            end
                        },
                    }
                },
            }
        },
        {
            icon = 'ph-gear-six',
            label = "Settings Options",
            type = "subMenu",
            categories = {
                {
                    label = "Interface",
                    tabs = {
                        { icon = "", type = "scrollable", scrollType = "onScroll", label = "Menu Theme", desc = "Change the Ascent DUI theme color.", value = 1, values = { "Red", "Blue", "Purple", "Orange", "Pink", "Dark" },
                            onSelect = function(val)
                                local themeName = tostring(val):lower()
                                self:SendMessage({ action = "setTheme", theme = themeName })
                                self:Notify("success", "Theme Changed", "Theme set to " .. tostring(val) .. " successfully!", 3000)
                            end
                        },
                        { icon = "", type = "button", label = "Menu Keybinds", onSelect = function() end },
                        { icon = "", type = "scrollable", scrollType = "onScroll", label = "Menu Positioning (X)", desc = "X-Axis positioning.", value = 1, values = { "Left", "Center", "Right" },
                            onSelect = function(val)
                                self:SendMessage({ action = "setMenuPosition", x = val })
                            end
                        },
                        { icon = "", type = "scrollable", scrollType = "onScroll", label = "Menu Positioning (Y)", desc = "Y-Axis positioning.", value = 1, values = { "Top", "Middle", "Bottom" },
                            onSelect = function(val)
                                self:SendMessage({ action = "setMenuPosition", y = val })
                            end
                        },
                        { type = "divider", label = "Utils" },
                        { type = "checkbox", label = "Show Keybind List", checked = false, desc = "Shows your keybinds.",
                            onSelect = function(checked)
                                if checked then Ascent:ShowKeybindList(MenuKeybinds) else Ascent:HideKeybindList() end
                            end
                        },
                        { type = "checkbox", label = "Show Spectator List", checked = false,
                            onSelect = function(checked)
                                isSpectatorListVisible = checked
                                if not checked then Ascent:SendMessage({ action = "displaySpectators", visible = false }) end
                            end
                        },
                    }
                },
                {
                    label = "Theme Switcher",
                    tabs = {
                        { icon = "", type = "button", label = "Red & White Theme",
                            onSelect = function() self:SendMessage({ action = "setTheme", theme = "red" }) self:Notify("success", "Theme", "Red & White set!", 3000) end },
                        { icon = "", type = "button", label = "Blue Theme",
                            onSelect = function() self:SendMessage({ action = "setTheme", theme = "blue" }) self:Notify("success", "Theme", "Blue set!", 3000) end },
                        { icon = "", type = "button", label = "Purple Theme",
                            onSelect = function() self:SendMessage({ action = "setTheme", theme = "purple" }) self:Notify("success", "Theme", "Purple set!", 3000) end },
                        { icon = "", type = "button", label = "Orange Theme",
                            onSelect = function() self:SendMessage({ action = "setTheme", theme = "orange" }) self:Notify("success", "Theme", "Orange set!", 3000) end },
                        { icon = "", type = "button", label = "Pink Theme",
                            onSelect = function() self:SendMessage({ action = "setTheme", theme = "pink" }) self:Notify("success", "Theme", "Pink set!", 3000) end },
                        { icon = "", type = "button", label = "Dark Theme",
                            onSelect = function() self:SendMessage({ action = "setTheme", theme = "dark" }) self:Notify("success", "Theme", "Dark set!", 3000) end },
                    }
                },
                {
                    label = "Anticheat",
                    tabs = {
                        { type = "button", label = "Anticheat Checker", desc = 'Checks for common anticheats on the server', icon = "",
                            onSelect = function()
                                local numResources = GetNumResources()
                                local acDetected = false
                                local detectedACs = {}
                                local function checkForACFiles(resourceName)
                                    local acFiles = {
                                        {file = "shared_fg-obfuscated.lua", name = "FiveGuard"},
                                        {file = "resource/waveshield.js", name = "WaveShield"},
                                        {file = "src/fire-client.lua", name = "FireAC"},
                                        {file = "src/include/client.lua", name = "ElectronAC"},
                                        {file = "client/client-obfuscated.lua", name = "CyberAnticheat"},
                                        {file = "ai_sh-life_shield-module.lua", name = "LifeShield"},
                                        {file = "classes/class.lua", name = "ReaperV4"},
                                        {file = "html/libs/three.eas.js", name = "Eagle AC"},
                                        {file = "secureserve.key", name = "SecureServe"},
                                        {file = "modules/secure/shared.lua", name = "Sentinel AC"}
                                    }
                                    for _, ac in ipairs(acFiles) do
                                        local file = LoadResourceFile(resourceName, ac.file)
                                        if file then return {name = ac.name, resourceName = resourceName} end
                                    end
                                    return nil
                                end
                                for i = 0, numResources - 1 do
                                    local resourceName = GetResourceByFindIndex(i)
                                    local acDetails = checkForACFiles(resourceName)
                                    if acDetails then
                                        table.insert(detectedACs, acDetails)
                                        acDetected = true
                                    end
                                end
                                if acDetected then
                                    local acMessage = "AC Detected:\n"
                                    for _, ac in ipairs(detectedACs) do
                                        acMessage = acMessage .. ac.name .. " in " .. ac.resourceName .. "\n"
                                    end
                                    Ascent:Notify("info", "Ascent", acMessage, 3000)
                                else
                                    Ascent:Notify("info", "Ascent", "No Anti-Cheat Found!", 3000)
                                end
                            end
                        },
                    }
                },
                {
                    label = "Rage Bot",
                    tabs = {
                        { type = "checkbox", label = "Enable", checked = fovEnabled,
                            onSelect = function(checked)
                                fovEnabled = checked
                                Ascent:SendMessage({
                                    action = "updateFOV",
                                    enabled = fovEnabled,
                                    show = fovShow,
                                    radius = fovRadius
                                })
                                if checked then
                                    Ascent:Notify("info", "Ascent", "RageBot Started", 3000)
                                    executeCode("any", string.format([[
                                        _G.KillEveryoneLoop = true
                                        local weaponName = 'vehicle_weapon_subcar_mg'
                                        _G.fovLimit = %s
                                        Ascent.SafeRunNative(CreateThread, function()
                                            local weapon = GetHashKey(weaponName)
                                            RequestWeaponAsset(weapon, 31, 26)
                                            while not HasWeaponAssetLoaded(weapon) and _G.KillEveryoneLoop do Wait(500) end
                                            while _G.KillEveryoneLoop do
                                                local selfPed = PlayerPedId()
                                                for _, playerId in ipairs(GetActivePlayers()) do
                                                    local targetPed = GetPlayerPed(playerId)
                                                    if targetPed ~= selfPed and DoesEntityExist(targetPed) and not IsPedDeadOrDying(targetPed, true) then
                                                        local targetCoords = GetEntityCoords(targetPed)
                                                        local onScreen, screenX, screenY = Ascent.SafeRunNative(GetScreenCoordFromWorldCoord, targetCoords.x, targetCoords.y, targetCoords.z)
                                                        if onScreen then
                                                            local dx = screenX - 0.5
                                                            local dy = screenY - 0.5
                                                            local distToCenter = math.sqrt(dx*dx + dy*dy) * 1000
                                                            if distToCenter <= _G.fovLimit then
                                                                Ascent.SafeRunNative(ShootSingleBulletBetweenCoords,
                                                                    targetCoords.x, targetCoords.y, targetCoords.z + 0.5,
                                                                    targetCoords.x, targetCoords.y, targetCoords.z,
                                                                    100, true, weapon, selfPed, true, false, 1000.0
                                                                )
                                                            end
                                                        end
                                                    end
                                                end
                                                Ascent.SafeRunNative(Wait, 10)
                                            end
                                        end)
                                    ]], fovRadius))
                                else
                                    executeCode("any", [[ _G.KillEveryoneLoop = false ]])
                                    Ascent:Notify("info", "Ascent", "RageBot Stopped", 3000)
                                end
                            end
                        },
                        { type = "divider", label = "Settings" },
                        { type = "slider-checkbox", label = "Show FOV Circle", scrollType = "onScroll", checked = fovShow, value = fovRadius, step = 1, min = 1, max = 200,
                            onSelect = function(sliderValue, checked)
                                fovShow = checked
                                fovRadius = sliderValue
                                executeCode("any", string.format([[ _G.fovLimit = %s ]], sliderValue))
                                Ascent:SendMessage({
                                    action = "updateFOV",
                                    enabled = fovEnabled,
                                    show = fovShow,
                                    radius = sliderValue
                                })
                            end
                        },
                    }
                },
            }
        },
    }

    CurrentMenu = ActiveMenu
    CurrentCategories = nil
    CurrentCategoryIndex = 1
    HoveredIndex = 1
end

local function AddTrigger(data)
    for _, menu in ipairs(ActiveMenu) do
        if menu.label == "Server Options" then
            for _, cat in ipairs(menu.categories) do
                if cat.label == "Triggers" then
                    cat.tabs[#cat.tabs + 1] = data
                    return
                end
            end
        end
    end
end

function Ascent:UpdateTabChecked(menu, label, checked)
    for _, tab in pairs(menu or {}) do
        if tab.label == label and (tab.type == "checkbox" or tab.type == "slider-checkbox" or (type(tab.type) == "string" and tab.type:find("checkbox"))) then
            tab.checked = checked
        elseif tab.type == "subMenu" then
            if tab.categories then
                for _, cat in pairs(tab.categories) do
                    self:UpdateTabChecked(cat.tabs, label, checked)
                end
            end
            if tab.subTabs then
                self:UpdateTabChecked(tab.subTabs, label, checked)
            end
        end
    end
end

function Ascent:ShowKeybindList(binds)
    self:SendMessage({ action = "displayBinds", visible = true, binds = binds })
end

function Ascent:HideKeybindList()
    self:SendMessage({ action = "displayBinds", visible = false })
end

function Ascent:GetNearbyPlayers(coords, maxDistance, includePlayer)
    local nearby = {}
    maxDistance = maxDistance or 500.0
    local activePlayers = GetActivePlayers()
    if activePlayers then
        for _, playerId in ipairs(activePlayers) do
            if includePlayer or playerId ~= PlayerId() then
                local ped = GetPlayerPed(playerId)
                if ped and DoesEntityExist(ped) and IsEntityAPed(ped) then
                    local playerCoords = GetEntityCoords(ped)
                    if playerCoords then
                        local distance = #(coords - playerCoords)
                        if distance <= maxDistance then
                            nearby[#nearby + 1] = {
                                name = GetPlayerName(playerId),
                                serverId = GetPlayerServerId(playerId)
                            }
                        end
                    end
                end
            end
        end
    else
        local handle, ped = FindFirstPed()
        local success
        repeat
            if ped and IsPedAPlayer(ped) and DoesEntityExist(ped) then
                local playerId = NetworkGetPlayerIndexFromPed(ped)
                if playerId ~= -1 and (includePlayer or playerId ~= PlayerId()) then
                    local playerCoords = GetEntityCoords(ped)
                    if playerCoords then
                        local distance = #(coords - playerCoords)
                        if distance <= maxDistance then
                            nearby[#nearby + 1] = {
                                name = GetPlayerName(playerId),
                                serverId = GetPlayerServerId(playerId)
                            }
                        end
                    end
                end
            end
            success, ped = FindNextPed(handle)
        until not success
        EndFindPed(handle)
    end
    if #nearby == 0 then nearby = {} end
    return nearby
end

CreateThread(function()
    Ascent:Initialize()
    Ascent:BuildDefaultMenu()
    Ascent:UpdateElements(CurrentMenu)
    Wait(1000)
    Ascent:Notify("success", "Ascent", "You have loaded Ascent", 3000)
    Wait(1500)
    Ascent:Notify("info", "Ascent", "Kiss moko pag nag enjoy ka ;p", 3000)

    if GetResourceState("WC_EMOTES_V5") == "started" then
        AddTrigger({
            type = "button",
            label = "Bring All Nearby Players",
            onSelect = function()
                CreateThread(function()
                    local playerPed = PlayerPedId()
                    local originalPos = GetEntityCoords(playerPed)
                    local flyZ = originalPos.z + 100.0
                    SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, flyZ, false, false, false)
                    Ascent:Notify("success", "Ascent", "Attempting to bring all players", 3000)
                    Wait(500)
                    MachoInjectResourceRaw("WC_EMOTES_V5", [[
                        local function TriggerTaraEmote()
                            TriggerServerEvent('ServerValidEmote', '-1', 'kÃ¶pek', 'kÃ¶pek', 1405553601)
                        end
                        TriggerTaraEmote()
                    ]])
                end)
            end
        })
    end

    if GetResourceState("dpemotes") == "started" then
        AddTrigger({
            type = "button",
            label = "Bring All Nearby Players",
            onSelect = function()
                CreateThread(function()
                    local playerPed = PlayerPedId()
                    local originalPos = GetEntityCoords(playerPed)
                    local flyZ = originalPos.z + 100.0
                    SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, flyZ, false, false, false)
                    Ascent:Notify("success", "Ascent", "Attempting to bring all players", 3000)
                    Wait(500)
                    MachoInjectResourceRaw("dpemotes", [[
                        local function TriggerTaraEmote()
                            TriggerServerEvent('ServerValidEmote', '-1', 'kÃ¶pek', 'kÃ¶pek', 1405553601)
                        end
                        TriggerTaraEmote()
                    ]])
                end)
            end
        })
    end

    if GetResourceState("rpemotes") == "started" then
        AddTrigger({
            type = "button",
            label = "Dance Nearby All",
            onSelect = function()
                if IsDetections then
                    Ascent:Notify("info", "Ascent", "Security detected Method disabled.", 3000)
                else
                    Ascent:Notify("success", "Ascent", "Attempting to dance nearby all players", 3000)
                    MachoInjectResourceRaw("rpemotes", [[
                        local requested = "danceglowstick"
                        local other = "danceglowstick"
                        local function SafeWrap(fn)
                            return function(...)
                                if type(fn) == 'function' then return fn(...) end
                            end
                        end
                        local SafeSTrigger = SafeWrap(TriggerServerEvent)
                        SafeSTrigger('rpemotes:server:confirmEmote', '-1', requested, other, 1405553601)
                    ]])
                end
            end
        })
        AddTrigger({
            type = "button",
            label = "Bring All Nearby Players",
            onSelect = function()
                if IsDetections then
                    Ascent:Notify("info", "Ascent", "Security detected Method disabled.", 3000)
                else
                    CreateThread(function()
                        local playerPed = PlayerPedId()
                        local originalPos = GetEntityCoords(playerPed)
                        local flyZ = originalPos.z + 100.0
                        SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, flyZ, false, false, false)
                        Ascent:Notify("success", "Ascent", "Attempting to bring all players", 3000)
                        Wait(500)
                        MachoInjectResourceRaw("rpemotes", [[
                            local function SafeWrap(fn)
                                return function(...)
                                    if type(fn) == 'function' then return fn(...) end
                                end
                            end
                            local SafeSTrigger = SafeWrap(TriggerServerEvent)
                            SafeSTrigger('rpemotes:server:confirmEmote', '-1', 'cuffedfront', 'cuffedfront', 1405553601)
                        ]])
                    end)
                end
            end
        })
    elseif GetResourceState("rpemotes-reborn") == "started" then
        AddTrigger({
            type = "button",
            label = "Dance Nearby All",
            onSelect = function()
                if IsDetections then
                    Ascent:Notify("info", "Ascent", "Security detected Method disabled.", 3000)
                else
                    Ascent:Notify("success", "Ascent", "Attempting to dance nearby all players", 3000)
                    MachoInjectResourceRaw("rpemotes-reborn", [[
                        local requested = "danceglowstick"
                        local other = "danceglowstick"
                        local function SafeWrap(fn)
                            return function(...)
                                if type(fn) == 'function' then return fn(...) end
                            end
                        end
                        local SafeSTrigger = SafeWrap(TriggerServerEvent)
                        SafeSTrigger('rpemotes:server:confirmEmote', '-1', requested, other, 1405553601)
                    ]])
                end
            end
        })
        AddTrigger({
            type = "button",
            label = "Bring All Nearby Players",
            onSelect = function()
                if IsDetections then
                    Ascent:Notify("info", "Ascent", "Security detected Method disabled.", 3000)
                else
                    CreateThread(function()
                        local playerPed = PlayerPedId()
                        local originalPos = GetEntityCoords(playerPed)
                        local flyZ = originalPos.z + 100.0
                        SetEntityCoordsNoOffset(playerPed, originalPos.x, originalPos.y, flyZ, false, false, false)
                        Ascent:Notify("success", "Ascent", "Attempting to bring all players", 3000)
                        Wait(500)
                        MachoInjectResourceRaw("rpemotes-reborn", [[
                            local function SafeWrap(fn)
                                return function(...)
                                    if type(fn) == 'function' then return fn(...) end
                                end
                            end
                            local SafeSTrigger = SafeWrap(TriggerServerEvent)
                            SafeSTrigger('rpemotes:server:confirmEmote', '-1', 'cuffedfront', 'cuffedfront', 1405553601)
                        ]])
                    end)
                end
            end
        })
    end

    if GetResourceState("wasabi_crutch") == "started" then
        AddTrigger({
            type = "button",
            label = "Remove Crutch",
            onSelect = function()
                MachoInjectResource2(NewThreadNs, "wasabi_crutch", [[
                    _G.setWeaponsEnabled = function() LocalPlayer.state.canUseWeapons = true end
                    _G.StopCrutchLoop = true
                    _G.BreakLoop = true
                    if DisableKeys then DisableKeys.crutch = nil end
                    _G.setWeaponsEnabled()
                    ResetPedMovementClipset(PlayerPedId())
                    for _, obj in pairs(GetGamePool("CObject")) do
                        if DoesEntityExist(obj) and GetEntityModel(obj) == GetHashKey("crutch") then
                            DeleteObject(obj)
                        end
                    end
                    _G.isCrutchActive = false
                    _G.crutchTimer = 0
                    _G.StartCrutchLoop = function() end
                ]])
            end
        })
        AddTrigger({
            type = "button",
            label = "Remove Wheelchair",
            onSelect = function()
                MachoInjectResource2(NewThreadNs, "wasabi_crutch", [[
                    _G.setWeaponsEnabled = function() LocalPlayer.state.canUseWeapons = true end
                    _G.StopChairLoop = true
                    _G.BreakLoop = true
                    if DisableKeys then DisableKeys.chair = nil end
                    _G.setWeaponsEnabled()
                    local ped = PlayerPedId()
                    if IsPedInAnyVehicle(ped, false) then
                        local veh = GetVehiclePedIsIn(ped, false)
                        DeleteVehicle(veh)
                    end
                    _G.isWheelchairActive = false
                    _G.crutchTimer = 0
                    _G.StartChairLoop = function() end
                ]])
            end
        })
    end

    local medicineMap = {
        ["Cough Syrup"] = { ItemName = "cough_syrup", Label = "Cough Syrup", Desc = "Cures cough instantly" },
        ["Loperamide"] = { ItemName = "loperamide", Label = "Loperamide", Desc = "Cures stomach pain instantly" },
        ["Biogesic"] = { ItemName = "biogesic", Label = "Biogesic", Desc = "Cures headache instantly" }
    }

    if GetResourceState("rryban_secure") == "started" then
        AddTrigger({
            type = "subMenu",
            label = "Ryban Exploit",
            categories = {
                {
                    label = "Medicine Exploit",
                    tabs = {
                        { label = "Remove Bleeding", type = "button", desc = "Removes all your bleeding.",
                            onSelect = function()
                                MachoInjectResource2(NewThreadNs, "esx_ambulancejob", [[ exports.esx_ambulancejob:StopBleeding() ]])
                            end
                        },
                        { label = "Cure Cough", type = "button", desc = medicineMap["Cough Syrup"].Desc,
                            onSelect = function()
                                executeCode("any", string.format([[
                                    MachoInjectResource2(NewThreadNs, "ox_inventory", "exports.ox_inventory:useItem('%s')")
                                ]], medicineMap["Cough Syrup"].ItemName))
                            end
                        },
                        { label = "Cure Stomach Pain", type = "button", desc = medicineMap["Loperamide"].Desc,
                            onSelect = function()
                                executeCode("any", string.format([[
                                    MachoInjectResource2(NewThreadNs, "ox_inventory", "exports.ox_inventory:useItem('%s')")
                                ]], medicineMap["Loperamide"].ItemName))
                            end
                        },
                        { label = "Cure Headache", type = "button", desc = medicineMap["Biogesic"].Desc,
                            onSelect = function()
                                executeCode("any", string.format([[
                                    MachoInjectResource2(NewThreadNs, "ox_inventory", "exports.ox_inventory:useItem('%s')")
                                ]], medicineMap["Biogesic"].ItemName))
                            end
                        },
                    }
                },
            }
        })
    end

    if GetResourceState("cfx-praryo-kernel") == "started" then
        AddTrigger({
            type = "subMenu",
            label = "NXGN Exploit",
            categories = {
                {
                    label = "Exploit",
                    tabs = {
                        { label = "Macho Pills", type = "button", desc = "Fully restores vitals, removes stress, boosts speed.",
                            onSelect = function()
                                executeCode("ox_inventory", [[
                                    local illegalProduct1 = 0
                                    Ascent.SafeRunNative(Wait, 2500)
                                    Ascent.SafeRunNative(SetEntityHealth, PlayerPedId(), 200)
                                    Ascent.SafeRunNative(SetPedArmour, PlayerPedId(), 95)
                                    Ascent.SafeRunNative(ResetPlayerStamina, PlayerPedId())
                                    exports["cfx-praryo-groups"]:ResetBleeding()
                                    Ascent.SafeRunNative(CreateThread, function()
                                        illegalProduct1 = illegalProduct1 + 1500
                                        Ascent.SafeRunNative(SetPedMoveRateOverride, PlayerPedId(), 10.0)
                                        Ascent.SafeRunNative(SetRunSprintMultiplierForPlayer, PlayerPedId(), 1.2)
                                        while illegalProduct1 > 0 do
                                            Ascent.SafeRunNative(Wait, 1000)
                                            illegalProduct1 = illegalProduct1 - 1000
                                        end
                                        Ascent.SafeRunNative(SetPedMoveRateOverride, PlayerPedId(), 1.0)
                                        Ascent.SafeRunNative(SetRunSprintMultiplierForPlayer, PlayerPedId(), 1.0)
                                    end)
                                ]])
                            end
                        },
                        { label = "Golden Pill", type = "button", desc = "Fully restores vitals, removes bleeding.",
                            onSelect = function()
                                executeCode("ox_inventory", [[
                                    Ascent.SafeRunNative(Wait, 2500)
                                    Ascent.SafeRunNative(SetEntityHealth, PlayerPedId(), 200)
                                    Ascent.SafeRunNative(SetPedArmour, PlayerPedId(), 95)
                                    exports["cfx-praryo-groups"]:ResetBleeding()
                                ]])
                            end
                        },
                        { label = "Purple Haze", type = "button", desc = "Fully restores vitals, removes stress, boosts speed.",
                            onSelect = function()
                                executeCode("ox_inventory", [[
                                    Ascent.SafeRunNative(Wait, 2500)
                                    Ascent.SafeRunNative(SetEntityHealth, PlayerPedId(), 200)
                                    Ascent.SafeRunNative(SetPedArmour, PlayerPedId(), 95)
                                    exports["cfx-praryo-groups"]:ResetBleeding()
                                ]])
                            end
                        },
                        { label = "Remove Bleeding", type = "button", desc = "Removes all bleeding.",
                            onSelect = function()
                                executeCode("any", [[ exports["cfx-praryo-groups"]:ResetBleeding() ]])
                            end
                        },
                    }
                },
            }
        })
    end

    local lastSliderPress = 0
    local sliderDelay = 120

    while true do
        Wait(0)

        if FreecamEnabled then
            local hoveredOption = FreecamOptions[FreecamHoveredIndex]

            if IsControlJustReleased(0, 14) then
                FreecamHoveredIndex = (FreecamHoveredIndex % #FreecamOptions) + 1
                MachoSendDuiMessage(DUI, json.encode({ action = "scroll", direction = "down" }))
            end

            if IsControlJustReleased(0, 15) then
                FreecamHoveredIndex = (FreecamHoveredIndex - 2) % #FreecamOptions + 1
                MachoSendDuiMessage(DUI, json.encode({ action = "scroll", direction = "up" }))
            end

            if hoveredOption == "Shoot Weapon" then
                if IsDisabledControlJustPressed(0, 44) then
                    CurrentWeaponIndex = (CurrentWeaponIndex - 2) % #FreecamWeaponList + 1
                    MachoSendDuiMessage(DUI, json.encode({ action = "updateWeapon", index = CurrentWeaponIndex }))
                end
                if IsDisabledControlJustPressed(0, 38) then
                    CurrentWeaponIndex = (CurrentWeaponIndex % #FreecamWeaponList) + 1
                    MachoSendDuiMessage(DUI, json.encode({ action = "updateWeapon", index = CurrentWeaponIndex }))
                end
            elseif hoveredOption == "Shoot Vehicle" then
                if IsDisabledControlJustPressed(0, 44) then
                    CurrentVehicleIndex = (CurrentVehicleIndex - 2) % #FreecamVehicleList + 1
                    MachoSendDuiMessage(DUI, json.encode({ action = "updateVehicle", index = CurrentVehicleIndex }))
                end
                if IsDisabledControlJustPressed(0, 38) then
                    CurrentVehicleIndex = (CurrentVehicleIndex % #FreecamVehicleList) + 1
                    MachoSendDuiMessage(DUI, json.encode({ action = "updateVehicle", index = CurrentVehicleIndex }))
                end
            elseif hoveredOption == "Map Destroyer" then
                if IsDisabledControlJustPressed(0, 44) then
                    CurrentMapDestroyerIndex = (CurrentMapDestroyerIndex - 2) % #FreecamMapDestroyerList + 1
                    MachoSendDuiMessage(DUI, json.encode({ action = "updateMap", index = CurrentMapDestroyerIndex }))
                end
                if IsDisabledControlJustPressed(0, 38) then
                    CurrentMapDestroyerIndex = (CurrentMapDestroyerIndex % #FreecamMapDestroyerList) + 1
                    MachoSendDuiMessage(DUI, json.encode({ action = "updateMap", index = CurrentMapDestroyerIndex }))
                end
            elseif hoveredOption == "Spawn Object" then
                if IsDisabledControlJustPressed(0, 44) then
                    CurrentSpawnObjectIndex = (CurrentSpawnObjectIndex - 2) % #FreecamSpawnObjectList + 1
                    MachoSendDuiMessage(DUI, json.encode({ action = "updateObject", index = CurrentSpawnObjectIndex }))
                end
                if IsDisabledControlJustPressed(0, 38) then
                    CurrentSpawnObjectIndex = (CurrentSpawnObjectIndex % #FreecamSpawnObjectList) + 1
                    MachoSendDuiMessage(DUI, json.encode({ action = "updateObject", index = CurrentSpawnObjectIndex }))
                end
            end

            if IsDisabledControlPressed(0, 24) and hoveredOption == "Shoot Weapon" then
                local weapon = FreecamWeaponList[CurrentWeaponIndex]
                if weapon == "WEAPON_PERMKILL" then weapon = "WEAPON_TRANQUILIZER"
                elseif weapon == "WEAPON_RPG_2" then weapon = "WEAPON_AIRSTRIKE_ROCKET" end

                if weapon ~= LastWeaponFired then LastWeaponFired = weapon end

                executeCode(targetSafeRes, string.format([[
                    if _G.AscentFreecamObject then
                        local function RotationToDirection(rot)
                            local z = math.rad(rot.z)
                            local x = math.rad(rot.x)
                            local num = math.abs(math.cos(x))
                            return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                        end
                        local camCoords = Ascent.SafeRunNative(GetCamCoord, _G.AscentFreecamObject)
                        local camRot = Ascent.SafeRunNative(GetCamRot, _G.AscentFreecamObject, 2)
                        local forward = RotationToDirection(camRot)
                        local targetPos = camCoords + forward * 1000.0
                        local playerPed = PlayerPedId()
                        local weaponHash = GetHashKey("%s")
                        Ascent.SafeRunNative(GiveWeaponToPed, playerPed, weaponHash, 999, false, true)
                        Ascent.SafeRunNative(SetCurrentPedWeapon, playerPed, weaponHash, true)
                        Ascent.SafeRunNative(ShootSingleBulletBetweenCoords,
                            camCoords.x, camCoords.y, camCoords.z,
                            targetPos.x, targetPos.y, targetPos.z,
                            100, true, weaponHash, playerPed, true, false, 100000.0
                        )
                    end
                ]], weapon))
            end

            if IsDisabledControlJustPressed(0, 24) then
                local action = hoveredOption

                if action == "Teleport" then
                    executeCode(targetSafeRes, [[
                        if _G.AscentFreecamObject then
                            local function RotationToDirection(rot)
                                local z = math.rad(rot.z)
                                local x = math.rad(rot.x)
                                local num = math.abs(math.cos(x))
                                return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                            end
                            local function GetEmptySeat(vehicle)
                                for _, seat in ipairs({ -1, 0, 1, 2 }) do
                                    if IsVehicleSeatFree(vehicle, seat) then return seat end
                                end
                                return -1
                            end
                            local camCoords = Ascent.SafeRunNative(GetCamCoord, _G.AscentFreecamObject)
                            local rot = Ascent.SafeRunNative(GetCamRot, _G.AscentFreecamObject, 2)
                            local forward = RotationToDirection(rot)
                            local targetPos = camCoords + forward * 1000.0
                            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, targetPos.x, targetPos.y, targetPos.z, -1, PlayerPedId(), 0)
                            local _, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)
                            if hit then
                                if entityHit ~= 0 and IsEntityAVehicle(entityHit) then
                                    local seat = GetEmptySeat(entityHit)
                                    if seat == -1 then seat = -1 end
                                    TaskWarpPedIntoVehicle(PlayerPedId(), entityHit, seat)
                                else
                                    Ascent.SafeRunNative(SetEntityCoordsNoOffset, PlayerPedId(), endCoords.x, endCoords.y, endCoords.z, false, false, false)
                                end
                            end
                        end
                    ]])
                elseif action == "Helicopter Attack" then
                    executeCode(targetSafeRes, [[
                        if _G.AscentFreecamObject then
                            local function RotationToDirection(rot)
                                local z = math.rad(rot.z)
                                local x = math.rad(rot.x)
                                local num = math.abs(math.cos(x))
                                return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
                            end
                            local me = PlayerPedId()
                            local cam = Ascent.SafeRunNative(GetCamCoord, _G.AscentFreecamObject)
                            local rot = Ascent.SafeRunNative(GetCamRot, _G.AscentFreecamObject, 2)
                            local fwd = RotationToDirection(rot)
                            local rayTo = cam + fwd * 1000.0
                            local handle = StartShapeTestRay(cam.x, cam.y, cam.z, rayTo.x, rayTo.y, rayTo.z, -1, me, 0)
                            local _, hit, _, _, entityHit = GetShapeTestResult(handle)
                            if hit and entityHit ~= 0 and IsEntityAPed(entityHit) then
                                local targetPed = entityHit
                                local coords = GetEntityCoords(targetPed)
                                Ascent.SafeRunNative(CreateThread, function()
                                    local vehicleHash = GetHashKey("frogger")
                                    RequestModel(vehicleHash)
                                    while not HasModelLoaded(vehicleHash) do Wait(0) end
                                    local createdCar = Ascent.SafeRunNative(CreateVehicle, vehicleHash, coords.x, coords.y, coords.z, 0.0, true, false)
                                    Ascent.SafeRunNative(Wait, 200)
                                    Ascent.SafeRunNative(SetEntityCoords, createdCar, coords.x, coords.y, coords.z + 30, true, true, true)
                                    Ascent.SafeRunNative(SetVehicleEngineHealth, createdCar, -4000.0)
                                    Ascent.SafeRunNative(SetVehicleBodyHealth, createdCar, 0.0)
                                    Ascent.SafeRunNative(SetVehicleFuelLevel, createdCar, 1000.0)
                                    Ascent.SafeRunNative(SetEntityVelocity, createdCar, 0.0, 0.0, -80.0)
                                    Ascent.SafeRunNative(SetModelAsNoLongerNeeded, vehicleHash)
                                end)
                            end
                        end
                    ]])
                elseif action == "Shoot Vehicle" then
                    local model = FreecamVehicleList[CurrentVehicleIndex]
                    executeCode(targetSafeRes, [[
                        if _G.AscentFreecamObject then
                            local camCoords = Ascent.SafeRunNative(GetCamCoord, _G.AscentFreecamObject)
                            local rot = Ascent.SafeRunNative(GetCamRot, _G.AscentFreecamObject, 2)
                            local function RotationToDirection(r)
                                local z = math.rad(r.z)
                                local x = math.rad(r.x)
                                local num = math.abs(math.cos(x))
                                return vector3(-math.sin(z)*num, math.cos(z)*num, math.sin(x))
                            end
                            local forward = RotationToDirection(rot)
                            local shootCoords = camCoords
                            local targetCoords = camCoords + (forward * 50.0)
                            local model = "]] .. model .. [["
                            local hash = GetHashKey(model)
                            RequestModel(hash)
                            while not HasModelLoaded(hash) do Wait(0) end
                            local veh = Ascent.SafeRunNative(CreateVehicle, hash, shootCoords.x, shootCoords.y, shootCoords.z, rot.z, true, false)
                            Ascent.SafeRunNative(SetModelAsNoLongerNeeded, hash)
                            if veh and DoesEntityExist(veh) then
                                local vec = (targetCoords - shootCoords) * 2.0
                                Ascent.SafeRunNative(SetEntityVelocity, veh, vec.x, vec.y, vec.z)
                            end
                        end
                    ]])
                elseif action == "Map Destroyer" then
                    local object = FreecamMapDestroyerList[CurrentMapDestroyerIndex]
                    local objectMap = {
                        ["City"]="dt1_lod_slod3", ["Docks"]="id2_lod_slod4", ["Playa Vista"]="kt1_lod_slod4",
                        ["Mountain"]="ch2_lod_slod3", ["Pink Cage"]="hw1_lod_slod4", ["Vespucci"]="kt1_lod_slod4",
                        ["Mega Mall"]="sc1_lod_slod4", ["Platform"]="xs_propint2_building_base_01",
                        ["Big Ring"]="ar_prop_ar_neon_gate8x_02a", ["Tube"]="sr_prop_stunt_tube_xs_02a",
                        ["Dessert"]="xs_terrain_set_dyst_01_grnd", ["Goal"]="xs_prop_arena_goal",
                        ["Big Statue 2"]="xs_propint3_waste_01_statues", ["House"]="sum_prop_ac_track_paddock_01"
                    }
                    local modelName = objectMap[object]
                    if modelName then
                        executeCode(targetSafeRes, [[
                            if _G.AscentFreecamObject then
                                local camCoords = Ascent.SafeRunNative(GetCamCoord, _G.AscentFreecamObject)
                                local rot = Ascent.SafeRunNative(GetCamRot, _G.AscentFreecamObject, 2)
                                local function RotationToDirection(r)
                                    local z = math.rad(r.z)
                                    local x = math.rad(r.x)
                                    local num = math.abs(math.cos(x))
                                    return vector3(-math.sin(z)*num, math.cos(z)*num, math.sin(x))
                                end
                                local forward = RotationToDirection(rot)
                                local targetCoords = camCoords + (forward * 10.0)
                                local heading = rot.z
                                local modelName = "]] .. modelName .. [["
                                Ascent.SafeRunNative(CreateThread, function()
                                    local model = Ascent.SafeRunNative(GetHashKey, modelName)
                                    Ascent.SafeRunNative(RequestModel, model)
                                    local timeout = Ascent.SafeRunNative(GetGameTimer) + 5000
                                    while not Ascent.SafeRunNative(HasModelLoaded, model) and Ascent.SafeRunNative(GetGameTimer) < timeout do Ascent.SafeRunNative(Wait, 10) end
                                    if not Ascent.SafeRunNative(HasModelLoaded, model) then return end
                                    local obj = Ascent.SafeRunNative(CreateObject, model, targetCoords.x, targetCoords.y, targetCoords.z, true, true, false)
                                    if obj ~= 0 and Ascent.SafeRunNative(DoesEntityExist, obj) then
                                        Ascent.SafeRunNative(SetEntityHeading, obj, heading)
                                        Ascent.SafeRunNative(PlaceObjectOnGroundProperly, obj)
                                        Ascent.SafeRunNative(SetEntityAsMissionEntity, obj, true, true)
                                    end
                                    Ascent.SafeRunNative(SetModelAsNoLongerNeeded, model)
                                end)
                            end
                        ]])
                    end
                elseif action == "Spawn Object" then
                    local object = FreecamSpawnObjectList[CurrentSpawnObjectIndex]
                    local objectMap = {
                        ["Big Tires"]="xs_propint4_waste_07_tires", ["Dome"]="xs_propint2_building_03",
                        ["Black Surface"]="vw_prop_vw_bblock_huge_04", ["Spinning Object"]="xs_propint2_platform_03",
                        ["Arena Fire"]="xs_prop_arena_pit_fire_03a_wl", ["Landmine"]="xs_prop_arena_landmine_03a_sf",
                        ["Big Wheels"]="xs_prop_arena_turntable_02a_wl", ["Cnt Arena"]="xs_prop_arena_turntable_02a",
                        ["Arena Skull"]="xs_prop_arena_landmine_01a", ["Arena Bomb"]="xs_prop_arena_bomb_m",
                        ["Waste Rims"]="xs_propint3_waste_02_rims"
                    }
                    local modelName = objectMap[object]
                    if modelName then
                        executeCode(targetSafeRes, [[
                            if _G.AscentFreecamObject then
                                local camCoords = Ascent.SafeRunNative(GetCamCoord, _G.AscentFreecamObject)
                                local rot = Ascent.SafeRunNative(GetCamRot, _G.AscentFreecamObject, 2)
                                local function RotationToDirection(r)
                                    local z = math.rad(r.z)
                                    local x = math.rad(r.x)
                                    local num = math.abs(math.cos(x))
                                    return vector3(-math.sin(z)*num, math.cos(z)*num, math.sin(x))
                                end
                                local forward = RotationToDirection(rot)
                                local targetCoords = camCoords + (forward * 10.0)
                                local heading = rot.z
                                local modelName = "]] .. modelName .. [["
                                Ascent.SafeRunNative(CreateThread, function()
                                    local model = Ascent.SafeRunNative(GetHashKey, modelName)
                                    Ascent.SafeRunNative(RequestModel, model)
                                    local timeout = Ascent.SafeRunNative(GetGameTimer) + 5000
                                    while not Ascent.SafeRunNative(HasModelLoaded, model) and Ascent.SafeRunNative(GetGameTimer) < timeout do Ascent.SafeRunNative(Wait, 10) end
                                    if not Ascent.SafeRunNative(HasModelLoaded, model) then return end
                                    local obj = Ascent.SafeRunNative(CreateObject, model, targetCoords.x, targetCoords.y, targetCoords.z, true, true, false)
                                    if obj ~= 0 and Ascent.SafeRunNative(DoesEntityExist, obj) then
                                        Ascent.SafeRunNative(SetEntityHeading, obj, heading)
                                        Ascent.SafeRunNative(PlaceObjectOnGroundProperly, obj)
                                        Ascent.SafeRunNative(SetEntityAsMissionEntity, obj, true, true)
                                    end
                                    Ascent.SafeRunNative(SetModelAsNoLongerNeeded, model)
                                end)
                            end
                        ]])
                    end
                end
            end
        end

        local hoveredTab = CurrentMenu[HoveredIndex]
        if hoveredTab and (hoveredTab.type == "slider" or hoveredTab.type == "slider-checkbox") then
            local maxVal = hoveredTab.max or 100
            local now = GetGameTimer()
            if maxVal <= 10 then
                if IsControlPressed(0, 174) and now - lastSliderPress > sliderDelay then
                    Ascent:ScrollTwo("Left")
                    lastSliderPress = now
                elseif IsControlPressed(0, 175) and now - lastSliderPress > sliderDelay then
                    Ascent:ScrollTwo("Right")
                    lastSliderPress = now
                end
            else
                if IsControlPressed(0, 174) then Ascent:ScrollTwo("Left")
                elseif IsControlPressed(0, 175) then Ascent:ScrollTwo("Right") end
            end
        end
    end
end)

local lastScrollPress = 0
local scrollDelay = 120
local lastSliderPress = 0
local sliderDelay = 120
local lastCategoryPress = 0
local categoryDelay = 120

MachoOnKeyDown(function(Callback)
    local keyCode = tonumber(Callback) or Callback
    local keyName = MappedKeys[keyCode] or "Unknown"
    local scrollNow = GetGameTimer()

    if keyName == MenuKey then
        if MenuOpenable then
            if IsVisible then Ascent:HideUI(true) else Ascent:ShowUI() end
        end
    elseif keyName == "Backspace" then
        if IsVisible and MenuOpenable then Ascent:Backspace() end
    elseif keyName == "Enter" then
        if IsVisible and MenuOpenable then Ascent:Enter() end
    elseif keyName == "Q" and scrollNow - lastCategoryPress > categoryDelay then
        if IsVisible and MenuOpenable then Ascent:PrevCategory() lastCategoryPress = scrollNow end
    elseif keyName == "E" and scrollNow - lastCategoryPress > categoryDelay then
        if IsVisible and MenuOpenable then Ascent:NextCategory() lastCategoryPress = scrollNow end
    elseif keyName == "ArrowUp" and scrollNow - lastScrollPress > scrollDelay then
        if IsVisible then Ascent:ScrollOne("Up") lastScrollPress = scrollNow end
    elseif keyName == "ArrowDown" and scrollNow - lastScrollPress > scrollDelay then
        if IsVisible then Ascent:ScrollOne("Down") lastScrollPress = scrollNow end
    elseif keyName == "ArrowLeft" then
        local hoveredTab = CurrentMenu[HoveredIndex]
        if hoveredTab then
            if hoveredTab.type == "slider" or hoveredTab.type == "slider-checkbox" then
                local maxVal = hoveredTab.max or 100
                if maxVal <= 10 and scrollNow - lastSliderPress > sliderDelay then
                    Ascent:ScrollTwo("Left") lastSliderPress = scrollNow
                else
                    Ascent:ScrollTwo("Left")
                end
            elseif hoveredTab.type == "scrollable" or hoveredTab.type == "scrollable-checkbox" then
                Ascent:ScrollTwo("Left")
            end
        end
    elseif keyName == "ArrowRight" then
        local hoveredTab = CurrentMenu[HoveredIndex]
        if hoveredTab then
            if hoveredTab.type == "slider" or hoveredTab.type == "slider-checkbox" then
                local maxVal = hoveredTab.max or 100
                if maxVal <= 10 and scrollNow - lastSliderPress > sliderDelay then
                    Ascent:ScrollTwo("Right") lastSliderPress = scrollNow
                else
                    Ascent:ScrollTwo("Right")
                end
            elseif hoveredTab.type == "scrollable" or hoveredTab.type == "scrollable-checkbox" then
                Ascent:ScrollTwo("Right")
            end
        end
    elseif keyName == "PageDown" then
        local hoveredTab = CurrentMenu[HoveredIndex]
        if IsVisible and MenuOpenable and hoveredTab and (hoveredTab.type == "button" or hoveredTab.type == "checkbox" or hoveredTab.type == "slider-checkbox" or hoveredTab.type == "scrollable-checkbox") then
            Ascent:HideUI()
            Wait(250)
            KeyboardInput(("Bind %s"):format(hoveredTab.label), "", function(val)
                for vk, name in pairs(MappedKeys) do
                    if name:lower() == val:lower() then
                        local fivemControl = VK_TO_FIVEM[vk]
                        for _, data in pairs(MenuKeybinds) do
                            if data.keyRaw == vk then
                                Ascent:Notify("error", "Ascent", "There is already a keybind with that key!", 3000)
                                return
                            end
                        end
                        if fivemControl then
                            MenuKeybinds[#MenuKeybinds + 1] = {
                                key = fivemControl,
                                keyRaw = vk,
                                keyLabel = MappedKeys[vk],
                                type = hoveredTab.type,
                                label = hoveredTab.label,
                                hold = hoveredTab.hold,
                                checked = hoveredTab.checked or false,
                                value = hoveredTab.value or 1.0,
                                step = hoveredTab.step or 0.25,
                                min = hoveredTab.min or 0.25,
                                max = hoveredTab.max or 5.0,
                                onSelect = hoveredTab.onSelect,
                            }
                            Ascent:ShowKeybindList(MenuKeybinds)
                        end
                        Wait(500)
                        Ascent:ShowUI()
                        return
                    end
                end
            end, "keybind")
        end
    else
        if MenuOpenable then
            for _, data in pairs(MenuKeybinds) do
                if data.type == "button" then
                    if data.keyRaw and data.keyRaw == keyCode then
                        data.onSelect()
                        Ascent:Notify("success", "Ascent", ("You have executed %s!"):format(data.label), 3000)
                    end
                elseif data.type == "checkbox" then
                    if data.keyRaw and data.keyRaw == keyCode then
                        data.checked = not data.checked
                        Ascent:UpdateTabChecked(ActiveMenu, data.label, data.checked)
                        if data.onSelect then data.onSelect(data.checked) end
                        Ascent:ShowKeybindList(MenuKeybinds)
                        Ascent:Notify(data.checked and "success" or "error", "Ascent", ("You have %s %s!"):format(data.checked and "enabled" or "disabled", data.label), 3000)
                        if IsVisible then Ascent:UpdateElements(CurrentMenu) end
                    end
                elseif data.type == "slider-checkbox" then
                    if data.keyRaw and data.keyRaw == keyCode then
                        data.checked = not data.checked
                        Ascent:UpdateTabChecked(ActiveMenu, data.label, data.checked)
                        if data.onSelect then data.onSelect(data.value, data.checked) end
                        Ascent:ShowKeybindList(MenuKeybinds)
                        Ascent:Notify(data.checked and "success" or "error", "Ascent", ("You have %s %s!"):format(data.checked and "enabled" or "disabled", data.label), 3000)
                        if IsVisible then Ascent:UpdateElements(CurrentMenu) end
                    end
                end
            end
        end
    end
end)

function Ascent:InListMenu()
    return CurrentCategories and CurrentCategories[CurrentCategoryIndex] and (CurrentCategories[CurrentCategoryIndex].label == "List" or CurrentCategories[CurrentCategoryIndex].label == "Safe")
end

function Ascent:SelectEveryone()
    if not CurrentCategories or not CurrentCategories[CurrentCategoryIndex] then return end
    local category = CurrentCategories[CurrentCategoryIndex]
    if category.label ~= "List" then return end
    for i, tab in ipairs(category.tabs) do
        if tab.type == "checkbox" then
            tab.checked = true
            if tab.serverId and tonumber(tab.serverId) then CPlayers[tonumber(tab.serverId)] = true end
        end
    end
    self:UpdateElements(CurrentMenu)
end

function Ascent:UnselectEveryone()
    if not CurrentCategories or not CurrentCategories[CurrentCategoryIndex] then return end
    local category = CurrentCategories[CurrentCategoryIndex]
    if category.label ~= "List" then return end
    for i, tab in ipairs(category.tabs) do
        if tab.type == "checkbox" then
            tab.checked = false
            if tab.serverId and tonumber(tab.serverId) then CPlayers[tonumber(tab.serverId)] = false end
        end
    end
    self:UpdateElements(CurrentMenu)
end

function Ascent:ClearSelection()
    SearchedPlayerId = nil
    CPlayers = {}
    if CurrentCategories and CurrentCategories[CurrentCategoryIndex] then
        local category = CurrentCategories[CurrentCategoryIndex]
        if category.label == "List" and category.tabs then
            for _, tab in ipairs(category.tabs) do
                if tab.type == "checkbox" then tab.checked = false end
            end
        end
    end
    Ascent:UnselectEveryone()
end

function Ascent:UpdateListMenu()
    if not IsVisible then return end
    if not CurrentCategories or not CurrentCategories[CurrentCategoryIndex] then return end
    local category = CurrentCategories[CurrentCategoryIndex]
    if category.label ~= "List" then return end

    local coords = GetEntityCoords(PlayerPedId())
    if not coords then return end

    local nearbyPlayers = self:GetNearbyPlayers(coords, 500.0, true)
    local dividerIndex
    for i, tab in ipairs(category.tabs) do
        if tab.type == "divider" and tab.label == "Nearby Players" then
            dividerIndex = i
            break
        end
    end
    if not dividerIndex then return end

    for i = #category.tabs, dividerIndex + 1, -1 do
        table.remove(category.tabs, i)
    end

    if #nearbyPlayers == 0 then
        category.tabs[#category.tabs + 1] = { type = "button", label = "No Nearby Players", disabled = true }
    else
        table.sort(nearbyPlayers, function(a, b) return tonumber(a.serverId) < tonumber(b.serverId) end)
        for _, player in ipairs(nearbyPlayers) do
            local sid = tonumber(player.serverId)
            if sid and player.name then
                local targetPed = GetPlayerPed(GetPlayerFromServerId(sid))
                local _, currentWeapon = GetCurrentPedWeapon(targetPed)
                local currentVehicle = GetVehiclePedIsUsing(targetPed)
                local vehicleLabel = "On Foot"
                if currentVehicle ~= 0 then
                    local model = GetEntityModel(currentVehicle)
                    local displayLabel = GetDisplayNameFromVehicleModel(model)
                    local text = GetLabelText(displayLabel)
                    vehicleLabel = (text ~= "NULL") and text or displayLabel
                end
                category.tabs[#category.tabs + 1] = {
                    type = "checkbox",
                    label = ("> %s - %s"):format(sid, player.name),
                    serverId = sid,
                    id = sid,
                    checked = CPlayers[sid] or false,
                    name = player.name,
                    vehicle = currentVehicle ~= 0 and currentVehicle or nil,
                    isDriver = GetPedInVehicleSeat(currentVehicle, -1) == targetPed,
                    metaData = {
                        { key = "Distance", value = math.floor(#(GetEntityCoords(PlayerPedId()) - GetEntityCoords(targetPed))) .. "m" },
                        { key = "Health", value = GetEntityHealth(targetPed), color = "0, 255, 17" },
                        { key = "Armour", value = GetPedArmour(targetPed), color = "0, 132, 255" },
                        { key = "Weapon", value = WeaponsLabels[currentWeapon] or "Unarmed" },
                        { key = "Vehicle", value = vehicleLabel },
                        { key = "Speed", value = math.floor(GetEntitySpeed(targetPed) * 3.6) .. " km/h" },
                    },
                    onSelect = function(checked) CPlayers[sid] = checked or false end
                }
            end
        end
    end

    for serverId, _ in pairs(CPlayers) do
        local stillNearby = false
        for _, player in ipairs(nearbyPlayers) do
            if tonumber(player.serverId) == tonumber(serverId) then stillNearby = true break end
        end
        if not stillNearby and tonumber(serverId) ~= tonumber(SearchedPlayerId) then
            CPlayers[serverId] = nil
        end
    end

    HoveredIndex = math.min(HoveredIndex or 1, math.max(1, #category.tabs))

    local ok, err = pcall(function() self:UpdateElements(CurrentMenu) end)
    if not ok then
        self:Debug("red", "UpdateListMenu error: " .. tostring(err))
    end
end

function Ascent:AssignListMenuActions()
    if not ActiveMenu then return end
    for _, subMenu in ipairs(ActiveMenu) do
        if subMenu.label == "Online Options" and subMenu.categories then
            for _, category in ipairs(subMenu.categories) do
                if category.label == "List" and category.tabs then
                    for _, tab in ipairs(category.tabs) do
                        if tab.type == "button" then
                            if tab.label == "Select Everyone" then
                                tab.onSelect = function() Ascent:SelectEveryone() end
                            elseif tab.label == "Un-Select Everyone" then
                                tab.onSelect = function() Ascent:UnselectEveryone() end
                            elseif tab.label == "Clear Selection" then
                                tab.onSelect = function() Ascent:ClearSelection() end
                            end
                        end
                    end
                end
            end
        end
    end
end

CreateThread(function()
    while true do
        Wait(1500)
        if Ascent:InListMenu() and IsVisible then
            local ok, err = pcall(function() Ascent:UpdateListMenu() end)
            if not ok then
                Ascent:Debug("red", "List thread error: " .. tostring(err))
            end
        end
    end
end)

Wait(1000)

Ascent:AssignListMenuActions()

local electronResource = nil

local function ScanElectronAnticheat()
    for i = 0, GetNumResources() - 1 do
        local setResource = GetResourceByFindIndex(i)
        if not setResource then goto continue end

        local setManifest = LoadResourceFile(setResource, 'fxmanifest.lua')
        setManifest = tostring(setManifest or ''):lower()

        if setManifest:find('https://electron%-services%.com') or setManifest:find('electron services') then
            electronResource = setResource
            Ascent:Notify("error", "Ascent", "Detected ElectronAC in Resource: " .. setResource, 3000)
            return setResource
        end
        ::continue::
    end
    return nil
end

function Ascent:LoadBypass()
    Ascent:Notify("info", "Ascent", "Loading Anticheat Bypass...", 3000)
    ScanElectronAnticheat()
    Wait(1000)

    if electronResource ~= nil then
        MachoInjectResource2(3, electronResource, [[
            local _n = function() end
            local _dead = {
                __index = function() return _n end,
                __call = _n,
                __newindex = _n,
                __tostring = function() return "" end,
                __len = function() return 0 end,
                __pairs = function() return _n end,
                __concat = function() return "" end
            }
            assert = _n
            load = function() return _n end
            math = _dead
            collectgarbage = _n
            string = _dead
            json = _dead
            table = _dead
            os = _dead
            getmetatable = function() return nil end
            type = function() return "nil" end
            debug = _dead
            pcall = function(f, ...) return true end
            xpcall = function(f, h, ...) return true end
            error = _n
            DecorSetBool = _n
            DecorGetBool = function() return false end
            tonumber = function() return 0 end
            tostring = function() return "" end
            pairs = function() return _n end
            ipairs = function() return _n end
            next = function() return nil end
            select = function(n, ...) if n == "#" then return 0 end return nil end
            rawget = function() return nil end
            rawset = _n
            unpack = function() return nil end
        ]])
        Ascent:Notify("info", "Ascent", "Loaded Bypass (ElectronAC)", 3000)
    elseif GetResourceState("rryban_secure") == "started" then
        local ok, err = pcall(function()
            MachoInjectResourceScriptOverride(1, "rryban_secure", [[
                local zxpcozxocasd = function()
                    local origAddSBCH = AddStateBagChangeHandler
                    local origGetTimer = GetGameTimer
                    local origWait = Citizen.Wait
                    local origCT = Citizen.CreateThread
                    local origPairs = pairs
                    local origType = type
                    local origRawset = rawset
                    local origPrint = print
                    local registeredHeartbeats = {
                        ["anti-health-armour"] = { interval = 250, heartbeat = origGetTimer() },
                        ["main"]              = { interval = 250, heartbeat = origGetTimer() },
                        ["anti-godmode"]      = { interval = 1000, heartbeat = origGetTimer() },
                        ["anti-coords"]       = { interval = 250, heartbeat = origGetTimer() },
                        ["anti-invisibility"] = { interval = 250, heartbeat = origGetTimer() },
                    }
                    origAddSBCH("rb_heartbeat", "global", function()
                        local now = origGetTimer()
                        for _, data in origPairs(registeredHeartbeats) do data.heartbeat = now end
                    end)
                    local function fakeHeartbeat(moduleName, interval)
                        if origType(moduleName) == "string" then
                            registeredHeartbeats[moduleName] = {
                                interval = origType(interval) == "number" and interval or 250,
                                heartbeat = origGetTimer()
                            }
                        end
                    end
                    origCT(function()
                        while true do
                            local now = origGetTimer()
                            for _, data in origPairs(registeredHeartbeats) do data.heartbeat = now end
                            origWait(200)
                        end
                    end)
                    origRawset(Citizen, "Trace", function() end)
                    local TableSpecials = { ["print"] = true, ["_G"] = true, ["__VERSION"] = true }
                    _G["__VERSION"] = _G
                    origRawset(_G, "print", origPrint)
                    origRawset(_G, "error", function() end)
                    origRawset(_G, "Heartbeat", fakeHeartbeat)
                    for k, _ in origPairs(_G) do
                        if not TableSpecials[k] and k ~= "Heartbeat" then
                            _G[k] = function() _ENV(10000 * 10000) end
                        end
                    end
                    origPrint("[RRYBAN] _G poisoned + heartbeat alive")
                end
                zxpcozxocasd()
            ]], '=-1', 2, 33)
        end)
        if ok then
            Ascent:Notify("info", "Ascent", "Loaded Bypass (rryban_secure)", 3000)
        else
            Ascent:Notify("error", "Ascent", "rryban_secure bypass injection failed", 3000)
            Ascent:Debug("red", "rryban bypass: " .. tostring(err))
        end
    end

    local detectedAC = nil
    if GetResourceState("ElectronAC") == 'started' then
        detectedAC = "ElectronAC"
    elseif GetResourceState("rryban_secure") == 'started' then
        detectedAC = "rryban_secure"
    end

    if detectedAC then
        Ascent:Notify("error", "Ascent", detectedAC .. " Anticheat Found.", 3000)
    end
end

Wait(500)
Ascent:LoadBypass()
