fx_version 'cerulean'
game 'gta5'

author 'Advanced Drugs Development Team'
description 'Advanced Drug Script for ESX Legacy with Realistic Systems'
version '1.0.0'

dependencies {
    'es_extended',
    'ox_inventory',
    'ox_lib'
}

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@es_extended/imports.lua',
    'server.lua'
}

escrow_ignore {
    'config.lua',
    'README.md'
}

lua54 'yes'
