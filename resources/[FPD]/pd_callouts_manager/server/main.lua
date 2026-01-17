local Config = require 'config'
---@class PDOfferState
---@field id string
---@field calloutName string
---@field location vector3
---@field expiresAt number

local Offers = {}

local function nowMs()
    return GetGameTimer()
end

---@param src number
---@return table|nil
local function getPlayerData(src)
    ---@diagnostic disable-next-line: undefined-field
    local playerData = exports.pd_core:GetPlayerData(src)
    if not playerData then
        return nil
    end
    playerData.metadata = playerData.metadata or {}
    return playerData
end

---@param data table
---@return boolean
local function isTenFour(data)
    local meta = data and data.metadata
    if type(meta) ~= 'table' then
        return false
    end
    local key = Config.metadata.tenFourKey
    local v = meta[key]
    if v == true then
        return true
    end
    if type(v) == 'string' then
        return v == '10-4' or v == '10-8'
    end
    return false
end

---@param data table
---@return number
local function getRank(data)
    if not data then
        return 0
    end
    local pd = data.metadata and data.metadata.playerdata
    if type(pd) == 'table' and pd.grade ~= nil then
        local gradeNum = tonumber(pd.grade)
        if gradeNum then
            return gradeNum
        end
    end
    local meta = data.metadata
    if type(meta) == 'table' then
        local v = meta[Config.metadata.rankKey]
        if v ~= nil then
            return tonumber(v) or 0
        end
    end
    return 0
end

---@param data table
---@return string|nil
local function getDepartment(data)
    if not data then
        return nil
    end
    local pd = data.metadata and data.metadata.playerdata
    if type(pd) == 'table' and type(pd.job) == 'string' and pd.job ~= '' then
        return pd.job
    end
    local meta = data.metadata
    if type(meta) == 'table' then
        local v = meta[Config.metadata.departmentKey]
        if type(v) == 'string' and v ~= '' then
            return v
        end
    end
    return nil
end

---@param src number
---@return vector3|nil
local function getCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return nil
    end
    return GetEntityCoords(ped)
end

---@param src number
---@return boolean
local function eligible(src)
    if Config.DebugMode then return true end
    local data = getPlayerData(src)
    if not data then
        return false
    end
    local pd = data.metadata and data.metadata.playerdata
    local activeDuty = type(pd) == 'table' and pd.activeDuty == true
    if Config.requireActiveDuty and not activeDuty then
        return false
    end
    return isTenFour(data)
end

---@param src number
---@return number|nil
local function closestLocationDistance(src, locations)
    local coords = getCoords(src)
    if not coords then
        return nil
    end
    local best = nil
    for _, loc in ipairs(locations or {}) do
        local d = #(coords - loc)
        if not best or d < best then
            best = d
        end
    end
    return best
end

---@param src number
---@param callout table
---@return vector3|nil, number|nil
local function selectClosestLocation(src, callout)
    local coords = getCoords(src)
    if not coords then
        return nil, nil
    end
    local bestLoc = nil
    local bestDist = nil
    for _, loc in ipairs(callout.locations or {}) do
        local d = #(coords - loc)
        if not bestDist or d < bestDist then
            bestDist = d
            bestLoc = loc
        end
    end
    return bestLoc, bestDist
end

---@param src number
---@param callout table
---@return boolean
local function calloutAllowed(src, callout)
    if Config.DebugMode then return true end
    if not callout then
        return false
    end
    local data = getPlayerData(src)
    if not data then
        return false
    end
    local rank = getRank(data)
    local dep = getDepartment(data)
    local minRank = tonumber(callout.minRank) or 0
    if rank < minRank then
        return false
    end
    if callout.department and dep and callout.department ~= dep then
        return false
    end
    if callout.department and not dep then
        return false
    end
    local dist = closestLocationDistance(src, callout.locations)
    if not dist then
        return false
    end
    return dist <= Config.maxDistance
end

