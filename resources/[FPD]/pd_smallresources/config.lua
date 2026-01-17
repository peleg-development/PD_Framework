Config = {
    enable = true,
    debug = false,

    radius = 250.0, -- meters around player
    policeScanMs = 1000,
    engagedScanMs = 2500,
    reapplyPoliceMs = 6000,
    reapplyEngagedMs = 8000,

    buffEngagedNPCs = true,
    disableWantedLevel = true,

    policeSeeingRange = 90.0,
    policeHearingRange = 80.0,
    policeAlertness = 3,             -- 0..3

    policeCombatAbility = 2,         -- 0..2
    policeCombatMovement = 2,        -- 0..2 (0=stationary 1=defensive 2=offensive)
    policeCombatRange = 2,           -- 0..2 (0=near 1=medium 2=far)

    policeAccuracy = 45,             -- 0..100
    policeShootRate = 700,           -- ~0..1000

    policeMoveRate = 1.15,           -- 0.8..1.5 (on-foot)
    policeMoveBlend = 1.15,          -- 0.8..1.5 (on-foot)

    policeDriverAbility = 1.0,       -- 0..1
    policeDriverAggro = 1.0,         -- 0..1
    policeDrivingStyle = 1074528293, -- aggressive/pursuit-like

    policeRagdollFromImpact = false,

    engagedSeeingRange = 70.0,
    engagedHearingRange = 60.0,
    engagedAlertness = 2,

    engagedCombatAbility = 1,
    engagedCombatMovement = 1,
    engagedCombatRange = 1,

    engagedAccuracy = 25,
    engagedShootRate = 450,

    engagedMoveRate = 1.05,
    engagedMoveBlend = 1.05,
}
