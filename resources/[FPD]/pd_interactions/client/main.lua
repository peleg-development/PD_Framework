local Target = require('client.target')
local Actions = require('client.actions')
local Traffic = require('client.traffic')
local Vehicle = require('client.vehicle')

---@return boolean
local function openMenu()
    local ped = Target.getTargetPed(6.0)
    if not ped then
        lib.notify({
            title = 'Stop The Ped',
            description = 'No ped targeted (aim at a ped or get closer).',
            type = 'error'
        })
        return false
    end
    Actions.openMainMenu(ped)
    return true
end

RegisterNetEvent('pd_interactions:client:openMenu', function()
    openMenu()
end)

exports('OpenMenu', function()
    return openMenu()
end)

CreateThread(function()
    local cachedPed = nil
    local cachedVeh = nil
    local lastScan = 0
    while true do
        local now = GetGameTimer()
        if not IsNuiFocused() and not IsPauseMenuActive() then
            local ped = PlayerPedId()
            local inVehicle = IsPedInAnyVehicle(ped, false)
            
            if inVehicle then
                if IsControlJustReleased(0, 21) then
                    Traffic.tryPullOverInFront()
                end
            end
            
            if now - lastScan > 100 then
                lastScan = now
                if not inVehicle then
                    cachedPed = Target.getTargetPed(5.0)
                    cachedVeh = Target.getTargetVehicle(6.0)
                else
                    cachedPed = nil
                    cachedVeh = nil
                end
            end
            
            if cachedPed then
                DisableControlAction(0, 38, true)
                if IsDisabledControlJustReleased(0, 38) then
                    Actions.openMainMenu(cachedPed)
                end
            end
            
            if cachedVeh then
                DisableControlAction(0, 47, true)
                if IsDisabledControlJustReleased(0, 47) then
                    Vehicle.openMenu(cachedVeh)
                end
            end
        end
        Wait(0)
    end
end)

return {
    openMenu = openMenu
}


