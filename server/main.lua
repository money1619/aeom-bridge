--[[
    Serveur : validation des entrées + exports publics.
    Les modules (AB.Impl.*) ne sont appelés qu'après vérification ici :
    aucune action sensible n'est déclenchable par un client.
]]

local function F() return AB.Impl.framework end
local function I() return AB.Impl.inventory end

-- ---------------------------------------------------------------------------
-- Validation
-- ---------------------------------------------------------------------------
local function validSrc(src)
    src = tonumber(src)
    if not src or src <= 0 or not GetPlayerName(src) then return nil end
    return src
end

local function validAmount(n, max)
    n = tonumber(n)
    if not n or n ~= n or n < 1 or n > max then return nil end
    return math.floor(n)
end

local function validItem(item)
    return type(item) == 'string' and #item > 0 and #item <= 64 and item:match('^[%w_%-%.:]+$') ~= nil
end

local function audit(kind, caller, src, ...)
    if not Config.LogTransactions then return end
    AB.Print(('[audit] %s src=%s %s (par %s)'):format(kind, tostring(src), table.concat({ ... }, ' '), caller or '?'))
end

local function missing(what, fn)
    AB.Debug('%s ignoré : aucun %s actif.', fn, what)
end

-- ---------------------------------------------------------------------------
-- Framework
-- ---------------------------------------------------------------------------
exports('GetPlayer', function(src)
    src = validSrc(src)
    if not src then return nil end
    if not F() then return missing('framework', 'GetPlayer') end
    return F().GetPlayer(src)
end)

exports('GetIdentifier', function(src)
    src = validSrc(src)
    if not src then return nil end
    if not F() then return missing('framework', 'GetIdentifier') end
    return F().GetIdentifier(src)
end)

exports('GetName', function(src)
    src = validSrc(src)
    if not src then return nil end
    if not F() then return GetPlayerName(src) end
    return F().GetName(src) or GetPlayerName(src)
end)

--- @return table|nil { name, label, grade }
exports('GetJob', function(src)
    src = validSrc(src)
    if not src then return nil end
    if not F() then return missing('framework', 'GetJob') end
    return F().GetJob(src)
end)

exports('GetMoney', function(src, account)
    src = validSrc(src)
    local norm = AB.NormalizeAccount(account)
    if not src or not norm or not F() then return 0 end
    local native = AB.NativeAccount(norm)
    if not native then return 0 end
    return F().GetMoney(src, native) or 0
end)

exports('AddMoney', function(src, account, amount)
    local caller = GetInvokingResource()
    src = validSrc(src)
    local norm = AB.NormalizeAccount(account)
    amount = validAmount(amount, Config.MaxMoneyPerCall)
    if not src or not norm or not amount then return false end
    if not F() then return missing('framework', 'AddMoney') or false end
    local native = AB.NativeAccount(norm)
    if not native then
        AB.Warn('Compte "%s" non supporté par le framework %s (voir Config.Accounts).', norm, AB.Selected.framework)
        return false
    end
    local ok = F().AddMoney(src, native, amount, caller or 'aeom-bridge')
    if ok then audit('AddMoney', caller, src, norm, '+' .. amount) end
    return ok and true or false
end)

exports('RemoveMoney', function(src, account, amount)
    local caller = GetInvokingResource()
    src = validSrc(src)
    local norm = AB.NormalizeAccount(account)
    amount = validAmount(amount, Config.MaxMoneyPerCall)
    if not src or not norm or not amount then return false end
    if not F() then return missing('framework', 'RemoveMoney') or false end
    local native = AB.NativeAccount(norm)
    if not native then return false end
    -- Jamais de solde négatif : on vérifie avant de retirer.
    if (F().GetMoney(src, native) or 0) < amount then return false end
    local ok = F().RemoveMoney(src, native, amount, caller or 'aeom-bridge')
    if ok then audit('RemoveMoney', caller, src, norm, '-' .. amount) end
    return ok and true or false
end)

--- cb(src, item) avec item = { name, slot, metadata }. Les erreurs du callback sont isolées.
exports('RegisterUsableItem', function(item, cb)
    if not validItem(item) or type(cb) ~= 'function' and type(cb) ~= 'table' then return false end
    if not F() then return missing('framework', 'RegisterUsableItem') or false end
    local caller = GetInvokingResource()
    F().RegisterUsableItem(item, function(src, data)
        local ok, err = pcall(cb, src, data)
        if not ok then AB.Warn('Erreur dans l\'item utilisable "%s" (%s) : %s', item, caller or '?', tostring(err)) end
    end)
    return true
end)

-- ---------------------------------------------------------------------------
-- Inventaire
-- ---------------------------------------------------------------------------
exports('GetItemCount', function(src, item)
    src = validSrc(src)
    if not src or not validItem(item) or not I() then return 0 end
    return tonumber(I().GetItemCount(src, item)) or 0
end)

