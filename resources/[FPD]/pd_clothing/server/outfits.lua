local Config = require('config')

---@class Outfits
local Outfits = {}

---@return table[]
function Outfits.getAll()
    return Config.presetOutfits or {}
end

---@param name string
---@return table|nil
function Outfits.getByName(name)
    local outfits = Outfits.getAll()
    for _, outfit in ipairs(outfits) do
        if outfit.name == name then
            return outfit
        end
    end
    return nil
end

return Outfits

