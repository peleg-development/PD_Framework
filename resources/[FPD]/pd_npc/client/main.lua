local Profile = PDNPC.use('client.profile')
local Population = PDNPC.use('client.population')
local Search = PDNPC.use('client.search')

CreateThread(function()
    local seed = GetGameTimer() + math.random(1000, 9999)
    math.randomseed(seed)
    math.random()
    math.random()
end)

CreateThread(function()
    Population.start()
end)

exports('GetProfile', function(entity)
    return Profile.get(entity)
end)

exports('EnsurePedProfile', function(ped, timeoutMs)
    return Profile.ensureServer(ped, 'ped', timeoutMs)
end)

exports('EnsureVehicleProfile', function(vehicle, timeoutMs)
    return Profile.ensureServer(vehicle, 'vehicle', timeoutMs)
end)

exports('SearchPed', function(ped)
    local profile = Profile.ensureServer(ped, 'ped', 1500)
    if not profile then
        return nil
    end
    return Search.ped(profile)
end)

exports('SearchVehicle', function(vehicle)
    local profile = Profile.ensureServer(vehicle, 'vehicle', 1500)
    if not profile then
        return nil
    end
    return Search.vehicle(profile)
end)

exports('RunBreathalyzer', function(ped)
    local profile = Profile.ensureServer(ped, 'ped', 1500)
    if not profile then
        return nil
    end
    local bac = type(profile.bac) == 'number' and profile.bac or 0.0
    return {
        bac = bac,
        isOverLimit = bac >= 0.08
    }
end)

exports('RunDrugSwab', function(ped)
    local profile = Profile.ensureServer(ped, 'ped', 1500)
    if not profile then
        return nil
    end
    local drugType = profile.drugs and profile.drugs.type or nil
    return {
        isPositive = profile.flags and profile.flags.isDrugged == true,
        drugType = drugType
    }
end)

exports('RunFST', function(ped, testType)
    local profile = Profile.ensureServer(ped, 'ped', 1500)
    if not profile then
        return nil
    end
    local flags = profile.flags or {}
    local failChance = 0.05
    if flags.isDrunk then
        local bac = type(profile.bac) == 'number' and profile.bac or 0.0
        failChance = math.min(0.90, 0.10 + bac * 2.5)
    elseif flags.isDrugged then
        local lvl = profile.drugs and type(profile.drugs.level) == 'number' and profile.drugs.level or 0.5
        failChance = math.min(0.85, 0.20 + lvl * 0.65)
    end
    return {
        test = tostring(testType or 'Unknown'),
        passed = math.random() >= failChance
    }
end)



