---@return boolean
local function eventDomesticDispute()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local person1 = Utils.spawnPedAt(pos, heading or 0.0, 4)
    if not person1 then return false end

    local person2 = Utils.spawnPedAt(GetOffsetFromEntityInWorldCoords(person1, 2.0, 0.0, 0.0), heading + 180.0, 4)
    if not person2 then
        Utils.safeDelete(person1)
        return false
    end

    local copVeh, cop = Utils.spawnPoliceCarWithCopAt(GetOffsetFromEntityInWorldCoords(person1, 0.0, -10.0, 0.0), heading)
    if not copVeh then
        Utils.safeDelete(person1)
        Utils.safeDelete(person2)
        return false
    end

    SetVehicleSiren(copVeh, true)
    SetVehicleHasMutedSirens(copVeh, true)

    TaskWanderStandard(person1, 3.0, 10)
    TaskWanderStandard(person2, 3.0, 10)

    Utils.after(2000, function()
        if DoesEntityExist(cop) then TaskLeaveVehicle(cop, copVeh, 256) end
    end)

    Utils.after(4000, function()
        if DoesEntityExist(cop) and DoesEntityExist(person1) then
            local targetPos = GetOffsetFromEntityInWorldCoords(person1, 0.0, 2.0, 0.0)
            TaskGoStraightToCoord(cop, targetPos.x, targetPos.y, targetPos.z, 1.0, 8000, heading or 0.0, 0.2)
        end
    end)

    Utils.after(7000, function()
        if DoesEntityExist(person1) and DoesEntityExist(person2) then
            ClearPedTasks(person1)
            ClearPedTasks(person2)
            local approachPos = GetOffsetFromEntityInWorldCoords(person2, 0.0, 1.5, 0.0)
            TaskGoStraightToCoord(person1, approachPos.x, approachPos.y, approachPos.z, 1.0, 5000, heading or 0.0, 0.2)
        end
    end)

    Utils.after(12000, function()
        if DoesEntityExist(person1) and DoesEntityExist(person2) then
            TaskStartScenarioInPlace(person1, 'WORLD_HUMAN_AA_SMOKE', 0, true)
            local walkPos = GetOffsetFromEntityInWorldCoords(person2, math.random(-5, 5), math.random(-5, 5), 0.0)
            TaskGoStraightToCoord(person2, walkPos.x, walkPos.y, walkPos.z, 1.0, 8000, heading or 0.0, 0.2)
        end
    end)

    EventManager.registerEvent({ person1, person2, copVeh, cop }, pos, 70000)
    return true
end

EventManager.registerEventType('DomesticDispute', eventDomesticDispute)

