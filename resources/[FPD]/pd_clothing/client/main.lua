local Config = require('config')
local Appearance = require('client.appearance')

local isMenuOpen = false
local originalCoords = nil
local originalPed = nil
local previewCamera = nil
local currentAppearance = nil
local originalAppearance = nil

---@param ped number
local function setupPreviewPed(ped)
    if not DoesEntityExist(ped) then
        return
    end
    
    originalCoords = GetEntityCoords(ped)
    originalPed = ped
    
    SetEntityCoords(ped, Config.skyCoords.x, Config.skyCoords.y, Config.skyCoords.z, false, false, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, false, false)
    
    ClearTimecycleModifier()
    SetTimecycleModifierStrength(0.0)
end

local function setupPreviewCamera()
    if previewCamera then
        return
    end
    
    local camCoords = vector3(Config.previewCoords.x - 1.5, Config.previewCoords.y - 1.5, Config.previewCoords.z + 0.5)
    previewCamera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(previewCamera, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(previewCamera, Config.previewCoords.x, Config.previewCoords.y, Config.previewCoords.z)
    SetCamActive(previewCamera, true)
    RenderScriptCams(true, false, 0, true, true)
end

local function cleanupPreviewCamera()
    if previewCamera then
        RenderScriptCams(false, false, 0, true, true)
        SetCamActive(previewCamera, false)
        DestroyCam(previewCamera, false)
        previewCamera = nil
    end
end

local function restorePed()
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        if originalCoords then
            SetEntityCoords(ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, true)
        end
        SetEntityVisible(ped, true, false)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
        SetEntityCollision(ped, true, true)
    end
    
    if originalAppearance then
        Appearance.apply(ped, originalAppearance)
    end
    
    originalCoords = nil
    originalPed = nil
end

---@param data table
local function openMenu(data)
    if isMenuOpen then
        return
    end
    
    isMenuOpen = true
    local ped = PlayerPedId()
    
    originalAppearance = Appearance.extract(ped)
    currentAppearance = data.appearance or originalAppearance
    
    setupPreviewPed(ped)
    setupPreviewCamera()
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'open',
        appearance = currentAppearance,
        outfits = data.outfits or {}
    })
end

local function closeMenu()
    if not isMenuOpen then
        return
    end
    
    isMenuOpen = false
    
    ClearTimecycleModifier()
    cleanupPreviewCamera()
    restorePed()
    
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'close'
    })
end

CreateThread(function()
    while true do
        Wait(0)
        if isMenuOpen then
            local ped = PlayerPedId()
            if DoesEntityExist(ped) then
                SetEntityCoords(ped, Config.skyCoords.x, Config.skyCoords.y, Config.skyCoords.z, false, false, false, true)
                FreezeEntityPosition(ped, true)
                SetEntityInvincible(ped, true)
                SetEntityVisible(ped, true, false)
                SetEntityCollision(ped, false, false)
                ClearTimecycleModifier()
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

RegisterNetEvent('pd_clothing:client:openMenu', function(data)
    openMenu(data)
end)

RegisterNetEvent('pd_clothing:client:closeMenu', function()
    closeMenu()
end)

RegisterNetEvent('pd_clothing:client:receiveData', function(data)
    if isMenuOpen then
        SendNUIMessage({
            type = 'updateData',
            appearance = data.appearance,
            outfits = data.outfits
        })
    end
end)

RegisterNetEvent('pd_clothing:client:appearanceSaved', function()
    if isMenuOpen then
        originalAppearance = currentAppearance
        SendNUIMessage({
            type = 'appearanceSaved'
        })
    end
end)

RegisterNetEvent('pd_clothing:client:appearanceSaveFailed', function()
    if isMenuOpen then
        SendNUIMessage({
            type = 'appearanceSaveFailed'
        })
    end
end)

RegisterNUICallback('pd_clothing:requestData', function(_, cb)
    TriggerServerEvent('pd_clothing:server:requestData')
    cb({ ok = true })
end)

RegisterNUICallback('pd_clothing:updatePreview', function(data, cb)
    if not isMenuOpen then
        cb({ ok = false })
        return
    end
    
    if type(data.appearance) == 'table' then
        currentAppearance = data.appearance
        local ped = PlayerPedId()
        if DoesEntityExist(ped) then
            Appearance.apply(ped, currentAppearance)
        end
    end
    
    cb({ ok = true })
end)

RegisterNUICallback('pd_clothing:close', function(_, cb)
    closeMenu()
    cb({ ok = true })
end)

RegisterNUICallback('pd_clothing:save', function(data, cb)
    if type(data.appearance) == 'table' then
        TriggerServerEvent('pd_clothing:server:saveAppearance', data.appearance)
        currentAppearance = data.appearance
    end
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isMenuOpen then
            closeMenu()
        end
    end
end)

