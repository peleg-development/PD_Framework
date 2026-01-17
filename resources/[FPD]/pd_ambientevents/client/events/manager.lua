EventManager = {
    events = {},
    eventTypes = {},
    enabled = true,
    nextEventAt = 0,
}

---@param entities table
---@param anchor vector3
---@param lifetimeMs number
function EventManager.registerEvent(entities, anchor, lifetimeMs)
    EventManager.events[#EventManager.events + 1] = {
        entities = entities,
        anchor = anchor,
        createdAt = GetGameTimer(),
        lifetimeMs = lifetimeMs or 60000
    }
end

---@param name string
---@param fn function
function EventManager.registerEventType(name, fn)
    EventManager.eventTypes[name] = fn
end

---@param force boolean
function EventManager.cleanupEvents(force)
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end
    local p = GetEntityCoords(ped)
    local now = GetGameTimer()

    for i = #EventManager.events, 1, -1 do
        local e = EventManager.events[i]
        local tooOld = (now - e.createdAt) > e.lifetimeMs
        local tooFar = e.anchor and Utils.dist(p, e.anchor) > Config.Events.DespawnDistance

        if force or tooOld or tooFar then
            for _, ent in ipairs(e.entities) do Utils.safeDelete(ent) end
            table.remove(EventManager.events, i)
        end
    end
end

---@return boolean
function EventManager.tryStartEvent()
    if not Config.Events.Enabled or not EventManager.enabled then return false end
    if #EventManager.events >= Config.Events.MaxActive then return false end
    if GetGameTimer() < EventManager.nextEventAt then return false end

    local weights = {}
    for name, weight in pairs(Config.Events.Weights) do
        if name == 'StrangeCall' and not Config.Events.WeirdMode then
            goto continue
        end
        weights[name] = weight
        ::continue::
    end

    local total = 0
    for _, w in pairs(weights) do total = total + w end
    if total <= 0 then return false end

    local r = math.random() * total
    local acc = 0
    local pick = nil
    for k, w in pairs(weights) do
        acc = acc + w
        if r <= acc then
            pick = k
            break
        end
    end

    if not pick or not EventManager.eventTypes[pick] then return false end

    local ok = EventManager.eventTypes[pick]()
    if ok then
        EventManager.nextEventAt = GetGameTimer() + Config.Events.CooldownMs
    end

    return ok
end

