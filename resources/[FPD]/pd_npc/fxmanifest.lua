fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'pd_npc'

dependency 'pd_lib'

shared_scripts {
    '@pd_lib/init.lua',
    'shared/bootstrap.lua',
    'config.lua',
    'shared/types.lua',
    'shared/random.lua',
    'shared/generate.lua'
}

server_scripts {
    'server/generate.lua',
    'server/main.lua'
}

client_scripts {
    'client/effects.lua',
    'client/search.lua',
    'client/profile.lua',
    'client/population.lua',
    'client/main.lua'
}


