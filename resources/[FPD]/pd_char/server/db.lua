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
    PDLib.debug('pd_char', 'db init driver=oxmysql')
    DB.ensureSchema()
    return true
end

function DB.ensureSchema()
    local tableName = 'characters'
    PDLib.debug('pd_char', 'db ensure table=%s', tableName)
    await(([[CREATE TABLE IF NOT EXISTS `%s` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `identifier` VARCHAR(128) NOT NULL,
        `slot` INT NOT NULL,
        `first_name` VARCHAR(64) NOT NULL DEFAULT '',
        `last_name` VARCHAR(64) NOT NULL DEFAULT '',
        `appearance` LONGTEXT NOT NULL DEFAULT '{}',
        `metadata` LONGTEXT NOT NULL DEFAULT '{}',
        `created_at` INT NOT NULL DEFAULT 0,
        `updated_at` INT NOT NULL DEFAULT 0,
        UNIQUE KEY `unique_char` (`identifier`, `slot`),
        INDEX `idx_identifier` (`identifier`)
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

