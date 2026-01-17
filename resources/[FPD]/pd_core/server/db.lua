---@class DB
local DB = {}

---@param query string
---@param params table|nil
---@return any
    local function await(query, params)
        local p = promise.new()
    exports.oxmysql:execute(query, params or {}, function(result)
            p:resolve(result)
        end)
        return Citizen.Await(p)
    end

---@return boolean
    function DB.init()
    PDLib.debug('pd_core', 'db init driver=oxmysql')
        DB.ensureSchema()
        return true
    end

    function DB.ensureSchema()
    local tableName = 'players'
        PDLib.debug('pd_core', 'db ensure table=%s', tableName)
        await(([[CREATE TABLE IF NOT EXISTS `%s` (
            `identifier` VARCHAR(128) NOT NULL,
        `name` VARCHAR(255) NOT NULL DEFAULT '',
        `metadata` LONGTEXT NOT NULL DEFAULT '{}',
        `created_at` INT NOT NULL DEFAULT 0,
        `updated_at` INT NOT NULL DEFAULT 0,
            PRIMARY KEY (`identifier`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]]):format(tableName))
    end

    ---@param query string
    ---@param params table|nil
    ---@return table
    function DB.fetchAll(query, params)
        return await(query, params)
    end

    ---@param query string
    ---@param params table|nil
    ---@return table|nil
    function DB.fetchFirst(query, params)
        local rows = await(query, params)
        if rows and rows[1] then
            return rows[1]
        end
        return nil
    end

    ---@param query string
    ---@param params table|nil
    ---@return any
    function DB.execute(query, params)
        return await(query, params)
    end

    return DB

