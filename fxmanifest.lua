fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'djfivem-robbery'
author 'DieselJones'
description 'NEXUS v2 — Qbox heist pack with tablet, kit store, Wasabi PD/MDT dispatch, and armed guards'
version '2.0.0'

ox_libs {
    'locale',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/store.lua',
    'shared/locations.lua',
}

client_scripts {
    'client/utils.lua',
    'client/minigames.lua',
    'client/guards.lua',
    'client/shop.lua',
    'client/tablet.lua',
    'client/robbery.lua',
}

server_scripts {
    'server/utils.lua',
    'server/police.lua',
    'server/crew.lua',
    'server/jobs.lua',
    'server/store.lua',
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
