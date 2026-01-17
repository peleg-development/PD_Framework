local Questions = require('client.questions')
local Traffic = require('client.traffic')
local Custody = require('client.custody')
local PlayerData = require('@pd_core/client/playerdata')

local Actions = {}

local escorting = {}

---@return boolean
local function isOnDuty()
    local data = PlayerData.get()
    if not data then
        return false
    end
    local meta = data.metadata
    local pd = meta and meta.playerdata
    return type(pd) == 'table' and pd.activeDuty == true
end

---@return boolean
local function hasValidJob()
    local data = PlayerData.get()
    if not data then
        return false
    end
    local meta = data.metadata
    local pd = meta and meta.playerdata
    return type(pd) == 'table' and type(pd.job) == 'string' and pd.job ~= ''
end

---@param data { title: string, description: string, type: string|nil, duration: number|nil, position: string|nil }
local function notifyBottomLeft(data)
    if not lib or not lib.notify then
        return
    end
    data.position = 'bottom-left'
    lib.notify(data)
end

---@param sex any
---@return string
local function formatSex(sex)
    if type(sex) == 'string' then
        local s = sex:gsub('^%s+', ''):gsub('%s+$', '')
        if s == '' then
            return 'Unknown'
        end
        local lower = s:lower()
        if lower == 'm' or lower == 'male' then
            return 'Male'
        end
        if lower == 'f' or lower == 'female' then
            return 'Female'
        end
        if lower == 'o' or lower == 'other' then
            return 'Other'
        end
        return s
    end
    if type(sex) == 'number' then
        if sex == 0 then
            return 'Male'
        end
        if sex == 1 then
            return 'Female'
        end
        if sex == 2 then
            return 'Other'
        end
        return tostring(sex)
    end
    if sex == nil then
        return 'Unknown'
    end
    return tostring(sex)
end

---@param docType any
---@return string
local function normalizeDocumentType(docType)
    if type(docType) == 'number' then
        local idx = math.floor(docType)
        if idx == 0 then
            return 'ID Card'
        end
        if idx == 1 then
            return 'License'
        end
        if idx == 2 then
            return 'Registration'
        end
        if idx == 3 then
            return 'Registration'
        end
        return tostring(idx)
    end
    if type(docType) == 'string' then
        local s = docType:gsub('^%s+', ''):gsub('%s+$', '')
        if s == '' then
            return 'ID Card'
        end
        local asNum = tonumber(s)
        if asNum then
            return normalizeDocumentType(asNum)
        end
        local lower = s:lower()
        if lower == 'id' or lower == 'idcard' or lower == 'id card' or lower == 'identification' then
            return 'ID Card'
        end
        if lower == 'license' or lower == 'licence' or lower == 'driver license' or lower == "driver's license" or lower == 'drivers license' then
            return 'License'
        end
        if lower == 'registration' or lower == 'reg' or lower == 'vehicle registration' then
            return 'Registration'
        end
        return s
    end
    return 'ID Card'
end

---@param entity number
---@param timeoutMs number|nil
---@return boolean
local function requestControl(entity, timeoutMs)
    if type(entity) ~= 'number' or entity == 0 or not DoesEntityExist(entity) then
        return false
    end
    if NetworkHasControlOfEntity(entity) then
        return true
    end
    NetworkRequestControlOfEntity(entity)
    local t = GetGameTimer() + (type(timeoutMs) == 'number' and timeoutMs or 900)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() < t do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end
    return NetworkHasControlOfEntity(entity)
end

---@param ped number
---@return boolean
local function validPed(ped)
    if type(ped) ~= 'number' or ped == 0 then
        return false
    end
    if not DoesEntityExist(ped) then
        return false
    end
    if GetEntityType(ped) ~= 1 then
        return false
    end
    if IsPedAPlayer(ped) then
        return false
    end
    if IsEntityDead(ped) then
        return false
    end
    return true
end

