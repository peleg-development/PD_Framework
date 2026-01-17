local function ensureVec3(payload)
    if payload and payload.location and type(payload.location) == 'vector3' then
        return payload.location
    end
    return GetEntityCoords(PlayerPedId())
end

local function createCalloutBlip(coords, code, title)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 3)
    SetBlipScale(blip, 1.0)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(('%s %s'):format(code or '', title or 'Callout'))
    EndTextCommandSetBlipName(blip)
    return blip
end

RegisterNetEvent('pd_callouts:client:start', function(payload, calloutName)
    local loc = ensureVec3(payload)
    local info = payload and payload.callout or {}
    local code = info.code or 'CALL'
    local title = info.title or (calloutName or 'callout')

    PDLib.debug('pd_callouts', 'start %s', tostring(calloutName))

    local blip = createCalloutBlip(loc, code, title)
    SetNewWaypoint(loc.x, loc.y)

    CreateThread(function()
        Wait(600000)
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)


