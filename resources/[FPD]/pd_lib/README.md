# pd_lib

UI + utility library (ox_lib style) for FiveM.

## Install

1) Ensure resource:
- `ensure pd_lib`

2) In any resource that wants to use it:
```lua
shared_script '@pd_lib/init.lua'
```

## Debug

Debug is **on by default**.

- Global toggle: `setr pd_debug 0` or `setr pd_debug 1`
- Per-resource override: `setr <resourceName>:debug 0` or `setr <resourceName>:debug 1`

## API

### notify

Client:
```lua
lib.notify({
    title = 'Dispatch',
    description = 'New callout available',
    type = 'info',
    duration = 4000
})
```

Server:
```lua
lib.notify({
    target = source,
    title = 'Admin',
    description = 'You are now on duty',
    type = 'success'
})
```

### context menu

Client:
```lua
lib.registerContext({
    id = 'pd_actions',
    title = 'Police Actions',
    description = 'Quick menu',
    focus = true,
    options = {
        {
            id = 'onduty',
            title = 'Go On Duty',
            description = 'Enable dispatch and callouts',
            onSelect = function()
                TriggerServerEvent('my_resource:onDuty')
            end
        },
        {
            id = 'offduty',
            title = 'Go Off Duty',
            description = 'Disable dispatch and callouts',
            onSelect = function()
                TriggerServerEvent('my_resource:offDuty')
            end
        }
    }
})

lib.showContext('pd_actions')
```

### progress bar

Client:
```lua
local ok = lib.progressBar({
    duration = 5000,
    label = 'Checking vehicle plate...',
    canCancel = true
})

if ok then
    lib.notify({ title = 'Done', description = 'Plate checked', type = 'success' })
else
    lib.notify({ title = 'Cancelled', description = 'Action cancelled', type = 'warning' })
end
```

