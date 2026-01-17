local Xml = require('shared.xml')

local Questions = {}

local PAGE_SIZE = 14

local _loaded = false
local _loading = false

local traffic = {}
local customGroups = {}
local customByName = {}
local pedAnswerPools = {}

local FLOW_STEPS = {
    { id = 'greetings', title = 'Greetings', group = 'General Greetings and Statements' },
    { id = 'initiation', title = 'Stop Initiation', group = 'Stop Initiation and Interrogation Dialogue' },
    { id = 'id', title = 'License and ID', group = 'License and ID Questions' },
    { id = 'commands', title = 'Instructions and Commands', group = 'Instructions and Commands' },
    { id = 'citation', title = 'Citation and Warning', group = 'Citation and Warning Dialogue' },
    { id = 'wrap', title = 'Wrap-Up', group = 'Wrap-Up Dialogue' }
}

---@param s string
---@return string
local function safeIdPart(s)
    local out = tostring(s or ''):gsub('~%a~', '')
    out = out:gsub('[^%w_]+', '_')
    out = out:gsub('_+', '_')
    if #out > 32 then
        out = out:sub(1, 32)
    end
    if out == '' then
        out = 'group'
    end
    return out
end

---@param s string
---@return string
local function displayText(s)
    local out = Xml.normalizeKey(s or '')
    if #out > 60 then
        out = out:sub(1, 57) .. '...'
    end
    return out
end

---@param items PDNPCItem[]|nil
---@return boolean
local function hasIllegal(items)
    if type(items) ~= 'table' then
        return false
    end
    for _, it in ipairs(items) do
        if type(it) == 'table' and it.illegal == true then
            return true
        end
    end
    return false
end

---@param idx number
---@return number|nil
local function nextFlowStep(idx)
    local i = type(idx) == 'number' and math.floor(idx) or 1
    if i < 1 then
        i = 1
    end
    while i <= #FLOW_STEPS do
        local step = FLOW_STEPS[i]
        local group = step and customByName[step.group]
        if group and type(group.questions) == 'table' and #group.questions > 0 then
            return i
        end
        i = i + 1
    end
    return nil
end

---@return boolean
local function loadTrafficQuestions()
    local raw = LoadResourceFile(GetCurrentResourceName(), 'data/TrafficStopQuestions.xml')
    if type(raw) ~= 'string' or raw == '' then
        return false
    end
    local out = {}
    local i = 0
    for block in raw:gmatch('<TrafficStopQuestion>(.-)</TrafficStopQuestion>') do
        i = i + 1
        local q = Xml.firstTag(block, 'Question')
        if q then
            local answers = Xml.allTags(block, 'Answer')
            if #answers > 0 then
                out[#out + 1] = {
                    question = q,
                    key = Xml.normalizeKey(q),
                    answers = answers
                }
            end
        end
        if i % 250 == 0 then
            Wait(0)
        end
    end
    traffic = out
    return #traffic > 0
end

