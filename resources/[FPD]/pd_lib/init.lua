PDLib = PDLib or {}
PDLib._requireCache = PDLib._requireCache or {}

---@param name string
---@param default number
---@return number
function PDLib._convarInt(name, default)
    local v = GetConvar(name, tostring(default))
    return tonumber(v) or default
end

---@return boolean
function PDLib.isDebug()
    local res = GetCurrentResourceName()
    local override = PDLib._convarInt(res .. ':debug', -1)
    if override ~= -1 then
        return override == 1
    end
    return PDLib._convarInt('pd_debug', 1) == 1
end

---@param tag string
---@param fmt string
---@param ... any
function PDLib.debug(tag, fmt, ...)
    if not PDLib.isDebug() then
        return
    end
    local ok, msg = pcall(string.format, fmt, ...)
    if not ok then
        msg = tostring(fmt)
    end
    print(('[%s] %s'):format(tag, msg))
end

---@param moduleName string
---@return string, string
function PDLib._resolveModule(moduleName)
    local name = tostring(moduleName)
    local resource = GetCurrentResourceName()
    if name:sub(1, 1) == '@' then
        local slash = name:find('/', 2, true)
        if slash then
            resource = name:sub(2, slash - 1)
            name = name:sub(slash + 1)
        else
            resource = name:sub(2)
            name = 'init.lua'
        end
    end
    if name:find('%.') and not name:find('/') then
        name = name:gsub('%.', '/')
    end
    if not name:match('%.lua$') then
        name = name .. '.lua'
    end
    return resource, name
end

---@param moduleName string
---@return any
function PDLib.require(moduleName)
    local resource, path = PDLib._resolveModule(moduleName)
    local key = resource .. ':' .. path
    if PDLib._requireCache[key] ~= nil then
        return PDLib._requireCache[key]
    end
    local code = LoadResourceFile(resource, path)
    if type(code) ~= 'string' then
        error(('pd_require missing file %s/%s'):format(resource, path))
    end
    local chunk, err = load(code, ('@%s/%s'):format(resource, path), 't', _ENV)
    if not chunk then
        error(('pd_require compile error %s/%s: %s'):format(resource, path, err))
    end
    local ok, result = pcall(chunk)
    if not ok then
        error(('pd_require runtime error %s/%s: %s'):format(resource, path, result))
    end
    if result == nil then
        result = true
    end
    PDLib._requireCache[key] = result
    PDLib.debug('pd_require', 'loaded %s', key)
    return result
end

require = PDLib.require
_G.require = PDLib.require

lib = lib or {}

---@class PDLibNotify
---@field title string|nil
---@field description string|nil
---@field type string|nil
---@field duration number|nil
---@field position string|nil
---@field target number|nil

---@param data PDLibNotify
function lib.notify(data)
    local origin = GetCurrentResourceName()
    if IsDuplicityVersion() then
        local target = data and data.target
        if type(target) ~= 'number' then
            return false
        end
        TriggerClientEvent('pd_lib:notify', target, origin, data)
        return true
    end
    TriggerEvent('pd_lib:notify', origin, data)
    return true
end

---@class PDLibDialogueOpen
---@field title string|nil
---@field subtitle string|nil
---@field reset boolean|nil
---@field duration number|nil
---@field target number|nil

---@param data PDLibDialogueOpen
function lib.dialogueOpen(data)
    local origin = GetCurrentResourceName()
    if IsDuplicityVersion() then
        local target = data and data.target
        if type(target) ~= 'number' then
            return false
        end
        TriggerClientEvent('pd_lib:dialogue:open', target, origin, data)
        return true
    end
    TriggerEvent('pd_lib:dialogue:open', origin, data)
    return true
end

---@class PDLibDialogueLine
---@field side string
---@field name string|nil
---@field text string
---@field target number|nil

---@param data PDLibDialogueLine
function lib.dialoguePush(data)
    local origin = GetCurrentResourceName()
    if IsDuplicityVersion() then
        local target = data and data.target
        if type(target) ~= 'number' then
            return false
        end
        TriggerClientEvent('pd_lib:dialogue:push', target, origin, data)
        return true
    end
    TriggerEvent('pd_lib:dialogue:push', origin, data)
    return true
end

---@class PDLibDialogueClose
---@field target number|nil

---@param data PDLibDialogueClose|nil
function lib.dialogueClose(data)
    local origin = GetCurrentResourceName()
    if IsDuplicityVersion() then
        local target = data and data.target
        if type(target) ~= 'number' then
            return false
        end
        TriggerClientEvent('pd_lib:dialogue:close', target, origin, data)
        return true
    end
    TriggerEvent('pd_lib:dialogue:close', origin, data)
    return true
end

---@class PDLibResultField
---@field label string
---@field value string
---@field color string|nil

---@class PDLibResultData
---@field kind string
---@field title string
---@field subtitle string|nil
---@field fields PDLibResultField[]
---@field duration number|nil
---@field target number|nil

---@param data PDLibResultData
function lib.showResult(data)
    local origin = GetCurrentResourceName()
    if IsDuplicityVersion() then
        local target = data and data.target
        if type(target) ~= 'number' then
            return false
        end
        TriggerClientEvent('pd_lib:result:show', target, origin, data)
        return true
    end
    TriggerEvent('pd_lib:result:show', origin, data)
    return true
