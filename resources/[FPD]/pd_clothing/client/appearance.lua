---@class Appearance
local Appearance = {}

---@param ped number
---@param appearance table
function Appearance.apply(ped, appearance)
    if not appearance or type(appearance) ~= 'table' then
        return
    end
    
    if not DoesEntityExist(ped) then
        return
    end
    
    SetPedDefaultComponentVariation(ped) --[[@as boolean]]
    
    -- Parent/Heritage
    if appearance.mother ~= nil and appearance.father ~= nil then
        SetPedHeadBlendData(
            ped,
            appearance.mother or 0,
            appearance.father or 0,
            0,
            appearance.mother or 0,
            appearance.father or 0,
            0,
            appearance.skinMix or 0.5,
            appearance.shapeMix or 0.5,
            0.0,
            0.0
        )
    end
    
    -- Facial Features
    if appearance.features and type(appearance.features) == 'table' then
        local features = appearance.features
        SetPedFaceFeature(ped, 0, features.noseWidth or 0.0)
        SetPedFaceFeature(ped, 1, features.noseHeight or 0.0)
        SetPedFaceFeature(ped, 2, features.noseLength or 0.0)
        SetPedFaceFeature(ped, 3, features.noseBridge or 0.0)
        SetPedFaceFeature(ped, 4, features.noseTip or 0.0)
        SetPedFaceFeature(ped, 5, features.noseShift or 0.0)
        SetPedFaceFeature(ped, 6, features.browHeight or 0.0)
        SetPedFaceFeature(ped, 7, features.browWidth or 0.0)
        SetPedFaceFeature(ped, 8, features.cheekboneHeight or 0.0)
        SetPedFaceFeature(ped, 9, features.cheekboneWidth or 0.0)
        SetPedFaceFeature(ped, 10, features.cheeksWidth or 0.0)
        SetPedFaceFeature(ped, 11, features.eyes or 0.0)
        SetPedFaceFeature(ped, 12, features.lips or 0.0)
        SetPedFaceFeature(ped, 13, features.jawWidth or 0.0)
        SetPedFaceFeature(ped, 14, features.jawHeight or 0.0)
        SetPedFaceFeature(ped, 15, features.chinLength or 0.0)
        SetPedFaceFeature(ped, 16, features.chinPosition or 0.0)
        SetPedFaceFeature(ped, 17, features.chinWidth or 0.0)
        SetPedFaceFeature(ped, 18, features.chinShape or 0.0)
        SetPedFaceFeature(ped, 19, features.neckWidth or 0.0)
    end
    
    -- Hair
    if appearance.hairStyle ~= nil then
        SetPedComponentVariation(ped, 2, appearance.hairStyle or 0, 0, 0)
    end
    if appearance.hairColor ~= nil then
        SetPedHairColor(ped, appearance.hairColor or 0, appearance.hairHighlight or 0)
    end
    
    -- Eye Color
    if appearance.eyeColor ~= nil then
        SetPedEyeColor(ped, appearance.eyeColor or 0)
    end
    
    -- Eyebrows
    if appearance.eyebrows ~= nil then
        SetPedHeadOverlay(ped, 2, appearance.eyebrows or 0, appearance.eyebrowColor and (appearance.eyebrowColor / 255.0) or 1.0)
    end
    
    -- Beard
    if appearance.beard ~= nil then
        SetPedHeadOverlay(ped, 1, appearance.beard or 0, appearance.beardOpacity or 1.0)
        if appearance.beardColor ~= nil then
            SetPedHeadOverlayColor(ped, 1, 1, appearance.beardColor or 0, 0)
        end
    end
    
    -- Makeup
    if appearance.makeup ~= nil then
        SetPedHeadOverlay(ped, 4, appearance.makeup or 0, appearance.makeupOpacity or 1.0)
        if appearance.makeupColor ~= nil then
            SetPedHeadOverlayColor(ped, 4, 1, appearance.makeupColor or 0, 0)
        end
    end
    
    -- Blush
    if appearance.blush ~= nil then
        SetPedHeadOverlay(ped, 5, appearance.blush or 0, appearance.blushOpacity or 0.0)
        if appearance.blushColor ~= nil then
            SetPedHeadOverlayColor(ped, 5, 1, appearance.blushColor or 0, 0)
        end
    end
    
    -- Lipstick
    if appearance.lipstick ~= nil then
        SetPedHeadOverlay(ped, 8, appearance.lipstick or 0, appearance.lipstickOpacity or 0.0)
        if appearance.lipstickColor ~= nil then
            SetPedHeadOverlayColor(ped, 8, 1, appearance.lipstickColor or 0, 0)
        end
    end
    
    -- Components (Clothing)
    if appearance.components and type(appearance.components) == 'table' then
        for componentId, component in pairs(appearance.components) do
            if type(component) == 'table' and component.drawable ~= nil then
                SetPedComponentVariation(ped, tonumber(componentId), component.drawable or 0, component.texture or 0, 0)
            end
        end
    end
    
    -- Props (Accessories)
    if appearance.props and type(appearance.props) == 'table' then
        for propId, prop in pairs(appearance.props) do
            if type(prop) == 'table' then
                local propIndex = tonumber(propId)
                if prop.drawable == -1 or prop.drawable == nil then
                    ClearPedProp(ped, propIndex)
                else
                    SetPedPropIndex(ped, propIndex, prop.drawable or 0, prop.texture or 0, true)
                end
            end
        end
    end
    
    -- Overlays
    if appearance.overlays and type(appearance.overlays) == 'table' then
        local overlays = appearance.overlays
        if overlays.blemishes then
            SetPedHeadOverlay(ped, 0, overlays.blemishes.style or 0, overlays.blemishes.opacity or 1.0)
        end
        if overlays.blemishesColor then
            SetPedHeadOverlayColor(ped, 0, 0, overlays.blemishesColor.style or 0, 0)
        end
        if overlays.ageing then
            SetPedHeadOverlay(ped, 3, overlays.ageing.style or 0, overlays.ageing.opacity or 1.0)
        end
        if overlays.makeup then
            SetPedHeadOverlay(ped, 4, overlays.makeup.style or 0, overlays.makeup.opacity or 1.0)
        end
    end
    
    -- Tattoos
    if appearance.tattoos and type(appearance.tattoos) == 'table' then
        ClearPedDecorations(ped)
        for _, tattoo in ipairs(appearance.tattoos) do
            if tattoo.collection and tattoo.name then
                AddPedDecorationFromHashes(ped, GetHashKey(tattoo.collection), GetHashKey(tattoo.name))
            end
        end
    end
