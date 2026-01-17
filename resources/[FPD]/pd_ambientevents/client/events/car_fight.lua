---@return boolean
local function eventCarFight()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local veh1, driver1 = Utils.spawnCivilianCarWithDriverAt(pos, heading or 0.0)
    if not veh1 or not driver1 then return false end

    local veh2, driver2 = Utils.spawnCivilianCarWithDriverAt(GetOffsetFromEntityInWorldCoords(veh1, 0.0, 8.0, 0.0), heading or 0.0)
    if not veh2 or not driver2 then
        Utils.safeDelete(driver1)
        Utils.safeDelete(veh1)
        return false
    end

    TaskVehicleTempAction(driver1, veh1, 27, 3000)
    TaskVehicleTempAction(driver2, veh2, 27, 3000)

    local weapons = {
        { hash = GetHashKey('WEAPON_UNARMED'), name = 'Fists' },
        { hash = GetHashKey('WEAPON_KNIFE'), name = 'Knife' },
        { hash = GetHashKey('WEAPON_BAT'), name = 'Bat' },
        { hash = GetHashKey('WEAPON_NIGHTSTICK'), name = 'Nightstick' },
    }

    local weapon1 = weapons[math.random(1, #weapons)]
    local weapon2 = weapons[math.random(1, #weapons)]

    Utils.after(2000, function()
        if DoesEntityExist(driver1) then TaskLeaveVehicle(driver1, veh1, 256) end
        if DoesEntityExist(driver2) then TaskLeaveVehicle(driver2, veh2, 256) end
    end)

    Utils.after(3500, function()
        if DoesEntityExist(driver1) and DoesEntityExist(driver2) then
            if weapon1.hash ~= GetHashKey('WEAPON_UNARMED') then
                GiveWeaponToPed(driver1, weapon1.hash, 1, false, true)
                SetCurrentPedWeapon(driver1, weapon1.hash, true)
            end
            if weapon2.hash ~= GetHashKey('WEAPON_UNARMED') then
                GiveWeaponToPed(driver2, weapon2.hash, 1, false, true)
                SetCurrentPedWeapon(driver2, weapon2.hash, true)
            end

            SetPedCombatAbility(driver1, 100)
            SetPedCombatAbility(driver2, 100)
            SetPedCombatRange(driver1, 2)
            SetPedCombatRange(driver2, 2)
            SetPedFleeAttributes(driver1, 0, false)
            SetPedFleeAttributes(driver2, 0, false)
            SetPedCombatAttributes(driver1, 46, true)
            SetPedCombatAttributes(driver2, 46, true)

            TaskCombatPed(driver1, driver2, 0, 16)
            TaskCombatPed(driver2, driver1, 0, 16)
        end
    end)

    EventManager.registerEvent({ veh1, driver1, veh2, driver2 }, pos, 85000)
    return true
end

EventManager.registerEventType('CarFight', eventCarFight)

