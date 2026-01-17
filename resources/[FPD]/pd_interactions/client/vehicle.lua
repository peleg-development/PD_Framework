local Vehicle = {}

local towRequested = {}

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
    local t = GetGameTimer() + (type(timeoutMs) == 'number' and timeoutMs or 1200)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < t do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end
    return NetworkHasControlOfEntity(entity)
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

---@param vehicle number
---@return boolean
local function validVehicle(vehicle)
    if type(vehicle) ~= 'number' or vehicle == 0 then
        return false
    end
    if not DoesEntityExist(vehicle) then
        return false
    end
    if GetEntityType(vehicle) ~= 2 then
        return false
    end
    return true
end

---@param vehicle number
---@return string
local function getVehicleLabel(vehicle)
    local model = GetEntityModel(vehicle)
    local display = GetDisplayNameFromVehicleModel(model)
    local label = display and GetLabelText(display) or tostring(display or 'Vehicle')
    if label == 'NULL' then
        return tostring(display or 'Vehicle')
    end
    return tostring(label)
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

---@param vehicle number
---@return boolean
local function hasDriverOrPassengers(vehicle)
    if not validVehicle(vehicle) then
        return false
    end
    local driver = GetPedInVehicleSeat(vehicle, -1)
    if driver ~= 0 and DoesEntityExist(driver) then
        return true
    end
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
    for seat = 0, maxPassengers - 1 do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if ped ~= 0 and DoesEntityExist(ped) then
            return true
        end
    end
    return false
end

---@param vehicle number
---@return boolean
function Vehicle.plateCheck(vehicle)
    if not validVehicle(vehicle) then
        lib.notify({ title = 'Vehicle', description = 'Vehicle not valid.', type = 'error' })
        return false
    end

    local vProfile = exports.pd_npc:EnsureVehicleProfile(vehicle, 1500)
    local plate = GetVehicleNumberPlateText(vehicle)
    local label = getVehicleLabel(vehicle)
    local owner = (type(vProfile) == 'table' and vProfile.identity and vProfile.identity.full) or 'Unknown'

    lib.showResult({
        kind = 'vehiclecheck',
        title = 'Plate Check',
        subtitle = tostring(plate or 'UNKNOWN'),
        duration = 12000,
        fields = {
            { label = 'Plate', value = tostring(plate or 'UNKNOWN'), color = '#e5e7eb' },
            { label = 'Vehicle', value = tostring(label), color = '#60a5fa' },
            { label = 'Owner', value = tostring(owner), color = '#e5e7eb' },
            { label = 'Status', value = 'No wants/warrants', color = '#22c55e' },
        }
    })

    return true
end

