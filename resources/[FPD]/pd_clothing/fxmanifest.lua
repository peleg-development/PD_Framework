fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'pd_clothing'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*'
}

shared_scripts {
    '@pd_lib/init.lua',
    '@pd_core/shared/bootstrap.lua',
    'config.lua'
}

server_scripts {
    'server/outfits.lua',
    'server/main.lua'
}

client_scripts {
    'client/appearance.lua',
    'client/main.lua'
}

dependency 'pd_core'
dependency 'pd_char'

