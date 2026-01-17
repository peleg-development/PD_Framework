---@return boolean
local function eventArrestScene()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local suspect = Utils.spawnPedAt(pos, heading or 0.0, 4)
    if not suspect then return false end

    local copVeh, cop = Utils.spawnPoliceCarWithCopAt(GetOffsetFromEntityInWorldCoords(suspect, 0.0, -6.0, 0.0), heading)
    if not copVeh then
        Utils.safeDelete(suspect)
        return false
    end

    SetVehicleSiren(copVeh, true)
    SetVehicleHasMutedSirens(copVeh, true)

    TaskHandsUp(suspect, 60000, 0, -1, true)
    SetPedFleeAttributes(suspect, 0, false)

    Utils.after(1500, function()
        if DoesEntityExist(cop) then TaskLeaveVehicle(cop, copVeh, 256) end
    end)

    Utils.after(3000, function()
        if DoesEntityExist(cop) and DoesEntityExist(suspect) then
            local targetPos = GetOffsetFromEntityInWorldCoords(suspect, 0.0, 1.0, 0.0)
            TaskGoStraightToCoord(cop, targetPos.x, targetPos.y, targetPos.z, 1.0, 5000, heading or 0.0, 0.2)
        end
    end)

    Utils.after(6000, function()
        if DoesEntityExist(cop) and DoesEntityExist(suspect) then
            local searchPos = GetOffsetFromEntityInWorldCoords(suspect, -1.5, 0.0, 0.0)
            TaskGoStraightToCoord(cop, searchPos.x, searchPos.y, searchPos.z, 1.0, 4000, heading or 0.0, 0.2)
        end
    end)

    Utils.after(10000, function()
        if DoesEntityExist(cop) and DoesEntityExist(suspect) then
            local patrolPos = GetOffsetFromEntityInWorldCoords(suspect, 2.0, 0.0, 0.0)
            TaskGoStraightToCoord(cop, patrolPos.x, patrolPos.y, patrolPos.z, 1.0, 5000, heading or 0.0, 0.2)
        end
    end)

    EventManager.registerEvent({ suspect, copVeh, cop }, pos, 80000)
    return true
end

EventManager.registerEventType('ArrestScene', eventArrestScene)

