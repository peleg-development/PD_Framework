local Target = {}

---@param entity number
---@param maxDist number
---@return boolean
local function isValidPed(entity, maxDist)
    if type(entity) ~= 'number' or entity == 0 then
        return false
    end
    if not DoesEntityExist(entity) then
        return false
    end
    if GetEntityType(entity) ~= 1 then
        return false
    end
    if IsPedAPlayer(entity) then
        return false
    end
    if IsEntityDead(entity) then
        return false
    end
    if type(maxDist) == 'number' then
        local p = PlayerPedId()
        local pc = GetEntityCoords(p)
        local ec = GetEntityCoords(entity)
        if #(pc - ec) > maxDist then
            return false
        end
    end
    return true
end

---@param entity number
---@param maxDist number
---@return boolean
local function isValidVehicle(entity, maxDist)
    if type(entity) ~= 'number' or entity == 0 then
        return false
    end
    if not DoesEntityExist(entity) then
        return false
    end
    if GetEntityType(entity) ~= 2 then
        return false
    end
    if type(maxDist) == 'number' then
        local p = PlayerPedId()
        local pc = GetEntityCoords(p)
        local ec = GetEntityCoords(entity)
        if #(pc - ec) > maxDist then
            return false
        end
    end
    return true
end

---@param maxDist number
---@return number|nil
function Target.getAimedPed(maxDist)
    local ok, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if not ok then
        return nil
    end
    if isValidPed(entity, maxDist) then
        return entity
    end
    return nil
end

---@param maxDist number
---@return number|nil
function Target.getAimedVehicle(maxDist)
    local ok, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if not ok then
        return nil
    end
    if isValidVehicle(entity, maxDist) then
        return entity
    end
    return nil
end

---@param maxDist number
---@return number|nil
function Target.getClosestPed(maxDist)
    local p = PlayerPedId()
    local pc = GetEntityCoords(p)
    local best = nil
    local bestDist = type(maxDist) == 'number' and maxDist or 5.0
    local pool = GetGamePool('CPed')
    for _, ped in ipairs(pool) do
        if isValidPed(ped, bestDist) then
            local ec = GetEntityCoords(ped)
            local d = #(pc - ec)
            if d < bestDist then
                bestDist = d
                best = ped
            end
        end
    end
    return best
end

---@param maxDist number
---@return number|nil
function Target.getClosestVehicle(maxDist)
    local p = PlayerPedId()
    local pc = GetEntityCoords(p)
    local best = nil
    local bestDist = type(maxDist) == 'number' and maxDist or 6.0
    local pool = GetGamePool('CVehicle')
    for _, veh in ipairs(pool) do
        if isValidVehicle(veh, bestDist) then
            local ec = GetEntityCoords(veh)
            local d = #(pc - ec)
            if d < bestDist then
                bestDist = d
                best = veh
            end
        end
    end
    return best
end

---@param maxDist number
---@return number|nil
function Target.getTargetPed(maxDist)
    local aimed = Target.getAimedPed(maxDist)
    if aimed then
        return aimed
    end
    return Target.getClosestPed(maxDist)
end

---@param maxDist number
---@return number|nil
function Target.getTargetVehicle(maxDist)
    local aimed = Target.getAimedVehicle(maxDist)
    if aimed then
        return aimed
    end
    return Target.getClosestVehicle(maxDist)
end

return Target


