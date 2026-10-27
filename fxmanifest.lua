fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'AEOM Development'

name 'aeom-bridge'
description 'Bridge partagé : framework, inventaire, target, notifications, textui, clés de véhicule, callbacks'
version '1.1.0'

-- init.lua est inclus par les autres ressources via shared_script '@aeom-bridge/init.lua' :
-- le client doit pouvoir le télécharger, donc il doit être déclaré ici.
files {
    'init.lua',
}

-- Fichiers partagés (client + serveur) : config, puis utilitaires/détection.
shared_scripts {
    'config.lua',
    'shared/utils.lua',
}

-- Chaque module se désactive tout seul s'il n'est pas le système détecté.
-- main.lua doit rester en dernier : il assemble les exports.
client_scripts {
    'modules/framework/esx/client.lua',
    'modules/framework/qb/client.lua',
    'modules/framework/qbx/client.lua',
    'modules/target/ox_target/client.lua',
    'modules/target/qb-target/client.lua',
    'modules/notify/ox_lib/client.lua',
    'modules/notify/framework/client.lua',
    'modules/notify/native/client.lua',
    'modules/textui/ox_lib/client.lua',
    'modules/textui/native/client.lua',
    'modules/vehiclekeys/qb-vehiclekeys/client.lua',
    'modules/vehiclekeys/qbx_vehiclekeys/client.lua',
    'client/main.lua',
}

server_scripts {
    'modules/framework/esx/server.lua',
    'modules/framework/qb/server.lua',
    'modules/framework/qbx/server.lua',
    'modules/inventory/ox_inventory/server.lua',
    'modules/inventory/qb-inventory/server.lua',
    'modules/inventory/native/server.lua',
    'modules/vehiclekeys/qb-vehiclekeys/server.lua',
    'modules/vehiclekeys/qbx_vehiclekeys/server.lua',
    'server/compat.lua',
    'server/main.lua',
}
