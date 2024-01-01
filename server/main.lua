DiscordAPI = {
   URL = "https://discord.com/api/v10/"
}

function checkToken()
    if (DiscordAPI and DiscordAPI.URL) then
       local requestURL = ("%s/gateway/bot"):format(DiscordAPI.URL)
       if (Config and Config.BotToken) then
          local requestHeaders = {
             ['Authorization'] = ('Bot %s'):format(Config.BotToken)
          }
          httpRequest(
             requestURL,
             function(err, response, headers)

             end,
             'GET',
             '',
             requestHeaders
          )
       else
         
       end
    end
end
