Config = {
    BotToken = "",
    GuildID = ""
}

DiscordAPI = {
    URL = "https://discord.com/api/v10",
    ValidToken = false
}

local httpDispatch = {}

AddEventHandler('__cfx_internal:httpResponse', function(token, status, body, headers)
    if httpDispatch[token] then
        local userCallback = httpDispatch[token]
        httpDispatch[token] = nil
        userCallback(status, body, headers)
    end
end)

local function sendHttpRequest(url, cb, method, data, headers)
    local t = {
        url = url,
        method = method or 'GET',
        data = data or '',
        headers = headers or {}
    }
    local d = json.encode(t)

    local id = PerformHttpRequestInternal(d, d:len())

    httpDispatch[id] = cb
end

local function checkToken()
    if not (Config.BotToken and Config.GuildID) then
        print("^0[^1ERROR^0] Config.BotToken or Config.GuildID is not specified or is nil")
        return false
    end

    local requestURL = ("%s/gateway/bot"):format(DiscordAPI.URL)
    local requestHeaders = {
        ['Authorization'] = ("Bot %s"):format(Config.BotToken)
    }

    sendHttpRequest(
        requestURL,
        function(sCode, response, headers)
            if sCode == 200 then
                print("^0[^2SUCCESS^0] The bot token is valid")
                DiscordAPI.ValidToken = true
            else
                print("^0[^1ERROR^0] The specified Config.BotToken is not valid or isn't working well, please change it and restart the script")
                DiscordAPI.ValidToken = false
            end
        end,
        'GET',
        '',
        requestHeaders
    )
end

local function modifyUserRole(userId, roleId, method)
    if not (DiscordAPI.ValidToken and Config.GuildID ~= "" and userId and roleId) then
        return false
    end

    local guildCheck = checkIsInGuild(userId)
    if not guildCheck then
        return false
    end

    local requestURL = ("%s/guilds/%s/members/%s/roles/%s"):format(DiscordAPI.URL, Config.GuildID, userId, roleId)
    local requestHeaders = {
        ['Authorization'] = ("Bot %s"):format(Config.BotToken)
    }

    sendHttpRequest(
        requestURL,
        function(sCode, response, headers)
            return sCode == 204
        end,
        method,
        '',
        requestHeaders
    )
end

local function giveRole(userId, roleId)
    return modifyUserRole(userId, roleId, 'PUT')
end

local function removeRole(userId, roleId)
    return modifyUserRole(userId, roleId, 'DELETE')
end

local function checkIsInGuild(userId)
    if not (DiscordAPI.ValidToken and Config.GuildID and userId) then
        return false
    end

    local requestURL = ("%s/guilds/%s/members/%s"):format(DiscordAPI.URL, Config.GuildID, userId)
    local requestHeaders = {
        ['Authorization'] = ("Bot %s"):format(Config.BotToken)
    }

    sendHttpRequest(
        requestURL,
        function(sCode, response, headers)
            if sCode == 200 then
                local responseData = json.decode(response)
                return responseData and responseData['id']
            end
        end,
        'GET',
        '',
        requestHeaders
    )
end

AddEventHandler('onResourceStart', function(rName)
    if rName and rName ~= GetCurrentResourceName() then return end
    if DiscordAPI.ValidToken == nil then
        checkToken()
    end
end)

local exportFunctions = {
    checkIsInGuild = checkIsInGuild,
    removeRole = removeRole,
    giveRole = giveRole,
    checkBotToken = checkToken
}

for exportName, exportFunction in pairs(exportFunctions) do
    exports(exportName, exportFunction)
end