local Config = {}

---@param resourceName string
---@return table
function Config.get(resourceName)
    return Config
end

---@class ClothingConfig
Config.command = 'clothing'
Config.commandDescription = 'Open clothing menu'

---@type vector3
Config.previewCoords = vector3(-75.0, -818.0, 326.0)

---@type vector3
Config.skyCoords = vector3(0.0, 0.0, 2000.0)

---@class PresetOutfit
---@field name string
---@field label string
---@field appearance table

---@type PresetOutfit[]
Config.presetOutfits = {
    {
        name = 'police_uniform_1',
        label = 'Police Uniform - Standard',
        appearance = {
            mother = 21,
            father = 0,
            skinMix = 0.5,
            shapeMix = 0.5,
            features = {
                noseWidth = 0.0,
                noseHeight = 0.0,
                noseLength = 0.0,
                noseBridge = 0.0,
                noseTip = 0.0,
                noseShift = 0.0,
                browHeight = 0.0,
                browWidth = 0.0,
                cheekboneHeight = 0.0,
                cheekboneWidth = 0.0,
                cheeksWidth = 0.0,
                eyes = 0.0,
                lips = 0.0,
                jawWidth = 0.0,
                jawHeight = 0.0,
                chinLength = 0.0,
                chinPosition = 0.0,
                chinWidth = 0.0,
                chinShape = 0.0,
                neckWidth = 0.0
            },
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
            components = {
                [1] = { drawable = 0, texture = 0 },
                [2] = { drawable = 0, texture = 0 },
                [3] = { drawable = 55, texture = 0 },
                [4] = { drawable = 35, texture = 0 },
                [5] = { drawable = 0, texture = 0 },
                [6] = { drawable = 25, texture = 0 },
                [7] = { drawable = 0, texture = 0 },
                [8] = { drawable = 15, texture = 0 },
                [9] = { drawable = 0, texture = 0 },
                [10] = { drawable = 0, texture = 0 },
                [11] = { drawable = 55, texture = 0 },
            },
            props = {
                [0] = { drawable = -1, texture = 0 },
                [1] = { drawable = -1, texture = 0 },
                [2] = { drawable = -1, texture = 0 },
                [6] = { drawable = -1, texture = 0 },
                [7] = { drawable = -1, texture = 0 },
            },
            tattoos = {},
            overlays = {
                blemishes = { style = 0, opacity = 1.0 },
                blemishesColor = { style = 0, opacity = 1.0 },
                ageing = { style = 0, opacity = 1.0 },
                makeup = { style = 0, opacity = 1.0 },
            }
        }
    },
    {
        name = 'police_uniform_2',
        label = 'Police Uniform - Patrol',
        appearance = {
            mother = 21,
            father = 0,
            skinMix = 0.5,
            shapeMix = 0.5,
            features = {
                noseWidth = 0.0,
                noseHeight = 0.0,
                noseLength = 0.0,
                noseBridge = 0.0,
                noseTip = 0.0,
                noseShift = 0.0,
                browHeight = 0.0,
                browWidth = 0.0,
                cheekboneHeight = 0.0,
                cheekboneWidth = 0.0,
                cheeksWidth = 0.0,
                eyes = 0.0,
                lips = 0.0,
                jawWidth = 0.0,
                jawHeight = 0.0,
                chinLength = 0.0,
                chinPosition = 0.0,
                chinWidth = 0.0,
                chinShape = 0.0,
                neckWidth = 0.0
            },
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
            components = {
                [1] = { drawable = 0, texture = 0 },
                [2] = { drawable = 0, texture = 0 },
                [3] = { drawable = 55, texture = 1 },
                [4] = { drawable = 35, texture = 0 },
                [5] = { drawable = 0, texture = 0 },
                [6] = { drawable = 25, texture = 0 },
                [7] = { drawable = 0, texture = 0 },
                [8] = { drawable = 15, texture = 0 },
                [9] = { drawable = 0, texture = 0 },
                [10] = { drawable = 0, texture = 0 },
                [11] = { drawable = 55, texture = 1 },
            },
            props = {
                [0] = { drawable = -1, texture = 0 },
                [1] = { drawable = -1, texture = 0 },
                [2] = { drawable = -1, texture = 0 },
                [6] = { drawable = -1, texture = 0 },
                [7] = { drawable = -1, texture = 0 },
            },
            tattoos = {},
            overlays = {
                blemishes = { style = 0, opacity = 1.0 },
                blemishesColor = { style = 0, opacity = 1.0 },
                ageing = { style = 0, opacity = 1.0 },
                makeup = { style = 0, opacity = 1.0 },
            }
        }
    },
    {
        name = 'civilian_casual',
        label = 'Civilian - Casual',
        appearance = {
            mother = 21,
            father = 0,
            skinMix = 0.5,
            shapeMix = 0.5,
            features = {
                noseWidth = 0.0,
                noseHeight = 0.0,
                noseLength = 0.0,
                noseBridge = 0.0,
                noseTip = 0.0,
                noseShift = 0.0,
                browHeight = 0.0,
                browWidth = 0.0,
                cheekboneHeight = 0.0,
                cheekboneWidth = 0.0,
                cheeksWidth = 0.0,
                eyes = 0.0,
                lips = 0.0,
                jawWidth = 0.0,
                jawHeight = 0.0,
                chinLength = 0.0,
                chinPosition = 0.0,
                chinWidth = 0.0,
                chinShape = 0.0,
                neckWidth = 0.0
            },
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
            components = {
                [1] = { drawable = 0, texture = 0 },
                [2] = { drawable = 0, texture = 0 },
                [3] = { drawable = 15, texture = 0 },
                [4] = { drawable = 21, texture = 0 },
                [5] = { drawable = 0, texture = 0 },
                [6] = { drawable = 34, texture = 0 },
                [7] = { drawable = 0, texture = 0 },
                [8] = { drawable = 15, texture = 0 },
                [9] = { drawable = 0, texture = 0 },
                [10] = { drawable = 0, texture = 0 },
                [11] = { drawable = 15, texture = 0 },
            },
            props = {
                [0] = { drawable = -1, texture = 0 },
                [1] = { drawable = -1, texture = 0 },
                [2] = { drawable = -1, texture = 0 },
                [6] = { drawable = -1, texture = 0 },
                [7] = { drawable = -1, texture = 0 },
            },
            tattoos = {},
            overlays = {
                blemishes = { style = 0, opacity = 1.0 },
                blemishesColor = { style = 0, opacity = 1.0 },
                ageing = { style = 0, opacity = 1.0 },
                makeup = { style = 0, opacity = 1.0 },
            }
        }
    }
}

return Config

