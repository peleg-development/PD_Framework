---@return boolean
local function eventTrafficStop()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local civVeh, civDriver = Utils.spawnCivilianCarWithDriverAt(pos, heading or 0.0)
    if not civVeh or not civDriver then return false end

    local behind = GetOffsetFromEntityInWorldCoords(civVeh, 0.0, -10.0, 0.0)
    local copVeh, cop = Utils.spawnPoliceCarWithCopAt(behind, heading or 0.0)
    if not copVeh or not cop then
        Utils.safeDelete(civDriver); Utils.safeDelete(civVeh)
        return false
    end

    TaskVehicleTempAction(civDriver, civVeh, 27, 2500)
    TaskVehicleTempAction(cop, copVeh, 27, 2500)

    SetVehicleSiren(copVeh, true)
    SetVehicleHasMutedSirens(copVeh, true)

    Utils.after(2200, function()
        if DoesEntityExist(cop) then TaskLeaveVehicle(cop, copVeh, 256) end
    end)

    Utils.after(4200, function()
        if DoesEntityExist(cop) and DoesEntityExist(civVeh) then
            local w = GetOffsetFromEntityInWorldCoords(civVeh, -1.1, 0.2, 0.0)
            TaskGoStraightToCoord(cop, w.x, w.y, w.z, 1.0, 6000, heading or 0.0, 0.2)
        end
    end)

    EventManager.registerEvent({ civVeh, civDriver, copVeh, cop }, pos, 65000)
    return true
end

EventManager.registerEventType('TrafficStop', eventTrafficStop)

