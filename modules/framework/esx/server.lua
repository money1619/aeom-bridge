-- Framework ESX Legacy (côté serveur)
if not AB.Is('framework', 'esx') then return end

local ESX = exports['es_extended']:getSharedObject()
local F = {}

-- Job ESX -> format unifié { name, label, grade }
local function normJob(job)
    if not job then return { name = 'unemployed', label = 'Sans emploi', grade = 0 } end
    return {
        name = job.name, label = job.label,
        grade = tonumber(job.grade) or 0, gradeLabel = job.grade_label,
    }
end

function F.GetPlayer(src) return ESX.GetPlayerFromId(src) end

function F.GetIdentifier(src)
    local p = ESX.GetPlayerFromId(src)
    return p and p.identifier or nil
end

function F.GetName(src)
    local p = ESX.GetPlayerFromId(src)
    if not p then return nil end
    return (p.getName and p.getName()) or p.name or GetPlayerName(src)
end

function F.GetJob(src)
    local p = ESX.GetPlayerFromId(src)
    return p and normJob(p.getJob and p.getJob() or p.job) or nil
end

-- `account` est ici le nom NATIF (money / bank / black_money).
function F.GetMoney(src, account)
    local p = ESX.GetPlayerFromId(src)
    local acc = p and p.getAccount(account)
    return acc and acc.money or 0
end

function F.AddMoney(src, account, amount)
    local p = ESX.GetPlayerFromId(src)
    if not p or not p.getAccount(account) then return false end
    p.addAccountMoney(account, amount)
    return true
end

function F.RemoveMoney(src, account, amount)
    local p = ESX.GetPlayerFromId(src)
    if not p or not p.getAccount(account) then return false end
    p.removeAccountMoney(account, amount)
    return true
end

-- cb(src, item) avec item = { name, slot, metadata }
function F.RegisterUsableItem(item, cb)
    ESX.RegisterUsableItem(item, function(src, name, data)
        if type(name) == 'table' then data, name = name, name.name end
        cb(src, { name = name, slot = data and data.slot, metadata = data and data.metadata })
    end)
end

-- Actions "natives" utilisées par le module d'inventaire `native`.
function F.NativeAddItem(src, item, count)
    local p = ESX.GetPlayerFromId(src)
    if not p then return false end
    p.addInventoryItem(item, count)
    return true
end

function F.NativeRemoveItem(src, item, count)
    local p = ESX.GetPlayerFromId(src)
    if not p then return false end
    p.removeInventoryItem(item, count)
    return true
end

function F.NativeGetItemCount(src, item)
    local p = ESX.GetPlayerFromId(src)
    local i = p and p.getInventoryItem(item)
    return i and i.count or 0
end

AB.Impl.framework = F

-- Événements unifiés
AddEventHandler('esx:playerLoaded', function(playerId) AB.EmitLoaded(playerId) end)
AddEventHandler('esx:playerDropped', function(playerId) AB.EmitUnloaded(playerId) end)
AddEventHandler('esx:setJob', function(playerId, job, lastJob)
    AB.EmitJob(playerId, normJob(job), normJob(lastJob))
end)
