local function validVehicleFromNet(netId)
    if type(netId) ~= 'number' then
        return nil
    end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 then
        return nil
    end
    if GetEntityType(entity) ~= 2 then
        return nil
    end
    return entity
end

---@param netId number
---@param data table
---@return boolean
local function setStopState(netId, data)
    local veh = validVehicleFromNet(netId)
    if not veh then
        return false
    end
    Entity(veh).state:set('pd_interactions_stop', data, true)
    return true
end

RegisterNetEvent('pd_interactions:server:trafficStopStart', function(netId, dest)
    local src = source
    local veh = validVehicleFromNet(netId)
    if not veh then
        return
    end
    local state = Entity(veh).state
    local existing = state and state.pd_interactions_stop
    if type(existing) == 'table' and existing.active == true and existing.dismissed ~= true then
        return
    end
    local d = type(dest) == 'table' and dest or {}
    setStopState(netId, {
        active = true,
        dismissed = false,
        officer = src,
        dest = {
            x = tonumber(d.x) or 0.0,
            y = tonumber(d.y) or 0.0,
            z = tonumber(d.z) or 0.0,
            h = tonumber(d.h) or 0.0
        },
        createdAt = os.time()
    })
end)

RegisterNetEvent('pd_interactions:server:trafficStopDismiss', function(netId)
    local veh = validVehicleFromNet(netId)
    if not veh then
        return
    end
    local state = Entity(veh).state
    local existing = state and state.pd_interactions_stop
    if type(existing) ~= 'table' then
        return
    end
    existing.dismissed = true
    existing.active = false
    existing.dismissedAt = os.time()
    Entity(veh).state:set('pd_interactions_stop', existing, true)
end)


