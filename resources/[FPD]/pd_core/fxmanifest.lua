fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'pd_core'

shared_scripts {
    '@pd_lib/init.lua',
    'shared/bootstrap.lua',
    'config.lua',
    'shared/utils.lua'
}

server_scripts {
    'server/db.lua',
    'server/playerdata.lua',
    'server/callouts.lua',
    'server/main.lua'
}

client_scripts {
    'client/playerdata.lua',
    'client/main.lua'
}

server_exports {
    'GetPlayerData',
    'SetPlayerData',
    'CreatePlayer',
    'LoginPlayer',
    'RegisterCallout',
    'TriggerCallout',
    'GetCallouts'
}

client_exports {
    'GetLocalPlayerData'
}

