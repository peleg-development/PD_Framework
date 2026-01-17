local Custody = {}

local cuffed = {}
local kneeling = {}
local transportRequested = {}

---@param entity number
---@param timeoutMs number|nil
---@return boolean
local function requestControl(entity, timeoutMs)
    if type(entity) ~= 'number' or entity == 0 or not DoesEntityExist(entity) then
        return false
    end
    if NetworkHasControlOfEntity(entity) then
        return true
    end
    NetworkRequestControlOfEntity(entity)
    local t = GetGameTimer() + (type(timeoutMs) == 'number' and timeoutMs or 900)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < t do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end
    return NetworkHasControlOfEntity(entity)
end

---@param dict string
---@param timeoutMs number|nil
---@return boolean
local function loadAnimDict(dict, timeoutMs)
    if type(dict) ~= 'string' or dict == '' then
        return false
    end
    RequestAnimDict(dict)
    local t = GetGameTimer() + (type(timeoutMs) == 'number' and timeoutMs or 1500)
    while not HasAnimDictLoaded(dict) and GetGameTimer() < t do
        Wait(0)
    end
    return HasAnimDictLoaded(dict)
end

---@param hash number
---@param timeoutMs number|nil
---@return boolean
local function loadModel(hash, timeoutMs)
    if type(hash) ~= 'number' then
        return false
    end
    if not IsModelInCdimage(hash) then
        return false
    end
    RequestModel(hash)
    local t = GetGameTimer() + (type(timeoutMs) == 'number' and timeoutMs or 5000)
    while not HasModelLoaded(hash) and GetGameTimer() < t do
        Wait(0)
    end
    return HasModelLoaded(hash)
end

---@param ped number
---@return boolean
function Custody.isCuffed(ped)
    return cuffed[ped] == true
end

---@param ped number
---@return boolean
function Custody.isKneeling(ped)
    return kneeling[ped] == true
end

---@param ped number
---@return boolean
function Custody.isTransportRequested(ped)
    return transportRequested[ped] == true
end

---@param ped number
---@return boolean
function Custody.orderExitVehicle(ped)
    if type(ped) ~= 'number' or ped == 0 or not DoesEntityExist(ped) then
        return false
    end
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or not DoesEntityExist(veh) then
        return false
    end
    requestControl(ped, 900)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskLeaveVehicle(ped, veh, 0)
    CreateThread(function()
        local target = ped
        local tVeh = veh
        local timeout = GetGameTimer() + 9000
        while DoesEntityExist(target) and IsPedInAnyVehicle(target, false) and GetGameTimer() < timeout do
            Wait(150)
        end
        if not DoesEntityExist(target) then
            return
        end
        if IsPedInAnyVehicle(target, false) then
            return
        end
        requestControl(target, 900)
        ClearPedTasks(target)
        TaskStandStill(target, -1)
    end)
    return true
end

---@param ped number
---@return boolean
local function applyCuffs(ped)
    if type(ped) ~= 'number' or ped == 0 or not DoesEntityExist(ped) then
        return false
    end
    requestControl(ped, 900)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    SetPedCanRagdoll(ped, false)
    SetEnableHandcuffs(ped, true)
    SetPedCanPlayGestureAnims(ped, false)
    TaskStandStill(ped, -1)
    return true
end

---@param ped number
---@return boolean
local function clearCuffs(ped)
    if type(ped) ~= 'number' or ped == 0 or not DoesEntityExist(ped) then
        return false
    end
    requestControl(ped, 900)
    SetEnableHandcuffs(ped, false)
    SetPedCanPlayGestureAnims(ped, true)
    SetPedCanRagdoll(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, false)
    ClearPedTasks(ped)
    return true
end

---@param ped number
---@return boolean
function Custody.arrest(ped)
    if type(ped) ~= 'number' or ped == 0 or not DoesEntityExist(ped) then
        return false
    end
    if Custody.isCuffed(ped) then
        return true
    end
    if IsPedInAnyVehicle(ped, false) then
        return false
    end
    local player = PlayerPedId()
    local dict = 'mp_arrest_paired'
    local copAnim = 'cop_p2_back_right'
    local crookAnim = 'crook_p2_back_right'
    if not loadAnimDict(dict, 2000) then
        return false
    end
    requestControl(ped, 900)
    TaskTurnPedToFaceEntity(ped, player, 750)
    TaskPlayAnim(player, dict, copAnim, 8.0, -8.0, 4500, 48, 0.0, false, false, false)
    TaskPlayAnim(ped, dict, crookAnim, 8.0, -8.0, 4500, 48, 0.0, false, false, false)

    local ok = lib.progressBar({
        label = 'Cuffing suspect...',
        duration = 4500,
        canCancel = true
    })
    if not ok then
        ClearPedTasks(player)
        ClearPedTasks(ped)
        return false
    end
    applyCuffs(ped)
    cuffed[ped] = true
    kneeling[ped] = nil
    transportRequested[ped] = nil
    return true
end

---@param ped number
---@return boolean
function Custody.uncuff(ped)
    if type(ped) ~= 'number' or ped == 0 or not DoesEntityExist(ped) then
        return false
    end
    if not Custody.isCuffed(ped) then
        return true
    end
    clearCuffs(ped)
    cuffed[ped] = nil
    kneeling[ped] = nil
    transportRequested[ped] = nil
    return true
