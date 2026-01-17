# pd_core

Minimal core for an LSPDFR-like framework:
- Player data manager (job/grade/name/activeDuty/metadata) with a single patch export.
- Callout manager (register callouts from any resource, trigger them to a specific player).

## Requirements
- SQL driver: `oxmysql` or `ghmattimysql`
- Add to server cfg: `ensure pd_core`

## Config (`config.lua`)
- `database.driver`: `auto` / `oxmysql` / `ghmattimysql`
- `database.tablePrefix`: default `pd_`
- `database.playerTable`: default `players`

## Player Data (Server)

Exports:
- `exports.pd_core:GetPlayerData(source)` -> `PDPlayerData|nil`
- `exports.pd_core:SetPlayerData(source, patchTable)` -> `PDPlayerData|nil`
- `exports.pd_core:CreatePlayer(source, initialPatchTable)` -> `PDPlayerData|nil`
- `exports.pd_core:LoginPlayer(source)` -> `PDPlayerData|nil`

Patch rules:
- Only keys present in `patchTable` are applied.
- `metadata` merges shallowly into existing metadata.

Example:
```lua
exports.pd_core:CreatePlayer(src, { metadata = { created = os.time() } })
exports.pd_core:LoginPlayer(src)

exports.pd_core:SetPlayerData(src, {
    job = 'police',
    grade = 2,
    name = 'John Doe',
    activeDuty = true,
    metadata = { division = 'patrol', callsign = '1A-12' }
})
```

Client export:
- `exports.pd_core:GetLocalPlayerData()` -> cached `PDPlayerData|nil`

## Callouts (Server)

Callouts are registered from any resource and started by triggering the registered `startEvent` on the target player's client.

Exports:
- `exports.pd_core:RegisterCallout({ name = '...', startEvent = '...', locations = { ... } })` -> `boolean`
- `exports.pd_core:TriggerCallout(targetSource, calloutName, payload)` -> `boolean`
- `exports.pd_core:GetCallouts()` -> `table`

Example (in your callout resource, server-side):
```lua
CreateThread(function()
    exports.pd_core:RegisterCallout({
        name = 'stolen_vehicle',
        code = '10-60',
        title = 'Stolen Vehicle',
        description = 'Vehicle reported stolen in the area.',
        department = 'LSPD',
        minRank = 0,
        startEvent = 'my_callouts:stolenVehicle:start',
        locations = {
            vector3(215.2, -810.4, 30.7),
            vector3(425.1, -996.3, 30.7)
        }
    })
end)
```

Example (client-side in your callout resource):
```lua
RegisterNetEvent('my_callouts:stolenVehicle:start', function(payload, calloutName)
    print('Starting callout:', calloutName)
end)
```