exports('HasItem', function(src, item, count)
    count = validAmount(count or 1, Config.MaxItemPerCall)
    if not count then return false end
    src = validSrc(src)
    if not src or not validItem(item) or not I() then return false end
    return (tonumber(I().GetItemCount(src, item)) or 0) >= count
end)

exports('AddItem', function(src, item, count, metadata)
    local caller = GetInvokingResource()
    src = validSrc(src)
    count = validAmount(count or 1, Config.MaxItemPerCall)
    if not src or not count or not validItem(item) then return false end
    if metadata ~= nil and type(metadata) ~= 'table' then return false end
    if not I() then return missing('inventaire', 'AddItem') or false end
    local ok = I().AddItem(src, item, count, metadata)
    if ok then audit('AddItem', caller, src, item, 'x' .. count) end
    return ok and true or false
end)

exports('RemoveItem', function(src, item, count)
    local caller = GetInvokingResource()
    src = validSrc(src)
    count = validAmount(count or 1, Config.MaxItemPerCall)
    if not src or not count or not validItem(item) then return false end
    if not I() then return missing('inventaire', 'RemoveItem') or false end
    if (tonumber(I().GetItemCount(src, item)) or 0) < count then return false end
    local ok = I().RemoveItem(src, item, count)
    if ok then audit('RemoveItem', caller, src, item, 'x' .. count) end
    return ok and true or false
end)

-- ---------------------------------------------------------------------------
-- Notifications et clés de véhicule
-- ---------------------------------------------------------------------------
exports('Notify', function(src, msg, type, duration)
    if tonumber(src) ~= -1 then src = validSrc(src) end
    if not src or msg == nil then return false end
    TriggerClientEvent('aeom-bridge:client:notify', src, tostring(msg), type, duration)
    return true
end)

exports('GiveVehicleKeys', function(src, plate)
    src = validSrc(src)
    if not src or type(plate) ~= 'string' or #plate == 0 then return false end
    local K = AB.Impl.vehiclekeys
    if not K then return missing('système de clés', 'GiveVehicleKeys') or false end
    return K.Give(src, plate) and true or false
end)

-- ---------------------------------------------------------------------------
-- Callbacks client -> serveur
-- ---------------------------------------------------------------------------
local callbacks = {} -- nom -> { fn, resource }
local rate = {}      -- src -> { debut, nombre }

--- handler(src, ...) -> valeurs renvoyées au client
exports('RegisterCallback', function(name, handler)
    if type(name) ~= 'string' or (type(handler) ~= 'function' and type(handler) ~= 'table') then return false end
    callbacks[name] = { fn = handler, resource = GetInvokingResource() }
    return true
end)

RegisterNetEvent('aeom-bridge:cb:request', function(id, name, ...)
    local src = source
    if type(id) ~= 'number' or type(name) ~= 'string' then return end

    -- Anti-spam : limite de requêtes par seconde et par joueur.
    local now = GetGameTimer()
    local r = rate[src]
    if not r or now - r.t >= 1000 then r = { t = now, n = 0 }; rate[src] = r end
    r.n = r.n + 1
    if r.n > Config.CallbackRateLimit then
        AB.Debug('Callback "%s" ignoré : trop de requêtes de %s', name, src)
        -- Réponse d'échec immédiate : le client n'attend pas le délai d'expiration.
        TriggerClientEvent('aeom-bridge:cb:response', src, id, false)
        return
    end

    local cb = callbacks[name]
    if not cb then
        AB.Debug('Callback inconnu "%s" demandé par %s', name, src)
        TriggerClientEvent('aeom-bridge:cb:response', src, id, false)
        return
    end

    local result = table.pack(pcall(cb.fn, src, ...))
    if not result[1] then
        AB.Warn('Erreur dans le callback "%s" (%s) : %s', name, cb.resource or '?', tostring(result[2]))
        TriggerClientEvent('aeom-bridge:cb:response', src, id, false)
        return
    end
    TriggerClientEvent('aeom-bridge:cb:response', src, id, true, table.unpack(result, 2, result.n))
end)

AddEventHandler('playerDropped', function()
    if source then rate[source] = nil end
end)

-- Retire les callbacks d'une ressource arrêtée.
AddEventHandler('onResourceStop', function(resource)
    for name, cb in pairs(callbacks) do
        if cb.resource == resource then callbacks[name] = nil end
    end
end)

-- ---------------------------------------------------------------------------
-- Divers
-- ---------------------------------------------------------------------------
--- Systèmes retenus (copie), utile pour adapter un script à un cas précis.
exports('GetSystems', function()
    local copy = {}
    for k, v in pairs(AB.Selected) do copy[k] = v end
    return copy
end)

-- Joueurs déjà connectés lors d'un restart du bridge : marqués "chargés" sans événement.
CreateThread(function()
    Wait(0)
    if not F() then return end
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        if src and F().GetPlayer(src) then AB.MarkLoaded(src) end
    end
end)
