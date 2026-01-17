---@return boolean
local function eventStrangeCall()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local copVeh, cop = Utils.spawnPoliceCarWithCopAt(pos, heading or 0.0)
    if not copVeh or not cop then return false end

    SetVehicleHasMutedSirens(copVeh, true)

    Utils.after(1500, function()
        if DoesEntityExist(cop) and DoesEntityExist(copVeh) then TaskLeaveVehicle(cop, copVeh, 256) end
    end)

    Utils.after(3200, function()
        if DoesEntityExist(cop) then
            TaskStartScenarioInPlace(cop, 'WORLD_HUMAN_GUARD_STAND', 0, true)
        end
    end)

    EventManager.registerEvent({ copVeh, cop }, pos, 50000)
    return true
end

EventManager.registerEventType('StrangeCall', eventStrangeCall)

