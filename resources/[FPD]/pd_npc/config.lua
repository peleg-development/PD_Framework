---@class PDNPCItemDef
---@field id string
---@field label string
---@field illegal boolean|nil

---@class PDNPCConfigProbabilities
---@field drunk number
---@field drugged number
---@field smellsAlcohol number
---@field hasWarrants number
---@field illegalItem number

---@class PDNPCConfigPopulation
---@field enabled boolean
---@field pedRadius number
---@field maxPerTick number
---@field scanOnStart boolean
---@field reapplyMs number

---@class PDNPCConfig
---@field profileVersion number
---@field probabilities PDNPCConfigProbabilities
---@field bacMin number
---@field bacMax number
---@field drugTypes string[]
---@field itemPools { legal: PDNPCItemDef[], illegal: PDNPCItemDef[] }
---@field vehicleItemPools { legal: PDNPCItemDef[], illegal: PDNPCItemDef[] }
---@field population PDNPCConfigPopulation
local Config = {
    profileVersion = 1,
    probabilities = {
        drunk = 0.12,
        drugged = 0.08,
        smellsAlcohol = 0.18,
        hasWarrants = 0.06,
        illegalItem = 0.10
    },
    bacMin = 0.02,
    bacMax = 0.24,
    drugTypes = {
        'weed',
        'cocaine',
        'meth',
        'opioids'
    },
    itemPools = {
        legal = {
            { id = 'wallet', label = 'Wallet' },
            { id = 'phone', label = 'Mobile Phone' },
            { id = 'keys', label = 'Keys' },
            { id = 'cigarettes', label = 'Cigarettes' }
        },
        illegal = {
            { id = 'lockpick', label = 'Lockpick', illegal = true },
            { id = 'small_bag', label = 'Small Baggy', illegal = true },
            { id = 'switchblade', label = 'Switchblade', illegal = true }
        }
    },
    vehicleItemPools = {
        legal = {
            { id = 'firstaid', label = 'First Aid Kit' },
            { id = 'water', label = 'Bottle of Water' },
            { id = 'tools', label = 'Tools' }
        },
        illegal = {
            { id = 'stolen_goods', label = 'Stolen Goods', illegal = true },
            { id = 'drugs_cache', label = 'Hidden Drugs', illegal = true }
        }
    },
    population = {
        enabled = true,
        pedRadius = 120.0,
        maxPerTick = 6,
        scanOnStart = true,
        reapplyMs = 3000
    }
}

PDNPC.provide('config', function()
    return Config
end)

return Config


