Config = {}


-- Extra patrol spawner (police cars cruising around)
Config.Patrols = {
  Enabled = true,

  -- How often we try a spawn (ms)
  TickMs = 4500,

  -- Chance per tick to attempt a spawn (0.0 - 1.0)
  SpawnChance = 0.50,

  -- Max active patrol cars spawned by THIS client
  MaxActive = 8,

  -- Spawn distance from player
  DistanceMin = 90.0,
  DistanceMax = 260.0,

  -- Despawn when far away
  DespawnDistance = 450.0,

  -- Force-delete after this long (ms)
  MaxLifeMs = 180000,

  -- Avoid spawning where player has line-of-sight (reduces “pop-in”)
  AvoidLineOfSight = true,

  -- Subtle lights/siren
  LightsChance = 0.18,
  SirenChance  = 0.08,

  -- Driving
  CruiseSpeed = 17.0,
  DrivingStyle = 786603,

  -- Zone blacklist (4-letter zone codes)
  ZoneBlacklist = {
    'AIRP', -- LSIA
    'ZANC', -- Zancudo
  },

  PoliceVehicles = {
    { model = 'police',  weight = 50 },
    { model = 'police2', weight = 25 },
    { model = 'police3', weight = 15 },
    { model = 'police4', weight = 10 },
  },

  CopPeds = {
    's_m_y_cop_01',
    's_m_y_hwaycop_01',
    's_m_y_sheriff_01',
  },
}

-- Ambient event scenes
Config.Events = {
  Enabled = true,

  TickMs = 6500,
  MaxActive = 2,
  CooldownMs = 45000,

  DistanceMin = 120.0,
  DistanceMax = 300.0,

  -- Despawn if player is far (even if time not finished)
  DespawnDistance = 520.0,

  -- Adds a mild “weird” call type
  WeirdMode = true,

  Weights = {
    TrafficStop = 25,
    BriefChase  = 18,
    CrashScene  = 18,
    Stakeout    = 7,
    StrangeCall = 7, -- only if WeirdMode = true
    DrugBust = 12,
    DomesticDispute = 10,
    SpeedTrap = 8,
    ArrestScene = 12,
    Barricade = 7,
    CarFight = 20,
    RoadRage = 15,
    PedestrianAltercation = 18,
    SuspiciousActivity = 12,
    PublicDisturbance = 10,
    HitAndRun = 14,
  },

  CivilianVehicles = {
    { model = 'asea',     weight = 25 },
    { model = 'primo',    weight = 25 },
    { model = 'tailgater',weight = 20 },
    { model = 'sultan',   weight = 15 },
    { model = 'blista',   weight = 15 },
  },

  CivilianPeds = {
    'a_m_y_business_01',
    'a_m_y_hipster_01',
    'a_m_y_genstreet_01',
    'a_f_y_tourist_01',
  },
}