---@param vehicle number
---@return boolean
function Vehicle.search(vehicle)
    if not validVehicle(vehicle) then
        lib.notify({ title = 'Search', description = 'Vehicle not valid.', type = 'error' })
        return false
    end

    local ok = lib.progressBar({
        label = 'Searching vehicle...',
        duration = 4500,
        canCancel = true
    })
    if not ok then
        lib.notify({ title = 'Search', description = 'Vehicle search cancelled.', type = 'warning' })
        return false
    end

    local res = exports.pd_npc:SearchVehicle(vehicle)
    if type(res) ~= 'table' then
        lib.notify({ title = 'Search', description = 'Unable to search vehicle.', type = 'error' })
        return false
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    local label = getVehicleLabel(vehicle)
    local fields = {}
    for _, item in ipairs(res.items or {}) do
        local itemLabel = tostring((item and (item.label or item.id)) or 'Item')
        local count = tostring((item and item.count) or 1)
        if item and item.illegal then
            fields[#fields + 1] = { label = itemLabel, value = 'Illegal', color = '#ef4444' }
        else
            fields[#fields + 1] = { label = itemLabel, value = 'x' .. count, color = '#e5e7eb' }
        end
    end

    lib.showResult({
        kind = 'search',
        title = 'Search: Vehicle',
        subtitle = ('%s • %s'):format(tostring(plate or 'UNKNOWN'), tostring(label)),
        duration = 15000,
        fields = fields
    })

    return true
end

---@param vehicle number
---@return boolean
function Vehicle.impound(vehicle)
    if not validVehicle(vehicle) then
        lib.notify({ title = 'Impound', description = 'Vehicle not valid.', type = 'error' })
        return false
    end
    if hasDriverOrPassengers(vehicle) then
        lib.notify({ title = 'Impound', description = 'Vehicle must be empty.', type = 'warning' })
        return false
    end
    if not requestControl(vehicle, 1200) then
        lib.notify({ title = 'Impound', description = 'Unable to control vehicle.', type = 'error' })
        return false
    end
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteEntity(vehicle)
    lib.notify({ title = 'Impound', description = 'Vehicle impounded.', type = 'success', duration = 5000, position = 'bottom-left' })
    return true
end

---@param vehicle number
---@return boolean
function Vehicle.requestTow(vehicle)
    if not validVehicle(vehicle) then
        lib.notify({ title = 'Tow', description = 'Vehicle not valid.', type = 'error' })
        return false
    end
    if hasDriverOrPassengers(vehicle) then
        lib.notify({ title = 'Tow', description = 'Vehicle must be empty to tow.', type = 'warning' })
        return false
    end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId ~= 0 and towRequested[netId] then
        lib.notify({ title = 'Tow', description = 'Tow already requested.', type = 'warning' })
        return false
    end
    if netId ~= 0 then
        towRequested[netId] = true
    end

    lib.notify({ title = 'Tow', description = 'Tow truck requested.', type = 'success', duration = 5000, position = 'bottom-left' })

    CreateThread(function()
        local targetVeh = vehicle
        if not DoesEntityExist(targetVeh) then
            if netId ~= 0 then towRequested[netId] = nil end
            return
        end

        local player = PlayerPedId()
        local pCoords = GetEntityCoords(player)
        local spawnGuess = vec3(pCoords.x - 80.0, pCoords.y, pCoords.z)
        local spawn, heading = findRoadSpawn(spawnGuess)

        local towModel = GetHashKey('towtruck')
        if not loadModel(towModel, 6000) then
            towModel = GetHashKey('towtruck2')
            if not loadModel(towModel, 6000) then
                if netId ~= 0 then towRequested[netId] = nil end
                return
            end
        end
        local driverModel = GetHashKey('s_m_m_trucker_01')
        if not loadModel(driverModel, 6000) then
            if netId ~= 0 then towRequested[netId] = nil end
            return
        end

        local towVeh = CreateVehicle(towModel, spawn.x, spawn.y, spawn.z, heading, true, true)
        if not towVeh or towVeh == 0 then
            if netId ~= 0 then towRequested[netId] = nil end
            return
        end
        SetVehicleOnGroundProperly(towVeh)
        SetEntityAsMissionEntity(towVeh, true, true)

        local towDriver = CreatePedInsideVehicle(towVeh, 6, driverModel, -1, true, true)
        if not towDriver or towDriver == 0 then
            DeleteEntity(towVeh)
            if netId ~= 0 then towRequested[netId] = nil end
            return
        end
        SetBlockingOfNonTemporaryEvents(towDriver, true)

        local dest = GetEntityCoords(targetVeh)
        TaskVehicleDriveToCoordLongrange(towDriver, towVeh, dest.x, dest.y, dest.z, 18.0, 786603, 10.0)

        local timeout = GetGameTimer() + 60000
        while DoesEntityExist(towVeh) and DoesEntityExist(targetVeh) and GetGameTimer() < timeout do
            local tc = GetEntityCoords(towVeh)
            local vc = GetEntityCoords(targetVeh)
            if #(tc - vc) < 12.0 then
                break
            end
            Wait(650)
        end

        if DoesEntityExist(targetVeh) then
            if not requestControl(targetVeh, 1200) then
                if netId ~= 0 then towRequested[netId] = nil end
                DeleteEntity(towDriver)
                DeleteEntity(towVeh)
                return
            end
            SetEntityAsMissionEntity(targetVeh, true, true)
            DeleteEntity(targetVeh)
        end

        if DoesEntityExist(towDriver) then
            DeleteEntity(towDriver)
        end
        if DoesEntityExist(towVeh) then
            DeleteEntity(towVeh)
        end
        if netId ~= 0 then
            towRequested[netId] = nil
        end

        lib.notify({ title = 'Tow', description = 'Vehicle towed.', type = 'success', duration = 5000, position = 'bottom-left' })
    end)

    return true
end

---@param vehicle number
---@return boolean
function Vehicle.openMenu(vehicle)
    if not validVehicle(vehicle) then
        lib.notify({ title = 'Vehicle', description = 'No vehicle nearby.', type = 'error' })
        return false
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    local label = getVehicleLabel(vehicle)
    local desc = ('%s • %s'):format(tostring(plate or 'UNKNOWN'), tostring(label))

    lib.registerContext({
        id = 'pd_interactions_vehicle',
        title = 'Vehicle Options',
        description = desc,
        focus = true,
        options = {
            {
                id = 'plate',
                title = 'Plate Check',
                color = '#14b8a6',
                value = tostring(plate or 'UNKNOWN'),
                valueColor = '#14b8a6',
                onSelect = function()
                    Vehicle.plateCheck(vehicle)
                    Vehicle.openMenu(vehicle)
                end
            },
            {
                id = 'search',
                title = 'Search Vehicle',
                color = '#f59e0b',
                value = 'Inspect',
                valueColor = '#f59e0b',
                onSelect = function()
                    Vehicle.search(vehicle)
                    Vehicle.openMenu(vehicle)
                end
            },
            {
                id = 'tow',
                title = 'Request Tow Truck',
                color = '#a855f7',
                value = 'Call',
                valueColor = '#a855f7',
                onSelect = function()
                    Vehicle.requestTow(vehicle)
                    Vehicle.openMenu(vehicle)
                end
            },
            {
                id = 'impound',
                title = 'Impound Vehicle',
                color = '#ef4444',
                value = 'Remove',
                valueColor = '#ef4444',
                onSelect = function()
                    Vehicle.impound(vehicle)
                end
            },
        }
    })

    lib.showContext('pd_interactions_vehicle')
    return true
end

return Vehicle


