fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'pd_callouts_manager'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*'
}

shared_scripts {
    '@pd_lib/init.lua',
    'config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependency 'pd_core'

