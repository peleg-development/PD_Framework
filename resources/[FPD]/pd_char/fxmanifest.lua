fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'pd_char'

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*'
}

shared_scripts {
    '@pd_lib/init.lua',
    '@pd_core/shared/bootstrap.lua',
    'shared/bootstrap.lua',
    'config.lua'
}

server_scripts {
    'server/db.lua',
    'server/characters.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

server_exports {
    'GetCharacters',
    'GetActiveCharacter',
    'SelectCharacter',
    'CreateCharacter'
}

client_exports {
    'OpenSelection',
    'GetLocalCharacters'
}

dependency 'pd_core'
