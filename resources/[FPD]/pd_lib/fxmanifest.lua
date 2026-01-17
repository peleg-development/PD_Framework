fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'pd_lib'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*'
}

shared_scripts {
    'init.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

