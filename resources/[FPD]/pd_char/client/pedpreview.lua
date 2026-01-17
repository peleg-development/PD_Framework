local previewPed = nil
local previewCoords = vector3(-75.0, -818.0, 326.0)
local previewHeading = 180.0

---@param model string
---@return boolean
local function loadModel(model)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return false
    end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    return HasModelLoaded(hash)
end

---@param model string|nil
function CreatePreviewPed(model)
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
        previewPed = nil
    end

    if not model or model == '' then
        return
    end

    if not loadModel(model) then
        PDLib.debug('pd_char', 'failed to load model %s', model)
        return
    end

    previewPed = CreatePed(4, GetHashKey(model), previewCoords.x, previewCoords.y, previewCoords.z, previewHeading, false, true)
    if previewPed and previewPed ~= 0 then
        SetEntityAlpha(previewPed, 200, false)
        SetEntityInvincible(previewPed, true)
        SetBlockingOfNonTemporaryEvents(previewPed, true)
        FreezeEntityPosition(previewPed, true)
        SetEntityCollision(previewPed, false, false)
        TaskStartScenarioInPlace(previewPed, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
    end
end

function DeletePreviewPed()
    if previewPed and DoesEntityExist(previewPed) then
        DeleteEntity(previewPed)
        previewPed = nil
    end
end

CreateThread(function()
    while true do
        Wait(0)
        if previewPed and DoesEntityExist(previewPed) then
            local camCoords = GetGameplayCamCoord()
            local pedCoords = GetEntityCoords(previewPed)
            local distance = #(camCoords - pedCoords)
            
            if distance > 50.0 then
                SetEntityAlpha(previewPed, 0, false)
            else
                SetEntityAlpha(previewPed, 200, false)
            end
            
            DrawLightWithRange(pedCoords.x, pedCoords.y, pedCoords.z + 1.0, 255, 255, 255, 5.0, 2.0)
        else
            Wait(500)
        end
    end
end)

return {
    CreatePreviewPed = CreatePreviewPed,
    DeletePreviewPed = DeletePreviewPed
}

