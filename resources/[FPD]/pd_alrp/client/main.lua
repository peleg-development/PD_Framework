local Config = require('config')

---@type table<number, number>
local activeBlips = {}

---@type table<number, number>
local scannedVehicles = {}

local autoScanEnabled = Config.autoScanEnabled

---@type number
local toggleKey = (Config.toggleKey or 168) --[[@as number]]

---@return table
local function generateLicense()
    local statuses = { 'valid', 'expired', 'suspended', 'revoked' }
    local weights = { 0.75, 0.15, 0.07, 0.03 }
    local r = math.random()
    local status = 'valid'
    local cumulative = 0.0
    for i = 1, #statuses do
        cumulative = cumulative + weights[i]
        if r <= cumulative then
            status = statuses[i]
            break
        end
    end
    local now = GetGameTimer()
    local dayMultiplier = 24 * 60 * 60 * 1000
    local expiration = nil
    if status == 'valid' then
        local daysFromNow = math.random(30, 365 * 3)
        expiration = now + (daysFromNow * dayMultiplier)
    elseif status == 'expired' then
        local daysAgo = math.random(1, 365)
        expiration = now - (daysAgo * dayMultiplier)
    end
    return {
        status = status,
        expiration = expiration
    }
end

---@return table
local function generateRegistration()
    local statuses = { 'valid', 'expired', 'suspended' }
    local weights = { 0.80, 0.15, 0.05 }
    local r = math.random()
    local status = 'valid'
    local cumulative = 0.0
    for i = 1, #statuses do
        cumulative = cumulative + weights[i]
        if r <= cumulative then
            status = statuses[i]
            break
        end
    end
    local now = GetGameTimer()
    local dayMultiplier = 24 * 60 * 60 * 1000
    local expiration = nil
    if status == 'valid' then
        local daysFromNow = math.random(30, 365 * 2)
        expiration = now + (daysFromNow * dayMultiplier)
    elseif status == 'expired' then
        local daysAgo = math.random(1, 180)
        expiration = now - (daysAgo * dayMultiplier)
    end
    return {
        status = status,
        expiration = expiration
    }
end

---@param vehicle number
---@param profile table
---@return table|nil
local function ensureLicenseData(vehicle, profile)
    if type(profile) ~= 'table' then
        return nil
    end
    if type(profile.license) == 'table' and type(profile.registration) == 'table' then
        return profile
    end
    if not profile.license then
        profile.license = generateLicense()
    end
    if not profile.registration then
        profile.registration = generateRegistration()
    end
    local state = Entity(vehicle).state
    if state then
        state:set('pd_npc', profile, true)
    end
    return profile
end

---@param timestamp number|nil
---@return string
local function formatDate(timestamp)
    if type(timestamp) ~= 'number' then
        return 'N/A'
    end
    local now = GetGameTimer()
    local diff = timestamp - now
    local days = math.floor(diff / (24 * 60 * 60 * 1000))
    if days > 0 then
        return ('%d days'):format(days)
    elseif days < 0 then
        return ('%d days ago'):format(math.abs(days))
    else
        return 'Today'
    end
end

