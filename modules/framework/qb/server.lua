-- Framework QBCore (côté serveur)
if not AB.Is('framework', 'qb') then return end

local QBCore = exports['qb-core']:GetCoreObject()
local F = {}

-- Job QB -> format unifié { name, label, grade }
local function normJob(job)
    if not job then return { name = 'unemployed', label = 'Sans emploi', grade = 0 } end
    local g = job.grade or {}
    return {
        name = job.name, label = job.label,
        grade = tonumber(g.level) or 0, gradeLabel = g.name, onDuty = job.onduty,
    }
end

function F.GetPlayer(src) return QBCore.Functions.GetPlayer(src) end

function F.GetIdentifier(src)
    local p = QBCore.Functions.GetPlayer(src)
    return p and p.PlayerData.citizenid or nil
end

function F.GetName(src)
    local p = QBCore.Functions.GetPlayer(src)
    local c = p and p.PlayerData.charinfo
    return c and ('%s %s'):format(c.firstname or '', c.lastname or '') or nil
end

function F.GetJob(src)
    local p = QBCore.Functions.GetPlayer(src)
    return p and normJob(p.PlayerData.job) or nil
end

-- `account` = nom NATIF (cash / bank / ...)
function F.GetMoney(src, account)
    local p = QBCore.Functions.GetPlayer(src)
    return p and p.PlayerData.money[account] or 0
end

function F.AddMoney(src, account, amount, reason)
    local p = QBCore.Functions.GetPlayer(src)
    if not p or p.PlayerData.money[account] == nil then return false end
    return p.Functions.AddMoney(account, amount, reason) ~= false
end

function F.RemoveMoney(src, account, amount, reason)
    local p = QBCore.Functions.GetPlayer(src)
    if not p or p.PlayerData.money[account] == nil then return false end
    return p.Functions.RemoveMoney(account, amount, reason) ~= false
end

-- cb(src, item) avec item = { name, slot, metadata }
function F.RegisterUsableItem(item, cb)
    QBCore.Functions.CreateUseableItem(item, function(src, data)
        cb(src, { name = data and data.name or item, slot = data and data.slot, metadata = data and data.info })
    end)
end

-- Actions "natives" utilisées par le module d'inventaire `native`.
function F.NativeAddItem(src, item, count, metadata)
    local p = QBCore.Functions.GetPlayer(src)
    return p and p.Functions.AddItem(item, count, false, metadata) or false
end

function F.NativeRemoveItem(src, item, count)
    local p = QBCore.Functions.GetPlayer(src)
    return p and p.Functions.RemoveItem(item, count) or false
end

function F.NativeGetItemCount(src, item)
    local p = QBCore.Functions.GetPlayer(src)
    local i = p and p.Functions.GetItemByName(item)
    return i and (i.amount or i.count) or 0
end

AB.Impl.framework = F

-- Événements unifiés
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = type(player) == 'table' and player.PlayerData and player.PlayerData.source
    if src then AB.EmitLoaded(src) end
end)
AddEventHandler('QBCore:Server:OnPlayerUnload', function(src) AB.EmitUnloaded(src) end)
AddEventHandler('QBCore:Server:OnJobUpdate', function(src, job) AB.EmitJob(src, normJob(job), nil) end)
