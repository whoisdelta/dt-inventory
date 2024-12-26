fx_version 'adamant'
game 'gta5'
version '1.0.0'

author '@whoisdelta.'

client_scripts {
    'client.lua',
    'utils.lua'
}

server_scripts {
    'utils_sv.lua',
    'server.lua'
}

shared_scripts {
    'Config.lua'
}

files {
    'ui/**/*'
}

lua54 'yes'

ui_page 'ui/index.html'