fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'pd_alrp'

shared_scripts {
    '@pd_lib/init.lua',
    '@pd_core/shared/bootstrap.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

dependency 'pd_lib'
dependency 'pd_npc'

