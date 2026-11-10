local AscentConfig1337 = {
    Name    = "Ascent",
    OwnerID = "NYERJoti0k",
    Secret  = "5c358e20c72f883d742b52cc96c7721b3071e8f8cc4fdad4195582e08a39f71e",
    Version = "1.0",
}

local USER_LICENSE = _G.AscentLicense or "YOUR_KEY_HERE"
local ASCENT_RAW_URL = "https://tuswrld.xyz/ascent/ascent.lua"
local ASCENT_SCRIPT_HASH = ""

local function log(color, msg)
    print(string.format("^%s[ASCENT][Loader] %s", color, tostring(msg)))
end

local function isExecutorReady()
    if type(MachoWebRequest) ~= "function" then
        log("1", "Executor missing MachoWebRequest. Update Macho Executor.")
        return false
    end
    if type(MachoAuthenticationKey) ~= "function" then
        log("1", "Executor missing MachoAuthenticationKey. Update Macho Executor.")
        return false
    end
    return true
end

local function httpGet(url)
    local ok, res = pcall(MachoWebRequest, url)
    if not ok then
        log("1", "Request failed: " .. tostring(res))
        return nil
    end
    if type(res) ~= "string" or res == "" then
        log("1", "Empty response from server.")
        return nil
    end
    return res
end

local function urlEncode(str)
    if not str then return "" end
    return (string.gsub(tostring(str), "([^%w%-_.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

local function extractJsonString(body, field)
    return body:match('"' .. field .. '"%s*:%s*"([^"]*)"')
end

local function isSuccess(body)
    return body:match('"success"%s*:%s*true') ~= nil
end

local function sha256(str)
    if type(crypt) == "table" and type(crypt.hash) == "function" then
        local ok, hash = pcall(crypt.hash, str, "sha256")
        if ok then return hash end
    end
    if type(sha256) == "function" then
        local ok, hash = pcall(sha256, str)
        if ok then return hash end
    end
    return nil
end

local function LoadAscent()
    if not isExecutorReady() then return end

    if AscentConfig1337.OwnerID == "YOUR_OWNER_ID" or AscentConfig1337.OwnerID == "" then
        log("1", "Setup required: set AscentConfig1337.OwnerID.")
        return
    end

    if USER_LICENSE == "" or USER_LICENSE == "YOUR_KEY_HERE" then
        log("1", "No license key provided.")
        return
    end

    log("3", "Verifying license with KeyAuth...")

    local initUrl = string.format(
        "https://keyauth.win/api/1.2/?type=init&name=%s&ownerid=%s&ver=%s",
        urlEncode(AscentConfig1337.Name),
        urlEncode(AscentConfig1337.OwnerID),
        urlEncode(AscentConfig1337.Version)
    )

    local initRes = httpGet(initUrl)
    if not initRes then return end

    if not isSuccess(initRes) then
        local msg = extractJsonString(initRes, "message") or "Init failed"
        log("1", "KeyAuth init error: " .. msg)
        return
    end

    local sessionId = extractJsonString(initRes, "sessionid")
    if not sessionId or sessionId == "" then
        log("1", "KeyAuth init failed: no session ID returned.")
        return
    end

    local userHWID
    local hwidOk, hwidResult = pcall(MachoAuthenticationKey)
    if hwidOk and hwidResult then
        userHWID = tostring(hwidResult)
        if #userHWID < 20 then
            userHWID = userHWID .. string.rep("_", 20 - #userHWID)
        end
    else
        log("1", "Failed to obtain HWID from executor.")
        return
    end

    local authUrl = string.format(
        "https://keyauth.win/api/1.2/?type=license&key=%s&hwid=%s&sessionid=%s&name=%s&ownerid=%s",
        urlEncode(USER_LICENSE),
        urlEncode(userHWID),
        urlEncode(sessionId),
        urlEncode(AscentConfig1337.Name),
        urlEncode(AscentConfig1337.OwnerID)
    )

    local authRes = httpGet(authUrl)
    if not authRes then return end

    if not isSuccess(authRes) then
        local msg = extractJsonString(authRes, "message") or "Invalid or expired key"
        log("1", "Access Denied: " .. msg)
        return
    end

    local infoUser = extractJsonString(authRes, "username") or USER_LICENSE:sub(1, 10) .. "..."
    local expiryTimestamp = authRes:match('"expiry"%s*:%s*([0-9]+)') or authRes:match('"expiry"%s*:%s*"([0-9]+)"')
    local formattedExpiry = "Lifetime"

    if expiryTimestamp then
        local expNum = tonumber(expiryTimestamp)
        if expNum and expNum > 0 then
            local now = (type(GetCloudTimeAsInt) == "function" and GetCloudTimeAsInt()) or (type(os) == "table" and type(os.time) == "function" and os.time()) or 0
            local diff = (now > 0) and (expNum - now) or 0
            if now > 0 and diff > 0 then
                local days = math.floor(diff / 86400)
                local hours = math.floor((diff % 86400) / 3600)
                local minutes = math.floor((diff % 3600) / 60)
                if days > 0 then
                    formattedExpiry = string.format("%d days, %dh remaining", days, hours)
                elseif hours > 0 then
                    formattedExpiry = string.format("%dh %dm remaining", hours, minutes)
                else
                    formattedExpiry = string.format("%d minutes remaining", minutes)
                end
            elseif now > 0 and diff <= 0 then
                formattedExpiry = "Expired"
            else
                formattedExpiry = "Active"
            end
        end
    end

    _G.AscentLicense = USER_LICENSE
    _G.AscentUser = infoUser
    _G.AscentExpires = formattedExpiry
    _G.AscentRawExpiry = expiryTimestamp

    log("2", string.format("Key Verified! User: %s | Expiry: %s", tostring(infoUser), tostring(formattedExpiry)))
    log("2", "Loading script...")

    local scriptCode = httpGet(ASCENT_RAW_URL)
    if not scriptCode then return end

    if ASCENT_SCRIPT_HASH ~= "" then
        local actualHash = sha256(scriptCode)
        if not actualHash then
            log("1", "No hashing function available. Cannot verify script integrity.")
            return
        end
        if actualHash:lower() ~= ASCENT_SCRIPT_HASH:lower() then
            log("1", "Script integrity check failed. Aborting.")
            return
        end
    end

    local compileFunc = (type(loadstring) == "function" and loadstring) or load
    local chunk, loadErr = compileFunc(scriptCode, "@Ascent")
    if not chunk then
        log("1", "Script compile error: " .. tostring(loadErr))
        return
    end

    _G.AscentLicense = USER_LICENSE
    local runOk, runErr = pcall(chunk)
    if not runOk then
        log("1", "Runtime error: " .. tostring(runErr))
        return
    end

    log("2", "Ascent loaded successfully.")
end

LoadAscent()