---@param vehicle number
---@param silent boolean|nil
---@return boolean
local function scanPlate(vehicle, silent)
    if not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then
        return false
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate or plate == '' then
        if not silent then
            lib.notify({
                title = 'ALRP',
                description = 'Unable to read license plate.',
                type = 'error',
                duration = 3000
            })
        end
        return false
    end

    local now = GetGameTimer()
    local lastScanned = scannedVehicles[vehicle]
    if lastScanned and (now - lastScanned) < Config.autoScanCooldown then
        return false
    end
    scannedVehicles[vehicle] = now

    local vProfile = exports.pd_npc:EnsureVehicleProfile(vehicle, 2000)
    if not vProfile then
        if not silent then
            lib.notify({
                title = 'ALRP',
                description = 'Unable to retrieve vehicle information.',
                type = 'error',
                duration = 3000
            })
        end
        return false
    end

    local updatedProfile = ensureLicenseData(vehicle, vProfile)
    if not updatedProfile then
        if not silent then
            lib.notify({
                title = 'ALRP',
                description = 'Unable to process vehicle data.',
                type = 'error',
                duration = 3000
            })
        end
        return false
    end
    vProfile = updatedProfile

    local owner = (vProfile.identity and vProfile.identity.full) or 'Unknown'
    local licenseStatus = (vProfile.license and vProfile.license.status) or 'unknown'
    local registrationStatus = (vProfile.registration and vProfile.registration.status) or 'unknown'
    local warrants = vProfile.warrants or {}
    local hasWarrants = type(warrants) == 'table' and #warrants > 0

    local notifyType = 'info'
    local description = ('Owner: %s\nLicense: %s\nRegistration: %s'):format(
        owner,
        licenseStatus:upper(),
        registrationStatus:upper()
    )

    if hasWarrants then
        notifyType = 'error'
        description = description .. '\n\n⚠️ OUTSTANDING WARRANTS'
        for _, warrant in ipairs(warrants) do
            description = description .. '\n• ' .. tostring(warrant)
        end
    elseif licenseStatus ~= 'valid' or registrationStatus ~= 'valid' then
        notifyType = 'warning'
    end

    if vProfile.license and vProfile.license.expiration then
        description = description .. ('\nLicense Exp: %s'):format(formatDate(vProfile.license.expiration))
    end
    if vProfile.registration and vProfile.registration.expiration then
        description = description .. ('\nRegistration Exp: %s'):format(formatDate(vProfile.registration.expiration))
    end

    if not silent then
        lib.notify({
            title = ('Plate: %s'):format(plate),
            description = description,
            type = notifyType,
            duration = 8000
        })
    end

    if not activeBlips[vehicle] then
        local blip = AddBlipForEntity(vehicle)
        SetBlipSprite(blip, Config.blipSprite)
        SetBlipColour(blip, Config.blipColor)
        SetBlipScale(blip, Config.blipScale)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(('Plate: %s'):format(plate))
        EndTextCommandSetBlipName(blip)

        activeBlips[vehicle] = blip
    end

    return true
end

---@param vehicle number
---@return boolean
local function isPoliceVehicle(vehicle)
    if not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then
        return false
    end
    return GetVehicleClass(vehicle) == 18
end

---@return boolean
local function isPlayerInPoliceVehicle()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return false
    end
    local vehicle = GetVehiclePedIsIn(ped, false)
    return isPoliceVehicle(vehicle)
end

---@return number|nil
local function getVehicleInRange()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    local closest = nil
    local closestDist = Config.scanDistance

    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) and GetEntityType(vehicle) == 2 then
            local vehCoords = GetEntityCoords(vehicle)
            local dist = #(coords - vehCoords)
            if dist < closestDist then
                closest = vehicle
                closestDist = dist
            end
        end
    end

    return closest
end

CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustReleased(0, toggleKey) then
            autoScanEnabled = not autoScanEnabled
            lib.notify({
                title = 'ALRP',
                description = autoScanEnabled and 'Auto-scan enabled' or 'Auto-scan disabled',
                type = autoScanEnabled and 'success' or 'info',
                duration = 2000
            })
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.autoScanInterval)
        if autoScanEnabled then
            if Config.requirePoliceVehicle and not isPlayerInPoliceVehicle() then
                Wait(1000)
            else
                local vehicle = getVehicleInRange()
                if vehicle then
                    scanPlate(vehicle, true)
                end
            end
        end
    end
end)

exports('ScanPlate', function(vehicle)
    if type(vehicle) ~= 'number' then
        vehicle = getVehicleInRange()
    end
    if vehicle then
        return scanPlate(vehicle, false)
    end
    return false
end)

CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local toRemove = {}

        for vehicle, blip in pairs(activeBlips) do
            if not DoesEntityExist(vehicle) then
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
                toRemove[vehicle] = true
            else
                local vehCoords = GetEntityCoords(vehicle)
                local dist = #(coords - vehCoords)
                if dist > Config.blipDistance then
                    if DoesBlipExist(blip) then
                        RemoveBlip(blip)
                    end
                    toRemove[vehicle] = true
                end
            end
        end

        for vehicle, _ in pairs(toRemove) do
            activeBlips[vehicle] = nil
            scannedVehicles[vehicle] = nil
        end
    end
end)

