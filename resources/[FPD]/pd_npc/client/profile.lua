PDNPC.provide('client.profile', function()
    local Effects = PDNPC.use('client.effects')
    local Generate = PDNPC.use('shared.generate')

    local Profile = {}

    local KEY_SERVER = 'pd_npc'
    local KEY_LOCAL = 'pd_npc_local'

    local pendingEnsure = {}

    ---@param entity number
    ---@param timeoutMs number|nil
    ---@return boolean
    local function requestControl(entity, timeoutMs)
        if type(entity) ~= 'number' or entity == 0 or not DoesEntityExist(entity) then
            return false
        end
        if NetworkHasControlOfEntity(entity) then
            return true
        end
        NetworkRequestControlOfEntity(entity)
        local t = GetGameTimer() + (type(timeoutMs) == 'number' and timeoutMs or 1200)
        while not NetworkHasControlOfEntity(entity) and GetGameTimer() < t do
            NetworkRequestControlOfEntity(entity)
            Wait(0)
        end
        return NetworkHasControlOfEntity(entity)
    end

    ---@param entity number
    ---@param timeoutMs number|nil
    ---@return number|nil
    local function ensureNetworked(entity, timeoutMs)
        if type(entity) ~= 'number' or entity == 0 or not DoesEntityExist(entity) then
            return nil
        end
        requestControl(entity, timeoutMs)
        if not NetworkGetEntityIsNetworked(entity) then
            NetworkRegisterEntityAsNetworked(entity)
        end
        local netId = NetworkGetNetworkIdFromEntity(entity)
        if netId ~= 0 then
            SetNetworkIdExistsOnAllMachines(netId, true)
            SetNetworkIdCanMigrate(netId, true)
            return netId
        end
        local t = GetGameTimer() + (type(timeoutMs) == 'number' and timeoutMs or 1200)
        while netId == 0 and GetGameTimer() < t do
            NetworkRegisterEntityAsNetworked(entity)
            netId = NetworkGetNetworkIdFromEntity(entity)
            Wait(0)
        end
        if netId ~= 0 then
            SetNetworkIdExistsOnAllMachines(netId, true)
            SetNetworkIdCanMigrate(netId, true)
            return netId
        end
        return nil
    end

    ---@param entity number
    ---@return PDNPCProfile|nil
    function Profile.getServer(entity)
        if type(entity) ~= 'number' or entity == 0 or not DoesEntityExist(entity) then
            return nil
        end
        local state = Entity(entity).state
        local v = state and state[KEY_SERVER]
        if type(v) == 'table' then
            return v
        end
        return nil
    end

    ---@param entity number
    ---@return PDNPCProfile|nil
    function Profile.getLocal(entity)
        if type(entity) ~= 'number' or entity == 0 or not DoesEntityExist(entity) then
            return nil
        end
        local state = Entity(entity).state
        local v = state and state[KEY_LOCAL]
        if type(v) == 'table' then
            return v
        end
        return nil
    end

    ---@param entity number
    ---@return PDNPCProfile|nil
    function Profile.get(entity)
        return Profile.getServer(entity) or Profile.getLocal(entity)
    end

    ---@param entity number
    ---@param kind string|nil
    ---@return PDNPCProfile|nil
    function Profile.ensureLocal(entity, kind)
        if type(entity) ~= 'number' or entity == 0 or not DoesEntityExist(entity) then
            return nil
        end
        local server = Profile.getServer(entity)
        if server then
            return server
        end
        local localProfile = Profile.getLocal(entity)
        if localProfile then
            Effects.applyEntity(entity, localProfile)
            return localProfile
        end
        local t = GetEntityType(entity)
        if t == 0 then
            return nil
        end
        if t == 1 and IsPedAPlayer(entity) then
            return nil
        end
        local inferred = t == 2 and 'vehicle' or 'ped'
        local resolved = (kind == 'vehicle' or kind == 'ped') and kind or inferred
        local profile = Generate.profile(resolved)
        if type(profile) ~= 'table' then
            return nil
        end
        Entity(entity).state:set(KEY_LOCAL, profile, false)
        Effects.applyEntity(entity, profile)
        return profile
    end

    ---@param netId number
    ---@param ok boolean
    local function resolveEnsure(netId, ok)
        local p = pendingEnsure[netId]
        if p then
            p:resolve(ok == true)
        end
    end

    RegisterNetEvent('pd_npc:client:ensureResult', function(netId, ok)
        resolveEnsure(netId, ok)
    end)

    ---@type any
    local anyBagFilter = nil

    AddStateBagChangeHandler(KEY_SERVER, anyBagFilter, function(bagName, _, value)
        if type(value) ~= 'table' then
            return
        end
        local entity = GetEntityFromStateBagName(bagName)
        if not entity or entity == 0 or not DoesEntityExist(entity) then
            return
        end
        if GetEntityType(entity) ~= 1 then
            return
        end
        if IsPedAPlayer(entity) then
            return
        end
        requestControl(entity, 450)
        Effects.applyEntity(entity, value)
    end)

    AddStateBagChangeHandler(KEY_LOCAL, anyBagFilter, function(bagName, _, value)
        if type(value) ~= 'table' then
            return
        end
        local entity = GetEntityFromStateBagName(bagName)
        if not entity or entity == 0 or not DoesEntityExist(entity) then
            return
        end
        if GetEntityType(entity) ~= 1 then
            return
        end
        if IsPedAPlayer(entity) then
            return
        end
        requestControl(entity, 450)
        Effects.applyEntity(entity, value)
    end)

    ---@param entity number
    ---@param kind string|nil
    ---@param timeoutMs number|nil
    ---@return PDNPCProfile|nil
    function Profile.ensureServer(entity, kind, timeoutMs)
        if type(entity) ~= 'number' or entity == 0 or not DoesEntityExist(entity) then
            return nil
        end
        local server = Profile.getServer(entity)
        if server then
            return server
        end
        local suggested = Profile.getLocal(entity)
        local netId = ensureNetworked(entity, timeoutMs)
        if not netId then
            return nil
        end
        local p = pendingEnsure[netId]
        if not p then
            p = promise.new()
            pendingEnsure[netId] = p
            TriggerServerEvent('pd_npc:server:ensure', netId, kind, suggested)
        end
        local ok = Citizen.Await(p)
        pendingEnsure[netId] = nil
        if ok ~= true then
            return nil
        end
        local t = GetGameTimer() + (type(timeoutMs) == 'number' and timeoutMs or 1500)
        while GetGameTimer() < t do
            local v = Profile.getServer(entity)
            if v then
                return v
            end
            Wait(0)
        end
        return nil
    end

    return Profile
end)

return PDNPC.use('client.profile')


