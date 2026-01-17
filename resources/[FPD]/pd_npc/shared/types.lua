---@class PDNPCIdentity
---@field first string
---@field last string
---@field full string
---@field dob string
---@field sex string

---@class PDNPCDrugInfo
---@field type string|nil
---@field level number|nil

---@class PDNPCFlags
---@field isDrunk boolean
---@field isDrugged boolean
---@field smellsAlcohol boolean

---@class PDNPCItem
---@field id string
---@field label string
---@field count number
---@field illegal boolean|nil

---@class PDNPCLicenseInfo
---@field status string|nil
---@field expiration number|nil

---@class PDNPCProfile
---@field version number
---@field createdAt number
---@field identity PDNPCIdentity
---@field flags PDNPCFlags
---@field bac number|nil
---@field drugs PDNPCDrugInfo|nil
---@field inventory PDNPCItem[]
---@field vehicleInventory PDNPCItem[]|nil
---@field warrants string[]|nil
---@field license PDNPCLicenseInfo|nil
---@field registration PDNPCLicenseInfo|nil

PDNPC.provide('shared.types', function()
    local Types = {}
    return Types
end)

return PDNPC.use('shared.types')