---@param src number
---@return table|nil, vector3|nil, number|nil
local function pickCallout(src)
    local list = exports.pd_core:GetCallouts()
    if type(list) ~= 'table' then
        return nil, nil, nil
    end
    local best = nil
    local bestLoc = nil
    local bestDist = nil
    for _, callout in pairs(list) do
        if calloutAllowed(src, callout) then
            local loc, dist = selectClosestLocation(src, callout)
            if loc and dist and (not bestDist or dist < bestDist) then
                best = callout
                bestLoc = loc
                bestDist = dist
            end
        end
    end
    return best, bestLoc, bestDist
end

---@param src number
---@param callout table
---@param location vector3
---@param distance number
local function sendOffer(src, callout, location, distance)
    PDLib.debug('pd_callouts_manager', 'offer %s to %s (dist=%.1f)', callout.name, src, distance or -1.0)
    local offerId = tostring(math.random(100000, 999999)) .. '_' .. tostring(nowMs())
    local expiresAt = nowMs() + Config.offerTimeoutMs
    Offers[src] = {
        id = offerId,
        calloutName = callout.name,
        location = location,
        expiresAt = expiresAt
    }
    TriggerClientEvent('pd_callouts_manager:client:offer', src, {
        id = offerId,
        callout = {
            name = callout.name,
            code = callout.code,
            title = callout.title,
            description = callout.description,
            department = callout.department,
            minRank = callout.minRank
        },
        location = { x = location.x, y = location.y, z = location.z },
        distance = distance,
        timeoutMs = Config.offerTimeoutMs
    })
    CreateThread(function()
        Wait(Config.offerTimeoutMs)
        local current = Offers[src]
        if current and current.id == offerId then
            Offers[src] = nil
            PDLib.debug('pd_callouts_manager', 'offer timeout %s for %s', offerId, src)
            TriggerClientEvent('pd_callouts_manager:client:clear', src, offerId)
        end
    end)
end

RegisterNetEvent('pd_callouts_manager:server:accept', function(offerId)
    local src = source
    local offer = Offers[src]
    if not offer then
        return
    end
    if offer.id ~= offerId then
        return
    end
    if offer.expiresAt <= nowMs() then
        Offers[src] = nil
        PDLib.debug('pd_callouts_manager', 'accept expired offer %s for %s', offerId, src)
        return
    end
    Offers[src] = nil
    PDLib.debug('pd_callouts_manager', 'accepted offer %s for %s (%s)', offerId, src, offer.calloutName)
    exports.pd_core:TriggerCallout(src, offer.calloutName, {
        location = offer.location
    })
end)

AddEventHandler('playerDropped', function()
    Offers[source] = nil
end)



CreateThread(function()
    local tickCount = 0
    while true do

        Wait(Config.tickIntervalMs)
        tickCount = tickCount + 1
        if not Config.enabled then
            goto continue
        end
        local players = GetPlayers()
        local eligibleList = {}
        for _, sid in ipairs(players) do
            local src = tonumber(sid)
            if src and not Offers[src] and eligible(src) then
                table.insert(eligibleList, src)
            end
        end
        if #eligibleList == 0 then
            PDLib.debug('pd_callouts_manager', 'tick #%d: no eligible players (%d total)', tickCount, #players)
            goto continue
        end
        PDLib.debug('pd_callouts_manager', 'tick #%d: found %d eligible players', tickCount, #eligibleList)
        local target = eligibleList[math.random(1, #eligibleList)]
        PDLib.debug('pd_callouts_manager', 'selected target player %d', target)
        local callout, location, distance = pickCallout(target)
        if callout and location and distance then
            PDLib.debug('pd_callouts_manager', 'picked callout %s at distance %.1fm for player %d', callout.name, distance, target)
            sendOffer(target, callout, location, distance)
        else
            PDLib.debug('pd_callouts_manager', 'no suitable callout found for player %d', target)
        end
        ::continue::
    end
end)