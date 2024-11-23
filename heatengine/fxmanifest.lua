fx_version 'cerulean'
games { 'gta5' }

author 'Az Scripts'
description 'Vehicle Engine Heating Script'
version '1.0.0'


client_scripts {
    'client/client.lua'
}

shared_script 'config.lua'



server_scripts {
    'server/server.lua',
}

-- Specify the UI files
ui_page 'ui/index.html'
files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/engine-icon-normal.png',
    'ui/engine-icon-orange.png',
    'ui/engine-icon-red.png',
    'ui/beep.wav'
}

