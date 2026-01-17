PDNPC.provide('client.search', function()
    local Search = {}

    ---@class PDNPCSearchResult
    ---@field observations string[]
    ---@field items PDNPCItem[]
    ---@field hasIllegal boolean

    ---@param item PDNPCItem
    ---@return boolean
    local function isIllegal(item)
        if type(item) ~= 'table' then
            return false
        end
        return item.illegal == true
    end

    ---@param profile PDNPCProfile
    ---@return string[]
    local function buildObservations(profile)
        local out = {}
        if type(profile) ~= 'table' or type(profile.flags) ~= 'table' then
            return out
        end
        local flags = profile.flags
        if flags.smellsAlcohol then
            out[#out + 1] = 'Smells of alcohol'
        end
        if flags.isDrunk then
            out[#out + 1] = 'Appears intoxicated'
        end
        if flags.isDrugged then
            out[#out + 1] = 'Appears under the influence'
        end
        if type(profile.warrants) == 'table' and #profile.warrants > 0 then
            out[#out + 1] = 'Warrant hit possible'
        end
        return out
    end

    ---@param items PDNPCItem[]
    ---@return boolean
    local function anyIllegal(items)
        if type(items) ~= 'table' then
            return false
        end
        for _, it in ipairs(items) do
            if isIllegal(it) then
                return true
            end
        end
        return false
    end

    ---@param profile PDNPCProfile
    ---@return PDNPCSearchResult
    function Search.ped(profile)
        local items = {}
        if type(profile) == 'table' and type(profile.inventory) == 'table' then
            for i, it in ipairs(profile.inventory) do
                items[i] = it
            end
        end
        return {
            observations = buildObservations(profile),
            items = items,
            hasIllegal = anyIllegal(items)
        }
    end

    ---@param profile PDNPCProfile
    ---@return PDNPCSearchResult
    function Search.vehicle(profile)
        local items = {}
        if type(profile) == 'table' and type(profile.vehicleInventory) == 'table' then
            for i, it in ipairs(profile.vehicleInventory) do
                items[i] = it
            end
        end
        return {
            observations = {},
            items = items,
            hasIllegal = anyIllegal(items)
        }
    end

    return Search
end)

return PDNPC.use('client.search')


