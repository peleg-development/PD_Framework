---@return boolean
local function eventStakeout()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local copVeh, cop = Utils.spawnPoliceCarWithCopAt(pos, heading or 0.0)
    if not copVeh then return false end

    SetVehicleEngineOn(copVeh, true, true, false)
    SetVehicleHasMutedSirens(copVeh, true)
    SetVehicleSiren(copVeh, false)

    TaskVehicleTempAction(cop, copVeh, 27, 6000)

    EventManager.registerEvent({ copVeh, cop }, pos, 55000)
    return true
end

EventManager.registerEventType('Stakeout', eventStakeout)

