local Xml = {}

---@param s string
---@return string
function Xml.trim(s)
    if type(s) ~= 'string' then
        return ''
    end
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

---@param s string
---@return string
function Xml.unescape(s)
    if type(s) ~= 'string' then
        return ''
    end
    s = s:gsub('&quot;', '"')
    s = s:gsub('&apos;', "'")
    s = s:gsub('&lt;', '<')
    s = s:gsub('&gt;', '>')
    s = s:gsub('&amp;', '&')
    return s
end

---@param s string
---@return string
function Xml.normalizeKey(s)
    local out = Xml.trim(Xml.unescape(s or ''))
    out = out:gsub('~%a~', '')
    out = out:gsub('%s+', ' ')
    return Xml.trim(out)
end

---@param block string
---@param tag string
---@return string|nil
function Xml.firstTag(block, tag)
    if type(block) ~= 'string' or type(tag) ~= 'string' then
        return nil
    end
    local v = block:match('<' .. tag .. '>(.-)</' .. tag .. '>')
    if not v then
        return nil
    end
    v = Xml.trim(Xml.unescape(v))
    if v == '' then
        return nil
    end
    return v
end

---@param block string
---@param tag string
---@return string[]
function Xml.allTags(block, tag)
    local out = {}
    if type(block) ~= 'string' or type(tag) ~= 'string' then
        return out
    end
    for v in block:gmatch('<' .. tag .. '>(.-)</' .. tag .. '>') do
        local t = Xml.trim(Xml.unescape(v))
        if t ~= '' then
            out[#out + 1] = t
        end
    end
    return out
end

return Xml


