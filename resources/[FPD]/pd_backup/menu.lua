--============================================================
-- AI Backup Menu (NativeUI -> the SAME menu style as your example)
--
-- This follows the exact option fields you showed:
--   id, title, color, value, valueColor, disabled,
--   values, valueIndex, onSelect
--
-- It still uses lib.registerContext / lib.showContext like your example.
--============================================================

math.randomseed(GetGameTimer())

Actions = Actions or {}

-- Globals consumed by your existing spawn events (keep as globals!)
policeman = policeman
police = police
livery = livery
extras = extras
weapon = weapon
gunComponent = gunComponent
pedtype = pedtype
pilot = pilot
helicopter = helicopter

local DeptMap = {
    LSPD = 'lspd',
    LSSD = 'lssd',
    BCSO = 'bcso',
    SAHP = 'sahp',
    FIB  = 'fib'
}

local Colors = {
    patrol = '#3b82f6',
    motor  = '#22c55e',
    swat   = '#a855f7',
    air    = '#14b8a6',
    code4  = '#ef4444'
}

local Values = {
    patrol = { 'LSPD', 'LSSD', 'BCSO', 'SAHP', 'FIB' },
    motor  = { 'LSPD', 'LSSD', 'BCSO', 'SAHP' },
    swat   = { 'LSPD', 'LSSD', 'BCSO', 'SAHP', 'FIB' },
    air    = { 'LSPD', 'LSSD', 'BCSO', 'SAHP', 'FIB' }
}

local State = {
    patrol = { last = nil, t = nil },
    motor  = { last = nil, t = nil },
    swat   = { last = nil, t = nil },
    air    = { last = nil, t = nil }
}

