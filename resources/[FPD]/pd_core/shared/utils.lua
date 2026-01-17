---@class Utils
    local Utils = {}

    ---@param source number
    ---@return string|nil
    function Utils.getIdentifier(source)
        local ids = GetPlayerIdentifiers(source)
        if not ids then
            return nil
        end
        for _, id in ipairs(ids) do
            if id:sub(1, 8) == 'license:' then
                return id
            end
        end
        return ids[1]
    end

    return Utils

