local Config = require('config')
local Outfits = require('server.outfits')

---@param source number
---@return table|nil
local function getActiveCharacter(source)
    local character = exports.pd_char:GetActiveCharacter(source)
    return character
end

---@param source number
---@param appearance table
---@return boolean
local function updateCharacterAppearance(source, appearance)
    local character = getActiveCharacter(source)
    if not character then
        return false
    end
    
    TriggerEvent('pd_char:server:updateAppearance', source, character.slot, appearance)
    return true
end

RegisterCommand(Config.command, function(source, args, rawCommand)
    local character = getActiveCharacter(source)
    if not character then
        TriggerClientEvent('chat:addMessage', source, {
            color = { 255, 0, 0 },
            multiline = true,
            args = { 'Clothing', 'You must have an active character to use the clothing menu.' }
        })
        return
    end
    
    local outfits = Outfits.getAll()
    local appearance = character.appearance or {}
    
    TriggerClientEvent('pd_clothing:client:openMenu', source, {
        appearance = appearance,
        outfits = outfits
    })
end, false)

RegisterNetEvent('pd_clothing:server:requestData', function()
    local source = source
    local character = getActiveCharacter(source)
    if not character then
        return
    end
    
    local outfits = Outfits.getAll()
    local appearance = character.appearance or {}
    
    TriggerClientEvent('pd_clothing:client:receiveData', source, {
        appearance = appearance,
        outfits = outfits
    })
end)

RegisterNetEvent('pd_clothing:server:saveAppearance', function(appearance)
    local source = source
    if type(appearance) ~= 'table' then
        return
    end
    
    local character = getActiveCharacter(source)
    if not character then
        TriggerClientEvent('pd_clothing:client:appearanceSaveFailed', source)
        return
    end
    
    TriggerEvent('pd_char:server:updateAppearance', source, character.slot, appearance)
    TriggerClientEvent('pd_clothing:client:appearanceSaved', source)
end)