local function pick(list)
    if type(list) ~= 'table' or #list == 0 then return nil end
    return list[math.random(#list)]
end

local function notifyDispatch(msg)
    if type(ShowAdvancedNotification) == 'function' then
        ShowAdvancedNotification(companyIcon, companyName, 'DISPATCH', msg)
    else
        lib.notify({ title = 'DISPATCH', description = msg, type = 'inform' })
    end
end

local function err(msg)
    lib.notify({ title = 'Backup', description = msg, type = 'error' })
end

local function canUseBackupMenu()
    if Config and Config.Framework == 'Standalone' then
        return true
    end

    if not Config or not Config.Framework then
        return false
    end

    if (Config.Framework == 'EXS' or Config.Framework == 'ESX') then
        return ESX and ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name == 'police'
    end

    if Config.Framework == 'QBCore' then
        local job = QBCore and QBCore.PlayerJob
        return job and job.type == 'leo' and job.onduty
    end

    return false
end

local function getSelectedString(data, values)
    if data and type(data.value) == 'string' and data.value ~= '' then
        return data.value
    end

    -- Some menus pass only valueIndex (your example uses valueIndex = 0)
    if data and type(data.valueIndex) == 'number' and type(values) == 'table' then
        -- assume 0-based
        local idx = data.valueIndex + 1
        return values[idx] or values[1]
    end

    return (type(values) == 'table' and values[1]) or nil
end

--============================================================
-- Spawn helpers (sets the same variables your old menu set)
--============================================================

local function spawnPatrol(deptKey)
    local playerPed = PlayerPedId()

    if deptKey == 'lspd' then
        policeman = pick(Config.lspdOfficer)
        police = pick(Config.lspdCar)
        livery = pick(Config.lspdCarLivery)
        extras = Config.lspdCarExtras
        weapon = Config.PatrolGun
        gunComponent = Config.PatrolGunComponent
        pedtype = 6
        if not policeman or not police then return err('LSPD patrol config missing (officers/cars).') end
        notifyDispatch('A LSPD patrol unit is en route to assist')
        TriggerEvent('POL:Spawn', playerPed)
        return
    end

    if deptKey == 'lssd' then
        policeman = pick(Config.lssdOfficer)
        police = pick(Config.lssdCar)
        livery = pick(Config.lssdCarLivery)
        extras = Config.lssdCarExtras
        weapon = Config.PatrolGun
        gunComponent = Config.PatrolGunComponent
        pedtype = 6
        if not policeman or not police then return err('LSSD patrol config missing (officers/cars).') end
        notifyDispatch('A LSSD patrol unit is en route to assist.')
        TriggerEvent('POL:Spawn', playerPed)
        return
    end

    if deptKey == 'bcso' then
        policeman = pick(Config.bcsoOfficer)
        police = pick(Config.bcsoCar)
        livery = pick(Config.bcsoCarLivery)
        extras = Config.bcsoCarExtras
        weapon = Config.PatrolGun
        gunComponent = Config.PatrolGunComponent
        pedtype = 6
        if not policeman or not police then return err('BCSO patrol config missing (officers/cars).') end
        notifyDispatch('A BCSO patrol unit is en route to assist.')
        TriggerEvent('POL:Spawn', playerPed)
        return
    end

    if deptKey == 'sahp' then
        policeman = pick(Config.sahpOfficer)
        police = pick(Config.sahpCar)
        livery = pick(Config.sahpCarLivery)
        extras = Config.sahpCarExtras
        weapon = Config.PatrolGun
        gunComponent = Config.PatrolGunComponent
        pedtype = 6
        if not policeman or not police then return err('SAHP patrol config missing (officers/cars).') end
        notifyDispatch('A SAHP patrol unit is en route to assist.')
        TriggerEvent('POL:Spawn', playerPed)
        return
    end

    if deptKey == 'fib' then
        policeman = pick(Config.fibOfficer)
        police = pick(Config.fibCar)
        livery = pick(Config.fibCarLivery)
        extras = Config.fibCarExtras
        weapon = Config.SwatGun
        gunComponent = Config.SwatGunComponent
        pedtype = 27
        if not policeman or not police then return err('FIB patrol config missing (officers/cars).') end
        notifyDispatch('A FIB unit is en route to assist.')
        TriggerEvent('POL:Spawn', playerPed)
        return
    end
end

local function spawnMotor(deptKey)
    local playerPed = PlayerPedId()

    if deptKey == 'lspd' then
        policeman = pick(Config.lspdMotor)
        police = pick(Config.lspdBike)
        livery = pick(Config.lspdBikeLivery)
        extras = Config.lspdBikeExtras
        weapon = Config.PatrolGun
        gunComponent = Config.PatrolGunComponent
        pedtype = 6
        if not policeman or not police then return err('LSPD motor config missing (riders/bikes).') end
        notifyDispatch('A LSPD motorcycle unit is en route to assist.')
        TriggerEvent('POL:Spawn', playerPed)
        return
    end

    if deptKey == 'lssd' then
        policeman = pick(Config.lssdMotor)
        police = pick(Config.lssdBike)
        livery = pick(Config.lssdBikeLivery)
        extras = Config.lssdBikeExtras
        weapon = Config.PatrolGun
        gunComponent = Config.PatrolGunComponent
        pedtype = 6
        if not policeman or not police then return err('LSSD motor config missing (riders/bikes).') end
        notifyDispatch('A LSSD motorcycle unit is en route to assist.')
        TriggerEvent('POL:Spawn', playerPed)
        return
    end

    if deptKey == 'bcso' then
        policeman = pick(Config.bcsoMotor)
        police = pick(Config.bcsoBike)
        livery = pick(Config.bcsoBikeLivery)
        extras = Config.bcsoBikeExtras
        weapon = Config.PatrolGun
        gunComponent = Config.PatrolGunComponent
        pedtype = 6
        if not policeman or not police then return err('BCSO motor config missing (riders/bikes).') end
        notifyDispatch('A BCSO motorcycle unit is en route to assist.')
        TriggerEvent('POL:Spawn', playerPed)
        return
    end

    if deptKey == 'sahp' then
        policeman = pick(Config.sahpMotor)
        police = pick(Config.sahpBike)
        livery = pick(Config.sahpBikeLivery)
        extras = Config.sahpBikeExtras
        weapon = Config.PatrolGun
        gunComponent = Config.PatrolGunComponent
        pedtype = 6
        if not policeman or not police then return err('SAHP motor config missing (riders/bikes).') end
        notifyDispatch('A SAHP motorcycle unit is en route to assist.')
        TriggerEvent('POL:Spawn', playerPed)
        return
    end
end

local function spawnSwat(deptKey)
    local playerPed = PlayerPedId()

    if deptKey == 'lspd' then
        policeman = pick(Config.lspdSwat)
        police = pick(Config.lspdArmor)
        livery = pick(Config.lspdArmorLivery)
        extras = Config.lspdArmorExtras
        weapon = Config.SwatGun
        gunComponent = Config.SwatGunComponent
        pedtype = 27
        if not policeman or not police then return err('LSPD SWAT config missing (peds/armors).') end
        notifyDispatch('The LSPD SWAT Team is en route to assist.')
        TriggerEvent('POL:Spawn', playerPed)
        return
    end

    if deptKey == 'lssd' then
        policeman = pick(Config.lssdSwat)
        police = pick(Config.lssdArmor)
        livery = pick(Config.lssdArmorLivery)
        extras = Config.lssdArmorExtras
        weapon = Config.SwatGun
        gunComponent = Config.SwatGunComponent
        pedtype = 27
        if not policeman or not police then return err('LSSD SWAT config missing (peds/armors).') end
        notifyDispatch('The LSSD SWAT Team is en route to assist.')
        TriggerEvent('POL:Spawn', playerPed)
        return
    end

    if deptKey == 'bcso' then
        policeman = pick(Config.bcsoSwat)
        police = pick(Config.bcsoArmor)
        livery = pick(Config.bcsoArmorLivery)
        extras = Config.bcsoArmorExtras
        weapon = Config.SwatGun
        gunComponent = Config.SwatGunComponent
        pedtype = 27
        if not policeman or not police then return err('BCSO SWAT config missing (peds/armors).') end
        notifyDispatch('The BCSO SWAT Team is en route to assist.')
        TriggerEvent('POL:Spawn', playerPed)
        return
    end

    if deptKey == 'sahp' then
        policeman = pick(Config.sahpSwat)
        police = pick(Config.sahpArmor)
        livery = pick(Config.sahpArmorLivery)
        extras = Config.sahpArmorExtras
        weapon = Config.SwatGun
        gunComponent = Config.SwatGunComponent
        pedtype = 27
        if not policeman or not police then return err('SAHP SWAT config missing (peds/armors).') end
        notifyDispatch('The SAHP SWAT Team is en route to assist.')
        TriggerEvent('POL:Spawn', playerPed)
        return
    end

    if deptKey == 'fib' then
        policeman = pick(Config.fibSwat)
        police = pick(Config.fibArmor)
        livery = pick(Config.fibArmorLivery)
        extras = Config.fibArmorExtras
        weapon = Config.SwatGun
        gunComponent = Config.SwatGunComponent
        pedtype = 29
        if not policeman or not police then return err('FIB SWAT config missing (peds/armors).') end
        notifyDispatch('The FIB SWAT Team is en route to assist.')
        TriggerEvent('POL:Spawn', playerPed)
        return
    end
end

local function spawnAir(deptKey)
    local playerPed = PlayerPedId()

    if deptKey == 'lspd' then
        pilot = pick(Config.lspdHelicopterPilot)
        helicopter = pick(Config.lspdHelicopter)
        livery = pick(Config.lspdHelicopterLivery)
        pedtype = 6
        if not pilot or not helicopter then return err('LSPD air config missing (pilots/helis).') end
        notifyDispatch('A LSPD air unit is en route to assist.')
        TriggerEvent('POLMav:Spawn', playerPed)
        return
    end

    if deptKey == 'lssd' then
        pilot = pick(Config.lssdHelicopterPilot)
        helicopter = pick(Config.lssdHelicopter)
        livery = pick(Config.lssdHelicopterLivery)
        pedtype = 6
        if not pilot or not helicopter then return err('LSSD air config missing (pilots/helis).') end
        notifyDispatch('A LSSD air unit is en route to assist.')
        TriggerEvent('POLMav:Spawn', playerPed)
        return
    end

    if deptKey == 'bcso' then
        pilot = pick(Config.bcsoHelicopterPilot)
        helicopter = pick(Config.bcsoHelicopter)
        livery = pick(Config.bcsoHelicopterLivery)
        pedtype = 6
        if not pilot or not helicopter then return err('BCSO air config missing (pilots/helis).') end
        notifyDispatch('A BCSO air unit is en route to assist.')
        TriggerEvent('POLMav:Spawn', playerPed)
        return
    end

    if deptKey == 'sahp' then
        pilot = pick(Config.sahpHelicopterPilot)
        helicopter = pick(Config.sahpHelicopter)
        livery = pick(Config.sahpHelicopterLivery)
        pedtype = 6
        if not pilot or not helicopter then return err('SAHP air config missing (pilots/helis).') end
        notifyDispatch('A SAHP air unit is en route to assist.')
        TriggerEvent('POLMav:Spawn', playerPed)
        return
    end

    if deptKey == 'fib' then
        pilot = pick(Config.fibHelicopterPilot)
        helicopter = pick(Config.fibHelicopter)
        livery = pick(Config.fibHelicopterLivery)
        pedtype = 27
        if not pilot or not helicopter then return err('FIB air config missing (pilots/helis).') end
        notifyDispatch('A FIB air unit is en route to assist.')
        TriggerEvent('POLMav:Spawn', playerPed)
        return
    end
end

local function code4Dismiss()
    if type(LeaveScene) == 'function' then
        LeaveScene()
    end
    lib.notify({ title = 'Backup', description = 'Code 4. Backup dismissed.', type = 'success' })
end

--============================================================
-- Menu (matches your example menu format)
--============================================================

function Actions.openBackupMenu()
    if not canUseBackupMenu() then
        err('You are not authorized to use AI Backup.')
        return
    end

    local opts = {}

    opts[#opts + 1] = {
        id = 'patrol_backup',
        title = 'Patrol Backup',
        color = Colors.patrol,
        values = Values.patrol,
        valueIndex = 0,
        value = State.patrol.last and ('Last: ' .. tostring(State.patrol.last)) or 'Request',
        valueColor = Colors.patrol,
        onSelect = function(data)
            local sel = getSelectedString(data, Values.patrol)
            local deptKey = DeptMap[sel]
            if not deptKey then return end
            State.patrol.last = sel
            State.patrol.t = GetGameTimer()
            spawnPatrol(deptKey)
            Actions.openBackupMenu()
        end
    }

    opts[#opts + 1] = {
        id = 'motor_backup',
        title = 'Motor Unit Backup',
        color = Colors.motor,
        values = Values.motor,
        valueIndex = 0,
        value = State.motor.last and ('Last: ' .. tostring(State.motor.last)) or 'Request',
        valueColor = Colors.motor,
        onSelect = function(data)
            local sel = getSelectedString(data, Values.motor)
            local deptKey = DeptMap[sel]
            if not deptKey then return end
            State.motor.last = sel
            State.motor.t = GetGameTimer()
            spawnMotor(deptKey)
            Actions.openBackupMenu()
        end
    }

    opts[#opts + 1] = {
        id = 'swat_backup',
        title = 'SWAT Backup',
        color = Colors.swat,
        values = Values.swat,
        valueIndex = 0,
        value = State.swat.last and ('Last: ' .. tostring(State.swat.last)) or 'Request',
        valueColor = Colors.swat,
        onSelect = function(data)
            local sel = getSelectedString(data, Values.swat)
            local deptKey = DeptMap[sel]
            if not deptKey then return end
            State.swat.last = sel
            State.swat.t = GetGameTimer()
            spawnSwat(deptKey)
            Actions.openBackupMenu()
        end
    }

    opts[#opts + 1] = {
        id = 'air_support',
        title = 'Air Support',
        color = Colors.air,
        values = Values.air,
        valueIndex = 0,
        value = State.air.last and ('Last: ' .. tostring(State.air.last)) or 'Request',
        valueColor = Colors.air,
        onSelect = function(data)
            local sel = getSelectedString(data, Values.air)
            local deptKey = DeptMap[sel]
            if not deptKey then return end
            State.air.last = sel
            State.air.t = GetGameTimer()
            spawnAir(deptKey)
            Actions.openBackupMenu()
        end
    }

    opts[#opts + 1] = {
        id = 'code4',
        title = 'Code 4',
        color = Colors.code4,
        value = 'Dismiss',
        valueColor = Colors.code4,
        onSelect = function()
            code4Dismiss()
        end
    }

    lib.registerContext({
        id = 'ai_backup_main',
        title = 'AI Backup Menu',
        description = 'Spawn AI Officers for Backup',
        focus = true,
        options = opts
    })

    lib.showContext('ai_backup_main')
end

--============================================================
-- Keybind / command
--============================================================

RegisterCommand('+backup', function()
    Actions.openBackupMenu()
end, false)

RegisterCommand('-backup', function() end, false)

-- Default key: Numpad + (ADD)
RegisterKeyMapping('+backup', 'Open AI Backup Menu', 'keyboard', 'B')