end

---@param ped number
---@return table
function Appearance.extract(ped)
    if not DoesEntityExist(ped) then
        return {}
    end
    
    local appearance = {
        mother = 0,
        father = 0,
        skinMix = 0.5,
        shapeMix = 0.5,
        features = {},
        hairStyle = 0,
        hairColor = 0,
        hairHighlight = 0,
        eyeColor = 0,
        eyebrows = 0,
        eyebrowColor = 0,
        beard = 0,
        beardColor = 0,
        beardOpacity = 1.0,
        makeup = 0,
        makeupColor = 0,
        makeupOpacity = 1.0,
        blush = 0,
        blushColor = 0,
        blushOpacity = 0.0,
        lipstick = 0,
        lipstickColor = 0,
        lipstickOpacity = 0.0,
        components = {},
        props = {},
        tattoos = {},
        overlays = {}
    }
    
    -- Extract parent data
    local mother, father, motherMix, fatherMix, skinMix, shapeMix = GetPedHeadBlendData(ped)
    appearance.mother = (mother and mother >= 0) and mother or 0
    appearance.father = (father and father >= 0) and father or 0
    appearance.skinMix = (skinMix and skinMix >= 0) and skinMix or 0.5
    appearance.shapeMix = (shapeMix and shapeMix >= 0) and shapeMix or 0.5
    
    -- Extract facial features
    for i = 0, 19 do
        local value = GetPedFaceFeature(ped, i)
        if i == 0 then appearance.features.noseWidth = value
        elseif i == 1 then appearance.features.noseHeight = value
        elseif i == 2 then appearance.features.noseLength = value
        elseif i == 3 then appearance.features.noseBridge = value
        elseif i == 4 then appearance.features.noseTip = value
        elseif i == 5 then appearance.features.noseShift = value
        elseif i == 6 then appearance.features.browHeight = value
        elseif i == 7 then appearance.features.browWidth = value
        elseif i == 8 then appearance.features.cheekboneHeight = value
        elseif i == 9 then appearance.features.cheekboneWidth = value
        elseif i == 10 then appearance.features.cheeksWidth = value
        elseif i == 11 then appearance.features.eyes = value
        elseif i == 12 then appearance.features.lips = value
        elseif i == 13 then appearance.features.jawWidth = value
        elseif i == 14 then appearance.features.jawHeight = value
        elseif i == 15 then appearance.features.chinLength = value
        elseif i == 16 then appearance.features.chinPosition = value
        elseif i == 17 then appearance.features.chinWidth = value
        elseif i == 18 then appearance.features.chinShape = value
        elseif i == 19 then appearance.features.neckWidth = value
        end
    end
    
    -- Extract hair
    appearance.hairStyle = GetPedDrawableVariation(ped, 2) or 0
    local hairColor, highlightColor = GetPedHairColor(ped)
    appearance.hairColor = (hairColor and hairColor >= 0) and hairColor or 0
    appearance.hairHighlight = (highlightColor and highlightColor >= 0) and highlightColor or 0
    
    -- Extract eye color
    appearance.eyeColor = GetPedEyeColor(ped) or 0
    
    -- Extract overlays - using safe defaults since extraction natives may not be reliable
    -- These values will be preserved from existing appearance or set to defaults
    appearance.eyebrows = appearance.eyebrows or 0
    appearance.eyebrowColor = appearance.eyebrowColor or 0
    appearance.beard = appearance.beard or 0
    appearance.beardOpacity = appearance.beardOpacity or 1.0
    appearance.beardColor = appearance.beardColor or 0
    appearance.makeup = appearance.makeup or 0
    appearance.makeupOpacity = appearance.makeupOpacity or 1.0
    appearance.makeupColor = appearance.makeupColor or 0
    appearance.blush = appearance.blush or 0
    appearance.blushOpacity = appearance.blushOpacity or 0.0
    appearance.blushColor = appearance.blushColor or 0
    appearance.lipstick = appearance.lipstick or 0
    appearance.lipstickOpacity = appearance.lipstickOpacity or 0.0
    appearance.lipstickColor = appearance.lipstickColor or 0
    
    -- Extract components
    for i = 0, 11 do
        local drawable = GetPedDrawableVariation(ped, i) or 0
        local texture = GetPedTextureVariation(ped, i) or 0
        appearance.components[i] = { drawable = drawable, texture = texture }
    end
    
    -- Extract props
    for i = 0, 7 do
        local drawable = GetPedPropIndex(ped, i) or -1
        local texture = 0
        if drawable ~= -1 then
            texture = GetPedPropTextureIndex(ped, i) or 0
        end
        appearance.props[i] = { drawable = drawable, texture = texture }
    end
    
    return appearance
end

return Appearance

