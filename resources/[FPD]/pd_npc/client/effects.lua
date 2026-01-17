PDNPC.provide('client.effects', function()
    local Effects = {}

    ---@param clipset string
    ---@param timeoutMs number|nil
    ---@return boolean
    local function loadClipset(clipset, timeoutMs)
        if type(clipset) ~= 'string' or clipset == '' then
            return false
        end
        RequestAnimSet(clipset)
        local t = GetGameTimer() + (type(timeoutMs) == 'number' and timeoutMs or 1500)
        while not HasAnimSetLoaded(clipset) and GetGameTimer() < t do
            Wait(0)
        end
        return HasAnimSetLoaded(clipset)
    end

    ---@param profile PDNPCProfile
    ---@return string|nil
    local function pickMovementClipset(profile)
        if type(profile) ~= 'table' then
            return nil
        end
        local flags = profile.flags
        if type(flags) ~= 'table' then
            return nil
        end
        if not flags.isDrunk and not flags.isDrugged then
            return nil
        end
        local bac = type(profile.bac) == 'number' and profile.bac or 0.0
        if flags.isDrunk then
            if bac >= 0.16 then
                return 'move_m@drunk@verydrunk'
            end
            if bac >= 0.08 then
                return 'move_m@drunk@moderatedrunk'
            end
            return 'move_m@drunk@slightlydrunk'
        end
        return 'move_m@drunk@moderatedrunk'
    end

    ---@param ped number
    ---@param profile PDNPCProfile
    ---@return boolean
    function Effects.applyPed(ped, profile)
        if type(ped) ~= 'number' or ped == 0 or not DoesEntityExist(ped) then
            return false
        end
        if IsPedAPlayer(ped) then
            return false
        end
        if not NetworkHasControlOfEntity(ped) then
            return false
        end
        if type(profile) ~= 'table' or type(profile.flags) ~= 'table' then
            return false
        end
        local flags = profile.flags
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                local ability = 1.0
                local aggressiveness = 0.5
                if flags.isDrunk then
                    ability = 0.35
                    aggressiveness = 0.80
                elseif flags.isDrugged then
                    ability = 0.55
                    aggressiveness = 0.65
                end
                SetDriverAbility(ped, ability)
                SetDriverAggressiveness(ped, aggressiveness)
            end
            return true
        end
        local clipset = pickMovementClipset(profile)
        if clipset then
            if loadClipset(clipset, 1500) then
                SetPedMovementClipset(ped, clipset, 1.0)
            end
            return true
        end
        ResetPedMovementClipset(ped, 1.0)
        return true
    end

    ---@param entity number
    ---@param profile PDNPCProfile
    ---@return boolean
    function Effects.applyEntity(entity, profile)
        if type(entity) ~= 'number' or entity == 0 or not DoesEntityExist(entity) then
            return false
        end
        local t = GetEntityType(entity)
        if t == 1 then
            return Effects.applyPed(entity, profile)
        end
        return false
    end

    return Effects
end)

return PDNPC.use('client.effects')


