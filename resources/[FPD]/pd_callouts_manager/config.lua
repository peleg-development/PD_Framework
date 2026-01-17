---@class PDCalloutsManagerMetadataConfig
---@field tenFourKey string
---@field rankKey string
---@field departmentKey string

---@class PDCalloutsManagerConfig
---@field enabled boolean
---@field offerTimeoutMs number
---@field tickIntervalMs number
---@field maxDistance number
---@field requireActiveDuty boolean
---@field metadata PDCalloutsManagerMetadataConfig
local Config = {
    enabled = true,
    offerTimeoutMs = 15000,
    tickIntervalMs = 20000,
    maxDistance = 2500.0,
    requireActiveDuty = false,
    metadata = {
        tenFourKey = 'tenFour',
        rankKey = 'rank',
        departmentKey = 'department'
    },

    DebugMode = true,
}

return Config

