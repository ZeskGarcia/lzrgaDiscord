local httpDispatch = {}

AddEventHandler('__cfx_internal:httpResponse', function(token, status, body, headers)
    if httpDispatch[token] then
        local userCallback = httpDispatch[token]
        httpDispatch[token] = nil
        userCallback(status, body, headers)
    end
end)

function httpRequest(url, cb, method, data, headers, options)
    local followLocation = true
                
    if options and options.followLocation ~= nil then followLocation = options.followLocation; end

    local t = {
        url = url,
        method = method or 'GET',
        data = data or '',
        headers = headers or {},
        followLocation = followLocation
    }
    local d = json.encode(t)

    local id = PerformHttpRequestInternal(d, d:len())

    httpDispatch[id] = cb
end

DiscordAPI = {
   URL = "https://discord.com/api/v10",
   ValidToken = nil
}

function checkToken()
   if (DiscordAPI and DiscordAPI.URL) then
      local requestURL = ("%s/gateway/bot"):format(DiscordAPI.URL)
      if (requestURL) then
         if (Config and Config.BotToken) then
            local requestHeaders = {
               ['Authorization'] = ("Bot %s"):format(Config.BotToken)
            }
            if (requestHeaders and requestHeaders['Authorization']) then
                httpRequest(
                  requestURL,
                  function(sCode, response, headers)
                     if (sCode and sCode == 200) then
                        print("^0[^2SUCCESS^0] The bot token is valid")
                        return true
                     else
                        print("^0[^1ERROR^0] The Specified Config.BotToken is not valid or isn't working well, please change it and restart the script")
                        return false
                     end
                  end,
                  'GET',
                  '',
                  requestHeaders
               )
            else
                print("^0[^1ERROR^0] Contact support to get help with this error")
                return false
            end
         else
            print("^0[^1ERROR^0] Config.BotToken is not specified or is nil")
            return false
         end
      else
            print("^0[^1ERROR^0] Internal API Error is not Specified")
            return false
      end
   else
        print("^0[^1ERROR^0] Internal Bot Token Validity Check Error")
        return false
   end
end

function giveRole(userId, roleId)
    if (DiscordAPI and DiscordAPI.ValidToken) then
        if (DiscordAPI and DiscordAPI.URL) then
            if (Config and Config.GuildID ~= "") then
                if (userId and roleId) then
                    local guildCheck = checkIsInGuild(userId)
                    if (guildCheck) then
                        local requestURL = ("%s/guilds/%s/members/%s/roles/%s"):format(DiscordAPI.URL, Config.GuildID, userId, roleId)
                        if (requestURL) then
                            local requestHeaders = {
                                ['Authorization'] = ("Bot %s"):format(Config.BotToken)
                            }

                            if (requestHeaders and requestHeaders['Authorization']) then
                                httpRequest(
                                    requestURL,
                                    function(sCode, response, headers)
                                        if (sCode and sCode == 204) then
                                            return true
                                        else
                                            return false
                                        end
                                    end,
                                    'PUT',
                                    '',
                                    requestHeaders
                                )
                            else
                                return false
                            end
                        else
                            return false
                        end
                    else
                        return false
                    end
                else
                    return false
                end
            else
                return false
            end
        else
            return false
        end
    else
        if (not DiscordAPI.ValidToken) then
            print("^0[^1ERROR^0] The specified Bot Token is not valid or isn't working")
            return false
        end
    end
end

function removeRole(userId, roleId)
    if (DiscordAPI and DiscordAPI.ValidToken) then
        if (DiscordAPI and DiscordAPI.URL) then
            if (Config and Config.GuildID ~= "") then
                if (userId and roleId) then
                    local guildCheck = checkIsInGuild(userId)
                    if (guildCheck) then
                        local requestURL = ("%s/guilds/%s/members/%s/roles/%s"):format(DiscordAPI.URL, Config.GuildID, userId, roleId)
                        if (requestURL) then
                            local requestHeaders = {
                                ['Authorization'] = ("Bot %s"):format(Config.BotToken)
                            }

                            if (requestHeaders and requestHeaders['Authorization']) then
                                httpRequest(
                                    requestURL,
                                    function(sCode, response, headers)
                                        if (sCode and sCode == 204) then
                                            return true
                                        else
                                            return false
                                        end
                                    end,
                                    'DELETE',
                                    '',
                                    requestHeaders
                                )
                            else
                                return false
                            end
                        else
                            return false
                        end
                    else
                        return false
                    end
                else
                    return false
                end
            else
                return false
            end
        else
            return false
        end
    else
        if (not DiscordAPI.ValidToken) then
            print("^0[^1ERROR^0] The specified Bot Token is not valid or isn't working")
            return false
        end
    end
end

function checkIsInGuild(userId)
    if (DiscordAPI and DiscordAPI.URL and DiscordAPI.ValidToken) then
        if (Config and Config.GuildID) then
            if (userId) then
                local requestURL = ("%s/guilds/%s/members/%s"):format(DiscordAPI.URL, Config.GuildID, userId)
                if (requestURL) then
                    local requestHeaders = {
                        ['Authorization'] = ("Bot %s"):format(Config.BotToken)
                    }
                    if (requestHeaders and requestHeaders['Authorization']) then
                        httpRequest(
                            requestURL,
                            function(sCode, response, headers)
                                if (sCode and sCode == 200) then
                                    if (response) then
                                        local responseData = json.decode(response)
                                        if (responseData and responseData['id']) then
                                            return true
                                        else
                                            return false
                                        end
                                    end
                                end
                            end,
                            'GET',
                            '',
                            requestHeaders
                        )
                    else
                        return false
                    end
                else
                    return false
                end
            else
                return false
            end
        else
            return false
        end
    else
        return false
    end
end

AddEventHandler(
   'onResourceStart',
   function(rName)
      if (rName and rName ~= GetCurrentResourceName()) then return; end
      if (DiscordAPI and DiscordAPI.ValidToken == nil) then
         local tokenCheck = checkToken()
         if (tokenCheck) then
            DiscordAPI.ValidToken = true
         else
            DiscordAPI.ValidToken = false
         end
      end
   end
)

local exportFunctions {
    ['checkIsInGuild'] = checkIsInGuild,
    ['removeRole'] = removeRole,
    ['giveRole'] = giveRole,
    ['checkBotToken'] = checkToken
}

for exportName, exportFunction in pairs(exportFunctions) do
    exports(exportName, exportFunction)
end
