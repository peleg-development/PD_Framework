---@class PlayerData
local PlayerData = {
    data = nil
}

RegisterNetEvent('pd_core:client:playerDataSync', function(session)
    PlayerData.data = session
end)

---@return PDPlayerData|nil
function PlayerData.get()
    return PlayerData.data
end

return PlayerData

