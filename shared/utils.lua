--[[
    Utilitaires partagés : logs, détection des systèmes, normalisation des comptes,
    émission des événements unifiés.
    `AB` est la table globale interne du bridge (propre à cette ressource).
]]

AB = {
    IsServer = IsDuplicityVersion(),
    Impl     = {}, -- implémentations remplies par les modules (framework, inventory, target...)
    Selected = {}, -- système retenu pour chaque catégorie
}

local PREFIX = '^5[aeom-bridge]^7 '

function AB.Print(msg)
    print(PREFIX .. msg)
end

function AB.Warn(fmt, ...)
    local ok, msg = pcall(string.format, fmt, ...)
    print(PREFIX .. '^3[attention]^7 ' .. (ok and msg or fmt))
end

function AB.Debug(fmt, ...)
    if not Config.Debug then return end
    local ok, msg = pcall(string.format, fmt, ...)
    print(PREFIX .. '^6[debug]^7 ' .. (ok and msg or fmt))
end

-- ---------------------------------------------------------------------------
-- Détection
-- ---------------------------------------------------------------------------
function AB.IsStarted(resource)
    local state = GetResourceState(resource)
    return state == 'started' or state == 'starting'
end

-- { identifiant du module, ressource à tester } par ordre de priorité.
local CANDIDATES = {
    framework   = { { 'qbx', 'qbx_core' }, { 'qb', 'qb-core' }, { 'esx', 'es_extended' } },
    inventory   = { { 'ox_inventory', 'ox_inventory' }, { 'qb-inventory', 'qb-inventory' } },
    target      = { { 'ox_target', 'ox_target' }, { 'qb-target', 'qb-target' } },
    notify      = { { 'ox_lib', 'ox_lib' } },
    textui      = { { 'ox_lib', 'ox_lib' } },
    vehiclekeys = { { 'qbx_vehiclekeys', 'qbx_vehiclekeys' }, { 'qb-vehiclekeys', 'qb-vehiclekeys' } },
}

-- Valeurs manuelles qui ne dépendent d'aucune ressource précise.
local SPECIAL = { native = true, framework = true, none = true }

local CONFIG_KEY = {
    framework = 'Framework', inventory = 'Inventory', target = 'Target',
    notify = 'Notify', textui = 'TextUI', vehiclekeys = 'VehicleKeys',
}

local function pick(kind)
    local wanted = Config[CONFIG_KEY[kind]]
    if wanted and wanted ~= 'auto' then
        if SPECIAL[wanted] then return wanted end
        for _, c in ipairs(CANDIDATES[kind]) do
            if c[1] == wanted then
                if AB.IsStarted(c[2]) then return wanted end
                AB.Warn('%s forcé sur "%s" mais la ressource "%s" n\'est pas démarrée : retour en détection auto.', kind, wanted, c[2])
                break
            end
        end
    end
    for _, c in ipairs(CANDIDATES[kind]) do
        if AB.IsStarted(c[2]) then return c[1] end
    end
    return nil
end

local function detect()
    local S = AB.Selected
    S.framework   = pick('framework')
    S.inventory   = pick('inventory')
    S.target      = pick('target') or 'none'
    S.notify      = pick('notify')
    S.textui      = pick('textui') or 'native'
    S.vehiclekeys = pick('vehiclekeys') or 'none'

    -- Replis : inventaire du framework, notifs du framework, puis natif GTA.
    if (S.inventory == 'native') and not S.framework then S.inventory = nil end
    if not S.inventory and S.framework then S.inventory = 'native' end
    if S.notify == 'framework' and not S.framework then S.notify = nil end
    if not S.notify then S.notify = S.framework and 'framework' or 'native' end

    if not AB.IsServer then return end

    AB.Print(('Systèmes retenus : framework=%s | inventaire=%s | target=%s | notif=%s | textui=%s | clés=%s'):format(
        S.framework or 'AUCUN', S.inventory or 'AUCUN', S.target, S.notify, S.textui, S.vehiclekeys))
    if not S.framework then
        AB.Warn('Aucun framework trouvé (es_extended / qb-core / qbx_core). Les fonctions joueur/argent/job seront inactives.')
    end
    if not S.inventory then
        AB.Warn('Aucun inventaire utilisable : AddItem/RemoveItem/HasItem seront inactifs.')
    end
end

--- Vrai si `value` est le système retenu pour la catégorie `kind`.
function AB.Is(kind, value)
    return AB.Selected[kind] == value
end

-- ---------------------------------------------------------------------------
-- Comptes d'argent normalisés
-- ---------------------------------------------------------------------------
local ALIASES = {
    cash = 'cash', money = 'cash',
    bank = 'bank',
    black_money = 'black_money', blackmoney = 'black_money', dirty = 'black_money',
}

--- "money"/"cash" -> "cash", etc. nil si inconnu.
function AB.NormalizeAccount(account)
    if type(account) ~= 'string' then return nil end
    return ALIASES[account:lower()]
end

--- Compte normalisé -> nom natif du framework retenu (nil si non supporté).
function AB.NativeAccount(normalized)
    local map = Config.Accounts[AB.Selected.framework or '']
    return map and map[normalized] or nil
end

--- Plaque en majuscules sans espaces (comparaison fiable).
function AB.TrimPlate(plate)
    if type(plate) ~= 'string' then return nil end
    return (plate:gsub('%s+', ''):upper())
end

-- ---------------------------------------------------------------------------
-- Événements unifiés
-- ---------------------------------------------------------------------------
if AB.IsServer then
    local loaded = {}

    -- Marque un joueur comme chargé sans émettre (joueurs déjà en ligne au démarrage).
    function AB.MarkLoaded(src) loaded[src] = true end

    function AB.EmitLoaded(src)
        src = tonumber(src)
        if not src or loaded[src] then return end
        loaded[src] = true
        AB.Debug('playerLoaded src=%s', src)
        TriggerEvent('aeom-bridge:playerLoaded', src)
    end

    function AB.EmitUnloaded(src)
        src = tonumber(src)
        if not src or not loaded[src] then return end
        loaded[src] = nil
        AB.Debug('playerUnloaded src=%s', src)
        TriggerEvent('aeom-bridge:playerUnloaded', src)
    end

    function AB.EmitJob(src, job, lastJob)
        src = tonumber(src)
        if not src then return end
        AB.Debug('jobUpdated src=%s job=%s', src, job and job.name or 'nil')
        TriggerEvent('aeom-bridge:jobUpdated', src, job, lastJob)
    end

    -- Filet de sécurité : tout joueur qui part est "déchargé".
    AddEventHandler('playerDropped', function()
        AB.EmitUnloaded(source)
    end)
else
    AB.Loaded = false

    function AB.EmitLoaded(data)
        AB.Loaded = true
        AB.Debug('playerLoaded')
        TriggerEvent('aeom-bridge:playerLoaded', data)
    end

    function AB.EmitUnloaded()
        AB.Loaded = false
        AB.Debug('playerUnloaded')
        TriggerEvent('aeom-bridge:playerUnloaded')
    end

    function AB.EmitJob(job, lastJob)
        AB.Debug('jobUpdated job=%s', job and job.name or 'nil')
        TriggerEvent('aeom-bridge:jobUpdated', job, lastJob)
    end
end

detect()
