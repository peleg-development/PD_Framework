---@return boolean
local function eventRoadRage()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local veh1, driver1 = Utils.spawnCivilianCarWithDriverAt(pos, heading or 0.0)
    if not veh1 or not driver1 then return false end

    local veh2, driver2 = Utils.spawnCivilianCarWithDriverAt(GetOffsetFromEntityInWorldCoords(veh1, 0.0, 6.0, 0.0), heading or 0.0)
    if not veh2 or not driver2 then
        Utils.safeDelete(driver1)
        Utils.safeDelete(veh1)
        return false
    end

    TaskVehicleTempAction(driver1, veh1, 27, 2500)
    TaskVehicleTempAction(driver2, veh2, 27, 2500)

    Utils.after(1800, function()
        if DoesEntityExist(driver1) then TaskLeaveVehicle(driver1, veh1, 256) end
        if DoesEntityExist(driver2) then TaskLeaveVehicle(driver2, veh2, 256) end
    end)

    Utils.after(3000, function()
        if DoesEntityExist(driver1) and DoesEntityExist(driver2) then
            local targetPos1 = GetOffsetFromEntityInWorldCoords(driver2, 0.0, 1.5, 0.0)
            local targetPos2 = GetOffsetFromEntityInWorldCoords(driver1, 0.0, 1.5, 0.0)

            TaskGoStraightToCoord(driver1, targetPos1.x, targetPos1.y, targetPos1.z, 1.0, 4000, heading or 0.0, 0.2)
            TaskGoStraightToCoord(driver2, targetPos2.x, targetPos2.y, targetPos2.z, 1.0, 4000, heading or 0.0, 0.2)
        end
    end)

    Utils.after(5500, function()
        if DoesEntityExist(driver1) and DoesEntityExist(driver2) then
            local weaponHash = math.random() < 0.4 and GetHashKey('WEAPON_KNIFE') or GetHashKey('WEAPON_UNARMED')
            
            if weaponHash ~= GetHashKey('WEAPON_UNARMED') then
                GiveWeaponToPed(driver1, weaponHash, 1, false, true)
                SetCurrentPedWeapon(driver1, weaponHash, true)
            end

            SetPedCombatAbility(driver1, 120)
            SetPedCombatAbility(driver2, 100)
            SetPedFleeAttributes(driver1, 0, false)
            SetPedFleeAttributes(driver2, 512, false)
            SetPedCombatAttributes(driver1, 46, true)

            TaskCombatPed(driver1, driver2, 0, 16)
            TaskReactAndFleePed(driver2, driver1)
        end
    end)

    EventManager.registerEvent({ veh1, driver1, veh2, driver2 }, pos, 90000)
    return true
end

EventManager.registerEventType('RoadRage', eventRoadRage)

