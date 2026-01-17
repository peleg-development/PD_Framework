--========================================
-- ULTIMATE TRAFFIC STOP SYSTEM
-- Advanced AI-Driven NPC Pull-Over System
-- Features: Multi-stage pathfinding, dynamic follow mode,
-- intelligent pavement detection, safety scoring
--========================================

local Traffic = {}

-- ============================================
-- CONFIGURATION & CONSTANTS
-- ============================================

local Config = {
    -- Basic behavior
    DRIVING_STYLE = 786603,
    APPROACH_SPEED = 14.0,
    SLOW_APPROACH_SPEED = 8.0,
    PARK_SPEED = 4.0,
    FOLLOW_SPEED = 18.0,
    FOLLOW_DISTANCE = 12.0,

    -- Distance thresholds
    MIN_STOP_DISTANCE = 40.0,
    MAX_STOP_DISTANCE = 150.0,
    IDEAL_STOP_DISTANCE = 80.0,

    -- Shoulder/Pavement detection
    MIN_SHOULDER_WIDTH = 2.2,
    IDEAL_SHOULDER_WIDTH = 3.5,
    MAX_SHOULDER_WIDTH = 8.0,
    PAVEMENT_SEARCH_RADIUS = 10.0,
    ROAD_EDGE_BUFFER = 0.8,

    -- Search parameters
    PRIMARY_SEARCH_STEPS = 12,
    SECONDARY_SEARCH_STEPS = 8,
    RADIAL_SEARCH_POINTS = 6,
    MAX_SEARCH_ITERATIONS = 25,

    -- Timing
    CONTROL_TIMEOUT = 1200,
    UPDATE_INTERVAL = 300,
    TASK_REISSUE_INTERVAL = 2000,
    FOLLOW_UPDATE_INTERVAL = 500,
    STUCK_TIMEOUT = 15000,
    COOLDOWN_TIME = 8000,
    FOLLOW_TIMEOUT = 45000,

    -- Scoring weights (0-100)
    SCORE_SHOULDER_WIDTH = 25.0,
    SCORE_DISTANCE_OPTIMAL = 20.0,
    SCORE_SAFETY = 20.0,
    SCORE_ACCESSIBILITY = 15.0,
    SCORE_TRAFFIC_CLEAR = 10.0,
    SCORE_GROUND_QUALITY = 5.0,
    SCORE_SIDE_CORRECT = 5.0,

    -- Safety thresholds
    MIN_ACCEPTABLE_SCORE = 35.0,
    GOOD_SCORE_THRESHOLD = 65.0,
    EXCELLENT_SCORE_THRESHOLD = 85.0,
}

-- State storage
local activeStops = {}
local pullOverCooldowns = {}
local followingVehicles = {}

--========================================
-- UTILITY FUNCTIONS
--========================================

local function getNetId(entity)
    if not DoesEntityExist(entity) then return nil end
    local netId = NetworkGetNetworkIdFromEntity(entity)
    return netId ~= 0 and netId or nil
end

