fx_version 'cerulean'
game 'gta5'

author 'SantosMods.dev'
description 'Vehicle Spawner (OxLib + ox_target)'
version '1.0'

shared_script '@ox_lib/init.lua'
dependencies {
    'ox_lib',
    'ox_target'
}

client_scripts {
    'config.lua',
    'client.lua'
}

lua54 'yes'
