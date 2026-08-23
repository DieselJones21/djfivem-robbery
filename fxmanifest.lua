fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'djfivem-robbery'
author 'DieselJones'
description 'Qbox robbery tablet for banks, stores, ATMs, vehicles, money trucks, and Ammunation'
version '1.0.0'

ox_libs {
    'locale',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/locations.lua',
}

client_scripts {
    'client/utils.lua',
    'client/minigames.lua',
    'client/tablet.lua',
    'client/robbery.lua',
}

server_scripts {
    'server/utils.lua',
    'server/crew.lua',
    'server/jobs.lua',
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
    'web/images/jobs/*.jpg',
    'web/images/items/*',
    'locales/*.json',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'qbx_core',
}
