# pd_callouts_manager

Dispatch/offer callouts to players based on:
- player location (closest location for each callout)
- player metadata (10-4 availability, rank, department)
- config limits (max distance, interval, timeout)

## Requirements
- `pd_core` must be started before this resource.
- Build the UI once:
  - `cd pd_callouts_manager/web`
  - `npm i`
  - `npm run build`

## Config (`config.lua`)
- `enabled`: toggle dispatcher
- `offerTimeoutMs`: how long the offer stays on screen (default `15000`)
- `tickIntervalMs`: how often to try offering a callout (default `30000`)
- `maxDistance`: max meters to closest callout location (default `2500.0`)
- `requireActiveDuty`: requires `pd_core` player data `activeDuty == true`
- `metadata.tenFourKey`: metadata key used for 10-4 (default `tenFour`)
- `metadata.rankKey`: metadata key used for rank (default `rank`)
- `metadata.departmentKey`: metadata key used for department (default `department`)

10-4 logic:
- `metadata[tenFourKey] == true` is treated as available.
- `metadata[tenFourKey] == '10-4'` or `'10-8'` is treated as available.

## Callout registration schema (in pd_core)

Register callouts from any resource:
```lua
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
```

`pd_callouts_manager` will pick the closest location to the player and offer it.

## Flow
- Server selects a target player who is eligible (active duty + 10-4 + no pending offer).
- Picks the best callout for that player (rank/department + distance).
- Client shows offer UI + creates a blip at the chosen location.
- Player presses **Y** to accept (15s timeout).
- Server triggers the callout via `exports.pd_core:TriggerCallout(player, calloutName, { location = vector3(...) })`.

