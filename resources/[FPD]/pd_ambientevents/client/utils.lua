---@param model string|number
---@return number
local function hash(model)
    return type(model) == 'number' and model or GetHashKey(model)
end

---@param ms number
---@param fn function
local function after(ms, fn)
    CreateThread(function()
        Wait(ms)
        pcall(fn)
    end)
end

---@param model string|number
---@return boolean
local function requestModel(model)
    local h = hash(model)
    if not IsModelInCdimage(h) then return false end
    RequestModel(h)

    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(h) do
        Wait(0)
        if GetGameTimer() > deadline then
            return false
        end
    end
    return true
end

---@param model string|number
local function releaseModel(model)
    local h = hash(model)
    if IsModelInCdimage(h) then
        SetModelAsNoLongerNeeded(h)
    end
end

---@param entity number
local function ensureMission(entity)
    if not entity or entity == 0 then return end
    SetEntityAsMissionEntity(entity, true, true)
end

---@param entity number
local function safeDelete(entity)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

---@param a vector3
---@param b vector3
---@return number
local function dist(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

---@param list table
---@return table
local function weightedPick(list)
    local total = 0
    for i = 1, #list do total = total + (list[i].weight or 1) end
    if total <= 0 then return list[1] end

    local r = math.random() * total
    local acc = 0
    for i = 1, #list do
        acc = acc + (list[i].weight or 1)
        if r <= acc then return list[i] end
    end
    return list[#list]
end

---@param ped number
---@param x number
---@param y number
---@param z number
---@return boolean
local function HasClearLosToCoord(ped, x, y, z)
    local from = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
    local handle = StartShapeTestRay(from.x, from.y, from.z, x, y, z, -1, ped, 0)
  
    for _ = 1, 10 do
      local result, hit = GetShapeTestResult(handle)
      if result ~= 0 then
        return hit == 0
      end
      Wait(0)
    end
  
    return false
end

---@param coords vector3
---@return boolean
local function isZoneBlacklisted(coords)
    local zone = GetNameOfZone(coords.x, coords.y, coords.z)
    for _, z in ipairs(Config.Patrols.ZoneBlacklist) do
        if zone == z then return true end
    end
    return false
end

---@param minDist number
---@param maxDist number
---@return vector3|nil, number|nil
local function findRoadSpawnAroundPlayer(minDist, maxDist)
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) or IsEntityDead(ped) then return nil end
    if GetInteriorFromEntity(ped) ~= 0 then return nil end

    local p = GetEntityCoords(ped)

    for _ = 1, 12 do
        local ang = math.random() * (math.pi * 2)
        local d = minDist + math.random() * (maxDist - minDist)

        local cx = p.x + math.cos(ang) * d
        local cy = p.y + math.sin(ang) * d
        local cz = p.z

        local found, roadPos, roadHeading = GetClosestVehicleNodeWithHeading(cx, cy, cz, 0, 3, 0)
        if found and roadPos then
            local s = vector3(roadPos.x, roadPos.y, roadPos.z)

            if not isZoneBlacklisted(s) and not IsAnyVehicleNearPoint(s.x, s.y, s.z, 7.0) then
                if Config.Patrols.AvoidLineOfSight and HasClearLosToCoord(ped, s.x, s.y, s.z + 1.5) then
                    goto continue
                end
                return s, roadHeading
            end
        end

        ::continue::
    end

    return nil, nil
end

---@param pos vector3
---@param heading number
---@return number|nil, number|nil
local function spawnPoliceCarWithCopAt(pos, heading)
    local vehPick = weightedPick(Config.Patrols.PoliceVehicles)
    local pedModel = Config.Patrols.CopPeds[math.random(1, #Config.Patrols.CopPeds)]

    if not requestModel(vehPick.model) then return nil end
    if not requestModel(pedModel) then
        releaseModel(vehPick.model)
        return nil
    end

    local veh = CreateVehicle(hash(vehPick.model), pos.x, pos.y, pos.z, heading or 0.0, false, false)
    if not veh or veh == 0 then
        releaseModel(vehPick.model)
        releaseModel(pedModel)
        return nil
    end

    ensureMission(veh)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleHasMutedSirens(veh, true)

    local cop = CreatePedInsideVehicle(veh, 6, hash(pedModel), -1, true, false)
    if not cop or cop == 0 then
        safeDelete(veh)
        releaseModel(vehPick.model)
        releaseModel(pedModel)
        return nil
    end

    ensureMission(cop)
    SetBlockingOfNonTemporaryEvents(cop, true)
    SetPedKeepTask(cop, true)
    SetPedAsCop(cop, true)

    releaseModel(vehPick.model)
    releaseModel(pedModel)

    return veh, cop
end

---@param pos vector3
---@param heading number
---@return number|nil, number|nil
local function spawnCivilianCarWithDriverAt(pos, heading)
    local vehPick = weightedPick(Config.Events.CivilianVehicles)
    local pedModel = Config.Events.CivilianPeds[math.random(1, #Config.Events.CivilianPeds)]

    if not requestModel(vehPick.model) then return nil end
    if not requestModel(pedModel) then
        releaseModel(vehPick.model)
        return nil
    end

    local veh = CreateVehicle(hash(vehPick.model), pos.x, pos.y, pos.z, heading or 0.0, false, false)
    if not veh or veh == 0 then
        releaseModel(vehPick.model)
        releaseModel(pedModel)
        return nil
    end

    ensureMission(veh)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, true, true, false)

    local driver = CreatePedInsideVehicle(veh, 4, hash(pedModel), -1, true, false)
    if not driver or driver == 0 then
        safeDelete(veh)
        releaseModel(vehPick.model)
        releaseModel(pedModel)
        return nil
    end

    ensureMission(driver)
    SetBlockingOfNonTemporaryEvents(driver, true)
    SetPedKeepTask(driver, true)

    releaseModel(vehPick.model)
    releaseModel(pedModel)

    return veh, driver
end

---@param pos vector3
---@param heading number
---@param pedType number
---@return number|nil
local function spawnPedAt(pos, heading, pedType)
    pedType = pedType or 4
    local pedModel = Config.Events.CivilianPeds[math.random(1, #Config.Events.CivilianPeds)]

    if not requestModel(pedModel) then return nil end

    local ped = CreatePed(pedType, hash(pedModel), pos.x, pos.y, pos.z, heading or 0.0, false, false)
    if not ped or ped == 0 then
        releaseModel(pedModel)
        return nil
    end

    ensureMission(ped)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedKeepTask(ped, true)

    releaseModel(pedModel)
    return ped
end

Utils = {
    hash = hash,
    after = after,
    requestModel = requestModel,
    releaseModel = releaseModel,
    ensureMission = ensureMission,
    safeDelete = safeDelete,
    dist = dist,
    weightedPick = weightedPick,
    HasClearLosToCoord = HasClearLosToCoord,
    isZoneBlacklisted = isZoneBlacklisted,
    findRoadSpawnAroundPlayer = findRoadSpawnAroundPlayer,
    spawnPoliceCarWithCopAt = spawnPoliceCarWithCopAt,
    spawnCivilianCarWithDriverAt = spawnCivilianCarWithDriverAt,
    spawnPedAt = spawnPedAt,
}

