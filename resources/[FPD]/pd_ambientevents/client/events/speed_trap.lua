---@return boolean
local function eventSpeedTrap()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local copVeh, cop = Utils.spawnPoliceCarWithCopAt(pos, heading or 0.0)
    if not copVeh or not cop then return false end

    SetVehicleEngineOn(copVeh, true, true, false)
    SetVehicleHasMutedSirens(copVeh, true)
    SetVehicleSiren(copVeh, false)

    TaskVehicleTempAction(cop, copVeh, 27, 10000)

    Utils.after(3000, function()
        if DoesEntityExist(cop) then
            TaskStartScenarioInPlace(cop, 'WORLD_HUMAN_BINOCULARS', 0, true)
        end
    end)

    EventManager.registerEvent({ copVeh, cop }, pos, 60000)
    return true
end

EventManager.registerEventType('SpeedTrap', eventSpeedTrap)

