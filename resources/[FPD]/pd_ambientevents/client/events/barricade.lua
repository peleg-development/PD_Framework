---@return boolean
local function eventBarricade()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local copVeh1, cop1 = Utils.spawnPoliceCarWithCopAt(pos, heading or 0.0)
    if not copVeh1 then return false end

    local copVeh2, cop2 = Utils.spawnPoliceCarWithCopAt(GetOffsetFromEntityInWorldCoords(copVeh1, 0.0, 8.0, 0.0), heading or 0.0)
    if not copVeh2 then
        Utils.safeDelete(cop1)
        Utils.safeDelete(copVeh1)
        return false
    end

    SetVehicleSiren(copVeh1, true)
    SetVehicleHasMutedSirens(copVeh1, true)
    SetVehicleSiren(copVeh2, true)
    SetVehicleHasMutedSirens(copVeh2, true)

    SetVehicleEngineOn(copVeh1, false, true, true)
    SetVehicleEngineOn(copVeh2, false, true, true)

    Utils.after(2000, function()
        if DoesEntityExist(cop1) then TaskLeaveVehicle(cop1, copVeh1, 256) end
        if DoesEntityExist(cop2) then TaskLeaveVehicle(cop2, copVeh2, 256) end
    end)

    Utils.after(4000, function()
        if DoesEntityExist(cop1) then
            local pos1 = GetOffsetFromEntityInWorldCoords(copVeh1, -2.0, 0.0, 0.0)
            TaskGoStraightToCoord(cop1, pos1.x, pos1.y, pos1.z, 1.0, 5000, heading or 0.0, 0.2)
        end
        if DoesEntityExist(cop2) then
            local pos2 = GetOffsetFromEntityInWorldCoords(copVeh2, 2.0, 0.0, 0.0)
            TaskGoStraightToCoord(cop2, pos2.x, pos2.y, pos2.z, 1.0, 5000, heading or 0.0, 0.2)
        end
    end)

    Utils.after(7000, function()
        if DoesEntityExist(cop1) then
            TaskStartScenarioInPlace(cop1, 'WORLD_HUMAN_GUARD_STAND', 0, true)
        end
        if DoesEntityExist(cop2) then
            TaskStartScenarioInPlace(cop2, 'WORLD_HUMAN_GUARD_STAND', 0, true)
        end
    end)

    EventManager.registerEvent({ copVeh1, cop1, copVeh2, cop2 }, pos, 90000)
    return true
end

EventManager.registerEventType('Barricade', eventBarricade)