local function getEntityFromNetId(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    return DoesEntityExist(entity) and entity or nil
end

local function requestControl(entity, timeout)
    if not DoesEntityExist(entity) then return false end
    if NetworkHasControlOfEntity(entity) then return true end

    NetworkRequestControlOfEntity(entity)
    local endTime = GetGameTimer() + (timeout or Config.CONTROL_TIMEOUT)

    while GetGameTimer() < endTime do
        if NetworkHasControlOfEntity(entity) then return true end
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end

    return NetworkHasControlOfEntity(entity)
end

local function getDriver(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    local driver = GetPedInVehicleSeat(vehicle, -1)
    if driver == 0 or not DoesEntityExist(driver) or IsPedAPlayer(driver) then
        return nil
    end
    return driver
end

local function isEmergencyWithSiren(vehicle)
    return DoesEntityExist(vehicle)
        and GetVehicleClass(vehicle) == 18
        and IsVehicleSirenOn(vehicle)
end

local function getVehicleAhead(fromVehicle, maxDistance)
    local coords = GetEntityCoords(fromVehicle)
    local forward = GetEntityForwardVector(fromVehicle)
    local startPos = coords + vector3(0, 0, 1.0)
    local endPos = startPos + (forward * (maxDistance or 35.0))

    local rayHandle = StartShapeTestRay(
        startPos.x, startPos.y, startPos.z,
        endPos.x, endPos.y, endPos.z,
        10, fromVehicle, 0
    )

    local _, hit, _, _, entity = GetShapeTestResult(rayHandle)

    if hit == 1 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
        return entity
    end

    return nil
end

local function headingDifference(h1, h2)
    local diff = math.abs((h1 - h2) % 360.0)
    return diff > 180.0 and (360.0 - diff) or diff
end

local function getRightVector(heading)
    local rad = math.rad(heading)
    return vector3(math.cos(rad), -math.sin(rad), 0.0)
end

local function getLeftVector(heading)
    local rad = math.rad(heading)
    return vector3(-math.cos(rad), math.sin(rad), 0.0)
end

local function getForwardVector(heading)
    local rad = math.rad(heading)
    return vector3(math.sin(rad), math.cos(rad), 0.0)
end

local function getBackwardVector(heading)
    local rad = math.rad(heading)
    return vector3(-math.sin(rad), -math.cos(rad), 0.0)
end

local function normalizeHeading(heading)
    while heading < 0 do heading = heading + 360.0 end
    while heading >= 360.0 do heading = heading - 360.0 end
    return heading
end

--========================================
-- ADVANCED ROAD TOPOLOGY ANALYSIS
--========================================

-- Analyzes road structure using multiple raycasts
local function analyzeRoadTopology(coords, heading)
    local rightVec = getRightVector(heading)
    local leftVec = getLeftVector(heading)
    local forwardVec = getForwardVector(heading)

    -- Multi-point analysis
    local scanPoints = {
        { offset = vector3(0, 0, 0),  weight = 1.0 },
        { offset = forwardVec * 5.0,  weight = 0.8 },
        { offset = forwardVec * 10.0, weight = 0.6 },
        { offset = forwardVec * -5.0, weight = 0.5 },
    }

    local results = {
        rightBoundaries = {},
        leftBoundaries = {},
        rightDistances = {},
        leftDistances = {},
        avgRightDist = 0,
        avgLeftDist = 0,
        roadWidth = 0,
        confidence = 0,
    }

    local validScans = 0

    for _, scanPoint in ipairs(scanPoints) do
        local scanCoords = coords + scanPoint.offset

        -- Get road boundaries
        local foundRight, rightBoundary = GetRoadBoundaryUsingHeading(
            scanCoords.x, scanCoords.y, scanCoords.z,
            heading
        )

        local foundLeft, leftBoundary = GetRoadBoundaryUsingHeading(
            scanCoords.x, scanCoords.y, scanCoords.z,
            (heading + 180.0) % 360.0
        )

        if foundRight and rightBoundary then
            local rightPos = vector3(rightBoundary.x, rightBoundary.y, rightBoundary.z)
            local toRight = rightPos - scanCoords
            local rightDist = math.abs(toRight.x * rightVec.x + toRight.y * rightVec.y)

            table.insert(results.rightBoundaries, rightPos)
            table.insert(results.rightDistances, rightDist * scanPoint.weight)
            validScans = validScans + scanPoint.weight
        end

        if foundLeft and leftBoundary then
            local leftPos = vector3(leftBoundary.x, leftBoundary.y, leftBoundary.z)
            local toLeft = leftPos - scanCoords
            local leftDist = math.abs(toLeft.x * leftVec.x + toLeft.y * leftVec.y)

            table.insert(results.leftBoundaries, leftPos)
            table.insert(results.leftDistances, leftDist * scanPoint.weight)
        end
    end

    -- Calculate averages
    if #results.rightDistances > 0 then
        local sum = 0
        for _, dist in ipairs(results.rightDistances) do
            sum = sum + dist
        end
        results.avgRightDist = sum / validScans
    end

    if #results.leftDistances > 0 then
        local sum = 0
        for _, dist in ipairs(results.leftDistances) do
            sum = sum + dist
        end
        results.avgLeftDist = sum / validScans
    end

    results.roadWidth = results.avgRightDist + results.avgLeftDist
    results.confidence = math.min(validScans / 2.5, 1.0)

    return results
end

-- Determines which side of road to pull over to
local function determineCorrectSide(vehicle, coords, heading)
    -- Check if we're in a right-hand drive country (UK, AUS, etc)
    local isRightHandDrive = false -- Most of world is left-hand drive (pull to right)

    -- Could add zone detection here for different countries
    -- For now, assume right-side pull-over (US/EU style)

    local playerVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if not playerVeh or playerVeh == 0 then
        return 'RIGHT'
    end

    local playerCoords = GetEntityCoords(playerVeh)
    local playerHeading = GetEntityHeading(playerVeh)

    -- Check if player is behind or ahead
    local toVehicle = coords - playerCoords
    local playerForward = getForwardVector(playerHeading)
    local dotProduct = toVehicle.x * playerForward.x + toVehicle.y * playerForward.y

    -- If player is ahead (negative dot product), vehicle might need to pull opposite side
    -- But typically always pull right in most jurisdictions

    return isRightHandDrive and 'LEFT' or 'RIGHT'
end

--========================================
-- PAVEMENT/SIDEWALK DETECTION
--========================================

-- Searches for pavement/sidewalk using multiple methods
local function findPavementPosition(roadCoords, heading, side)
    local sideVec = side == 'RIGHT' and getRightVector(heading) or getLeftVector(heading)
    local forwardVec = getForwardVector(heading)

    local results = {}

    -- Method 1: Incremental distance search
    for dist = 2.5, Config.PAVEMENT_SEARCH_RADIUS, 0.8 do
        local testPos = roadCoords + (sideVec * dist)

        local foundSafe, safeCoord = GetSafeCoordForPed(
            testPos.x, testPos.y, testPos.z,
            true, -- onlyOnPavement
            16
        )

        if foundSafe and safeCoord then
            local pavementPos = vector3(safeCoord.x, safeCoord.y, safeCoord.z)
            local distFromRoad = #(pavementPos - roadCoords)

            if distFromRoad >= 1.8 and distFromRoad <= Config.PAVEMENT_SEARCH_RADIUS then
                table.insert(results, {
                    pos = pavementPos,
                    distance = distFromRoad,
                    method = 'INCREMENTAL',
                    quality = 1.0 - (math.abs(distFromRoad - 3.5) / 10.0)
                })
            end
        end
    end

    -- Method 2: Radial search around boundary
    local topology = analyzeRoadTopology(roadCoords, heading)
    if topology.confidence > 0.3 then
        local boundaryDist = side == 'RIGHT' and topology.avgRightDist or topology.avgLeftDist

        for angle = -30, 30, 15 do
            local adjustedHeading = normalizeHeading(heading + angle)
            local adjustedSideVec = side == 'RIGHT' and getRightVector(adjustedHeading) or getLeftVector(adjustedHeading)
            local searchPos = roadCoords + (adjustedSideVec * (boundaryDist + 2.0))

            local foundSafe, safeCoord = GetSafeCoordForPed(
                searchPos.x, searchPos.y, searchPos.z,
                true,
                16
            )

            if foundSafe and safeCoord then
                local pavementPos = vector3(safeCoord.x, safeCoord.y, safeCoord.z)
                local distFromRoad = #(pavementPos - roadCoords)

                if distFromRoad >= 1.8 and distFromRoad <= Config.PAVEMENT_SEARCH_RADIUS then
                    table.insert(results, {
                        pos = pavementPos,
                        distance = distFromRoad,
                        method = 'RADIAL',
                        quality = 0.9 - (math.abs(angle) / 60.0)
                    })
                end
            end
        end
    end

    -- Method 3: Forward projection search
    for forwardDist = 5, 15, 5 do
        local projectedPos = roadCoords + (forwardVec * forwardDist) + (sideVec * 3.0)

        local foundSafe, safeCoord = GetSafeCoordForPed(
            projectedPos.x, projectedPos.y, projectedPos.z,
            true,
            16
        )

        if foundSafe and safeCoord then
            local pavementPos = vector3(safeCoord.x, safeCoord.y, safeCoord.z)
            local distFromRoad = #(pavementPos - roadCoords)

            if distFromRoad >= 1.8 and distFromRoad <= Config.PAVEMENT_SEARCH_RADIUS then
                table.insert(results, {
                    pos = pavementPos,
                    distance = distFromRoad,
                    method = 'PROJECTION',
                    quality = 0.8
                })
            end
        end
    end

    return results
end

--========================================
-- SHOULDER ANALYSIS & SCORING
--========================================

-- Checks if position has adequate shoulder space
local function analyzeShoulderSpace(roadCoords, heading, side)
    local topology = analyzeRoadTopology(roadCoords, heading)

    if topology.confidence < 0.4 then
        return nil
    end

    local shoulderWidth = side == 'RIGHT' and topology.avgRightDist or topology.avgLeftDist

    if shoulderWidth < Config.MIN_SHOULDER_WIDTH then
        return nil
    end

    local sideVec = side == 'RIGHT' and getRightVector(heading) or getLeftVector(heading)
    local forwardVec = getForwardVector(heading)

    -- Calculate pull-off position
    local pullOffDist = math.min(
        shoulderWidth - Config.ROAD_EDGE_BUFFER,
        Config.IDEAL_SHOULDER_WIDTH
    )

    local shoulderPos = roadCoords + (sideVec * pullOffDist)

    -- Verify ground
    local _, groundZ = GetGroundZFor_3dCoord(shoulderPos.x, shoulderPos.y, shoulderPos.z + 2.0, false)
    if groundZ and groundZ ~= 0 then
        shoulderPos = vector3(shoulderPos.x, shoulderPos.y, groundZ)
    end

    -- Verify it's still road-adjacent
    if not IsPointOnRoad(shoulderPos.x, shoulderPos.y, shoulderPos.z, 0) then
        -- Try to find nearby safe coord
        local foundSafe, safeCoord = GetSafeCoordForPed(
            shoulderPos.x, shoulderPos.y, shoulderPos.z,
            false,
            0
        )

        if foundSafe and safeCoord then
            local testPos = vector3(safeCoord.x, safeCoord.y, safeCoord.z)
            if #(testPos - roadCoords) < 6.0 then
                shoulderPos = testPos
            end
        end
    end

    -- Calculate approach position
    local approachPos = shoulderPos - (forwardVec * 10.0) - (sideVec * (pullOffDist * 0.5))

    return {
        stopPos = shoulderPos,
        approachPos = approachPos,
        shoulderWidth = shoulderWidth,
        confidence = topology.confidence,
    }
end

--========================================
-- SAFETY & TRAFFIC ANALYSIS
--========================================

-- Checks if position is safe (no nearby traffic, obstacles)
local function analyzeSafety(coords, heading)
    local safetyScore = 100.0

    -- Check for nearby vehicles
    local nearbyVehicles = GetGamePool('CVehicle')
    local dangerousProximity = 0

    for _, veh in ipairs(nearbyVehicles) do
        if DoesEntityExist(veh) then
            local vehCoords = GetEntityCoords(veh)
            local dist = #(vehCoords - coords)

            if dist < 15.0 and dist > 0.1 then
                local vehHeading = GetEntityHeading(veh)
                local headingDiff = headingDifference(heading, vehHeading)

                -- Vehicles traveling same direction are less dangerous
                if headingDiff < 45.0 then
                    safetyScore = safetyScore - (5.0 * (1.0 - (dist / 15.0)))
                else
                    safetyScore = safetyScore - (15.0 * (1.0 - (dist / 15.0)))
                end

                dangerousProximity = dangerousProximity + 1
            end
        end
    end

    -- Check for intersection
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local isIntersection = crossingHash and crossingHash ~= 0

    if isIntersection then
        safetyScore = safetyScore - 30.0
    end

    -- Check for obstacles via raycast
    local forwardVec = getForwardVector(heading)
    local testPositions = {
        coords + forwardVec * 5.0,
        coords + forwardVec * 10.0,
        coords + forwardVec * -3.0,
    }

    for _, testPos in ipairs(testPositions) do
        local rayHandle = StartShapeTestRay(
            coords.x, coords.y, coords.z + 1.0,
            testPos.x, testPos.y, testPos.z + 1.0,
            1, -- check world only
            0, 0
        )

        local _, hit, _, _, _ = GetShapeTestResult(rayHandle)
        if hit == 1 then
            safetyScore = safetyScore - 10.0
        end
    end

    return {
        score = math.max(0, safetyScore),
        dangerousVehicles = dangerousProximity,
        isIntersection = isIntersection,
    }
end

-- Checks ground quality and slope
local function analyzeGroundQuality(coords)
    local _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 5.0, false)

    if not groundZ or groundZ == 0 then
        return { score = 0, reason = 'NO_GROUND' }
    end

    local heightDiff = math.abs(coords.z - groundZ)

    if heightDiff > 2.0 then
        return { score = 20, reason = 'STEEP_SLOPE' }
    elseif heightDiff > 1.0 then
        return { score = 60, reason = 'MODERATE_SLOPE' }
    end



    return { score = 100, reason = 'GOOD' }
end

--========================================
-- STOP LOCATION SCORING SYSTEM
--========================================

-- Calculates comprehensive score for a potential stop location
local function scoreStopLocation(location, vehicle, targetDistance)
    local score = 0
    local breakdown = {}

    -- 1. Shoulder width score (25 points max)
    if location.shoulderWidth then
        local widthScore = math.min(
            (location.shoulderWidth / Config.IDEAL_SHOULDER_WIDTH) * Config.SCORE_SHOULDER_WIDTH,
            Config.SCORE_SHOULDER_WIDTH
        )
        score = score + widthScore
        breakdown.shoulderWidth = widthScore
    else
        breakdown.shoulderWidth = 0
    end

    -- 2. Distance optimality score (20 points max)
    if targetDistance then
        local distDiff = math.abs(location.distanceAhead - targetDistance)
        local distScore = Config.SCORE_DISTANCE_OPTIMAL * (1.0 - math.min(distDiff / 100.0, 1.0))
        score = score + distScore
        breakdown.distance = distScore
    end

    -- 3. Safety score (20 points max)
    local safety = analyzeSafety(location.stopPos, location.heading)
    local safetyScore = (safety.score / 100.0) * Config.SCORE_SAFETY
    score = score + safetyScore
    breakdown.safety = safetyScore
    breakdown.safetyDetails = safety

    -- 4. Accessibility score (15 points max)
    local accessScore = 0
    if location.pavementFound then
        accessScore = Config.SCORE_ACCESSIBILITY
    elseif location.shoulderWidth and location.shoulderWidth > Config.MIN_SHOULDER_WIDTH then
        accessScore = Config.SCORE_ACCESSIBILITY * 0.7
    end
    score = score + accessScore
    breakdown.accessibility = accessScore

    -- 5. Traffic clearance score (10 points max)
    local trafficScore = Config.SCORE_TRAFFIC_CLEAR
    if safety.dangerousVehicles > 0 then
        trafficScore = trafficScore * (1.0 - math.min(safety.dangerousVehicles * 0.3, 0.9))
    end
    score = score + trafficScore
    breakdown.traffic = trafficScore

    -- 6. Ground quality score (5 points max)
    local groundQuality = analyzeGroundQuality(location.stopPos)
    local groundScore = (groundQuality.score / 100.0) * Config.SCORE_GROUND_QUALITY
    score = score + groundScore
    breakdown.ground = groundScore
    breakdown.groundReason = groundQuality.reason

    -- 7. Correct side bonus (5 points max)
    if location.side == determineCorrectSide(vehicle, location.stopPos, location.heading) then
        score = score + Config.SCORE_SIDE_CORRECT
        breakdown.correctSide = Config.SCORE_SIDE_CORRECT
    else
        breakdown.correctSide = 0
    end

    -- Penalties
    if safety.isIntersection then
        score = score * 0.6
        breakdown.intersectionPenalty = true
    end

    if location.confidence and location.confidence < 0.6 then
        score = score * location.confidence
        breakdown.lowConfidencePenalty = true
    end

    location.score = score
    location.scoreBreakdown = breakdown

    return location
end

--========================================
-- COMPREHENSIVE STOP LOCATION FINDER
--========================================

-- Main algorithm to find best stop location
local function findOptimalStopLocation(vehicle)
    local vehCoords = GetEntityCoords(vehicle)
    local vehHeading = GetEntityHeading(vehicle)
    local vehSpeed = GetEntitySpeed(vehicle)
    local forwardVec = GetEntityForwardVector(vehicle)

    -- Determine correct side
    local correctSide = determineCorrectSide(vehicle, vehCoords, vehHeading)

    -- Calculate dynamic search range based on speed
    local minDist = Config.MIN_STOP_DISTANCE
    local maxDist = math.min(
        Config.MAX_STOP_DISTANCE,
        Config.MIN_STOP_DISTANCE + (vehSpeed * 12.0)
    )

    local candidates = {}
    local searchIteration = 0

    -- Primary search: Forward projection along road
    local primaryStep = (maxDist - minDist) / Config.PRIMARY_SEARCH_STEPS

    for i = 0, Config.PRIMARY_SEARCH_STEPS do
        searchIteration = searchIteration + 1
        if searchIteration > Config.MAX_SEARCH_ITERATIONS then break end

        local searchDist = minDist + (primaryStep * i)
        local searchPos = vehCoords + (forwardVec * searchDist)

        -- Stream collision
        RequestCollisionAtCoord(searchPos.x, searchPos.y, searchPos.z)

        -- Find nearest road node
        local foundNode, nodePos, nodeHeading = GetClosestVehicleNodeWithHeading(
            searchPos.x, searchPos.y, searchPos.z,
            1, 5.0, 0
        )

        if foundNode and nodePos then
            local roadCoords = vector3(nodePos.x, nodePos.y, nodePos.z)

            -- Try shoulder on correct side
            local shoulder = analyzeShoulderSpace(roadCoords, nodeHeading, correctSide)
            if shoulder then
                local location = {
                    type = 'SHOULDER',
                    stopPos = shoulder.stopPos,
                    approachPos = shoulder.approachPos,
                    heading = nodeHeading,
                    shoulderWidth = shoulder.shoulderWidth,
                    confidence = shoulder.confidence,
                    side = correctSide,
                    distanceAhead = searchDist,
                    pavementFound = false,
                }

                -- Try to find pavement too
                local pavements = findPavementPosition(roadCoords, nodeHeading, correctSide)
                if pavements and #pavements > 0 then
                    -- Use best pavement
                    table.sort(pavements, function(a, b) return a.quality > b.quality end)
                    location.stopPos = pavements[1].pos
                    location.pavementFound = true
                    location.pavementDistance = pavements[1].distance
                end

                scoreStopLocation(location, vehicle, Config.IDEAL_STOP_DISTANCE)
                table.insert(candidates, location)
            else
                -- No shoulder, but check for pavement anyway
                local pavements = findPavementPosition(roadCoords, nodeHeading, correctSide)
                if pavements and #pavements > 0 then
                    table.sort(pavements, function(a, b) return a.quality > b.quality end)
                    local bestPavement = pavements[1]

                    local location = {
                        type = 'PAVEMENT',
                        stopPos = bestPavement.pos,
                        approachPos = roadCoords,
                        heading = nodeHeading,
                        shoulderWidth = 0,
                        confidence = bestPavement.quality,
                        side = correctSide,
                        distanceAhead = searchDist,
                        pavementFound = true,
                        pavementDistance = bestPavement.distance,
                    }

                    scoreStopLocation(location, vehicle, Config.IDEAL_STOP_DISTANCE)
                    table.insert(candidates, location)
                end
            end
        end

        Wait(0) -- Prevent blocking
    end

    -- Secondary search: Check opposite side as fallback
    if #candidates < 3 then
        local oppositeSide = correctSide == 'RIGHT' and 'LEFT' or 'RIGHT'
        local secondaryStep = (maxDist - minDist) / Config.SECONDARY_SEARCH_STEPS

        for i = 0, Config.SECONDARY_SEARCH_STEPS do
            searchIteration = searchIteration + 1
            if searchIteration > Config.MAX_SEARCH_ITERATIONS then break end

            local searchDist = minDist + (secondaryStep * i)
            local searchPos = vehCoords + (forwardVec * searchDist)

            local foundNode, nodePos, nodeHeading = GetClosestVehicleNodeWithHeading(
                searchPos.x, searchPos.y, searchPos.z,
                1, 5.0, 0
            )

            if foundNode and nodePos then
                local roadCoords = vector3(nodePos.x, nodePos.y, nodePos.z)
                local shoulder = analyzeShoulderSpace(roadCoords, nodeHeading, oppositeSide)

                if shoulder and shoulder.shoulderWidth >= Config.MIN_SHOULDER_WIDTH * 1.2 then
                    local location = {
                        type = 'SHOULDER_OPPOSITE',
                        stopPos = shoulder.stopPos,
                        approachPos = shoulder.approachPos,
                        heading = nodeHeading,
                        shoulderWidth = shoulder.shoulderWidth,
                        confidence = shoulder.confidence * 0.7,
                        side = oppositeSide,
                        distanceAhead = searchDist,
                        pavementFound = false,
                    }

                    scoreStopLocation(location, vehicle, Config.IDEAL_STOP_DISTANCE)
                    table.insert(candidates, location)
                end
            end

            Wait(0)
        end
    end

    -- Radial search: Check positions at angles
    if #candidates < 2 then
        for angle = -60, 60, 20 do
            searchIteration = searchIteration + 1
            if searchIteration > Config.MAX_SEARCH_ITERATIONS then break end

            local radialHeading = normalizeHeading(vehHeading + angle)
            local radialVec = getForwardVector(radialHeading)
            local searchPos = vehCoords + (radialVec * 50.0)

            local foundNode, nodePos, nodeHeading = GetClosestVehicleNodeWithHeading(
                searchPos.x, searchPos.y, searchPos.z,
                1, 8.0, 0
            )

            if foundNode and nodePos then
                local roadCoords = vector3(nodePos.x, nodePos.y, nodePos.z)
                local pavements = findPavementPosition(roadCoords, nodeHeading, correctSide)

                if pavements and #pavements > 0 then
                    table.sort(pavements, function(a, b) return a.quality > b.quality end)

                    local location = {
                        type = 'PAVEMENT_RADIAL',
                        stopPos = pavements[1].pos,
                        approachPos = roadCoords,
                        heading = nodeHeading,
                        shoulderWidth = 0,
                        confidence = pavements[1].quality * 0.6,
                        side = correctSide,
                        distanceAhead = #(searchPos - vehCoords),
                        pavementFound = true,
                    }

                    scoreStopLocation(location, vehicle, Config.IDEAL_STOP_DISTANCE)
                    table.insert(candidates, location)
                end
            end

            Wait(0)
        end
    end

    -- Sort candidates by score
    table.sort(candidates, function(a, b) return a.score > b.score end)

    -- Return best candidate if it meets minimum threshold
    if #candidates > 0 then
        local best = candidates[1]

        if best.score >= Config.MIN_ACCEPTABLE_SCORE then
            return best, candidates
        end
    end

    return nil, candidates
end

--========================================
-- FOLLOW MODE SYSTEM
--========================================

-- Makes vehicle follow player when no stop location found
local function initiateFollowMode(vehicle)
    local netId = getNetId(vehicle)
    if not netId then return false end

    local driver = getDriver(vehicle)
    if not driver then return false end

    if not requestControl(vehicle, 500) or not requestControl(driver, 500) then
        return false
    end

    followingVehicles[netId] = {
        vehicle = vehicle,
        netId = netId,
        driver = driver,
        startTime = GetGameTimer(),
        lastUpdateTime = 0,
        state = 'FOLLOWING',
    }

    -- Setup driver
    SetBlockingOfNonTemporaryEvents(driver, true)
    SetPedKeepTask(driver, true)
    SetDriverAbility(driver, 0.75)
    SetDriverAggressiveness(driver, 0.0)
    SetDriveTaskDrivingStyle(driver, Config.DRIVING_STYLE)

    -- Hazard lights
    SetVehicleIndicatorLights(vehicle, 0, true)
    SetVehicleIndicatorLights(vehicle, 1, true)

    if lib and lib.notify then
        lib.notify({
            title = 'Traffic Stop',
            description = 'No safe stop location found nearby. Vehicle will follow you.',
            type = 'warning',
            duration = 5000
        })
    end

    return true
end

-- Updates following vehicle behavior
local function updateFollowMode(followData)
    local now = GetGameTimer()

    -- Timeout check
    if now - followData.startTime > Config.FOLLOW_TIMEOUT then
        followingVehicles[followData.netId] = nil

        -- Release vehicle
        local veh = getEntityFromNetId(followData.netId)
        if veh and DoesEntityExist(veh) then
            local driver = getDriver(veh)
            if driver and requestControl(driver, 300) then
                ClearPedTasks(driver)
                SetBlockingOfNonTemporaryEvents(driver, false)
                TaskVehicleDriveWander(driver, veh, 20.0, Config.DRIVING_STYLE)
            end
        end

        return
    end

    -- Update interval check
    if now - followData.lastUpdateTime < Config.FOLLOW_UPDATE_INTERVAL then
        return
    end
    followData.lastUpdateTime = now

    local vehicle = getEntityFromNetId(followData.netId)
    if not vehicle then
        followingVehicles[followData.netId] = nil
        return
    end

    local driver = getDriver(vehicle)
    if not driver then
        followingVehicles[followData.netId] = nil
        return
    end

    local playerPed = PlayerPedId()
    local playerVeh = GetVehiclePedIsIn(playerPed, false)

    -- Check if player exited vehicle
    if playerVeh == 0 or GetPedInVehicleSeat(playerVeh, -1) ~= playerPed then
        -- Player is out of vehicle, try to find stop location now
        local location, allCandidates = findOptimalStopLocation(vehicle)

        if location and location.score >= Config.MIN_ACCEPTABLE_SCORE then
            -- Found good spot, create stop
            followingVehicles[followData.netId] = nil

            createStop(vehicle, location)

            if lib and lib.notify then
                lib.notify({
                    title = 'Traffic Stop',
                    description = 'Vehicle found stop location and is pulling over',
                    type = 'success'
                })
            end
        else
            -- Still no good spot, stop where they are
            followingVehicles[followData.netId] = nil

            local vehCoords = GetEntityCoords(vehicle)
            local vehHeading = GetEntityHeading(vehicle)

            local immediateLocation = {
                type = 'IMMEDIATE',
                stopPos = vehCoords,
                approachPos = vehCoords,
                heading = vehHeading,
                shoulderWidth = 0,
                score = 0,
            }

            createStop(vehicle, immediateLocation)

            if lib and lib.notify then
                lib.notify({
                    title = 'Traffic Stop',
                    description = 'Vehicle stopping at current position',
                    type = 'info'
                })
            end
        end

        return
    end

    -- Continue following
    if not requestControl(vehicle, 200) or not requestControl(driver, 200) then
        return
    end

    local playerCoords = GetEntityCoords(playerVeh)
    local vehCoords = GetEntityCoords(vehicle)
    local distance = #(playerCoords - vehCoords)

    -- Maintain follow distance
    if distance > Config.FOLLOW_DISTANCE + 5.0 then
        TaskVehicleFollow(driver, vehicle, playerVeh, Config.FOLLOW_SPEED, Config.DRIVING_STYLE, Config.FOLLOW_DISTANCE)
    elseif distance < Config.FOLLOW_DISTANCE - 5.0 then
        -- Slow down
        TaskVehicleTempAction(driver, vehicle, 3, 1000) -- Slow down action
    end
end

--========================================
-- STOP STATE MANAGEMENT
--========================================

local function setupDriver(driver, vehicle)
    SetBlockingOfNonTemporaryEvents(driver, true)
    SetPedKeepTask(driver, true)
    SetDriverAbility(driver, 0.70)
    SetDriverAggressiveness(driver, 0.0)
    SetDriveTaskDrivingStyle(driver, Config.DRIVING_STYLE)
    SetVehicleIndicatorLights(vehicle, 1, true) -- Right indicator
end

local function taskDriveToApproach(driver, vehicle, coords, speed)
    TaskVehicleDriveToCoordLongrange(
        driver, vehicle,
        coords.x, coords.y, coords.z,
        speed,
        Config.DRIVING_STYLE,
        10.0
    )
end

local function taskParkAtLocation(driver, vehicle, coords, heading, isPavement)
    if isPavement then
        -- More careful parking for pavement
        TaskVehicleDriveToCoord(
            driver, vehicle,
            coords.x, coords.y, coords.z,
            Config.PARK_SPEED,
            1.0,
            GetEntityModel(vehicle),
            Config.DRIVING_STYLE,
            1.5,
            0.5
        )
    else
        TaskVehiclePark(
            driver, vehicle,
            coords.x, coords.y, coords.z,
            heading,
            1,
            20.0,
            false
        )
    end
end

local function taskImmediateStop(driver, vehicle)
    TaskVehicleTempAction(driver, vehicle, 1, 3000)
    BringVehicleToHalt(vehicle, 2.5, 6000, false)
end

local function finalizeStop(vehicle, driver)
    TaskVehicleTempAction(driver, vehicle, 27, 2000)
    SetVehicleHandbrake(vehicle, true)
    SetVehicleBrake(vehicle, true)
    SetVehicleEngineOn(vehicle, false, true, true)
end

-- Creates a new stop
local function createStop(vehicle, location)
    local netId = getNetId(vehicle)
    if not netId then return false end

    activeStops[netId] = {
        vehicle = vehicle,
        netId = netId,
        location = location,
        state = 'APPROACHING',
        lastTaskTime = 0,
        createdAt = GetGameTimer(),
        dismissed = false,
        frozen = false,
        progressStuck = false,
        lastDistance = 999999.0,
        lastProgressTime = GetGameTimer(),
        attemptsStuck = 0,
    }

    -- Sync to server
    TriggerServerEvent('pd_interactions:server:trafficStopStart', netId, {
        x = location.stopPos.x,
        y = location.stopPos.y,
        z = location.stopPos.z,
        h = location.heading,
        t = location.type,
        s = location.score,
    })

    return true
end

-- Updates stop state machine
local function updateStop(stopData)
    local now = GetGameTimer()
    local vehicle = getEntityFromNetId(stopData.netId)

    if not vehicle then
        activeStops[stopData.netId] = nil
        return
    end

    local driver = getDriver(vehicle)
    if not driver then
        activeStops[stopData.netId] = nil
        return
    end

    if not requestControl(vehicle, 250) or not requestControl(driver, 250) then
        return
    end

    local vehCoords = GetEntityCoords(vehicle)
    local vehSpeed = GetEntitySpeed(vehicle)
    local location = stopData.location

    local distToApproach = #(vehCoords - location.approachPos)
    local distToStop = #(vehCoords - location.stopPos)

    -- Progress tracking
    if distToStop < stopData.lastDistance - 0.5 then
        stopData.lastDistance = distToStop
        stopData.lastProgressTime = now
        stopData.progressStuck = false
        stopData.attemptsStuck = 0
    elseif now - stopData.lastProgressTime > Config.STUCK_TIMEOUT then
        stopData.progressStuck = true
        stopData.attemptsStuck = stopData.attemptsStuck + 1
    end

    -- State machine
    if stopData.state == 'APPROACHING' then
        if distToApproach < 15.0 or distToStop < 20.0 then
            stopData.state = 'PARKING'
            stopData.lastTaskTime = 0
        elseif now - stopData.lastTaskTime > Config.TASK_REISSUE_INTERVAL then
            setupDriver(driver, vehicle)
            taskDriveToApproach(driver, vehicle, location.approachPos, Config.APPROACH_SPEED)
            stopData.lastTaskTime = now
        end

        if stopData.progressStuck and stopData.attemptsStuck > 2 then
            stopData.state = 'FORCE_STOP'
        end
    elseif stopData.state == 'PARKING' then
        if distToStop < 4.0 and vehSpeed < 1.0 then
            stopData.state = 'STOPPING'
            stopData.lastTaskTime = 0
        elseif now - stopData.lastTaskTime > Config.TASK_REISSUE_INTERVAL then
            setupDriver(driver, vehicle)
            taskParkAtLocation(driver, vehicle, location.stopPos, location.heading, location.pavementFound)
            stopData.lastTaskTime = now
        end

        if stopData.progressStuck and stopData.attemptsStuck > 3 then
            stopData.state = 'FORCE_STOP'
        end
    elseif stopData.state == 'FORCE_STOP' then
        if not stopData.forcedOnce then
            taskImmediateStop(driver, vehicle)
            stopData.forcedOnce = true
        end

        if vehSpeed < 0.5 then
            stopData.state = 'STOPPING'
        end
    elseif stopData.state == 'STOPPING' then
        if not stopData.finalized then
            finalizeStop(vehicle, driver)
            stopData.finalized = true
            stopData.settleUntil = now + 1500
        end

        if now > (stopData.settleUntil or 0) and vehSpeed < 0.3 then
            stopData.state = 'STOPPED'
        end
    elseif stopData.state == 'STOPPED' then
        if not stopData.frozen then
            FreezeEntityPosition(vehicle, true)
            SetVehicleHandbrake(vehicle, true)
            SetVehicleEngineOn(vehicle, false, true, true)
            stopData.frozen = true

            if lib and lib.notify then
                local qualityMsg = location.score >= Config.EXCELLENT_SCORE_THRESHOLD and 'excellent' or
                    location.score >= Config.GOOD_SCORE_THRESHOLD and 'good' or 'adequate'

                lib.notify({
                    title = 'Traffic Stop Complete',
                    description = string.format('Vehicle stopped at %s %s location', qualityMsg, location.type:lower()),
                    type = 'success'
                })
            end
        end
    end
end

--========================================
-- PUBLIC API
--========================================

function Traffic.pullOver(vehicle)
    if not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2 then
        return false
    end

    local netId = getNetId(vehicle)
    if not netId then return false end

    -- Check cooldown
    if pullOverCooldowns[netId] and GetGameTimer() - pullOverCooldowns[netId] < Config.COOLDOWN_TIME then
        return false
    end

    -- Check if already stopped or following
    if (activeStops[netId] and not activeStops[netId].dismissed) or followingVehicles[netId] then
        return false
    end

    local driver = getDriver(vehicle)
    if not driver then return false end

    -- Find optimal stop location
    local location, allCandidates = findOptimalStopLocation(vehicle)

    if location and location.score >= Config.MIN_ACCEPTABLE_SCORE then
        -- Found good location
        if createStop(vehicle, location) then
            pullOverCooldowns[netId] = GetGameTimer()

            if lib and lib.notify then
                lib.notify({
                    title = 'Traffic Stop Initiated',
                    description = string.format('Vehicle pulling to %s (score: %.1f)', location.type:lower(),
                        location.score),
                    type = 'info'
                })
            end

            return true
        end
    else
        -- No good location found, initiate follow mode
        if initiateFollowMode(vehicle) then
            pullOverCooldowns[netId] = GetGameTimer()
            return true
        else
            if lib and lib.notify then
                lib.notify({
                    title = 'Traffic Stop Failed',
                    description = 'Unable to find safe stop location and cannot initiate follow mode',
                    type = 'error'
                })
            end

            return false
        end
    end

    return false
end

function Traffic.tryPullOverInFront()
    local playerPed = PlayerPedId()

    if not IsPedInAnyVehicle(playerPed, false) then
        return false
    end

    local playerVeh = GetVehiclePedIsIn(playerPed, false)
    if GetPedInVehicleSeat(playerVeh, -1) ~= playerPed then
        return false
    end

    if not isEmergencyWithSiren(playerVeh) then
        return false
    end

    local targetVeh = getVehicleAhead(playerVeh, 40.0)
    if not targetVeh then return false end

    local playerHeading = GetEntityHeading(playerVeh)
    local targetHeading = GetEntityHeading(targetVeh)

    if headingDifference(playerHeading, targetHeading) > 60.0 then
        return false
    end

    return Traffic.pullOver(targetVeh)
end

function Traffic.dismiss(vehicle)
    local netId = getNetId(vehicle)
    if not netId then return false end

    -- Check if in follow mode
    if followingVehicles[netId] then
        followingVehicles[netId] = nil

        local veh = getEntityFromNetId(netId)
        if veh then
            local driver = getDriver(veh)
            if driver and requestControl(driver, 500) then
                ClearPedTasks(driver)
                SetBlockingOfNonTemporaryEvents(driver, false)
                SetVehicleIndicatorLights(veh, 0, false)
                SetVehicleIndicatorLights(veh, 1, false)
                TaskVehicleDriveWander(driver, veh, 20.0, Config.DRIVING_STYLE)
            end
        end
        if lib and lib.notify then
            lib.notify({
                title = 'Traffic Stop',
                description = 'Following vehicle dismissed',
                type = 'info'
            })
        end

        return true
    end

    -- Check active stop
    if not activeStops[netId] then
        return false
    end

    local stopData = activeStops[netId]
    stopData.dismissed = true

    local veh = getEntityFromNetId(netId)
    if veh then
        FreezeEntityPosition(veh, false)
        SetVehicleHandbrake(veh, false)
        SetVehicleBrake(veh, false)
        SetVehicleEngineOn(veh, true, true, false)
        SetVehicleIndicatorLights(veh, 1, false)
        SetVehicleIndicatorLights(veh, 0, false)

        local driver = getDriver(veh)
        if driver and requestControl(driver, 500) then
            ClearPedTasks(driver)
            SetBlockingOfNonTemporaryEvents(driver, false)
            TaskVehicleDriveWander(driver, veh, 20.0, Config.DRIVING_STYLE)
        end
    end

    TriggerServerEvent('pd_interactions:server:trafficStopDismiss', netId)

    SetTimeout(2000, function()
        activeStops[netId] = nil
    end)

    return true
end

function Traffic.isStoppedVehicle(vehicle)
    local netId = getNetId(vehicle)
    if not netId then return false end
    local stop = activeStops[netId]
    return stop and not stop.dismissed
end

function Traffic.isFollowingVehicle(vehicle)
    local netId = getNetId(vehicle)
    return netId and followingVehicles[netId] ~= nil
end

function Traffic.getStopData(vehicle)
    local netId = getNetId(vehicle)
    return netId and activeStops[netId] or nil
end

function Traffic.getFollowData(vehicle)
    local netId = getNetId(vehicle)
    return netId and followingVehicles[netId] or nil
end

function Traffic.getStoppedVehicleForPed(ped)
    if not DoesEntityExist(ped) then return nil end
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
        if Traffic.isStoppedVehicle(vehicle) then
            return vehicle
        end
    end

    local lastVehicle = GetVehiclePedIsIn(ped, true)
    if lastVehicle ~= 0 and Traffic.isStoppedVehicle(lastVehicle) then
        return lastVehicle
    end

    return nil
end

-- Debug function to visualize candidates
function Traffic.debugDrawCandidates(vehicle)
    local _, allCandidates = findOptimalStopLocation(vehicle)
    if not allCandidates or #allCandidates == 0 then
        print("No candidates found")
        return
    end

    print(string.format("Found %d candidates:", #allCandidates))

    for i, candidate in ipairs(allCandidates) do
        print(string.format("  [%d] Type: %s, Score: %.2f, Side: %s",
            i, candidate.type, candidate.score, candidate.side))

        if candidate.scoreBreakdown then
            for key, value in pairs(candidate.scoreBreakdown) do
                if type(value) == 'number' then
                    print(string.format("    - %s: %.2f", key, value))
                end
            end
        end

        -- Draw marker in game
        CreateThread(function()
            local endTime = GetGameTimer() + 10000
            while GetGameTimer() < endTime do
                local color = i == 1 and { 0, 255, 0, 200 } or { 255, 0, 0, 150 }
                DrawMarker(
                    1,             -- cylinder
                    candidate.stopPos.x, candidate.stopPos.y, candidate.stopPos.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    2.0, 2.0, 1.0,
                    color[1], color[2], color[3], color[4],
                    false, false, 2, false, nil, nil, false
                )
                Wait(0)
            end
        end)
    end
end

--========================================
-- STATE BAG SYNC
--========================================
AddStateBagChangeHandler('pd_interactions_stop', nil, function(bagName, _, value)
    if type(value) ~= 'table' then return end
    local entity = GetEntityFromStateBagName(bagName)
    if not entity or not DoesEntityExist(entity) or GetEntityType(entity) ~= 2 then
        return
    end

    local netId = getNetId(entity)
    if not netId then return end

    if not activeStops[netId] then
        activeStops[netId] = value
    end
end)
--========================================
-- MAIN UPDATE LOOPS
--========================================
-- Stop updates
CreateThread(function()
    while true do
        Wait(Config.UPDATE_INTERVAL)
        for netId, stopData in pairs(activeStops) do
            if stopData.dismissed then
                goto continue
            end

            local success = pcall(updateStop, stopData)
            if not success then
                activeStops[netId] = nil
            end

            ::continue::
        end
    end
end)
-- Follow mode updates
CreateThread(function()
    while true do
        Wait(Config.FOLLOW_UPDATE_INTERVAL)
        for netId, followData in pairs(followingVehicles) do
            local success = pcall(updateFollowMode, followData)
            if not success then
                followingVehicles[netId] = nil
            end
        end
    end
end)
--========================================
-- CLEANUP
--========================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    -- Clean up active stops
    for netId, stopData in pairs(activeStops) do
        local vehicle = getEntityFromNetId(netId)
        if vehicle then
            FreezeEntityPosition(vehicle, false)
            SetVehicleHandbrake(vehicle, false)
            SetVehicleBrake(vehicle, false)
            SetVehicleIndicatorLights(vehicle, 1, false)
            SetVehicleEngineOn(vehicle, true, true, false)

            local driver = getDriver(vehicle)
            if driver then
                ClearPedTasks(driver)
                SetBlockingOfNonTemporaryEvents(driver, false)
            end
        end
    end

    -- Clean up following vehicles
    for netId, followData in pairs(followingVehicles) do
        local vehicle = getEntityFromNetId(netId)
        if vehicle then
            SetVehicleIndicatorLights(vehicle, 0, false)
            SetVehicleIndicatorLights(vehicle, 1, false)

            local driver = getDriver(vehicle)
            if driver then
                ClearPedTasks(driver)
                SetBlockingOfNonTemporaryEvents(driver, false)
            end
        end
    end
end)
return Traffic
