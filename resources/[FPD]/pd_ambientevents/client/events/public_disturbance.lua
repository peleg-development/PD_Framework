---@return boolean
local function eventPublicDisturbance()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local disturber = Utils.spawnPedAt(pos, heading or 0.0, 4)
    if not disturber then return false end

    local bystander = Utils.spawnPedAt(GetOffsetFromEntityInWorldCoords(disturber, 5.0, 0.0, 0.0), (heading or 0.0) + 180.0, 4)
    if not bystander then
        Utils.safeDelete(disturber)
        return false
    end

    SetPedFleeAttributes(bystander, 512, false)
    SetBlockingOfNonTemporaryEvents(disturber, true)
    SetBlockingOfNonTemporaryEvents(bystander, true)

    TaskWanderStandard(bystander, 5.0, 10)

    Utils.after(1000, function()
        if DoesEntityExist(disturber) and DoesEntityExist(bystander) then
            local targetPos = GetOffsetFromEntityInWorldCoords(bystander, 0.0, 2.0, 0.0)
            TaskGoStraightToCoord(disturber, targetPos.x, targetPos.y, targetPos.z, 1.5, 6000, heading or 0.0, 0.2)
        end
    end)

    Utils.after(4000, function()
        if DoesEntityExist(disturber) then
            TaskStartScenarioInPlace(disturber, 'WORLD_HUMAN_AA_SMOKE', 0, true)
        end
    end)

    Utils.after(8000, function()
        if DoesEntityExist(disturber) and DoesEntityExist(bystander) then
            ClearPedTasks(disturber)
            local approachPos = GetOffsetFromEntityInWorldCoords(bystander, 0.0, 1.5, 0.0)
            TaskGoStraightToCoord(disturber, approachPos.x, approachPos.y, approachPos.z, 1.0, 4000, heading or 0.0, 0.2)
        end
    end)

    Utils.after(12000, function()
        if DoesEntityExist(bystander) then
            TaskReactAndFleePed(bystander, disturber)
        end
        if DoesEntityExist(disturber) then
            ClearPedTasks(disturber)
            TaskWanderStandard(disturber, 10.0, 10)
        end
    end)

    EventManager.registerEvent({ disturber, bystander }, pos, 70000)
    return true
end

EventManager.registerEventType('PublicDisturbance', eventPublicDisturbance)