---@param ped number
---@return PDNPCProfile|nil
local function ensureProfile(ped)
    if not validPed(ped) then
        return nil
    end
    local profile = exports.pd_npc:EnsurePedProfile(ped, 2000)
    if type(profile) ~= 'table' then
        return nil
    end
    return profile
end

---@param ped number
---@return boolean
local function isInVehicle(ped)
    return IsPedInAnyVehicle(ped, false)
end

---@param ped number
---@return boolean
local function isCuffed(ped)
    return Custody.isCuffed(ped)
end

---@param ped number
---@return boolean
local function canManipulatePed(ped)
    return validPed(ped) and not isInVehicle(ped)
end

---@param ped number
---@param title string
---@param rows { title: string, value: string|nil, valueColor: string|nil, color: string|nil, disabled: boolean|nil }[]
local function showTableMenu(ped, title, rows)
    local opts = {}
    for i, row in ipairs(rows or {}) do
        local isDisabled = row.disabled == true
        opts[#opts + 1] = {
            id = tostring(i),
            title = row.title or '',
            value = row.value,
            valueColor = row.valueColor,
            color = row.color,
            disabled = isDisabled,
            onSelect = (not isDisabled) and function()
                showTableMenu(ped, title, rows)
            end or nil
        }
    end
    opts[#opts + 1] = {
        id = 'back',
        title = 'Back',
        color = '#ef4444',
        value = 'Return',
        valueColor = '#ef4444',
        onSelect = function()
            Actions.openMainMenu(ped)
        end
    }
    local id = 'pd_interactions_table_' .. tostring(GetGameTimer())
    lib.registerContext({
        id = id,
        title = title,
        focus = true,
        options = opts
    })
    lib.showContext(id)
end

---@param ped number
---@param docType string|nil
function Actions.askIdentification(ped, docType)
    local profile = ensureProfile(ped)
    if not profile then
        lib.notify({ title = 'Stop The Ped', description = 'Unable to get ped identity.', type = 'error' })
        return
    end
    local idType = normalizeDocumentType(docType)
    local sex = formatSex(profile.identity and profile.identity.sex)
    lib.showResult({
        kind = 'idcard',
        title = profile.identity and profile.identity.full or 'Unknown',
        subtitle = idType,
        duration = 15000,
        fields = {
            { label = 'Document', value = idType, color = '#f59e0b' },
            { label = 'DOB', value = profile.identity and profile.identity.dob or 'Unknown', color = '#60a5fa' },
            { label = 'Sex', value = sex, color = '#60a5fa' }
        }
    })
    Actions.openMainMenu(ped)
end

---@param ped number
function Actions.requestDispatchCheck(ped)
    local profile = ensureProfile(ped)
    if not profile then
        lib.notify({ title = 'Dispatch', description = 'Unable to run ped check.', type = 'error' })
        return
    end
    local warrants = 'None'
    if type(profile.warrants) == 'table' and #profile.warrants > 0 then
        warrants = table.concat(profile.warrants, ', ')
    end
    local name = profile.identity and profile.identity.full or 'Unknown'
    local dob = profile.identity and profile.identity.dob or 'Unknown'
    local hasWarrants = warrants ~= 'None'
    lib.showResult({
        kind = 'pedcheck',
        title = 'Dispatch: Ped Check',
        subtitle = tostring(name),
        duration = 12000,
        fields = {
            { label = 'Name', value = tostring(name), color = '#e5e7eb' },
            { label = 'DOB', value = tostring(dob), color = '#60a5fa' },
            { label = 'Warrants', value = tostring(warrants), color = hasWarrants and '#f59e0b' or '#22c55e' },
        }
    })
    Actions.openMainMenu(ped)
end

