PDNPC.provide('shared.generate', function()
    local Config = PDNPC.use('config')
    local Random = PDNPC.use('shared.random')

    local Generate = {}

    local firstNames = { 'John', 'Michael', 'David', 'James', 'Robert', 'Daniel', 'Anthony', 'Brian', 'Kevin', 'Jason', 'Sarah', 'Emily', 'Jessica', 'Ashley', 'Amanda', 'Melissa', 'Lauren', 'Rachel', 'Nicole', 'Brittany' }
    local lastNames = { 'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas' }
    local warrantPool = { 'FTA', 'Bench warrant', 'Probation violation' }

    ---@return PDNPCIdentity
    function Generate.identity()
        local first = Random.pick(firstNames) or 'John'
        local last = Random.pick(lastNames) or 'Doe'
        local sex = math.random() < 0.5 and 'M' or 'F'
        local year = math.random(1965, 2006)
        local month = math.random(1, 12)
        local day = math.random(1, 28)
        local dob = ('%04d-%02d-%02d'):format(year, month, day)
        return {
            first = first,
            last = last,
            full = ('%s %s'):format(first, last),
            dob = dob,
            sex = sex
        }
    end

    ---@return PDNPCItem[]
    function Generate.inventory()
        local items = {}
        local legalCount = math.random(1, 3)
        local illegalCount = Random.chance(Config.probabilities.illegalItem) and 1 or 0
        local legal = Random.sample(Config.itemPools.legal or {}, legalCount)
        local illegal = illegalCount > 0 and Random.sample(Config.itemPools.illegal or {}, illegalCount) or {}
        for _, def in ipairs(legal) do
            items[#items + 1] = { id = def.id, label = def.label, count = 1, illegal = def.illegal }
        end
        for _, def in ipairs(illegal) do
            items[#items + 1] = { id = def.id, label = def.label, count = 1, illegal = def.illegal }
        end
        return items
    end

    ---@return PDNPCItem[]
    function Generate.vehicleInventory()
        local items = {}
        local legalCount = math.random(0, 2)
        local illegalCount = Random.chance(Config.probabilities.illegalItem * 0.75) and 1 or 0
        local legal = legalCount > 0 and Random.sample(Config.vehicleItemPools.legal or {}, legalCount) or {}
        local illegal = illegalCount > 0 and Random.sample(Config.vehicleItemPools.illegal or {}, illegalCount) or {}
        for _, def in ipairs(legal) do
            items[#items + 1] = { id = def.id, label = def.label, count = 1, illegal = def.illegal }
        end
        for _, def in ipairs(illegal) do
            items[#items + 1] = { id = def.id, label = def.label, count = 1, illegal = def.illegal }
        end
        return items
    end

    ---@return string[]|nil
    function Generate.warrants()
        if not Random.chance(Config.probabilities.hasWarrants) then
            return nil
        end
        local count = math.random(1, 2)
        local out = {}
        for i = 1, count do
            out[i] = Random.pick(warrantPool) or 'FTA'
        end
        return out
    end

    ---@return PDNPCLicenseInfo
    function Generate.license()
        local statuses = { 'valid', 'expired', 'suspended', 'revoked' }
        local weights = { 0.75, 0.15, 0.07, 0.03 }
        local r = math.random()
        local status = 'valid'
        local cumulative = 0.0
        for i = 1, #statuses do
            cumulative = cumulative + weights[i]
            if r <= cumulative then
                status = statuses[i]
                break
            end
        end
        local now
        local dayMultiplier
        if IsDuplicityVersion() then
            now = os.time()
            dayMultiplier = 24 * 60 * 60
        else
            now = GetGameTimer()
            dayMultiplier = 24 * 60 * 60 * 1000
        end
        local expiration = nil
        if status == 'valid' then
            local daysFromNow = math.random(30, 365 * 3)
            expiration = now + (daysFromNow * dayMultiplier)
        elseif status == 'expired' then
            local daysAgo = math.random(1, 365)
            expiration = now - (daysAgo * dayMultiplier)
        end
        return {
            status = status,
            expiration = expiration
        }
    end

    ---@return PDNPCLicenseInfo
    function Generate.registration()
        local statuses = { 'valid', 'expired', 'suspended' }
        local weights = { 0.80, 0.15, 0.05 }
        local r = math.random()
        local status = 'valid'
        local cumulative = 0.0
        for i = 1, #statuses do
            cumulative = cumulative + weights[i]
            if r <= cumulative then
                status = statuses[i]
                break
            end
        end
        local now
        local dayMultiplier
        if IsDuplicityVersion() then
            now = os.time()
            dayMultiplier = 24 * 60 * 60
        else
            now = GetGameTimer()
            dayMultiplier = 24 * 60 * 60 * 1000
        end
        local expiration = nil
        if status == 'valid' then
            local daysFromNow = math.random(30, 365 * 2)
            expiration = now + (daysFromNow * dayMultiplier)
        elseif status == 'expired' then
            local daysAgo = math.random(1, 180)
            expiration = now - (daysAgo * dayMultiplier)
        end
        return {
            status = status,
            expiration = expiration
        }
    end

    ---@param kind string
    ---@return PDNPCProfile
    function Generate.profile(kind)
        local isDrunk = Random.chance(Config.probabilities.drunk)
        local isDrugged = (not isDrunk) and Random.chance(Config.probabilities.drugged) or Random.chance(Config.probabilities.drugged * 0.35)
        local smellsAlcohol = isDrunk or Random.chance(Config.probabilities.smellsAlcohol)
        local bac = isDrunk and Random.float(Config.bacMin, Config.bacMax, 2) or 0.0
        local drugs = nil
        if isDrugged then
            drugs = {
                type = Random.pick(Config.drugTypes or {}),
                level = Random.float(0.2, 1.0, 2)
            }
        end
        local createdAt
        if IsDuplicityVersion() then
            createdAt = os.time()
        else
            createdAt = GetGameTimer()
        end
        local profile = {
            version = Config.profileVersion,
            createdAt = createdAt,
            identity = Generate.identity(),
            flags = {
                isDrunk = isDrunk,
                isDrugged = isDrugged,
                smellsAlcohol = smellsAlcohol
            },
            bac = isDrunk and bac or nil,
            drugs = drugs,
            inventory = Generate.inventory(),
            vehicleInventory = kind == 'vehicle' and Generate.vehicleInventory() or nil,
            warrants = Generate.warrants()
        }
        if kind == 'vehicle' then
            profile.license = Generate.license()
            profile.registration = Generate.registration()
        end
        return profile
    end

    return Generate
end)

return PDNPC.use('shared.generate')


