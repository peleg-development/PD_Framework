local activeContext = nil
local activeProgress = nil

RegisterNetEvent('pd_lib:notify', function(originResource, data)
    SendNUIMessage({
        type = 'notify:add',
        origin = originResource,
        data = data
    })
end)

RegisterNetEvent('pd_lib:context:open', function(originResource, context)
    activeContext = {
        origin = originResource,
        id = context and context.id
    }
    -- Only enable keyboard focus, not mouse focus (so player can still move)
    local focus = context and context.focus ~= false
    SetNuiFocus(focus, false) -- (keyboard, mouse) - mouse always false
    SetNuiFocusKeepInput(focus) -- Allow game input while NUI has focus
    SendNUIMessage({
        type = 'context:open',
        origin = originResource,
        context = context
    })
end)

RegisterNetEvent('pd_lib:context:close', function()
    activeContext = nil
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        type = 'context:close'
    })
end)

RegisterNetEvent('pd_lib:progress:start', function(originResource, progressId, data)
    activeProgress = {
        origin = originResource,
        id = progressId,
        canCancel = data and data.canCancel == true
    }
    SendNUIMessage({
        type = 'progress:start',
        origin = originResource,
        id = progressId,
        data = data
    })
end)

RegisterNetEvent('pd_lib:progress:end', function(progressId)
    if not activeProgress or activeProgress.id ~= progressId then
        return
    end
    activeProgress = nil
    SendNUIMessage({
        type = 'progress:end',
        id = progressId
    })
end)

RegisterNetEvent('pd_lib:dialogue:open', function(originResource, data)
    SendNUIMessage({
        type = 'dialogue:open',
        origin = originResource,
        data = data
    })
end)

RegisterNetEvent('pd_lib:dialogue:push', function(originResource, data)
    SendNUIMessage({
        type = 'dialogue:push',
        origin = originResource,
        data = data
    })
end)

RegisterNetEvent('pd_lib:dialogue:close', function()
    SendNUIMessage({
        type = 'dialogue:close'
    })
end)

RegisterNetEvent('pd_lib:result:show', function(originResource, data)
    SendNUIMessage({
        type = 'result:show',
        origin = originResource,
        data = data
    })
end)

RegisterNetEvent('pd_lib:result:close', function()
    SendNUIMessage({
        type = 'result:close'
    })
end)

RegisterNUICallback('pd_lib_context_select', function(data, cb)
    local origin = data and data.origin
    local contextId = data and data.contextId
    local optionId = data and data.optionId
    local valueIndex = data and data.valueIndex
    local value = data and data.value
    activeContext = nil
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    TriggerEvent('pd_lib:contextSelected', origin, contextId, optionId, valueIndex, value)
    cb({ ok = true })
end)

RegisterNUICallback('pd_lib_context_value_change', function(data, cb)
    local origin = data and data.origin
    local contextId = data and data.contextId
    local optionId = data and data.optionId
    local valueIndex = data and data.valueIndex
    local value = data and data.value
    TriggerEvent('pd_lib:contextValueChanged', origin, contextId, optionId, valueIndex, value)
    cb({ ok = true })
end)

RegisterNUICallback('pd_lib_context_close', function(_, cb)
    activeContext = nil
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    cb({ ok = true })
end)

RegisterNUICallback('pd_lib_progress_result', function(data, cb)
    local origin = data and data.origin
    local id = data and data.id
    local success = data and data.success == true
    TriggerEvent('pd_lib:progressResult', origin, id, success)
    TriggerEvent('pd_lib:progress:end', id)
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        if not activeProgress then
            Wait(250)
        else
            if activeProgress.canCancel and IsControlJustReleased(0, 202) then
                local origin = activeProgress.origin
                local id = activeProgress.id
                TriggerEvent('pd_lib:progressResult', origin, id, false)
                TriggerEvent('pd_lib:progress:end', id)
            end
            Wait(0)
        end
    end
end)

RegisterCommand('notify', function()
    lib.notify({
        title = 'Example Notify',
        description = 'This is a test notification from pd_lib!',
        type = 'info',
        duration = 5000
    })
    lib.notify({
        title = 'Success',
        description = 'Operation completed successfully',
        type = 'success',
        duration = 3000
    })
    lib.notify({
        title = 'Warning',
        description = 'Something needs your attention',
        type = 'warning',
        duration = 4000
    })
    lib.notify({
        title = 'Error',
        description = 'An error occurred',
        type = 'error',
        duration = 5000
    })
end, false)

RegisterCommand('progress', function()
    CreateThread(function()
        local ok = lib.progressBar({
            label = 'Example Progress',
            duration = 5000,
            canCancel = true
        })
        if ok then
            lib.notify({
                title = 'Progress Complete',
                description = 'The progress bar finished successfully!',
                type = 'success'
            })
        else
            lib.notify({
                title = 'Progress Cancelled',
                description = 'You cancelled the progress bar',
                type = 'warning'
            })
        end
    end)
end, false)

---@param model string
---@param timeoutMs number|nil
---@return number|nil
local function loadVehicleModel(model, timeoutMs)
    if type(model) ~= 'string' or model == '' then
        return nil
    end
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        return nil
    end
    RequestModel(hash)
    local t = GetGameTimer() + (type(timeoutMs) == 'number' and timeoutMs or 5000)
    while not HasModelLoaded(hash) and GetGameTimer() < t do
        Wait(0)
    end
    if not HasModelLoaded(hash) then
        return nil
    end
    return hash
end

RegisterCommand('car', function(_, args)
    local model = args and args[1]
    if type(model) ~= 'string' or model == '' then
        lib.notify({
            title = 'Car',
            description = 'Usage: /car <model>',
            type = 'info'
        })
        return
    end
    local hash = loadVehicleModel(model, 5000)
    if not hash then
        lib.notify({
            title = 'Car',
            description = 'Invalid vehicle model: ' .. tostring(model),
            type = 'error'
        })
        return
    end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local f = GetEntityForwardVector(ped)
    local spawn = vec3(coords.x + f.x * 3.5, coords.y + f.y * 3.5, coords.z + 0.5)
    local vehicle = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, heading, true, true)
    if not vehicle or vehicle == 0 then
        SetModelAsNoLongerNeeded(hash)
        lib.notify({
            title = 'Car',
            description = 'Failed to create vehicle.',
            type = 'error'
        })
        return
    end
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetPedIntoVehicle(ped, vehicle, -1)
    SetModelAsNoLongerNeeded(hash)
    lib.notify({
        title = 'Car',
        description = 'Spawned ' .. tostring(model),
        type = 'success'
    })
end, false)