end

---@param ped number
---@return boolean
function Custody.toggleKneel(ped)
    if type(ped) ~= 'number' or ped == 0 or not DoesEntityExist(ped) then
        return false
    end
    if not Custody.isCuffed(ped) then
        return false
    end
    requestControl(ped, 900)
    if kneeling[ped] then
        kneeling[ped] = nil
        ClearPedTasks(ped)
        TaskStandStill(ped, -1)
        return true
    end
    local dict = 'random@arrests'
    local anim = 'kneeling_arrest_idle'
    if not loadAnimDict(dict, 2000) then
        return false
    end
    ClearPedTasks(ped)
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 1, 0.0, false, false, false)
    kneeling[ped] = true
    return true
end

---@param origin vector3
---@return vector3, number
local function findRoadSpawn(origin)
    local found, node, heading = GetClosestVehicleNodeWithHeading(origin.x, origin.y, origin.z, 1, 3.0, 0)
    if found then
        return vec3(node.x, node.y, node.z), heading
    end
    return origin, GetEntityHeading(PlayerPedId())
end

---@param ped number
---@return boolean
function Custody.callTransport(ped)
    if type(ped) ~= 'number' or ped == 0 or not DoesEntityExist(ped) then
        return false
    end
    if not Custody.isCuffed(ped) then
        return false
    end
    if transportRequested[ped] then
        return false
    end
    transportRequested[ped] = true

    CreateThread(function()
        local suspect = ped
        local player = PlayerPedId()
        local pCoords = GetEntityCoords(player)
        local spawnGuess = vec3(pCoords.x - 55.0, pCoords.y, pCoords.z)
        local spawn, heading = findRoadSpawn(spawnGuess)

        local vehModel = GetHashKey('policet')
        if not loadModel(vehModel, 5000) then
            vehModel = GetHashKey('police')
            if not loadModel(vehModel, 5000) then
                transportRequested[suspect] = nil
                return
            end
        end
        local pedModel = GetHashKey('s_m_y_cop_01')
        if not loadModel(pedModel, 5000) then
            transportRequested[suspect] = nil
            return
        end

        local veh = CreateVehicle(vehModel, spawn.x, spawn.y, spawn.z, heading, true, true)
        if not veh or veh == 0 then
            transportRequested[suspect] = nil
            return
        end
        SetVehicleOnGroundProperly(veh)
        SetEntityAsMissionEntity(veh, true, true)
        local driver = CreatePedInsideVehicle(veh, 6, pedModel, -1, true, true)
        if not driver or driver == 0 then
            DeleteEntity(veh)
            transportRequested[suspect] = nil
            return
        end
        SetBlockingOfNonTemporaryEvents(driver, true)
        SetDriverAbility(driver, 0.8)
        SetDriverAggressiveness(driver, 0.2)

        local sCoords = GetEntityCoords(suspect)
        TaskVehicleDriveToCoordLongrange(driver, veh, sCoords.x, sCoords.y, sCoords.z, 18.0, 786603, 8.0)

        local arrived = false
        local t = GetGameTimer() + 45000
        while GetGameTimer() < t do
            if not DoesEntityExist(suspect) or not DoesEntityExist(veh) or not DoesEntityExist(driver) then
                transportRequested[suspect] = nil
                return
            end
            sCoords = GetEntityCoords(suspect)
            local vCoords = GetEntityCoords(veh)
            local dist = #(vCoords - sCoords)
            if dist < 14.0 then
                arrived = true
                break
            end
            Wait(250)
        end

        if not arrived then
            DeleteEntity(driver)
            DeleteEntity(veh)
            transportRequested[suspect] = nil
            return
        end

        TaskVehicleTempAction(driver, veh, 27, 2500)
        Wait(800)

        requestControl(suspect, 1200)
        local seat = 1
        if IsVehicleSeatFree(veh, seat) ~= true then
            seat = 2
        end
        TaskEnterVehicle(suspect, veh, 20000, seat, 1.0, 1, 0)

        local entered = false
        local t2 = GetGameTimer() + 20000
        while GetGameTimer() < t2 do
            if not DoesEntityExist(suspect) then
                break
            end
            if IsPedInVehicle(suspect, veh, false) then
                entered = true
                break
            end
            Wait(250)
        end

        if entered then
            TaskVehicleDriveWander(driver, veh, 22.0, 786603)
            local t3 = GetGameTimer() + 45000
            while GetGameTimer() < t3 do
                if not DoesEntityExist(veh) then
                    break
                end
                local v = GetEntityCoords(veh)
                local p = GetEntityCoords(player)
                if #(v - p) > 220.0 then
                    break
                end
                Wait(1000)
            end
        end

        if DoesEntityExist(suspect) then
            DeleteEntity(suspect)
        end
        if DoesEntityExist(driver) then
            DeleteEntity(driver)
        end
        if DoesEntityExist(veh) then
            DeleteEntity(veh)
        end
        transportRequested[suspect] = nil
    end)

    return true
end

CreateThread(function()
    while true do
        for ped, _ in pairs(cuffed) do
            if not DoesEntityExist(ped) then
                cuffed[ped] = nil
                kneeling[ped] = nil
                transportRequested[ped] = nil
            end
        end
        Wait(1500)
    end
end)

return Custody


