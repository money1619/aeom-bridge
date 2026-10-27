Config = {}

-- Affiche des logs détaillés dans la console (détection, appels, erreurs avalées).
Config.Debug = false

-- Journalise dans la console chaque mouvement d'argent / d'item fait via le bridge.
Config.LogTransactions = true

-- ---------------------------------------------------------------------------
-- Choix des systèmes : 'auto' = détection par GetResourceState.
-- Une valeur manuelle est utilisée si la ressource correspondante est démarrée,
-- sinon le bridge prévient et repasse en 'auto'.
-- ---------------------------------------------------------------------------
Config.Framework    = 'auto' -- 'esx' | 'qb' | 'qbx'
Config.Inventory    = 'auto' -- 'ox_inventory' | 'qb-inventory' | 'native' (inventaire du framework)
Config.Target       = 'auto' -- 'ox_target' | 'qb-target' | 'none'
Config.Notify       = 'auto' -- 'ox_lib' | 'framework' | 'native'
Config.TextUI       = 'auto' -- 'ox_lib' | 'native'
Config.VehicleKeys  = 'auto' -- 'qb-vehiclekeys' | 'qbx_vehiclekeys' | 'none'

-- ---------------------------------------------------------------------------
-- Correspondance des comptes normalisés ("cash", "bank", "black_money")
-- vers le nom natif de chaque framework. nil/absent = compte non supporté.
-- QB/QBX n'ont pas d'argent sale par défaut : ajoute le type dans
-- QBCore.Config.Money.MoneyTypes (ou change la valeur ici).
-- ---------------------------------------------------------------------------
Config.Accounts = {
    esx = { cash = 'money', bank = 'bank', black_money = 'black_money' },
    qb  = { cash = 'cash',  bank = 'bank', black_money = 'black_money' },
    qbx = { cash = 'cash',  bank = 'bank', black_money = 'black_money' },
}

-- ---------------------------------------------------------------------------
-- Garde-fous serveur (valeurs maximales acceptées par appel).
-- ---------------------------------------------------------------------------
Config.MaxMoneyPerCall = 10000000
Config.MaxItemPerCall  = 1000

-- Callbacks maison
Config.CallbackTimeout   = 10000 -- ms avant abandon côté client
Config.CallbackRateLimit = 30    -- requêtes max par joueur et par seconde

-- Target
Config.TargetDistance = 2.5

-- ---------------------------------------------------------------------------
-- Compat : pont utilisé par les scripts AEOM (Bridge.* / Inv.* via leur bridge/server.lua).
-- Forcer un choix : framework = 'esx'|'qb'|'qbx', inventory = 'ox'|'qs'|'qb'|'esx'.
-- ---------------------------------------------------------------------------
Config.Compat = {
    -- framework = nil,
    -- inventory = nil,
    blackMoneyItem = 'black_money', -- objet d'argent sale (QB/Qbox seulement)
}
