---@class PDSpawnLocation
---@field name string
---@field x number
---@field y number
---@field z number
---@field heading number

---@class PDCharConfig
---@field maxCharacters number
---@field spawnLocations PDSpawnLocation[]
local Config = {
    maxCharacters = 3,
    spawnLocations = {
        { name = 'Mission Row PD', x = 425.1, y = -979.5, z = 30.7, heading = 90.0 },
        { name = 'Sandy Shores', x = 1851.7, y = 3689.5, z = 34.3, heading = 210.0 },
        { name = 'Paleto Bay', x = -448.0, y = 6008.0, z = 31.7, heading = 135.0 },
        { name = 'Los Santos Airport', x = -1037.0, y = -2737.0, z = 20.2, heading = 150.0 },
        { name = 'Pillbox Hill', x = 298.0, y = -584.0, z = 43.3, heading = 70.0 }
    }
}

return Config
