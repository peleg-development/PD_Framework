local Generate = PDNPC.use('server.generate')
local Config = PDNPC.use('config')

CreateThread(function()
    local seed = os.time() + math.floor(os.clock() * 100000)
    math.randomseed(seed)
    math.random()
    math.random()
end)

---@param suggested any
---@return PDNPCProfile|nil
local function sanitizeSuggested(suggested)
    if type(suggested) ~= 'table' then
        return nil
    end
    if type(suggested.identity) ~= 'table' then
        return nil
    end
    if type(suggested.identity.full) ~= 'string' then
        return nil
    end
    if type(suggested.flags) ~= 'table' then
        return nil
    end
    if type(suggested.flags.isDrunk) ~= 'boolean' then
        return nil
    end
    if type(suggested.flags.isDrugged) ~= 'boolean' then
        return nil
    end
    if type(suggested.flags.smellsAlcohol) ~= 'boolean' then
        return nil
    end
    if type(suggested.inventory) ~= 'table' then
        return nil
    end
    suggested.version = type(suggested.version) == 'number' and suggested.version or Config.profileVersion
    suggested.createdAt = type(suggested.createdAt) == 'number' and suggested.createdAt or os.time()
    return suggested
end

---@param entity number
---@param kind string|nil
---@param suggested any
---@return PDNPCProfile|nil
local function ensureProfileForEntity(entity, kind, suggested)
    if type(entity) ~= 'number' or entity == 0 then
        return nil
    end
    if not DoesEntityExist(entity) then
        return nil
    end
    local entityType = GetEntityType(entity)
    if entityType == 0 then
        return nil
    end
    if entityType ~= 1 and entityType ~= 2 then
        return nil
    end
    if entityType == 1 and IsPedAPlayer(entity) then
        return nil
    end
    local inferred = entityType == 2 and 'vehicle' or 'ped'
    local resolved = (kind == 'vehicle' or kind == 'ped') and kind or inferred
    local state = Entity(entity).state
    local existing = state and state.pd_npc
    if type(existing) == 'table' then
        return existing
    end
    local profile = sanitizeSuggested(suggested) or Generate.profile(resolved)
    if type(profile) ~= 'table' then
        return nil
    end
    state:set('pd_npc', profile, true)
    return profile
end

---@param netId number
---@param kind string|nil
---@param suggested any
---@return PDNPCProfile|nil
local function ensureEntityProfile(netId, kind, suggested)
    if type(netId) ~= 'number' then
        return nil
    end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 then
        return nil
    end
    return ensureProfileForEntity(entity, kind, suggested)
end

---@param netId number
---@return PDNPCProfile|nil
local function getEntityProfile(netId)
    if type(netId) ~= 'number' then
        return nil
    end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 then
        return nil
    end
    local state = Entity(entity).state
    local existing = state and state.pd_npc
    if type(existing) == 'table' then
        return existing
    end
    return nil
end

RegisterNetEvent('pd_npc:server:ensure', function(netId, kind, suggested)
    local src = source
    local ok = ensureEntityProfile(netId, kind, suggested) ~= nil
    TriggerClientEvent('pd_npc:client:ensureResult', src, netId, ok)
end)

AddEventHandler('entityCreated', function(entity)
    CreateThread(function()
        Wait(0)
        ensureProfileForEntity(entity, nil, nil)
    end)
end)

exports('EnsureEntityProfile', function(netId, kind)
    return ensureEntityProfile(netId, kind, nil)
end)

exports('GetEntityProfile', function(netId)
    return getEntityProfile(netId)
end)



