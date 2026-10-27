-- Framework Qbox / qbx_core (côté client)
if not AB.Is('framework', 'qbx') then return end

local F = {}
local lastJob = nil

local function normJob(job)
    if not job then return { name = 'unemployed', label = 'Sans emploi', grade = 0 } end
    local g = job.grade or {}
    return { name = job.name, label = job.label, grade = tonumber(g.level) or 0, gradeLabel = g.name, onDuty = job.onduty }
end

function F.GetPlayerData() return exports.qbx_core:GetPlayerData() end

function F.GetJob()
    local d = exports.qbx_core:GetPlayerData()
    return normJob(d and d.job)
end

function F.IsLoaded()
    local d = exports.qbx_core:GetPlayerData()
    return d ~= nil and d.citizenid ~= nil
end

-- Types Qbox : success / error / inform / warning
function F.RawNotify(msg, type, duration)
    exports.qbx_core:Notify(msg, type == 'info' and 'inform' or type, duration)
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
