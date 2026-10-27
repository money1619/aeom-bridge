-- Framework QBCore (côté client)
if not AB.Is('framework', 'qb') then return end

local QBCore = exports['qb-core']:GetCoreObject()
local F = {}
local lastJob = nil

local function normJob(job)
    if not job then return { name = 'unemployed', label = 'Sans emploi', grade = 0 } end
    local g = job.grade or {}
    return { name = job.name, label = job.label, grade = tonumber(g.level) or 0, gradeLabel = g.name, onDuty = job.onduty }
end

function F.GetPlayerData() return QBCore.Functions.GetPlayerData() end

function F.GetJob()
    local d = QBCore.Functions.GetPlayerData()
    return normJob(d and d.job)
end

function F.IsLoaded()
    local d = QBCore.Functions.GetPlayerData()
    return d ~= nil and d.citizenid ~= nil
end

-- Types QB : primary / success / error ; info et warning -> primary
function F.RawNotify(msg, type, duration)
    QBCore.Functions.Notify(msg, (type == 'info' or type == 'warning') and 'primary' or type, duration)
end

AB.Impl.framework = F
AB.Loaded = F.IsLoaded()
lastJob = AB.Loaded and F.GetJob() or nil

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    lastJob = F.GetJob()
    AB.EmitLoaded(F.GetPlayerData())
end)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    lastJob = nil
    AB.EmitUnloaded()
end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    local new = normJob(job)
    local old = lastJob
    lastJob = new
    AB.EmitJob(new, old)
end)
