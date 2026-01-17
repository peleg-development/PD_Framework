PDNPC.provide('client.population', function()
    local Config = PDNPC.use('config')
    local Profile = PDNPC.use('client.profile')

    local Population = {}

    local started = false
    local queued = {}
    local queue = {}
    local qHead = 1

    local tracked = {}

    ---@param entity number
    ---@return boolean
    local function isValidPed(entity)
        if type(entity) ~= 'number' or entity == 0 then
            return false
        end
        if not DoesEntityExist(entity) then
            return false
        end
        if GetEntityType(entity) ~= 1 then
            return false
        end
        if IsPedAPlayer(entity) then
            return false
        end
        if IsEntityDead(entity) then
            return false
        end
        return true
    end

    ---@param entity number
    local function enqueue(entity)
        if queued[entity] then
            return
        end
        queued[entity] = true
        queue[#queue + 1] = entity
    end

    ---@return number|nil
    local function dequeue()
        local entity = queue[qHead]
        if not entity then
            return nil
        end
        queue[qHead] = nil
        qHead = qHead + 1
        if qHead > 512 then
            local new = {}
            for i = qHead, #queue do
                new[#new + 1] = queue[i]
            end
            queue = new
            qHead = 1
        end
        return entity
    end

    ---@param ped number
    ---@param radius number
    ---@return boolean
    local function withinRadius(ped, radius)
        local r = type(radius) == 'number' and radius or 120.0
        local p = PlayerPedId()
        local pc = GetEntityCoords(p)
        local ec = GetEntityCoords(ped)
        return #(pc - ec) <= r
    end

    local function configPopulation()
        local pop = type(Config.population) == 'table' and Config.population or {}
        local enabled = pop.enabled ~= false
        local radius = type(pop.pedRadius) == 'number' and pop.pedRadius or 120.0
        local maxPerTick = type(pop.maxPerTick) == 'number' and pop.maxPerTick or 5
        local scanOnStart = pop.scanOnStart ~= false
        local reapplyMs = type(pop.reapplyMs) == 'number' and pop.reapplyMs or 3000
        return enabled, radius, maxPerTick, scanOnStart, reapplyMs
    end

    ---@return boolean
    function Population.start()
        if started then
            return true
        end
        local enabled, radius, maxPerTick, scanOnStart, reapplyMs = configPopulation()
        if not enabled then
            return false
        end
        started = true

        AddEventHandler('entityCreated', function(entity)
            if not started then
                return
            end
            if isValidPed(entity) and withinRadius(entity, radius) then
                enqueue(entity)
            end
        end)

        if scanOnStart then
            CreateThread(function()
                local pool = GetGamePool('CPed')
                for i, ped in ipairs(pool) do
                    if isValidPed(ped) and withinRadius(ped, radius) then
                        enqueue(ped)
                    end
                    if i % 150 == 0 then
                        Wait(0)
                    end
                end
            end)
        end

        CreateThread(function()
            while started do
                local processed = 0
                while processed < maxPerTick do
                    local entity = dequeue()
                    if not entity then
                        break
                    end
                    queued[entity] = nil
                    if isValidPed(entity) and withinRadius(entity, radius) then
                        local profile = Profile.ensureLocal(entity, 'ped')
                        local flags = profile and profile.flags
                        if type(flags) == 'table' and (flags.isDrunk or flags.isDrugged) then
                            tracked[entity] = true
                        end
                    end
                    processed = processed + 1
                end
                if processed == 0 then
                    Wait(500)
                else
                    Wait(0)
                end
            end
        end)

        CreateThread(function()
            while started do
                Wait(reapplyMs)
                for ped, _ in pairs(tracked) do
                    if not DoesEntityExist(ped) or IsEntityDead(ped) then
                        tracked[ped] = nil
                    else
                        Profile.ensureLocal(ped, 'ped')
                    end
                end
            end
        end)

        return true
    end

    return Population
end)

return PDNPC.use('client.population')


