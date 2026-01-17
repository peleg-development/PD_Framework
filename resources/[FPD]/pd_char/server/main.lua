local Config = require('config')
local Characters = require('server.characters')
local DB = require('server.db')
local Utils = require('@pd_core/shared.utils')

CreateThread(function()
    Wait(1000)
    DB.init()
end)

---@param source number
local function onPlayerLoaded(source)
    Wait(2000)
    local allChars = Characters.getAll(Utils.getIdentifier(source) or '')
    TriggerClientEvent('pd_char:client:openSelection', source, allChars)
end

AddEventHandler('pd_core:server:playerLoaded', function(source)
    onPlayerLoaded(source)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    CreateThread(function()
        Wait(3000)
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            local source = tonumber(playerId)
            if source then
                local identifier = Utils.getIdentifier(source)
                if identifier then
                    local allChars = Characters.getAll(identifier)
                    TriggerClientEvent('pd_char:client:openSelection', source, allChars)
                end
            end
        end
    end)
end)

RegisterNetEvent('pd_char:server:requestCharacters', function()
    local source = source
    local identifier = Utils.getIdentifier(source)
    if not identifier then
        return
    end
    local allChars = Characters.getAll(identifier)
    TriggerClientEvent('pd_char:client:receiveCharacters', source, allChars)
end)

RegisterNetEvent('pd_char:server:createCharacter', function(slot, data)
    local source = source
    local character = Characters.create(source, slot, data)
    if character then
        local allChars = Characters.getAll(Utils.getIdentifier(source) or '')
        TriggerClientEvent('pd_char:client:receiveCharacters', source, allChars)
        TriggerClientEvent('pd_char:client:characterCreated', source, character)
    else
        TriggerClientEvent('pd_char:client:characterCreateFailed', source)
    end
end)

RegisterNetEvent('pd_char:server:selectCharacter', function(slot)
    local source = source
    local success = Characters.select(source, slot)
    if success then
        TriggerClientEvent('pd_char:client:openSpawnSelector', source, Config.spawnLocations)
    else
        TriggerClientEvent('pd_char:client:characterSelectFailed', source)
    end
end)

RegisterNetEvent('pd_char:server:requestSpawnLocations', function()
    local source = source
    TriggerClientEvent('pd_char:client:receiveSpawnLocations', source, Config.spawnLocations)
end)

RegisterNetEvent('pd_char:server:selectSpawn', function(spawnIndex)
    local source = source
    local index = tonumber(spawnIndex)
    if not index or index < 0 or index >= #Config.spawnLocations then
        return
    end
    
    local luaIndex = index + 1
    local spawn = Config.spawnLocations[luaIndex]
    if not spawn then
        return
    end
    
    local ped = GetPlayerPed(source)
    if ped and ped ~= 0 then
        FreezeEntityPosition(ped, false)
        
        SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, true)
        Wait(200)
        SetEntityHeading(ped, spawn.heading)
        
        Wait(100)
        FreezeEntityPosition(ped, false)
    end
    
    TriggerClientEvent('pd_char:client:closeUI', source)
    TriggerEvent('pd_char:server:characterSpawned', source)
end)

RegisterNetEvent('pd_char:server:requestSpawnLocations', function()
    local source = source
    TriggerClientEvent('pd_char:client:receiveSpawnLocations', source, Config.spawnLocations)
end)

RegisterNetEvent('pd_char:server:deleteCharacter', function(slot)
    local source = source
    local success = Characters.delete(source, slot)
    if success then
        local allChars = Characters.getAll(Utils.getIdentifier(source) or '')
        TriggerClientEvent('pd_char:client:receiveCharacters', source, allChars)
    end
end)

RegisterNetEvent('pd_char:server:updateAppearance', function(slot, appearance)
    local source = source
    local character = Characters.update(source, slot, { appearance = appearance })
    if character then
        TriggerClientEvent('pd_char:client:appearanceUpdated', source, character)
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    Characters.remove(source)
end)

exports('GetCharacters', function(source)
    local identifier = Utils.getIdentifier(source)
    if not identifier then
        return {}
    end
    return Characters.getAll(identifier)
end)

exports('GetActiveCharacter', function(source)
    return Characters.getActive(source)
end)

exports('SelectCharacter', function(source, slot)
    return Characters.select(source, slot)
end)

exports('CreateCharacter', function(source, slot, data)
    return Characters.create(source, slot, data)
end)
