local patrols = {}  
local patrolsEnabled = true

---@param vehPick table
---@param pedModel string
---@return boolean
local function requestPatrolModels(vehPick, pedModel)
    if not Utils.requestModel(vehPick.model) then return false end
    if not Utils.requestModel(pedModel) then
        Utils.releaseModel(vehPick.model)
        return false
    end
    return true
end

---@return nil
local function spawnPatrol()
    if #patrols >= Config.Patrols.MaxActive then return end
    if math.random() > Config.Patrols.SpawnChance then return end

    local spawnPos, heading = Utils.findRoadSpawnAroundPlayer(Config.Patrols.DistanceMin, Config.Patrols.DistanceMax)
    if not spawnPos then return end

    local vehPick = Utils.weightedPick(Config.Patrols.PoliceVehicles)
    local pedModel = Config.Patrols.CopPeds[math.random(1, #Config.Patrols.CopPeds)]

    if not requestPatrolModels(vehPick, pedModel) then return end

    local veh = CreateVehicle(Utils.hash(vehPick.model), spawnPos.x, spawnPos.y, spawnPos.z, heading or 0.0, false, false)
    if not veh or veh == 0 then
        Utils.releaseModel(vehPick.model)
        Utils.releaseModel(pedModel)
        return
    end

    Utils.ensureMission(veh)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleIsStolen(veh, false)

    local driver = CreatePedInsideVehicle(veh, 6, Utils.hash(pedModel), -1, true, false)
    if not driver or driver == 0 then
        Utils.safeDelete(veh)
        Utils.releaseModel(vehPick.model)
        Utils.releaseModel(pedModel)
        return
    end

    Utils.ensureMission(driver)
    SetBlockingOfNonTemporaryEvents(driver, true)
    SetPedKeepTask(driver, true)
    SetPedAsCop(driver, true)

    if math.random() < Config.Patrols.LightsChance then
        SetVehicleSiren(veh, true)
    end

    if math.random() < Config.Patrols.SirenChance then
        SetVehicleSiren(veh, true)
        SetVehicleHasMutedSirens(veh, false)
    else
        SetVehicleHasMutedSirens(veh, true)
    end

    TaskVehicleDriveWander(driver, veh, Config.Patrols.CruiseSpeed, Config.Patrols.DrivingStyle)

    patrols[#patrols + 1] = { veh = veh, driver = driver, createdAt = GetGameTimer() }

    Utils.releaseModel(vehPick.model)
    Utils.releaseModel(pedModel)
end

---@return nil
local function cleanupPatrols()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    local p = GetEntityCoords(ped)
    local now = GetGameTimer()

    for i = #patrols, 1, -1 do
        local it = patrols[i]
        local veh = it.veh
        local driver = it.driver

        local kill = false

        if not DoesEntityExist(veh) then
            kill = true
        else
            local vpos = GetEntityCoords(veh)
            local d = Utils.dist(p, vpos)
            if d > Config.Patrols.DespawnDistance then kill = true end
            if (now - it.createdAt) > Config.Patrols.MaxLifeMs then kill = true end
        end

        if kill then
            Utils.safeDelete(driver)
            Utils.safeDelete(veh)
            table.remove(patrols, i)
        end
    end
end

CreateThread(function()
    math.randomseed(GetGameTimer())

    while true do
        if Config.Patrols.Enabled and patrolsEnabled then
            spawnPatrol()
        end
        cleanupPatrols()
        Wait(Config.Patrols.TickMs)
    end
end)

CreateThread(function()
    while true do
        if Config.Events.Enabled and EventManager.enabled then
            EventManager.tryStartEvent()
        end
        EventManager.cleanupEvents(false)
        Wait(Config.Events.TickMs)
    end
end)
