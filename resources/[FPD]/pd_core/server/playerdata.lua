---@class PDPlayerData
---@field identifier string
---@field source number
---@field name string|nil
---@field metadata table<string, any>

local Config = require('config')
local DB = require('server.db')
local Utils = require('shared.utils')

---@class PlayerData
    local PlayerData = {
        cache = {},
        dirty = {}
    }

local tableName = 'players'

    ---@param metadata table|nil
    ---@return table
    local function ensurePlayerdataMeta(metadata)
        local meta = metadata
        if type(meta) ~= 'table' then
            meta = {}
        end
        if type(meta.playerdata) ~= 'table' then
            meta.playerdata = {}
        end
        if meta.playerdata.activeDuty == nil then
            meta.playerdata.activeDuty = false
        end
        return meta
    end

    local function defaultData(identifier, source)
        return {
            identifier = identifier,
            source = source,
            name = GetPlayerName(source),
            metadata = ensurePlayerdataMeta({})
        }
    end

    local function decodeData(raw)
        if type(raw) ~= 'string' or raw == '' then
            return {}
        end
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            return decoded
        end
        return {}
    end

    local function encodeData(data)
        return json.encode(data or {})
    end

    local function loadStored(identifier)
        if not DB.init() then
            return nil
        end
    local row = DB.fetchFirst(('SELECT name, metadata FROM `%s` WHERE identifier = ? LIMIT 1'):format(tableName), { identifier })
        if not row then
            return nil
        end
    return {
        name = row.name or '',
        metadata = decodeData(row.metadata)
    }
    end

    local function saveStored(identifier, stored)
        if not DB.init() then
            return false
        end
    local now = os.time()
    local existing = DB.fetchFirst(('SELECT created_at FROM `%s` WHERE identifier = ? LIMIT 1'):format(tableName), { identifier })
    if existing then
        DB.execute(([[UPDATE `%s` SET name = ?, metadata = ?, updated_at = ? WHERE identifier = ?]]):format(tableName), {
            stored.name or '',
            encodeData(stored.metadata or {}),
            now,
            identifier
        })
    else
        DB.execute(([[INSERT INTO `%s` (identifier, name, metadata, created_at, updated_at) VALUES (?, ?, ?, ?, ?)]]):format(tableName), {
            identifier,
            stored.name or '',
            encodeData(stored.metadata or {}),
            now,
            now
        })
    end
        return true
    end

    local function toStored(session)
        session.metadata = ensurePlayerdataMeta(session.metadata)
        return {
        name = session.name or '',
            metadata = session.metadata or {}
        }
    end

    local function applyPatch(session, patch)
        if type(patch) ~= 'table' then
            return session
        end
        session.metadata = ensurePlayerdataMeta(session.metadata)
        if patch.name ~= nil then
            session.name = patch.name
        end
        if patch.job ~= nil then
            session.metadata.playerdata.job = patch.job
        end
        if patch.grade ~= nil then
            session.metadata.playerdata.grade = patch.grade
        end
        if patch.activeDuty ~= nil then
            session.metadata.playerdata.activeDuty = patch.activeDuty and true or false
        end
        if patch.metadata ~= nil then
            if type(patch.metadata) == 'table' then
                for k, v in pairs(patch.metadata) do
                    session.metadata[k] = v
                end
            else
                session.metadata = ensurePlayerdataMeta(session.metadata)
            end
        end
        session.metadata = ensurePlayerdataMeta(session.metadata)
        return session
    end

    ---@param source number
    ---@return PDPlayerData|nil
    function PlayerData.login(source)
        local cached = PlayerData.cache[source]
        if cached then
            return cached
        end
        local identifier = Utils.getIdentifier(source)
        if not identifier then
            PDLib.debug('pd_core', 'login failed source=%s no identifier', source)
            return nil
        end
        local stored = loadStored(identifier)
        if not stored then
            PDLib.debug('pd_core', 'login miss source=%s id=%s', source, identifier)
            return nil
        end
        local session = defaultData(identifier, source)
        session = applyPatch(session, stored)
        PlayerData.cache[source] = session
        PlayerData.dirty[source] = nil
        PDLib.debug('pd_core', 'login ok source=%s id=%s', source, identifier)
        TriggerClientEvent('pd_core:client:playerDataSync', source, session)
        TriggerEvent('pd_core:server:playerLoaded', source, session)
        return session
    end

    ---@param source number
    ---@param initialPatch table|nil
    ---@return PDPlayerData|nil
    function PlayerData.create(source, initialPatch)
        local cached = PlayerData.cache[source]
        if cached then
            return cached
        end
        local existing = PlayerData.login(source)
        if existing then
            return existing
        end
        local identifier = Utils.getIdentifier(source)
        if not identifier then
            PDLib.debug('pd_core', 'create failed source=%s no identifier', source)
            return nil
        end
        local session = defaultData(identifier, source)
        session = applyPatch(session, initialPatch or {})
        PlayerData.cache[source] = session
        local ok = saveStored(identifier, toStored(session))
        PlayerData.dirty[source] = ok and nil or true
        PDLib.debug('pd_core', 'create source=%s id=%s ok=%s', source, identifier, tostring(ok))
        TriggerClientEvent('pd_core:client:playerDataSync', source, session)
        TriggerEvent('pd_core:server:playerLoaded', source, session)
        return session
    end

    ---@param source number
    ---@return PDPlayerData|nil
    function PlayerData.ensure(source)
        local session = PlayerData.login(source)
        if session then
            return session
        end
        return PlayerData.create(source, {})
    end

    ---@param source number
    function PlayerData.remove(source)
        PlayerData.flush(source)
        PlayerData.cache[source] = nil
        PlayerData.dirty[source] = nil
    end

    ---@param source number
    ---@return PDPlayerData|nil
    function PlayerData.get(source)
        return PlayerData.cache[source]
    end

    ---@param source number
    ---@param patch table
    ---@return PDPlayerData|nil
    function PlayerData.set(source, patch)
        local session = PlayerData.cache[source]
        if not session then
            session = PlayerData.ensure(source)
        end
        if not session then
            return nil
        end
        session = applyPatch(session, patch)
        PlayerData.cache[source] = session
        PlayerData.dirty[source] = true
        PDLib.debug('pd_core', 'set source=%s dirty=1', source)
        TriggerClientEvent('pd_core:client:playerDataSync', source, session)
        return session
    end

    ---@param source number
    ---@return boolean
    function PlayerData.flush(source)
        local session = PlayerData.cache[source]
        if not session then
            return false
        end
        if not PlayerData.dirty[source] then
            return true
        end
        local ok = saveStored(session.identifier, toStored(session))
        if ok then
            PlayerData.dirty[source] = nil
        end
        PDLib.debug('pd_core', 'flush source=%s ok=%s', source, tostring(ok))
        return ok
    end

    function PlayerData.flushAll()
        local count = 0
        for src, _ in pairs(PlayerData.cache) do
            PlayerData.flush(src)
            count = count + 1
        end
        PDLib.debug('pd_core', 'flushAll count=%s', count)
    end

    RegisterNetEvent('pd_core:server:playerDataPatch', function(patch)
        PlayerData.set(source, patch or {})
    end)

    return PlayerData
