local function clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

local function dbg(msg)
    if Config.debug then
        print('[SmartAI] ' .. msg)
    end
end

local COP_HASH = GetHashKey('COP')

local function isPoliceVehicleEntity(veh)
    if veh == 0 or not DoesEntityExist(veh) then return false end

    local model = GetEntityModel(veh)
    if model and model ~= 0 then
        if GetVehicleClass(model) == 18 then
            return true
        end
    end

    return GetVehicleClass(veh) == 18
end

local function isPolicePed(ped)
    if IsPedInAnyPoliceVehicle(ped) then
        return true
    end

    local grp = GetPedRelationshipGroupHash(ped)
    if grp == COP_HASH then
        return true
    end

    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        if isPoliceVehicleEntity(veh) then
            return true
        end
    end

    return false
end

local function isEngagedWithPlayer(ped, playerPed)
    -- engaged = actively fighting / shooting with LOS
    if IsPedInCombat(ped, playerPed) then
        return true
    end

    if IsPedShooting(ped) and HasEntityClearLosToEntity(ped, playerPed, 17) then
        return true
    end

    return false
end


local function applyPoliceProfile(ped)
    -- Awareness
    SetPedSeeingRange(ped, Config.policeSeeingRange)
    SetPedHearingRange(ped, Config.policeHearingRange)
    SetPedAlertness(ped, clamp(Config.policeAlertness, 0, 3))

    -- Combat
    SetPedCombatAbility(ped, clamp(Config.policeCombatAbility, 0, 2))
    SetPedCombatMovement(ped, clamp(Config.policeCombatMovement, 0, 2))
    SetPedCombatRange(ped, clamp(Config.policeCombatRange, 0, 2))
    SetPedAccuracy(ped, clamp(Config.policeAccuracy, 0, 100))
    SetPedShootRate(ped, clamp(Config.policeShootRate, 0, 1000))

    -- Movement (on-foot)
    if not IsPedInAnyVehicle(ped, false) then
        SetPedMoveRateOverride(ped, clamp(Config.policeMoveRate, 0.8, 1.5))
        SetPedMaxMoveBlendRatio(ped, clamp(Config.policeMoveBlend, 0.8, 1.5))
    end

    -- Pursuit driving
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            SetDriverAbility(ped, clamp(Config.policeDriverAbility, 0.0, 1.0))
            SetDriverAggressiveness(ped, clamp(Config.policeDriverAggro, 0.0, 1.0))
            SetDriveTaskDrivingStyle(ped, Config.policeDrivingStyle)
        end
    end

    SetPedCanRagdollFromPlayerImpact(ped, Config.policeRagdollFromImpact and true or false)
end

local function applyEngagedProfile(ped)
    SetPedSeeingRange(ped, Config.engagedSeeingRange)
    SetPedHearingRange(ped, Config.engagedHearingRange)
    SetPedAlertness(ped, clamp(Config.engagedAlertness, 0, 3))

    SetPedCombatAbility(ped, clamp(Config.engagedCombatAbility, 0, 2))
    SetPedCombatMovement(ped, clamp(Config.engagedCombatMovement, 0, 2))
    SetPedCombatRange(ped, clamp(Config.engagedCombatRange, 0, 2))

    SetPedAccuracy(ped, clamp(Config.engagedAccuracy, 0, 100))
    SetPedShootRate(ped, clamp(Config.engagedShootRate, 0, 1000))

    if not IsPedInAnyVehicle(ped, false) then
        SetPedMoveRateOverride(ped, clamp(Config.engagedMoveRate, 0.8, 1.5))
        SetPedMaxMoveBlendRatio(ped, clamp(Config.engagedMoveBlend, 0.8, 1.5))
    end
end


local lastPoliceApply = {}
local lastEngagedApply = {}

local function shouldReapply(cache, ped, cooldownMs)
    local now = GetGameTimer()
    local last = cache[ped]
    if last and (now - last) < cooldownMs then
        return false
    end
    cache[ped] = now
    return true
end

local function cleanupCache(cache)
    -- Prevent unbounded growth
    local count = 0
    for _ in pairs(cache) do count = count + 1 end
    if count < 512 then return end

    local now = GetGameTimer()
    for ped, t in pairs(cache) do
        if (now - t) > 60000 or not DoesEntityExist(ped) then
            cache[ped] = nil
        end
    end
end

local function scanAndApply(policeOnly)
    local playerPed = PlayerPedId()
    if playerPed == 0 or not DoesEntityExist(playerPed) then
        return
    end

    local px, py, pz = table.unpack(GetEntityCoords(playerPed))
    local r2 = Config.radius * Config.radius

    local applied, examined = 0, 0

    local pool = GetGamePool('CPed')
    for i = 1, #pool do
        local ped = pool[i]

        if ped ~= 0
            and DoesEntityExist(ped)
            and IsEntityAPed(ped)
            and not IsPedAPlayer(ped)
            and not IsPedDeadOrDying(ped, true)
        then
            examined = examined + 1

            local x, y, z = table.unpack(GetEntityCoords(ped))
            local dx, dy, dz = (x - px), (y - py), (z - pz)
            local d2 = dx * dx + dy * dy + dz * dz

            if d2 <= r2 then
                local police = isPolicePed(ped)

                if policeOnly then
                    if police and shouldReapply(lastPoliceApply, ped, Config.reapplyPoliceMs) then
                        applyPoliceProfile(ped)
                        applied = applied + 1
                    end
                else
                    if (not police)
                        and isEngagedWithPlayer(ped, playerPed)
                        and shouldReapply(lastEngagedApply, ped, Config.reapplyEngagedMs)
                    then
                        applyEngagedProfile(ped)
                        applied = applied + 1
                    end
                end
            end
        end
    end

    dbg(('%s scan: examined=%d applied=%d'):format(policeOnly and 'Police' or 'Engaged', examined, applied))

    cleanupCache(lastPoliceApply)
    cleanupCache(lastEngagedApply)
end


CreateThread(function()
    dbg(('Loaded. enable=%s radius=%.1f policeScan=%d engagedScan=%d'):format(tostring(Config.enable), Config.radius,
        Config.policeScanMs, Config.engagedScanMs))

    local nextPoliceAt = 0
    local nextEngagedAt = 0

    while true do
        if not Config.enable then
            Wait(500)
        else
            local now = GetGameTimer()

            if now >= nextPoliceAt then
                nextPoliceAt = now + Config.policeScanMs
                scanAndApply(true)
            end

            if Config.buffEngagedNPCs and now >= nextEngagedAt then
                nextEngagedAt = now + Config.engagedScanMs
                scanAndApply(false)
            end

            Wait(100)
        end
    end
end)

CreateThread(function()
    if not Config.disableWantedLevel then
        return
    end

    SetMaxWantedLevel(0)
    SetPoliceIgnorePlayer(PlayerPedId(), true)
    SetPlayerWantedLevel(PlayerId(), 0, false)
    SetPlayerWantedLevelNow(PlayerId(), false)

    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local wantedLevel = GetPlayerWantedLevel(PlayerId())

        if wantedLevel > 0 then
            ClearPlayerWantedLevel(PlayerId())
            SetPlayerWantedLevel(PlayerId(), 0, false)
            SetPlayerWantedLevelNow(PlayerId(), false)
        end

        SetPoliceIgnorePlayer(playerPed, true)
        SetMaxWantedLevel(0)
    end
end)