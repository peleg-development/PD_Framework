---@return boolean
local function eventSuspiciousActivity()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local suspect = Utils.spawnPedAt(pos, heading or 0.0, 4)
    if not suspect then return false end

    SetPedFleeAttributes(suspect, 512, false)
    SetBlockingOfNonTemporaryEvents(suspect, true)

    local walkPos1 = GetOffsetFromEntityInWorldCoords(suspect, math.random(-8, 8), math.random(-8, 8), 0.0)
    TaskGoStraightToCoord(suspect, walkPos1.x, walkPos1.y, walkPos1.z, 1.0, 8000, heading or 0.0, 0.2)

    Utils.after(3000, function()
        if DoesEntityExist(suspect) then
            TaskStartScenarioInPlace(suspect, 'WORLD_HUMAN_MOBILE_FILM_SHORT', 0, true)
        end
    end)

    Utils.after(6000, function()
        if DoesEntityExist(suspect) then
            ClearPedTasks(suspect)
            local lookPos = GetOffsetFromEntityInWorldCoords(suspect, math.random(-10, 10), math.random(-10, 10), 0.0)
            TaskLookAtCoord(suspect, lookPos.x, lookPos.y, lookPos.z, 2000, 2048, 2)
        end
    end)

    Utils.after(9000, function()
        if DoesEntityExist(suspect) then
            ClearPedTasks(suspect)
            local walkPos2 = GetOffsetFromEntityInWorldCoords(suspect, math.random(-12, 12), math.random(-12, 12), 0.0)
            TaskGoStraightToCoord(suspect, walkPos2.x, walkPos2.y, walkPos2.z, 1.0, 12000, heading or 0.0, 0.2)
        end
    end)

    Utils.after(15000, function()
        if DoesEntityExist(suspect) then
            ClearPedTasks(suspect)
            TaskWanderStandard(suspect, 10.0, 10)
        end
    end)

    EventManager.registerEvent({ suspect }, pos, 60000)
    return true
end

EventManager.registerEventType('SuspiciousActivity', eventSuspiciousActivity)