---@param ped number
function Actions.requestVehicleCheck(ped)
    if not validPed(ped) then
        lib.notify({ title = 'Dispatch', description = 'Ped not valid.', type = 'error' })
        return
    end
    local profile = ensureProfile(ped)
    if not profile then
        lib.notify({ title = 'Dispatch', description = 'Unable to run vehicle check.', type = 'error' })
        return
    end
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        lib.notify({ title = 'Dispatch', description = 'No vehicle found for that ped.', type = 'warning' })
        Actions.openMainMenu(ped)
        return
    end
    local vProfile = exports.pd_npc:EnsureVehicleProfile(vehicle, 1500)
    local plate = GetVehicleNumberPlateText(vehicle)
    local model = GetEntityModel(vehicle)
    local display = GetDisplayNameFromVehicleModel(model)
    local label = display and GetLabelText(display) or tostring(display or 'Vehicle')
    if label == 'NULL' then
        label = tostring(display or 'Vehicle')
    end
    local owner = (type(vProfile) == 'table' and vProfile.identity and vProfile.identity.full) or (profile.identity and profile.identity.full) or 'Unknown'
    lib.showResult({
        kind = 'vehiclecheck',
        title = 'Dispatch: Vehicle Check',
        subtitle = tostring(plate or 'UNKNOWN'),
        duration = 12000,
        fields = {
            { label = 'Plate', value = tostring(plate or 'UNKNOWN'), color = '#e5e7eb' },
            { label = 'Vehicle', value = tostring(label), color = '#60a5fa' },
            { label = 'Owner', value = tostring(owner), color = '#e5e7eb' },
            { label = 'Status', value = 'No wants/warrants', color = '#22c55e' },
        }
    })
    Actions.openMainMenu(ped)
end

---@param ped number
function Actions.grabPed(ped)
    if not canManipulatePed(ped) then
        lib.notify({ title = 'Stop The Ped', description = 'Ped not valid.', type = 'error' })
        return
    end
    requestControl(ped, 900)
    local p = PlayerPedId()
    if escorting[ped] then
        escorting[ped] = nil
        ClearPedTasks(ped)
        if isCuffed(ped) then
            TaskStandStill(ped, -1)
        end
        lib.notify({ title = 'Action', description = 'Released the ped.', type = 'info' })
        Actions.openMainMenu(ped)
        return
    end
    escorting[ped] = true
    ClearPedTasks(ped)
    SetPedKeepTask(ped, true)
    TaskFollowToOffsetOfEntity(ped, p, 0.0, 0.8, 0.0, 2.0, -1, 1.0, true)
    lib.notify({ title = 'Action', description = 'Ped is following you.', type = 'success' })
    Actions.openMainMenu(ped)
end

---@param ped number
function Actions.sitGround(ped)
    if not canManipulatePed(ped) then
        lib.notify({ title = 'Stop The Ped', description = 'Ped not valid.', type = 'error' })
        return
    end
    requestControl(ped, 900)
    ClearPedTasks(ped)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_SIT_GROUND', 0, true)
    lib.notify({ title = 'Action', description = 'Ped is sitting on the ground.', type = 'info' })
    Actions.openMainMenu(ped)
end

