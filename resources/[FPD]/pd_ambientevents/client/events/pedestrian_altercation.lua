---@return boolean
local function eventPedestrianAltercation()
    local pos, heading = Utils.findRoadSpawnAroundPlayer(Config.Events.DistanceMin, Config.Events.DistanceMax)
    if not pos then return false end

    local ped1 = Utils.spawnPedAt(pos, heading or 0.0, 4)
    if not ped1 then return false end

    local ped2 = Utils.spawnPedAt(GetOffsetFromEntityInWorldCoords(ped1, 2.0, 0.0, 0.0), (heading or 0.0) + 180.0, 4)
    if not ped2 then
        Utils.safeDelete(ped1)
        return false
    end

    local weapons = {
        { hash = GetHashKey('WEAPON_UNARMED'), name = 'Fists' },
        { hash = GetHashKey('WEAPON_KNIFE'), name = 'Knife' },
        { hash = GetHashKey('WEAPON_BAT'), name = 'Bat' },
    }

    local weapon1 = weapons[math.random(1, #weapons)]
    local weapon2 = weapons[math.random(1, #weapons)]

    Utils.after(1000, function()
        if DoesEntityExist(ped1) and DoesEntityExist(ped2) then
            if weapon1.hash ~= GetHashKey('WEAPON_UNARMED') then
                GiveWeaponToPed(ped1, weapon1.hash, 1, false, true)
                SetCurrentPedWeapon(ped1, weapon1.hash, true)
            end
            if weapon2.hash ~= GetHashKey('WEAPON_UNARMED') then
                GiveWeaponToPed(ped2, weapon2.hash, 1, false, true)
                SetCurrentPedWeapon(ped2, weapon2.hash, true)
            end

            SetPedCombatAbility(ped1, 100)
            SetPedCombatAbility(ped2, 100)
            SetPedCombatRange(ped1, 2)
            SetPedCombatRange(ped2, 2)
            SetPedFleeAttributes(ped1, 0, false)
            SetPedFleeAttributes(ped2, 0, false)
            SetPedCombatAttributes(ped1, 46, true)
            SetPedCombatAttributes(ped2, 46, true)

            TaskCombatPed(ped1, ped2, 0, 16)
            TaskCombatPed(ped2, ped1, 0, 16)
        end
    end)

    EventManager.registerEvent({ ped1, ped2 }, pos, 80000)
    return true
end

EventManager.registerEventType('PedestrianAltercation', eventPedestrianAltercation)