end

---@class PDLibResultClose
---@field target number|nil

---@param data PDLibResultClose|nil
function lib.closeResult(data)
    local origin = GetCurrentResourceName()
    if IsDuplicityVersion() then
        local target = data and data.target
        if type(target) ~= 'number' then
            return false
        end
        TriggerClientEvent('pd_lib:result:close', target, origin, data)
        return true
    end
    TriggerEvent('pd_lib:result:close', origin, data)
    return true
end

---@class PDLibContextOption
---@field id string
---@field title string
---@field description string|nil
---@field disabled boolean|nil
---@field color string|nil
---@field value string|nil
---@field valueColor string|nil
---@field values string[]|nil
---@field valueIndex number|nil
---@field onSelect fun(data: { valueIndex: number, value: string|nil })|nil
---@field onChange fun(data: { valueIndex: number, value: string|nil })|nil

---@class PDLibContext
---@field id string
---@field title string
---@field description string|nil
---@field focus boolean|nil
---@field options PDLibContextOption[]

local _pd_contexts = {}

---@param ctx PDLibContext
function lib.registerContext(ctx)
    if type(ctx) ~= 'table' or type(ctx.id) ~= 'string' then
        return false
    end
    local normalized = {
        id = ctx.id,
        title = ctx.title,
        description = ctx.description,
        focus = ctx.focus ~= false,
        options = {}
    }
    for i, opt in ipairs(ctx.options or {}) do
        local optId = opt.id
        if type(optId) ~= 'string' or optId == '' then
            optId = tostring(i)
        end
        normalized.options[i] = {
            id = optId,
            title = opt.title or optId,
            description = opt.description,
            disabled = opt.disabled and true or false,
            color = opt.color,
            value = opt.value,
            valueColor = opt.valueColor,
            values = opt.values,
            valueIndex = opt.valueIndex or 0,
            onSelect = opt.onSelect,
            onChange = opt.onChange
        }
    end
    _pd_contexts[ctx.id] = normalized
    return true
end

local function sanitizeContext(ctx)
    local options = {}
    for _, opt in ipairs(ctx.options or {}) do
        options[#options + 1] = {
            id = opt.id,
            title = opt.title,
            description = opt.description,
            disabled = opt.disabled and true or false,
            color = opt.color,
            value = opt.value,
            valueColor = opt.valueColor,
            values = opt.values,
            valueIndex = opt.valueIndex or 0
        }
    end
    return {
        id = ctx.id,
        title = ctx.title,
        description = ctx.description,
        focus = ctx.focus ~= false,
        options = options
    }
end

---@param id string
function lib.showContext(id)
    if IsDuplicityVersion() then
        return false
    end
    local ctx = _pd_contexts[id]
    if not ctx then
        return false
    end
    TriggerEvent('pd_lib:context:open', GetCurrentResourceName(), sanitizeContext(ctx))
    return true
end

function lib.hideContext()
    if IsDuplicityVersion() then
        return false
    end
    TriggerEvent('pd_lib:context:close')
    return true
end

---@class PDLibProgressData
---@field duration number
---@field label string
---@field canCancel boolean|nil

local _pd_progress = {}

---@param data PDLibProgressData
---@return boolean
function lib.progressBar(data)
    if IsDuplicityVersion() then
        return false
    end
    if type(data) ~= 'table' or type(data.duration) ~= 'number' then
        return false
    end
    local id = tostring(math.random(100000, 999999)) .. '_' .. tostring(GetGameTimer())
    local p = promise.new()
    _pd_progress[id] = {
        promise = p
    }
    TriggerEvent('pd_lib:progress:start', GetCurrentResourceName(), id, {
        duration = data.duration,
        label = data.label or '',
        canCancel = data.canCancel and true or false
    })
    local result = Citizen.Await(p)
    return result == true
end

AddEventHandler('pd_lib:contextSelected', function(originResource, contextId, optionId, valueIndex, value)
    if originResource ~= GetCurrentResourceName() then
        return
    end
    local ctx = _pd_contexts[contextId]
    if not ctx then
        return
    end
    for _, opt in ipairs(ctx.options or {}) do
        if opt.id == optionId and type(opt.onSelect) == 'function' and not opt.disabled then
            opt.onSelect({ valueIndex = valueIndex, value = value })
            return
        end
    end
end)

AddEventHandler('pd_lib:contextValueChanged', function(originResource, contextId, optionId, valueIndex, value)
    if originResource ~= GetCurrentResourceName() then
        return
    end
    local ctx = _pd_contexts[contextId]
    if not ctx then
        return
    end
    for _, opt in ipairs(ctx.options or {}) do
        if opt.id == optionId and type(opt.onChange) == 'function' then
            opt.onChange({ valueIndex = valueIndex, value = value })
            return
        end
    end
end)

AddEventHandler('pd_lib:progressResult', function(originResource, progressId, success)
    if originResource ~= GetCurrentResourceName() then
        return
    end
    local entry = _pd_progress[progressId]
    if not entry then
        return
    end
    _pd_progress[progressId] = nil
    entry.promise:resolve(success == true)
end)

return lib

