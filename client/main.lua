--[[
    Client : exports publics, callbacks, gestion des cibles (target).
]]

local function F() return AB.Impl.framework end

-- ---------------------------------------------------------------------------
-- Framework
-- ---------------------------------------------------------------------------
exports('GetPlayerData', function()
    if not F() then return nil end
    return F().GetPlayerData()
end)

--- @return table { name, label, grade }
exports('GetJob', function()
    if not F() then return nil end
    return F().GetJob()
end)

exports('IsPlayerLoaded', function()
    return AB.Loaded == true
end)

-- ---------------------------------------------------------------------------
-- Notifications / TextUI
-- ---------------------------------------------------------------------------
local VALID_TYPES = { success = true, error = true, info = true, warning = true }

local function notify(msg, type, duration)
    if not VALID_TYPES[type] then type = 'info' end
    AB.Impl.notify(tostring(msg), type, duration or 5000)
end

exports('Notify', notify)

-- Le serveur peut notifier un joueur via Bridge.Notify(src, ...)
RegisterNetEvent('aeom-bridge:client:notify', function(msg, type, duration)
    notify(msg, type, duration)
end)

exports('ShowTextUI', function(text) AB.Impl.textui.Show(tostring(text)) end)
exports('HideTextUI', function() AB.Impl.textui.Hide() end)

-- ---------------------------------------------------------------------------
-- Clés de véhicule
-- ---------------------------------------------------------------------------
local function giveKeys(plate)
    local K = AB.Impl.vehiclekeys
    if not K then
        AB.Debug('GiveVehicleKeys ignoré : aucun système de clés actif.')
        return false
    end
    return K.Give(plate) and true or false
end

exports('GiveVehicleKeys', giveKeys)

-- Déclenché par le serveur (repli quand l'export serveur du système de clés n'existe pas).
RegisterNetEvent('aeom-bridge:client:giveKeys', function(plate)
    if type(plate) == 'string' then giveKeys(plate) end
end)

-- ---------------------------------------------------------------------------
-- Target : poignées gérées par le bridge, retirées si la ressource appelante s'arrête
-- ---------------------------------------------------------------------------
local handles = {}
local nextHandle = 0

local function track(raw, resource)
    nextHandle = nextHandle + 1
    handles[nextHandle] = { raw = raw, resource = resource }
    return nextHandle
end

local function noTarget(fn)
    AB.Debug('%s ignoré : aucun système de target actif.', fn)
    return nil
end

exports('AddTargetEntity', function(entity, options)
    local res = GetInvokingResource()
    if not AB.Impl.target then return noTarget('AddTargetEntity') end
    if not entity or not DoesEntityExist(entity) then return nil end
    return track(AB.Impl.target.AddEntity(entity, options), res)
end)

exports('AddTargetModel', function(models, options)
    local res = GetInvokingResource()
    if not AB.Impl.target then return noTarget('AddTargetModel') end
    return track(AB.Impl.target.AddModel(models, options), res)
end)

exports('AddTargetZone', function(data)
    local res = GetInvokingResource()
    if not AB.Impl.target then return noTarget('AddTargetZone') end
    if type(data) ~= 'table' or not data.coords then return nil end
    return track(AB.Impl.target.AddZone(data), res)
end)

local function removeHandle(id)
    local h = handles[id]
    if not h then return false end
    handles[id] = nil
    local ok, err = pcall(AB.Impl.target.Remove, h.raw)
    if not ok then AB.Debug('RemoveTarget : %s', tostring(err)) end
    return ok
end

exports('RemoveTarget', function(id)
    if not AB.Impl.target then return false end
    return removeHandle(id)
end)

AddEventHandler('onResourceStop', function(resource)
    if not AB.Impl.target then return end
    for id, h in pairs(handles) do
        if h.resource == resource then removeHandle(id) end
    end
end)

-- ---------------------------------------------------------------------------
-- Callbacks client -> serveur
-- ---------------------------------------------------------------------------
local pending = {}
local nextId = 0

--- TriggerCallback(name, cb, ...) : cb reçoit les valeurs renvoyées par le serveur (nil en cas d'échec).
exports('TriggerCallback', function(name, cb, ...)
    if type(name) ~= 'string' or (type(cb) ~= 'function' and type(cb) ~= 'table') then return false end
    nextId = nextId + 1
    local id = nextId
    pending[id] = cb

    SetTimeout(Config.CallbackTimeout, function()
        local waiting = pending[id]
        if not waiting then return end
        pending[id] = nil
        AB.Warn('Callback "%s" sans réponse après %d ms.', name, Config.CallbackTimeout)
        pcall(waiting, nil)
    end)

    TriggerServerEvent('aeom-bridge:cb:request', id, name, ...)
    return true
end)

RegisterNetEvent('aeom-bridge:cb:response', function(id, ok, ...)
    local cb = pending[id]
    if not cb then return end
    pending[id] = nil
    local success, err = pcall(cb, ...)
    if not success then AB.Warn('Erreur dans un callback de réponse : %s', tostring(err)) end
    if not ok then AB.Debug('Callback %s a échoué côté serveur', tostring(id)) end
end)

-- ---------------------------------------------------------------------------
exports('GetSystems', function()
    local copy = {}
    for k, v in pairs(AB.Selected) do copy[k] = v end
    return copy
end)

AB.Debug('Client prêt : %s', json.encode(AB.Selected))
