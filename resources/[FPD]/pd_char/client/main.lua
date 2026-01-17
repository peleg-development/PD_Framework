local Config = require('config')
local isUIOpen = false
local currentCharacters = {}
local skyCoords = vector3(0.0, 0.0, 2000.0)
local originalCoords = nil
local originalPed = nil
local previewCamera = nil
local previewCoords = vector3(-75.0, -818.0, 326.0)

local function setupSkyPed()
    local ped = PlayerPedId()
    originalPed = ped
    originalCoords = GetEntityCoords(ped)
    
    SetEntityCoords(ped, skyCoords.x, skyCoords.y, skyCoords.z, false, false, false, true)
    Wait(100)
    
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    
    ClearTimecycleModifier()
    SetTimecycleModifierStrength(0.0)
end

CreateThread(function()
    while true do
        Wait(0)
        if isUIOpen then
            local ped = PlayerPedId()
            if DoesEntityExist(ped) then
                SetEntityCoords(ped, skyCoords.x, skyCoords.y, skyCoords.z, false, false, false, true)
                FreezeEntityPosition(ped, true)
                SetEntityInvincible(ped, true)
                SetEntityVisible(ped, false, false)
                SetEntityCollision(ped, false, false)
                ClearTimecycleModifier()
                
                if previewCamera then
                    local pedCoords = GetEntityCoords(ped)
                    local camCoords = vector3(pedCoords.x, pedCoords.y, pedCoords.z + 10.0)
                    SetCamCoord(previewCamera, camCoords.x, camCoords.y, camCoords.z)
                    PointCamAtCoord(previewCamera, pedCoords.x, pedCoords.y, pedCoords.z)
                end
            end
            DisplayRadar(false)
            DisplayHud(false)
        else
            DisplayRadar(true)
            DisplayHud(true)
            Wait(500)
        end
    end
end)

---@param characters table
local function handleCharacterFlow(characters)
    if isUIOpen then
        return
    end
    isUIOpen = true
    currentCharacters = characters or {}
    
    setupSkyPed()
    
    Wait(200)
    
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local camCoords = vector3(pedCoords.x, pedCoords.y, pedCoords.z + 10.0)
    
    previewCamera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(previewCamera, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(previewCamera, pedCoords.x, pedCoords.y, pedCoords.z)
    SetCamActive(previewCamera, true)
    RenderScriptCams(true, false, 0, true, true)
    
    ClearTimecycleModifier()
    SetNuiFocus(true, true)
    
    if #currentCharacters > 0 then
        local character = currentCharacters[1]
        TriggerServerEvent('pd_char:server:selectCharacter', character.slot)
    else
        SendNUIMessage({
            type = 'openCreation'
        })
    end
end

local function closeSelectionUI()
    if not isUIOpen then
        return
    end
    isUIOpen = false
    
    ClearTimecycleModifier()
    
    if previewCamera then
        RenderScriptCams(false, false, 0, true, true)
        SetCamActive(previewCamera, false)
        DestroyCam(previewCamera, false)
        previewCamera = nil
    end
    
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        SetEntityVisible(ped, true, false)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
        SetEntityCollision(ped, true, true)
    end
    
    SetNuiFocus(false, false)
    
    Wait(100)
    
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        SetEntityVisible(ped, true, false)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
        SetEntityCollision(ped, true, true)
    end
end

---@param characters table
RegisterNetEvent('pd_char:client:receiveCharacters', function(characters)
    currentCharacters = characters or {}
    SendNUIMessage({
        type = 'updateCharacters',
        characters = currentCharacters
    })
end)

RegisterNetEvent('pd_char:client:openSelection', function(characters)
    handleCharacterFlow(characters)
end)

RegisterNetEvent('pd_char:client:closeUI', function()
    closeSelectionUI()
    SendNUIMessage({
        type = 'close'
    })
end)

RegisterNetEvent('pd_char:client:characterCreated', function(character)
    SendNUIMessage({
        type = 'characterCreated',
        character = character
    })
    Wait(500)
    TriggerServerEvent('pd_char:server:selectCharacter', character.slot)
end)

RegisterNetEvent('pd_char:client:characterCreateFailed', function()
    SendNUIMessage({
        type = 'characterCreateFailed'
    })
end)

RegisterNetEvent('pd_char:client:characterSelectFailed', function()
    SendNUIMessage({
        type = 'characterSelectFailed'
    })
end)

RegisterNetEvent('pd_char:client:characterSelected', function(character)
    closeSelectionUI()
    SendNUIMessage({
        type = 'close'
    })
end)

RegisterNetEvent('pd_char:client:openSpawnSelector', function(spawnLocations)
    if not isUIOpen then
        setupSkyPed()
        isUIOpen = true
    end
    
    Wait(200)
    
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        SetEntityCoords(ped, skyCoords.x, skyCoords.y, skyCoords.z, false, false, false, true)
        Wait(100)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetEntityVisible(ped, false, false)
        SetEntityCollision(ped, false, false)
    end
    
    if not previewCamera then
        local pedCoords = GetEntityCoords(ped)
        local camCoords = vector3(pedCoords.x, pedCoords.y, pedCoords.z + 10.0)
        previewCamera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(previewCamera, camCoords.x, camCoords.y, camCoords.z)
        PointCamAtCoord(previewCamera, pedCoords.x, pedCoords.y, pedCoords.z)
        SetCamActive(previewCamera, true)
        RenderScriptCams(true, false, 0, true, true)
    end
    
    ClearTimecycleModifier()
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        type = 'openSpawnSelector',
        spawnLocations = spawnLocations
    })
