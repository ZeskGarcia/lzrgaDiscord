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
                        return true
                     else
                        return false
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
            return 'Config.BotToken is not specified or is nil'
         end
      else
         return 'Internal API Error is not Specified'
      end
   else
      return 'Internal Bot Token Validity Check Error'
   end
end

AddEventHandler(
   'onResourceStart',
   function(rName)
      if (rName and rName ~= GetCurrentResourceName()) then return; end
      if (DiscordAPI and DiscordAPI.ValidToken == nil) then
         local tokenCheck = checkToken()
         if (type(tokenCheck) == "string" or not tokenCheck) then
            DiscordAPI.ValidToken = false
         elseif (tokenCheck) then
            DiscordAPI.ValidToken = true
         end
      end
   end
)
