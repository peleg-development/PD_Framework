PDNPC.provide('shared.random', function()
    local Random = {}

    ---@param list any[]
    ---@return any|nil
    function Random.pick(list)
        if type(list) ~= 'table' or #list == 0 then
            return nil
        end
        return list[math.random(1, #list)]
    end

    ---@param p number
    ---@return boolean
    function Random.chance(p)
        if type(p) ~= 'number' then
            return false
        end
        if p <= 0 then
            return false
        end
        if p >= 1 then
            return true
        end
        return math.random() < p
    end

    ---@param min number
    ---@param max number
    ---@param decimals number|nil
    ---@return number
    function Random.float(min, max, decimals)
        local a = type(min) == 'number' and min or 0.0
        local b = type(max) == 'number' and max or 1.0
        local d = type(decimals) == 'number' and decimals or 2
        local v = a + (b - a) * math.random()
        local m = 10 ^ d
        return math.floor(v * m + 0.5) / m
    end

    ---@param items any[]
    ---@param count number
    ---@return any[]
    function Random.sample(items, count)
        if type(items) ~= 'table' then
            return {}
        end
        local n = type(count) == 'number' and count or 0
        if n <= 0 then
            return {}
        end
        local copy = {}
        for i = 1, #items do
            copy[i] = items[i]
        end
        local out = {}
        for i = 1, math.min(n, #copy) do
            local idx = math.random(1, #copy)
            out[#out + 1] = copy[idx]
            table.remove(copy, idx)
        end
        return out
    end

    return Random
end)

return PDNPC.use('shared.random')