---@param ped number
function Actions.patDown(ped)
    if not canManipulatePed(ped) then
        lib.notify({ title = 'Search', description = 'Ped not valid.', type = 'error' })
        return
    end
    local ok = lib.progressBar({
        label = 'Patting down...',
        duration = 3500,
        canCancel = true
    })
    if not ok then
        lib.notify({ title = 'Search', description = 'Pat down cancelled.', type = 'warning' })
        Actions.openMainMenu(ped)
        return
    end
    local result = exports.pd_npc:SearchPed(ped)
    if type(result) ~= 'table' then
        lib.notify({ title = 'Search', description = 'Unable to search ped.', type = 'error' })
        Actions.openMainMenu(ped)
        return
    end
    local profile = exports.pd_npc:GetProfile(ped)
    local subtitle = profile and profile.identity and profile.identity.full or 'Ped'
    local fields = {}
    for _, obs in ipairs(result.observations or {}) do
        fields[#fields + 1] = { label = 'Observation', value = tostring(obs), color = '#93c5fd' }
    end
    local hasIllegal = false
    for _, item in ipairs(result.items or {}) do
        local label = tostring((item and (item.label or item.id)) or 'Item')
        local count = tostring((item and item.count) or 1)
        if item and item.illegal then
            hasIllegal = true
            fields[#fields + 1] = { label = label, value = 'Illegal', color = '#ef4444' }
        else
            fields[#fields + 1] = { label = label, value = 'x' .. count, color = '#e5e7eb' }
        end
    end
    lib.showResult({
        kind = 'search',
        title = 'Search: Pat Down',
        subtitle = tostring(subtitle),
        duration = 15000,
        fields = fields
    })
    Actions.openMainMenu(ped)
end

---@param ped number
---@param testType string|nil
function Actions.fieldSobrietyTest(ped, testType)
    if not canManipulatePed(ped) then
        lib.notify({ title = 'Test', description = 'Ped not valid.', type = 'error' })
        return
    end
    local label = 'Running FST...'
    if type(testType) == 'string' and testType ~= '' then
        label = 'Running FST: ' .. testType
    end
    local ok = lib.progressBar({
        label = label,
        duration = 5000,
        canCancel = true
    })
    if not ok then
        lib.notify({ title = 'Test', description = 'FST cancelled.', type = 'warning' })
        Actions.openMainMenu(ped)
        return
    end
    local res = exports.pd_npc:RunFST(ped, testType)
    if type(res) ~= 'table' then
        lib.notify({ title = 'Test', description = 'Unable to run FST.', type = 'error' })
        Actions.openMainMenu(ped)
        return
    end
    local passed = res.passed == true
    lib.showResult({
        kind = 'generic',
        title = 'Field Sobriety Test',
        subtitle = tostring(res.test or testType or 'Unknown'),
        duration = 12000,
        fields = {
            { label = 'Result', value = passed and 'Passed' or 'Failed', color = passed and '#22c55e' or '#ef4444' }
        }
    })
    Actions.openMainMenu(ped)
end

---@param ped number
function Actions.breathalyzer(ped)
    if not validPed(ped) then
        lib.notify({ title = 'Test', description = 'Ped not valid.', type = 'error' })
        return
    end
    local ok = lib.progressBar({
        label = 'Breathalyzer...',
        duration = 4000,
        canCancel = true
    })
    if not ok then
        lib.notify({ title = 'Test', description = 'Breathalyzer cancelled.', type = 'warning' })
        Actions.openMainMenu(ped)
        return
    end
    local res = exports.pd_npc:RunBreathalyzer(ped)
    if type(res) ~= 'table' then
        lib.notify({ title = 'Test', description = 'Unable to run breathalyzer.', type = 'error' })
        Actions.openMainMenu(ped)
        return
    end
    local bac = type(res.bac) == 'number' and res.bac or 0.0
    local over = res.isOverLimit == true
    lib.showResult({
        kind = 'generic',
        title = 'Breathalyzer',
        subtitle = 'Test Result',
        duration = 12000,
        fields = {
            { label = 'BAC', value = string.format('%.2f', bac), color = over and '#ef4444' or '#22c55e' },
            { label = 'Legal Limit', value = '0.08', color = '#60a5fa' },
            { label = 'Result', value = over and 'Over limit' or 'Under limit', color = over and '#ef4444' or '#22c55e' }
        }
    })
    Actions.openMainMenu(ped)
end

---@param ped number
function Actions.drugSwab(ped)
    if not validPed(ped) then
        lib.notify({ title = 'Test', description = 'Ped not valid.', type = 'error' })
        return
    end
    local ok = lib.progressBar({
        label = 'Drug swab...',
        duration = 4000,
        canCancel = true
    })
    if not ok then
        lib.notify({ title = 'Test', description = 'Drug swab cancelled.', type = 'warning' })
        Actions.openMainMenu(ped)
        return
    end
    local res = exports.pd_npc:RunDrugSwab(ped)
    if type(res) ~= 'table' then
        lib.notify({ title = 'Test', description = 'Unable to run drug swab.', type = 'error' })
        Actions.openMainMenu(ped)
        return
    end
    local pos = res.isPositive == true
    lib.showResult({
        kind = 'generic',
        title = 'Drug Swab',
        subtitle = 'Test Result',
        duration = 12000,
        fields = {
            { label = 'Result', value = pos and 'Positive' or 'Negative', color = pos and '#ef4444' or '#22c55e' },
            { label = 'Substance', value = tostring(res.drugType or 'Unknown'), color = '#60a5fa' }
        }
    })
    Actions.openMainMenu(ped)
end

---@param ped number
function Actions.orderOutOfVehicle(ped)
    if not validPed(ped) then
        lib.notify({ title = 'Command', description = 'Ped not valid.', type = 'error' })
        return
    end
    if not isInVehicle(ped) then
        Actions.openMainMenu(ped)
        return
    end
    if Custody.orderExitVehicle(ped) then
        lib.notify({ title = 'Command', description = 'Ordered ped out of the vehicle.', type = 'info' })
    else
        lib.notify({ title = 'Command', description = 'Unable to order ped out.', type = 'error' })
    end
    Actions.openMainMenu(ped)
end

---@param ped number
function Actions.arrest(ped)
    if not canManipulatePed(ped) then
        lib.notify({ title = 'Arrest', description = 'Ped must be out of the vehicle.', type = 'warning' })
        Actions.openMainMenu(ped)
        return
    end
    local ok = Custody.arrest(ped)
    if ok then
        lib.notify({ title = 'Arrest', description = 'Suspect cuffed.', type = 'success' })
    else
        lib.notify({ title = 'Arrest', description = 'Arrest cancelled.', type = 'warning' })
    end
    Actions.openMainMenu(ped)
end

---@param ped number
function Actions.uncuff(ped)
    if not validPed(ped) then
        lib.notify({ title = 'Arrest', description = 'Ped not valid.', type = 'error' })
        return
    end
    Custody.uncuff(ped)
    lib.notify({ title = 'Arrest', description = 'Suspect uncuffed.', type = 'info' })
    Actions.openMainMenu(ped)
end

---@param ped number
function Actions.toggleKneel(ped)
    if not validPed(ped) then
        lib.notify({ title = 'Custody', description = 'Ped not valid.', type = 'error' })
        return
    end
    local ok = Custody.toggleKneel(ped)
    if not ok then
        lib.notify({ title = 'Custody', description = 'Unable to change kneel state.', type = 'warning' })
    end
    Actions.openMainMenu(ped)
end

---@param ped number
function Actions.callTransport(ped)
    if not validPed(ped) then
        lib.notify({ title = 'Transport', description = 'Ped not valid.', type = 'error' })
        return
    end
    if Custody.isTransportRequested(ped) then
        lib.notify({ title = 'Transport', description = 'Transport already requested.', type = 'warning' })
        Actions.openMainMenu(ped)
        return
    end
    local ok = Custody.callTransport(ped)
    if ok then
        lib.notify({ title = 'Transport', description = 'Transport en route.', type = 'info' })
    else
        lib.notify({ title = 'Transport', description = 'Unable to request transport.', type = 'error' })
    end
    Actions.openMainMenu(ped)
end

---@param ped number
function Actions.questionPed(ped)
    if not validPed(ped) then
        lib.notify({ title = 'Questions', description = 'Ped not valid.', type = 'error' })
        return
    end
    Questions.openRoot(ped, function()
        Actions.openMainMenu(ped)
    end)
end

---@param ped number
function Actions.openMainMenu(ped)
    if not validPed(ped) then
        lib.notify({ title = 'Stop The Ped', description = 'Ped not valid.', type = 'error' })
        return
    end
    ---@todo put this back
    -- if not isOnDuty() then
    --     lib.notify({ title = 'Stop The Ped', description = 'You must be on duty to use this menu.', type = 'error' })
    --     return
    -- end
    -- if not hasValidJob() then
    --     lib.notify({ title = 'Stop The Ped', description = 'You must have a valid job to use this menu.', type = 'error' })
    --     return
    -- end
    local profile = ensureProfile(ped)
    if not profile then
        lib.notify({ title = 'Stop The Ped', description = 'Unable to create ped profile.', type = 'error' })
        return
    end
    local pedName = profile.identity and profile.identity.full or 'Unknown'
    local stoppedVeh = Traffic.getStoppedVehicleForPed(ped)
    local stopData = stoppedVeh and Traffic.getStopData(stoppedVeh) or nil
    local canDismissStop = stopData and stopData.officer == GetPlayerServerId(PlayerId())
    local inVeh = isInVehicle(ped)
    local cuff = isCuffed(ped)
    local opts = {}

    if cuff then
        opts[#opts + 1] = {
            id = 'transport',
            title = 'Call Transport',
            color = '#3b82f6',
            value = Custody.isTransportRequested(ped) and 'En route' or 'Request',
            valueColor = '#3b82f6',
            disabled = Custody.isTransportRequested(ped),
            onSelect = function()
                Actions.callTransport(ped)
            end
        }
        opts[#opts + 1] = {
            id = 'kneel',
            title = Custody.isKneeling(ped) and 'Stand Up' or 'Kneel Down',
            color = '#f97316',
            onSelect = function()
                Actions.toggleKneel(ped)
            end
        }
        opts[#opts + 1] = {
            id = 'grab',
            title = 'Grab The Ped',
            color = '#22c55e',
            value = escorting[ped] and 'Release' or 'Grab',
            valueColor = '#22c55e',
            onSelect = function()
                Actions.grabPed(ped)
            end
        }
        opts[#opts + 1] = {
            id = 'pat_down',
            title = 'Pat Down The Ped',
            color = '#f59e0b',
            value = 'Search',
            valueColor = '#f59e0b',
            onSelect = function()
                Actions.patDown(ped)
            end
        }
        opts[#opts + 1] = {
            id = 'uncuff',
            title = 'Uncuff',
            color = '#ef4444',
            value = 'Release',
            valueColor = '#ef4444',
            onSelect = function()
                Actions.uncuff(ped)
            end
        }
    else
        opts[#opts + 1] = {
            id = 'ask_id',
            title = 'Ask Identification',
            color = '#f59e0b',
            values = { 'ID Card', 'License', 'Registration' },
            valueIndex = 0,
            valueColor = '#f59e0b',
            onSelect = function(data)
                Actions.askIdentification(ped, data and (data.value or data.valueIndex))
            end
        }
        opts[#opts + 1] = {
            id = 'request_check',
            title = 'Request Ped Check to Dispatch',
            color = '#3b82f6',
            onSelect = function()
                Actions.requestDispatchCheck(ped)
            end
        }
        opts[#opts + 1] = {
            id = 'vehicle_check',
            title = 'Request Vehicle Check to Dispatch',
            color = '#14b8a6',
            onSelect = function()
                Actions.requestVehicleCheck(ped)
            end
        }
        opts[#opts + 1] = {
            id = 'question',
            title = 'Question The Ped',
            color = '#60a5fa',
            onSelect = function()
                Actions.questionPed(ped)
            end
        }

        if canDismissStop and stoppedVeh then
            local stopVeh = stoppedVeh
            opts[#opts + 1] = {
                id = 'dismiss_stop',
                title = 'Dismiss Traffic Stop',
                color = '#ef4444',
                value = 'Release',
                valueColor = '#ef4444',
                onSelect = function()
                    Traffic.dismiss(stopVeh)
                    if not IsPedInAnyVehicle(ped, false) then
                        requestControl(ped, 900)
                        requestControl(stopVeh, 900)
                        TaskEnterVehicle(ped, stopVeh, 10000, -1, 1.0, 1, 0)
                        Wait(600)
                        TaskVehicleDriveWander(ped, stopVeh, 18.0, 786603)
                    end
                    lib.notify({ title = 'Traffic Stop', description = 'Dismissed. Vehicle can leave.', type = 'success' })
                    Actions.openMainMenu(ped)
                end
            }
        end

        if inVeh then
            opts[#opts + 1] = {
                id = 'order_exit',
                title = 'Order Out Of Vehicle',
                color = '#f97316',
                onSelect = function()
                    Actions.orderOutOfVehicle(ped)
                end
            }
            opts[#opts + 1] = {
                id = 'breathalyzer',
                title = 'Breathalyzer Test',
                color = '#a855f7',
                onSelect = function()
                    Actions.breathalyzer(ped)
                end
            }
            opts[#opts + 1] = {
                id = 'drug_test',
                title = 'Drug Swab Test',
                color = '#a855f7',
                onSelect = function()
                    Actions.drugSwab(ped)
                end
            }
        else
            opts[#opts + 1] = {
                id = 'grab',
                title = 'Grab The Ped',
                color = '#22c55e',
                value = escorting[ped] and 'Release' or 'Grab',
                valueColor = '#22c55e',
                onSelect = function()
                    Actions.grabPed(ped)
                end
            }
            opts[#opts + 1] = {
                id = 'sit_ground',
                title = 'Sit The Ped On Ground',
                color = '#f97316',
                onSelect = function()
                    Actions.sitGround(ped)
                end
            }
            opts[#opts + 1] = {
                id = 'pat_down',
                title = 'Pat Down The Ped',
                color = '#f59e0b',
                value = 'Search',
                valueColor = '#f59e0b',
                onSelect = function()
                    Actions.patDown(ped)
                end
            }
            opts[#opts + 1] = {
                id = 'sobriety',
                title = 'Field Sobriety Test',
                color = '#a855f7',
                values = { 'Horizontal Gaze', 'Walk & Turn', 'One Leg Stand' },
                valueIndex = 0,
                valueColor = '#a855f7',
                onSelect = function(data)
                    Actions.fieldSobrietyTest(ped, data and data.value)
                end
            }
            opts[#opts + 1] = {
                id = 'breathalyzer',
                title = 'Breathalyzer Test',
                color = '#a855f7',
                onSelect = function()
                    Actions.breathalyzer(ped)
                end
            }
            opts[#opts + 1] = {
                id = 'drug_test',
                title = 'Drug Swab Test',
                color = '#a855f7',
                onSelect = function()
                    Actions.drugSwab(ped)
                end
            }
            opts[#opts + 1] = {
                id = 'arrest',
                title = 'Arrest',
                color = '#ef4444',
                value = 'Cuff',
                valueColor = '#ef4444',
                onSelect = function()
                    Actions.arrest(ped)
                end
            }
            opts[#opts + 1] = {
                id = 'escort',
                title = 'Request Escort Vehicle',
                color = '#94a3b8',
                values = { 'Taxi', 'Ambulance', 'Tow Truck', 'Coroner' },
                valueIndex = 0,
                valueColor = '#94a3b8',
                onSelect = function(data)
                    lib.notify({
                        title = 'Request',
                        description = 'Calling ' .. tostring((data and data.value) or 'vehicle') .. '...',
                        type = 'success'
                    })
                    Actions.openMainMenu(ped)
                end
            }
        end
    end

    lib.registerContext({
        id = 'pd_interactions_main',
        title = 'Stop The Ped',
        description = pedName,
        focus = true,
        options = opts
    })
    lib.showContext('pd_interactions_main')
end

return Actions


