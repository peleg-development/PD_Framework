local Config = require 'config'

---@class PDClientOffer
---@field id string
---@field callout table
---@field location vector3
---@field expiresAt number
---@field blip number|nil

local Offer = nil

local function nowMs()
    return GetGameTimer()
end

---@param offer PDClientOffer|nil
local function setOffer(offer)
    Offer = offer
end

local function clearBlip()
    if Offer and Offer.blip and DoesBlipExist(Offer.blip) then
        RemoveBlip(Offer.blip)
    end
end

local function hideUi()
    SendNUIMessage({ type = 'hide' })
end

local function showUi(payload)
    SendNUIMessage(payload)
end

---@param coords vector3
---@return number
local function createCalloutBlip(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 1.0)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Callout')
    EndTextCommandSetBlipName(blip)
    return blip
end

local function clearOffer()
    clearBlip()
    hideUi()
    setOffer(nil)
end

RegisterNetEvent('pd_callouts_manager:client:offer', function(data)
    if Offer then
        clearOffer()
    end
    local loc = vector3(data.location.x, data.location.y, data.location.z)
    local offer = {
        id = data.id,
        callout = data.callout,
        location = loc,
        expiresAt = nowMs() + (data.timeoutMs or Config.offerTimeoutMs),
        blip = nil
    }
    offer.blip = createCalloutBlip(loc)
    setOffer(offer)
    PDLib.debug('pd_callouts_manager', 'offer received %s (%s)', offer.id, offer.callout and offer.callout.name or 'unknown')
    SetNuiFocus(false, false)
    showUi({
        type = 'offer',
        id = offer.id,
        callout = offer.callout,
        distance = data.distance,
        timeoutMs = data.timeoutMs or Config.offerTimeoutMs
    })
end)

RegisterNetEvent('pd_callouts_manager:client:clear', function(offerId)
    if not Offer then
        return
    end
    if Offer.id ~= offerId then
        return
    end
    PDLib.debug('pd_callouts_manager', 'offer cleared %s', offerId)
    clearOffer()
end)

CreateThread(function()
    while true do
        if not Offer then
            Wait(500)
            goto continue
        end
        if Offer.expiresAt <= nowMs() then
            clearOffer()
            Wait(500)
            goto continue
        end
        if IsControlJustReleased(0, 246) then
            PDLib.debug('pd_callouts_manager', 'offer accept key %s', Offer.id)
            TriggerServerEvent('pd_callouts_manager:server:accept', Offer.id)
            clearOffer()
            Wait(250)
            goto continue
        end
        Wait(0)
        ::continue::
    end
end)


