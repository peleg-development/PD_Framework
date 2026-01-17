---@return boolean
local function eventBriefChase()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local suspectVeh, suspect = Utils.spawnCivilianCarWithDriverAt(pos, heading or 0.0)
    if not suspectVeh then return false end

    local behind = GetOffsetFromEntityInWorldCoords(suspectVeh, 0.0, -25.0, 0.0)
    local copVeh, cop = Utils.spawnPoliceCarWithCopAt(behind, heading)
    if not copVeh then
        Utils.safeDelete(suspect); Utils.safeDelete(suspectVeh)
        return false
    end

    TaskVehicleDriveWander(suspect, suspectVeh, 28.0, 786603)

    SetVehicleSiren(copVeh, true)
    SetVehicleHasMutedSirens(copVeh, false)
    TaskVehicleChase(cop, suspect)
    SetTaskVehicleChaseBehaviorFlag(cop, 1, true)

    EventManager.registerEvent({ suspectVeh, suspect, copVeh, cop }, pos, 70000)
    return true
end

EventManager.registerEventType('BriefChase', eventBriefChase)

