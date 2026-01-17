PDNPC = PDNPC or {}
PDNPC._registry = PDNPC._registry or {}
PDNPC._cache = PDNPC._cache or {}

---@param name string
---@param factory fun():any
function PDNPC.provide(name, factory)
    if PDNPC._registry[name] then
        return
    end
    PDNPC._registry[name] = factory
end

---@param name string
---@return any
function PDNPC.use(name)
    if PDNPC._cache[name] then
        return PDNPC._cache[name]
    end
    local factory = PDNPC._registry[name]
    if not factory then
        error('pd_npc missing module ' .. name)
    end
    local value = factory()
    PDNPC._cache[name] = value
    return value
end

return PDNPC


