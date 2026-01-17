local Config = {}

---@param resourceName string
---@return table
function Config.get(resourceName)
    return Config
end

---@class ALRPConfig
---@field toggleKey number
---@field scanDistance number
---@field blipDistance number
---@field blipSprite number
---@field blipColor number
---@field blipScale number
---@field autoScanEnabled boolean
---@field autoScanInterval number
---@field autoScanCooldown number
---@field requirePoliceVehicle boolean
Config.toggleKey = 168
Config.scanDistance = 15.0
Config.blipDistance = 200.0
Config.blipSprite = 225
Config.blipColor = 1
Config.blipScale = 0.8
Config.autoScanEnabled = true
Config.autoScanInterval = 1000
Config.autoScanCooldown = 1000
Config.requirePoliceVehicle = true

return Config

