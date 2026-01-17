---@return boolean
local function eventHitAndRun()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local victim = Utils.spawnPedAt(pos, heading or 0.0, 4)
    if not victim then return false end

    local hitVeh, hitDriver = Utils.spawnCivilianCarWithDriverAt(GetOffsetFromEntityInWorldCoords(victim, 0.0, -15.0, 0.0), heading or 0.0)
    if not hitVeh or not hitDriver then
        Utils.safeDelete(victim)
        return false
    end

    SetPedFleeAttributes(victim, 0, false)
    SetBlockingOfNonTemporaryEvents(victim, true)

    local walkPos = GetOffsetFromEntityInWorldCoords(victim, 0.0, 3.0, 0.0)
    TaskGoStraightToCoord(victim, walkPos.x, walkPos.y, walkPos.z, 1.0, 3000, heading or 0.0, 0.2)

    Utils.after(1500, function()
        if DoesEntityExist(hitDriver) and DoesEntityExist(hitVeh) then
            TaskVehicleDriveWander(hitDriver, hitVeh, 35.0, 786603)
            SetVehicleEngineHealth(hitVeh, 800.0)
        end
    end)

    Utils.after(2500, function()
        if DoesEntityExist(victim) then
            SetPedToRagdoll(victim, 8000, 8000, 0, false, false, false)
        end
    end)

    Utils.after(10000, function()
        if DoesEntityExist(victim) then
            ClearPedTasks(victim)
            SetPedMovementClipset(victim, 'move_m@injured', 0.25)
            local crawlPos = GetOffsetFromEntityInWorldCoords(victim, 0.0, 3.0, 0.0)
            TaskGoStraightToCoord(victim, crawlPos.x, crawlPos.y, crawlPos.z, 0.5, 15000, heading or 0.0, 0.2)
        end
    end)

    EventManager.registerEvent({ victim, hitVeh, hitDriver }, pos, 90000)
    return true
end

EventManager.registerEventType('HitAndRun', eventHitAndRun)

