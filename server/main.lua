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
    local requestData = {
        url = url,
        method = method or 'GET',
        data = data or '',
        headers = headers or {}
    }
    local requestDataString = json.encode(requestData)
    local requestId = PerformHttpRequestInternal(requestDataString, requestDataString:len())
    httpDispatch[requestId] = cb
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
        function(statusCode, response, headers)
            if statusCode == 200 then
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

    if not checkIsInGuild(userId) then
        return false
    end

    local hasRole = checkUserHasRole(userId, roleId)

    if (method == 'PUT' and not hasRole) or (method == 'DELETE' and hasRole) then
        return sendRoleRequest(userId, roleId, method)
    else
        return true
    end
end

local function sendRoleRequest(userId, roleId, method)
    local requestURL = ("%s/guilds/%s/members/%s/roles/%s"):format(DiscordAPI.URL, Config.GuildID, userId, roleId)
    local requestHeaders = {
        ['Authorization'] = ("Bot %s"):format(Config.BotToken)
    }

    sendHttpRequest(
        requestURL,
        function(statusCode, response, headers)
            return statusCode == 204
        end,
        method,
        '',
        requestHeaders
    )
end

local function checkUserHasRole(userId, roleId)
    if not (DiscordAPI.ValidToken and Config.GuildID and userId and roleId) then
        return false
    end

    local requestURL = ("%s/guilds/%s/members/%s"):format(DiscordAPI.URL, Config.GuildID, userId)
    local requestHeaders = {
        ['Authorization'] = ("Bot %s"):format(Config.BotToken)
    }

    local hasRole = false

    sendHttpRequest(
        requestURL,
        function(statusCode, response, headers)
            if statusCode == 200 then
                local responseData = json.decode(response)
                if responseData and responseData.roles then
                    hasRole = hasRoleInRoles(roleId, responseData.roles)
                end
            end
        end,
        'GET',
        '',
        requestHeaders
    )

    return hasRole
end

local function hasRoleInRoles(roleId, roles)
    for _, role in ipairs(roles) do
        if role == roleId then
            return true
        end
    end
    return false
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
        function(statusCode, response, headers)
            return statusCode == 200
        end,
        'GET',
        '',
        requestHeaders
    )
end

local function getUserData(userId)
    if not (DiscordAPI.ValidToken and Config.GuildID and userId) then
        return {}
    end

    local requestURL = ("%s/guilds/%s/members/%s"):format(DiscordAPI.URL, Config.GuildID, userId)
    local requestHeaders = {
        ['Authorization'] = ("Bot %s"):format(Config.BotToken)
    }

    local userData = {}

    sendHttpRequest(
        requestURL,
        function(statusCode, response, headers)
            if statusCode == 200 then
                userData = json.decode(response)
            end
        end,
        'GET',
        '',
        requestHeaders
    )

    return userData
end

local function getUserAvatar(userId)
    local userData = getUserData(userId)
    return {
        id = userData.avatar,
        avatarURL = ("https://cdn.discordapp.com/avatars/%s/%s.png"):format(userId, userData.avatar)
    }
end

local function getUserBio(userId)
    local userData = getUserData(userId)
    return userData.bio
end

local function getUserStatus(userId)
    local userData = getUserData(userId)
    return userData.status
end

AddEventHandler('onResourceStart', function(rName)
    if rName and rName ~= GetCurrentResourceName() then return end
    if DiscordAPI.ValidToken == nil then
        checkToken()
    end
end)

local function getUserRoles(userId)
    if not (DiscordAPI.ValidToken and Config.GuildID and userId) then
        return {}
    end

    local requestURL = ("%s/guilds/%s/members/%s"):format(DiscordAPI.URL, Config.GuildID, userId)
    local requestHeaders = {
        ['Authorization'] = ("Bot %s"):format(Config.BotToken)
    }

    local userRoles = {}

    sendHttpRequest(
        requestURL,
        function(sCode, response, headers)
            if sCode == 200 then
                local responseData = json.decode(response)
                if responseData and responseData.roles then
                    userRoles = responseData.roles
                end
            end
        end,
        'GET',
        '',
        requestHeaders
    )

    return userRoles
end

local exportFunctions = {
    checkIsInGuild = checkIsInGuild,
    removeRole = removeRole,
    giveRole = giveRole,
    checkBotToken = checkToken,
    checkUserHasRole = checkUserHasRole,
    getUserRoles = getUserRoles,
    getUserAvatar = getUserAvatar,
    getUserData = getUserData,
    getUserStatus = getUserStatus,
    getUserBio = getUserBio
}

for exportName, exportFunction in pairs(exportFunctions) do
    exports(exportName, exportFunction)
end
