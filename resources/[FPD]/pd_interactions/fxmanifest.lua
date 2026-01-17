fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'pd_interactions'

dependency 'pd_lib'
dependency 'pd_npc'
dependency 'pd_core'

files {
    'data/*.xml'
}

shared_scripts {
    '@pd_lib/init.lua',
    '@pd_core/shared/bootstrap.lua'
}

server_scripts {
    '@pd_lib/init.lua',
    'server/main.lua'
}

client_scripts {
    'shared/xml.lua',
    'client/target.lua',
    'client/traffic.lua',
    'client/questions.lua',
    'client/custody.lua',
    'client/vehicle.lua',
    'client/actions.lua',
    'client/main.lua',
    'menu.lua'
}