end)

RegisterNetEvent('pd_char:client:receiveSpawnLocations', function(spawnLocations)
    SendNUIMessage({
        type = 'receiveSpawnLocations',
        spawnLocations = spawnLocations
    })
end)

RegisterNUICallback('pd_char:requestCharacters', function(_, cb)
    TriggerServerEvent('pd_char:server:requestCharacters')
    cb({ ok = true })
end)

RegisterNUICallback('pd_char:createCharacter', function(data, cb)
    TriggerServerEvent('pd_char:server:createCharacter', data.slot, data.data)
    cb({ ok = true })
end)

RegisterNUICallback('pd_char:selectCharacter', function(data, cb)
    TriggerServerEvent('pd_char:server:selectCharacter', data.slot)
    cb({ ok = true })
end)

RegisterNUICallback('pd_char:deleteCharacter', function(data, cb)
    TriggerServerEvent('pd_char:server:deleteCharacter', data.slot)
    cb({ ok = true })
end)

RegisterNUICallback('pd_char:close', function(_, cb)
    closeSelectionUI()
    cb({ ok = true })
end)

RegisterNUICallback('pd_char:selectSpawn', function(data, cb)
    local spawnIndex = data and data.spawnIndex
    if type(spawnIndex) == 'number' then
        isUIOpen = false
        
        if previewCamera then
            RenderScriptCams(false, false, 0, true, true)
            SetCamActive(previewCamera, false)
            DestroyCam(previewCamera, false)
            previewCamera = nil
        end
        
        local ped = PlayerPedId()
        if DoesEntityExist(ped) then
            SetEntityVisible(ped, true, false)
            FreezeEntityPosition(ped, false)
            SetEntityInvincible(ped, false)
            SetEntityCollision(ped, true, true)
        end
        
        SetNuiFocus(false, false)
        
        TriggerServerEvent('pd_char:server:selectSpawn', spawnIndex)
    end
    cb({ ok = true })
end)

exports('OpenSelection', function()
    TriggerServerEvent('pd_char:server:requestCharacters')
end)

exports('GetLocalCharacters', function()
    return currentCharacters
end)
