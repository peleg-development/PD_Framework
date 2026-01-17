local PlayerData = require('server.playerdata')
local Callouts = require('server.callouts')

AddEventHandler('playerJoining', function()
    PlayerData.ensure(source)
end)

AddEventHandler('playerDropped', function()
    PlayerData.remove(source)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    PlayerData.flushAll()
end)

exports('GetPlayerData', function(targetSource)
    return PlayerData.get(targetSource)
end)

exports('SetPlayerData', function(targetSource, patch)
    return PlayerData.set(targetSource, patch or {})
end)

exports('CreatePlayer', function(targetSource, initialPatch)
    return PlayerData.create(targetSource, initialPatch or {})
end)

exports('LoginPlayer', function(targetSource)
    return PlayerData.login(targetSource)
end)

exports('RegisterCallout', function(def)
    return Callouts.register(def)
end)

exports('TriggerCallout', function(targetSource, calloutName, payload)
    return Callouts.trigger(targetSource, calloutName, payload)
end)

exports('GetCallouts', function()
    return Callouts.list()
end)

