---@return boolean
local function eventCrashScene()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local wreckVeh, wreckDriver = Utils.spawnCivilianCarWithDriverAt(pos, heading or 0.0)
    if not wreckVeh then return false end

    SetVehicleEngineHealth(wreckVeh, 150.0)
    SetVehicleEngineOn(wreckVeh, false, true, true)
    SetVehicleDoorOpen(wreckVeh, 0, false, false)
    SetVehicleDoorOpen(wreckVeh, 1, false, false)

    TaskLeaveVehicle(wreckDriver, wreckVeh, 256)
    Utils.after(1800, function()
        if DoesEntityExist(wreckDriver) and DoesEntityExist(wreckVeh) then
            local inspectPos = GetOffsetFromEntityInWorldCoords(wreckVeh, -2.0, 0.0, 0.0)
            TaskGoStraightToCoord(wreckDriver, inspectPos.x, inspectPos.y, inspectPos.z, 1.0, 5000, heading or 0.0, 0.2)
        end
    end)

    Utils.after(5000, function()
        if DoesEntityExist(wreckDriver) then
            TaskStartScenarioInPlace(wreckDriver, 'WORLD_HUMAN_MOBILE_FILM_SHORT', 0, true)
        end
    end)

    Utils.after(10000, function()
        if DoesEntityExist(wreckDriver) and DoesEntityExist(wreckVeh) then
            ClearPedTasks(wreckDriver)
            local walkPos = GetOffsetFromEntityInWorldCoords(wreckVeh, 2.0, 0.0, 0.0)
            TaskGoStraightToCoord(wreckDriver, walkPos.x, walkPos.y, walkPos.z, 1.0, 5000, heading or 0.0, 0.2)
        end
    end)

    local behind = GetOffsetFromEntityInWorldCoords(wreckVeh, 0.0, -14.0, 0.0)
    local copVeh, cop1 = Utils.spawnPoliceCarWithCopAt(behind, heading)
    if not copVeh then
        Utils.safeDelete(wreckDriver); Utils.safeDelete(wreckVeh)
        return false
    end

    SetVehicleSiren(copVeh, true)
    SetVehicleHasMutedSirens(copVeh, true)

    Utils.after(2200, function()
        if DoesEntityExist(cop1) then TaskLeaveVehicle(cop1, copVeh, 256) end
    end)

    Utils.after(4200, function()
        if DoesEntityExist(cop1) and DoesEntityExist(wreckVeh) then
            local a = GetOffsetFromEntityInWorldCoords(wreckVeh, -1.5, 0.5, 0.0)
            TaskGoStraightToCoord(cop1, a.x, a.y, a.z, 1.0, 6000, heading or 0.0, 0.2)
        end
    end)

    EventManager.registerEvent({ wreckVeh, wreckDriver, copVeh, cop1 }, pos, 80000)
    return true
end

EventManager.registerEventType('CrashScene', eventCrashScene)

