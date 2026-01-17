    ---@class PDCalloutDef
    ---@field name string
    ---@field code string
    ---@field title string
    ---@field description string
    ---@field department string|nil
    ---@field minRank number|nil
    ---@field startEvent string
    ---@field locations table

---@class Callouts
    local Callouts = {
        registry = {}
    }

---@param def PDCalloutDef
---@return boolean
    local function validDef(def)
        if type(def) ~= 'table' then
            return false
        end
        if type(def.name) ~= 'string' or def.name == '' then
            return false
        end
        if type(def.startEvent) ~= 'string' or def.startEvent == '' then
            return false
        end
        if type(def.locations) ~= 'table' then
            return false
        end
        if type(def.code) ~= 'string' or def.code == '' then
            return false
        end
        if type(def.title) ~= 'string' or def.title == '' then
            return false
        end
        if type(def.description) ~= 'string' then
            return false
        end
        if def.department ~= nil and type(def.department) ~= 'string' then
            return false
        end
        if def.minRank ~= nil and type(def.minRank) ~= 'number' then
            return false
        end
        return true
    end

    ---@param def PDCalloutDef
    ---@return boolean
    function Callouts.register(def)
        if not validDef(def) then
            PDLib.debug('pd_core', 'callout register invalid')
            return false
        end
        Callouts.registry[def.name] = {
            name = def.name,
            code = def.code,
            title = def.title,
            description = def.description,
            department = def.department,
            minRank = def.minRank or 0,
            startEvent = def.startEvent,
            locations = def.locations
        }
        PDLib.debug('pd_core', 'callout register %s (%s)', def.name, def.code)
        return true
    end

    ---@param targetSource number
    ---@param calloutName string
    ---@param payload any
    ---@return boolean
    function Callouts.trigger(targetSource, calloutName, payload)
        if type(targetSource) ~= 'number' then
            return false
        end
        local def = Callouts.registry[calloutName]
        if not def then
            PDLib.debug('pd_core', 'callout trigger missing %s', tostring(calloutName))
            return false
        end
        PDLib.debug('pd_core', 'callout trigger %s -> %s', calloutName, targetSource)
        local out = payload or {}
        if type(out) ~= 'table' then
            out = {}
        end
        out.callout = {
            name = def.name,
            code = def.code,
            title = def.title,
            description = def.description,
            department = def.department,
            minRank = def.minRank
        }
        TriggerClientEvent(def.startEvent, targetSource, out, calloutName)
        return true
    end

    ---@return table<string, PDCalloutDef>
    function Callouts.list()
        local out = {}
        for name, def in pairs(Callouts.registry) do
            local locations = {}
            for i, loc in ipairs(def.locations or {}) do
                locations[i] = loc
            end
            out[name] = {
                name = def.name,
                code = def.code,
                title = def.title,
                description = def.description,
                department = def.department,
                minRank = def.minRank,
                startEvent = def.startEvent,
                locations = locations
            }
        end
        return out
    end

    return Callouts

