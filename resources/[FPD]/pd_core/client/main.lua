local PlayerData = require('client.playerdata')

exports('GetLocalPlayerData', function()
    return PlayerData.get()
end)