---@param block string
---@param groupName string
local function parseCustomQuestion(block, groupName)
    local q = Xml.firstTag(block, 'Question')
    if not q then
        return
    end
    local answers = Xml.allTags(block, 'Answer')
    if #answers == 0 then
        return
    end
    local g = customByName[groupName]
    if not g then
        g = { name = groupName, questions = {} }
        customByName[groupName] = g
        customGroups[#customGroups + 1] = g
    end
    g.questions[#g.questions + 1] = {
        question = q,
        key = Xml.normalizeKey(q),
        answers = answers
    }
end

---@return boolean
local function loadCustomQuestions()
    local raw = LoadResourceFile(GetCurrentResourceName(), 'data/CustomQuestions.xml')
    if type(raw) ~= 'string' or raw == '' then
        return false
    end
    customGroups = {}
    customByName = {}
    local groupName = 'General'
    local inQ = false
    local buf = {}
    local lineCount = 0
    for line in raw:gmatch('([^\n\r]*)[\n\r]?') do
        lineCount = lineCount + 1
        if line:find('<CustomQuestionGroup', 1, true) then
            local name = line:match('name="(.-)"')
            if name then
                groupName = Xml.trim(Xml.unescape(name))
                if groupName == '' then
                    groupName = 'General'
                end
                if not customByName[groupName] then
                    customByName[groupName] = { name = groupName, questions = {} }
                    customGroups[#customGroups + 1] = customByName[groupName]
                end
            end
        elseif line:find('<CustomQuestion>', 1, true) then
            inQ = true
            buf = { line }
        elseif inQ then
            buf[#buf + 1] = line
            if line:find('</CustomQuestion>', 1, true) then
                inQ = false
                parseCustomQuestion(table.concat(buf, '\n'), groupName)
                buf = {}
            end
        end
        if lineCount % 700 == 0 then
            Wait(0)
        end
    end
    return #customGroups > 0
end

---@return boolean
local function loadPedAnswers()
    local raw = LoadResourceFile(GetCurrentResourceName(), 'data/PedAnswers.xml')
    if type(raw) ~= 'string' or raw == '' then
        return false
    end
    pedAnswerPools = {}
    local count = 0
    for section, qAttr, body in raw:gmatch('<(%w+)%s+question="(.-)"[^>]*>(.-)</%1>') do
        count = count + 1
        local qKey = Xml.normalizeKey(qAttr)
        local positive = {}
        local negative = {}
        local pBody = body:match('<Positive>(.-)</Positive>')
        if pBody then
            positive = Xml.allTags(pBody, 'Answer')
        end
        local nBody = body:match('<Negative>(.-)</Negative>')
        if nBody then
            negative = Xml.allTags(nBody, 'Answer')
        end
        if #positive == 0 and #negative == 0 then
            local direct = Xml.allTags(body, 'Answer')
            if #direct > 0 then
                negative = direct
            end
        end
        if qKey ~= '' and (#positive > 0 or #negative > 0) then
            pedAnswerPools[qKey] = pedAnswerPools[qKey] or {}
            pedAnswerPools[qKey][section] = {
                Positive = positive,
                Negative = negative
            }
        end
        if count % 25 == 0 then
            Wait(0)
        end
    end
    return true
end

---@return boolean
local function ensureLoaded()
    if _loaded then
        return true
    end
    if _loading then
        local t = GetGameTimer() + 7000
        while _loading and GetGameTimer() < t do
            Wait(0)
        end
        return _loaded
    end
    _loading = true
    lib.notify({ title = 'Questions', description = 'Loading question sets...', type = 'info' })
    local ok1 = loadTrafficQuestions()
    local ok2 = loadCustomQuestions()
    loadPedAnswers()
    _loaded = ok1 or ok2
    _loading = false
    return _loaded
end

---@param list any[]
---@param page number
---@return number, number, any[]
local function paginate(list, page)
    local total = #list
    local per = PAGE_SIZE
    local pages = math.max(1, math.ceil(total / per))
    local p = type(page) == 'number' and math.floor(page) or 1
    if p < 1 then p = 1 end
    if p > pages then p = pages end
    local start = (p - 1) * per + 1
    local finish = math.min(total, start + per - 1)
    local out = {}
    for i = start, finish do
        out[#out + 1] = list[i]
    end
    return p, pages, out
end

---@param ped number
---@param entry table
---@return string
local function pickAnswer(ped, entry)
    local answers = type(entry.answers) == 'table' and entry.answers or {}
    local fallback = answers[math.random(1, math.max(1, #answers))] or '...'
    local profile = exports.pd_npc:GetProfile(ped)
    if type(profile) ~= 'table' then
        profile = exports.pd_npc:EnsurePedProfile(ped, 1500)
    end
    if type(profile) ~= 'table' then
        return fallback
    end
    local key = entry.key or Xml.normalizeKey(entry.question or '')
    local pool = pedAnswerPools[key]
    if type(pool) ~= 'table' then
        return fallback
    end
    local flags = type(profile.flags) == 'table' and profile.flags or {}
    local invIllegal = hasIllegal(profile.inventory)
    local sectionName = nil
    local useNegative = false
    if flags.isDrunk and pool.Drinking then
        sectionName = 'Drinking'
        useNegative = true
    elseif flags.isDrugged and pool.Drugs then
        sectionName = 'Drugs'
        useNegative = true
    elseif invIllegal and pool.IllegalItem then
        sectionName = 'IllegalItem'
        useNegative = true
    else
        for sec, _ in pairs(pool) do
            sectionName = sec
            break
        end
        useNegative = false
    end
    if not sectionName then
        return fallback
    end
    local section = pool[sectionName]
    if type(section) ~= 'table' then
        return fallback
    end
    local list = useNegative and section.Negative or section.Positive
    if type(list) ~= 'table' or #list == 0 then
        list = section.Positive
    end
    if type(list) ~= 'table' or #list == 0 then
        return fallback
    end
    return list[math.random(1, #list)]
end

---@param ped number
---@param entry table
local function ask(ped, entry)
    local q = tostring(entry.question or '')
    local a = pickAnswer(ped, entry)
    local profile = exports.pd_npc:GetProfile(ped)
    if type(profile) ~= 'table' then
        profile = exports.pd_npc:EnsurePedProfile(ped, 1500)
    end
    local subtitle = 'Dialogue'
    if type(profile) == 'table' and type(profile.identity) == 'table' and type(profile.identity.full) == 'string' then
        subtitle = profile.identity.full
    end
    lib.dialogueOpen({
        title = 'Stop The Ped',
        subtitle = subtitle,
        reset = false,
        duration = 12000
    })
    lib.dialoguePush({ side = 'you', name = 'Officer', text = Xml.normalizeKey(q) })
    lib.dialoguePush({ side = 'ped', name = 'Ped', text = tostring(a) })
end

---@param ped number
---@param stepIndex number
---@param page number
---@param backFn function
function Questions.openFlowStep(ped, stepIndex, page, backFn)
    if not ensureLoaded() then
        lib.notify({ title = 'Questions', description = 'Failed to load question sets.', type = 'error' })
        if type(backFn) == 'function' then
            backFn()
        end
        return
    end
    local idx = nextFlowStep(stepIndex)
    if not idx then
        lib.notify({ title = 'Questions', description = 'Dialogue flow complete.', type = 'success' })
        Questions.openRoot(ped, backFn)
        return
    end
    local step = FLOW_STEPS[idx]
    local group = step and customByName[step.group]
    if not group or type(group.questions) ~= 'table' then
        Questions.openFlowStep(ped, idx + 1, 1, backFn)
        return
    end
    local p, pages, slice = paginate(group.questions, page)
    local opts = {}
    opts[#opts + 1] = { id = 'step', title = ('Step %s / %s'):format(idx, #FLOW_STEPS), value = step.title, valueColor = '#60a5fa', disabled = true }
    opts[#opts + 1] = { id = 'page', title = 'Page', value = tostring(p) .. '/' .. tostring(pages), valueColor = '#60a5fa', disabled = true }
    for i, entry in ipairs(slice) do
        local e = entry
        opts[#opts + 1] = {
            id = tostring(i),
            title = displayText(e.question),
            onSelect = function()
                ask(ped, e)
                Questions.openFlowStep(ped, idx + 1, 1, backFn)
            end
        }
    end
    if p > 1 then
        opts[#opts + 1] = { id = 'prev', title = 'Previous Page', value = '◀', valueColor = '#f59e0b', onSelect = function() Questions.openFlowStep(ped, idx, p - 1, backFn) end }
    end
    if p < pages then
        opts[#opts + 1] = { id = 'next', title = 'Next Page', value = '▶', valueColor = '#f59e0b', onSelect = function() Questions.openFlowStep(ped, idx, p + 1, backFn) end }
    end
    if idx > 1 then
        opts[#opts + 1] = { id = 'backStep', title = 'Previous Category', value = 'Back', valueColor = '#f59e0b', onSelect = function() Questions.openFlowStep(ped, idx - 1, 1, backFn) end }
    end
    opts[#opts + 1] = { id = 'restart', title = 'Restart Flow', value = 'Reset', valueColor = '#f59e0b', onSelect = function() Questions.openFlowStep(ped, 1, 1, backFn) end }
    opts[#opts + 1] = { id = 'back', title = 'Back', color = '#ef4444', value = 'Questions', valueColor = '#ef4444', onSelect = function() Questions.openRoot(ped, backFn) end }
    local id = 'pd_interactions_q_flow_' .. tostring(idx) .. '_' .. tostring(p)
    lib.registerContext({
        id = id,
        title = 'Dialogue Flow',
        description = step.group,
        focus = true,
        options = opts
    })
    lib.showContext(id)
end

---@param ped number
---@param page number
---@param backFn function
function Questions.openTraffic(ped, page, backFn)
    if not ensureLoaded() then
        lib.notify({ title = 'Questions', description = 'Failed to load question sets.', type = 'error' })
        if type(backFn) == 'function' then
            backFn()
        end
        return
    end
    local p, pages, slice = paginate(traffic, page)
    local opts = {}
    opts[#opts + 1] = { id = 'page', title = 'Page', value = tostring(p) .. '/' .. tostring(pages), valueColor = '#60a5fa', disabled = true }
    for idx, entry in ipairs(slice) do
        local e = entry
        opts[#opts + 1] = {
            id = tostring(idx),
            title = displayText(e.question),
            onSelect = function()
                ask(ped, e)
                Questions.openTraffic(ped, p, backFn)
            end
        }
    end
    if p > 1 then
        opts[#opts + 1] = { id = 'prev', title = 'Previous Page', value = '◀', valueColor = '#f59e0b', onSelect = function() Questions.openTraffic(ped, p - 1, backFn) end }
    end
    if p < pages then
        opts[#opts + 1] = { id = 'next', title = 'Next Page', value = '▶', valueColor = '#f59e0b', onSelect = function() Questions.openTraffic(ped, p + 1, backFn) end }
    end
    opts[#opts + 1] = { id = 'back', title = 'Back', color = '#ef4444', value = 'Return', valueColor = '#ef4444', onSelect = function() Questions.openRoot(ped, backFn) end }
    local id = 'pd_interactions_q_traffic_' .. tostring(p)
    lib.registerContext({ id = id, title = 'Traffic Stop Questions', focus = true, options = opts })
    lib.showContext(id)
end

---@param ped number
---@param page number
---@param backFn function
function Questions.openGroups(ped, page, backFn)
    if not ensureLoaded() then
        lib.notify({ title = 'Questions', description = 'Failed to load question sets.', type = 'error' })
        if type(backFn) == 'function' then
            backFn()
        end
        return
    end
    local p, pages, slice = paginate(customGroups, page)
    local opts = {}
    opts[#opts + 1] = { id = 'page', title = 'Page', value = tostring(p) .. '/' .. tostring(pages), valueColor = '#60a5fa', disabled = true }
    for idx, group in ipairs(slice) do
        local g = group
        opts[#opts + 1] = {
            id = tostring(idx),
            title = displayText(g.name),
            onSelect = function()
                Questions.openGroupQuestions(ped, g.name, 1, backFn)
            end
        }
    end
    if p > 1 then
        opts[#opts + 1] = { id = 'prev', title = 'Previous Page', value = '◀', valueColor = '#f59e0b', onSelect = function() Questions.openGroups(ped, p - 1, backFn) end }
    end
    if p < pages then
        opts[#opts + 1] = { id = 'next', title = 'Next Page', value = '▶', valueColor = '#f59e0b', onSelect = function() Questions.openGroups(ped, p + 1, backFn) end }
    end
    opts[#opts + 1] = { id = 'back', title = 'Back', color = '#ef4444', value = 'Return', valueColor = '#ef4444', onSelect = function() Questions.openRoot(ped, backFn) end }
    local id = 'pd_interactions_q_groups_' .. tostring(p)
    lib.registerContext({ id = id, title = 'Custom Question Groups', focus = true, options = opts })
    lib.showContext(id)
end

---@param ped number
---@param groupName string
---@param page number
---@param backFn function
function Questions.openGroupQuestions(ped, groupName, page, backFn)
    if not ensureLoaded() then
        lib.notify({ title = 'Questions', description = 'Failed to load question sets.', type = 'error' })
        if type(backFn) == 'function' then
            backFn()
        end
        return
    end
    local group = customByName[groupName]
    if not group or type(group.questions) ~= 'table' then
        lib.notify({ title = 'Questions', description = 'Group not found.', type = 'error' })
        Questions.openGroups(ped, 1, backFn)
        return
    end
    local p, pages, slice = paginate(group.questions, page)
    local opts = {}
    opts[#opts + 1] = { id = 'page', title = 'Page', value = tostring(p) .. '/' .. tostring(pages), valueColor = '#60a5fa', disabled = true }
    for idx, entry in ipairs(slice) do
        local e = entry
        opts[#opts + 1] = {
            id = tostring(idx),
            title = displayText(e.question),
            onSelect = function()
                ask(ped, e)
                Questions.openGroupQuestions(ped, groupName, p, backFn)
            end
        }
    end
    if p > 1 then
        opts[#opts + 1] = { id = 'prev', title = 'Previous Page', value = '◀', valueColor = '#f59e0b', onSelect = function() Questions.openGroupQuestions(ped, groupName, p - 1, backFn) end }
    end
    if p < pages then
        opts[#opts + 1] = { id = 'next', title = 'Next Page', value = '▶', valueColor = '#f59e0b', onSelect = function() Questions.openGroupQuestions(ped, groupName, p + 1, backFn) end }
    end
    opts[#opts + 1] = { id = 'back', title = 'Back', color = '#ef4444', value = 'Groups', valueColor = '#ef4444', onSelect = function() Questions.openGroups(ped, 1, backFn) end }
    local id = 'pd_interactions_q_group_' .. safeIdPart(groupName) .. '_' .. tostring(p)
    lib.registerContext({ id = id, title = 'Questions: ' .. tostring(groupName), focus = true, options = opts })
    lib.showContext(id)
end

---@param ped number
---@param backFn function
function Questions.openRoot(ped, backFn)
    if not ensureLoaded() then
        lib.notify({ title = 'Questions', description = 'Failed to load question sets.', type = 'error' })
        if type(backFn) == 'function' then
            backFn()
        end
        return
    end
    lib.registerContext({
        id = 'pd_interactions_questions_root',
        title = 'Questions',
        focus = true,
        options = {
            {
                id = 'flow',
                title = 'Guided Dialogue Flow',
                value = 'Step-by-step',
                valueColor = '#60a5fa',
                onSelect = function()
                    Questions.openFlowStep(ped, 1, 1, backFn)
                end
            },
            {
                id = 'traffic',
                title = 'Traffic Stop Questions',
                value = tostring(#traffic),
                valueColor = '#60a5fa',
                onSelect = function()
                    Questions.openTraffic(ped, 1, backFn)
                end
            },
            {
                id = 'custom',
                title = 'Custom Questions',
                value = tostring(#customGroups),
                valueColor = '#60a5fa',
                onSelect = function()
                    Questions.openGroups(ped, 1, backFn)
                end
            },
            {
                id = 'back',
                title = 'Back',
                color = '#ef4444',
                value = 'Return',
                valueColor = '#ef4444',
                onSelect = function()
                    if type(backFn) == 'function' then
                        backFn()
                    end
                end
            }
        }
    })
    lib.showContext('pd_interactions_questions_root')
end

return Questions


