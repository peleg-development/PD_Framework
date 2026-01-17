local Config = require('config')
local DB = require('server.db')
local Utils = require('@pd_core/shared.utils')

---@class Characters
    local Characters = {
        cache = {},
        active = {}
    }

local tableName = 'characters'

---@class PDCharacter
---@field id number
---@field identifier string
---@field slot number
---@field firstName string
---@field lastName string
---@field appearance table
---@field metadata table<string, any>
---@field createdAt number
---@field updatedAt number

---@param identifier string
---@param slot number
---@param data table
---@return PDCharacter|nil
local function createCharacter(identifier, slot, data)
    local firstName = data.firstName or ''
    local lastName = data.lastName or ''
    local appearance = data.appearance or {}
    local metadata = data.metadata or {}
    
    if type(metadata) ~= 'table' then
        metadata = {}
    end
    if type(metadata.playerdata) ~= 'table' then
        metadata.playerdata = {}
    end
    
    if data.dateOfBirth ~= nil then
        metadata.playerdata.dateOfBirth = data.dateOfBirth
    end
    if data.gender ~= nil then
        metadata.playerdata.gender = data.gender
    else
        metadata.playerdata.gender = metadata.playerdata.gender or 'male'
    end

    if not DB.init() then
        return nil
    end

    local now = os.time()
    DB.execute(([[INSERT INTO `%s` (identifier, slot, first_name, last_name, appearance, metadata, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)]]):format(tableName), {
        identifier,
        slot,
        firstName,
        lastName,
        json.encode(appearance),
        json.encode(metadata),
        now,
        now
    })

    return Characters.getBySlot(identifier, slot)
end

    ---@param identifier string
    ---@return PDCharacter[]
    function Characters.getAll(identifier)
        if not DB.init() then
            return {}
        end

        local rows = DB.fetchAll(([[SELECT id, identifier, slot, first_name, last_name, appearance, metadata, created_at, updated_at
        FROM `%s` WHERE identifier = ? ORDER BY slot ASC]]):format(tableName), { identifier })

        local result = {}
        for _, row in ipairs(rows) do
            local metadata = json.decode(row.metadata or '{}')
            local playerdata = metadata.playerdata or {}
            table.insert(result, {
                id = row.id,
                identifier = row.identifier,
                slot = row.slot,
                firstName = row.first_name,
                lastName = row.last_name,
                dateOfBirth = playerdata.dateOfBirth,
                gender = playerdata.gender,
                appearance = json.decode(row.appearance or '{}'),
                metadata = metadata,
                createdAt = row.created_at,
                updatedAt = row.updated_at
            })
        end

        return result
end

    ---@param identifier string
    ---@param slot number
    ---@return PDCharacter|nil
    function Characters.getBySlot(identifier, slot)
        if not DB.init() then
            return nil
        end

        local row = DB.fetchFirst(([[SELECT id, identifier, slot, first_name, last_name, appearance, metadata, created_at, updated_at
        FROM `%s` WHERE identifier = ? AND slot = ? LIMIT 1]]):format(tableName), { identifier, slot })

        if not row then
            return nil
        end

        local metadata = json.decode(row.metadata or '{}')
        local playerdata = metadata.playerdata or {}
        return {
            id = row.id,
            identifier = row.identifier,
            slot = row.slot,
            firstName = row.first_name,
            lastName = row.last_name,
            dateOfBirth = playerdata.dateOfBirth,
            gender = playerdata.gender,
            appearance = json.decode(row.appearance or '{}'),
            metadata = metadata,
            createdAt = row.created_at,
            updatedAt = row.updated_at
        }
