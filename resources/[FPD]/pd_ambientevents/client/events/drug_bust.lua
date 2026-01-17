---@return boolean
local function eventDrugBust()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local suspect = Utils.spawnPedAt(pos, heading or 0.0, 4)
    if not suspect then return false end

    local copVeh, cop = Utils.spawnPoliceCarWithCopAt(GetOffsetFromEntityInWorldCoords(suspect, 0.0, -8.0, 0.0), heading)
    if not copVeh then
        Utils.safeDelete(suspect)
        return false
    end

    SetVehicleSiren(copVeh, true)
    SetVehicleHasMutedSirens(copVeh, true)

    SetPedFleeAttributes(suspect, 0, false)
    TaskWanderStandard(suspect, 5.0, 10)

    Utils.after(2000, function()
        if DoesEntityExist(cop) then TaskLeaveVehicle(cop, copVeh, 256) end
    end)

    Utils.after(3500, function()
        if DoesEntityExist(cop) and DoesEntityExist(suspect) then
            local targetPos = GetOffsetFromEntityInWorldCoords(suspect, 0.0, 1.5, 0.0)
            TaskGoStraightToCoord(cop, targetPos.x, targetPos.y, targetPos.z, 1.0, 5000, heading or 0.0, 0.2)
        end
    end)

    Utils.after(6000, function()
        if DoesEntityExist(cop) and DoesEntityExist(suspect) then
            TaskHandsUp(suspect, 15000, 0, -1, true)
        end
    end)

    EventManager.registerEvent({ suspect, copVeh, cop }, pos, 75000)
    return true
end

EventManager.registerEventType('DrugBust', eventDrugBust)