end

    ---@param source number
    ---@param slot number
    ---@param data table
    ---@return PDCharacter|nil
    function Characters.create(source, slot, data)
        local identifier = Utils.getIdentifier(source)
        if not identifier then
            PDLib.debug('pd_char', 'create failed source=%s no identifier', source)
            return nil
        end

        if slot < 1 or slot > Config.maxCharacters then
            PDLib.debug('pd_char', 'create failed source=%s invalid slot=%s', source, slot)
            return nil
        end

        local existing = Characters.getBySlot(identifier, slot)
        if existing then
            PDLib.debug('pd_char', 'create failed source=%s slot=%s already exists', source, slot)
            return nil
        end

        local character = createCharacter(identifier, slot, data)
        if character then
            PDLib.debug('pd_char', 'create ok source=%s slot=%s', source, slot)
        end
        return character
    end

    ---@param source number
    ---@param slot number
    ---@param patch table
    ---@return PDCharacter|nil
    function Characters.update(source, slot, patch)
        local identifier = Utils.getIdentifier(source)
        if not identifier then
            return nil
        end

        local character = Characters.getBySlot(identifier, slot)
        if not character then
            return nil
        end

        if not DB.init() then
            return nil
        end

        local updates = {}
        local params = {}

        if patch.firstName ~= nil then
            table.insert(updates, 'first_name = ?')
            table.insert(params, patch.firstName)
        end
        if patch.lastName ~= nil then
            table.insert(updates, 'last_name = ?')
            table.insert(params, patch.lastName)
        end
        if patch.appearance ~= nil then
            table.insert(updates, 'appearance = ?')
            table.insert(params, json.encode(patch.appearance))
        end
        
        local mergedMeta = character.metadata or {}
        if type(mergedMeta.playerdata) ~= 'table' then
            mergedMeta.playerdata = {}
        end
        
        if patch.dateOfBirth ~= nil then
            mergedMeta.playerdata.dateOfBirth = patch.dateOfBirth
        end
        if patch.gender ~= nil then
            mergedMeta.playerdata.gender = patch.gender
        end
        if patch.metadata ~= nil then
            if type(patch.metadata) == 'table' then
                for k, v in pairs(patch.metadata) do
                    if k == 'playerdata' and type(v) == 'table' then
                        for pk, pv in pairs(v) do
                            mergedMeta.playerdata[pk] = pv
                        end
                    else
                        mergedMeta[k] = v
                    end
                end
            end
        end
        
        table.insert(updates, 'metadata = ?')
        table.insert(params, json.encode(mergedMeta))

        table.insert(updates, 'updated_at = ?')
        table.insert(params, os.time())
        table.insert(params, identifier)
        table.insert(params, slot)

        DB.execute(([[UPDATE `%s` SET %s WHERE identifier = ? AND slot = ?]]):format(tableName, table.concat(updates, ', ')), params)

        return Characters.getBySlot(identifier, slot)
    end

    ---@param source number
    ---@param slot number
    ---@return boolean
    function Characters.delete(source, slot)
        local identifier = Utils.getIdentifier(source)
        if not identifier then
            return false
        end

        if not DB.init() then
            return false
        end

        DB.execute(([[DELETE FROM `%s` WHERE identifier = ? AND slot = ?]]):format(tableName), { identifier, slot })
        return true
    end

    ---@param source number
    ---@param slot number
    ---@return boolean
    function Characters.select(source, slot)
        local identifier = Utils.getIdentifier(source)
        if not identifier then
            return false
        end

        local character = Characters.getBySlot(identifier, slot)
        if not character then
            return false
        end

        Characters.active[source] = slot
        PDLib.debug('pd_char', 'select source=%s slot=%s', source, slot)

        local playerData = exports.pd_core:GetPlayerData(source)
        if playerData then
            exports.pd_core:SetPlayerData(source, {
                name = character.firstName .. ' ' .. character.lastName,
                metadata = character.metadata
            })
        end

        TriggerEvent('pd_char:server:characterSelected', source, character)
        TriggerClientEvent('pd_char:client:characterSelected', source, character)
        return true
    end

    ---@param source number
    ---@return number|nil
    function Characters.getActiveSlot(source)
        return Characters.active[source]
    end

    ---@param source number
    ---@return PDCharacter|nil
    function Characters.getActive(source)
        local slot = Characters.active[source]
        if not slot then
            return nil
        end
        local identifier = Utils.getIdentifier(source)
        if not identifier then
            return nil
        end
        return Characters.getBySlot(identifier, slot)
    end

    ---@param source number
    function Characters.remove(source)
        Characters.active[source] = nil
    end

    return Characters
