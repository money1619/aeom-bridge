-- Framework ESX Legacy (côté client)
if not AB.Is('framework', 'esx') then return end

local ESX = exports['es_extended']:getSharedObject()
local F = {}

local function normJob(job)
    if not job then return { name = 'unemployed', label = 'Sans emploi', grade = 0 } end
    return {
        name = job.name, label = job.label,
        grade = tonumber(job.grade) or 0, gradeLabel = job.grade_label,
    }
end

function F.GetPlayerData() return ESX.GetPlayerData() end

function F.GetJob()
    local d = ESX.GetPlayerData()
    return normJob(d and d.job)
end

function F.IsLoaded() return ESX.IsPlayerLoaded() end

-- Notification native ESX (warning n'existe pas : affiché en "info")
function F.RawNotify(msg, type, duration)
    ESX.ShowNotification(msg, type == 'warning' and 'info' or type, duration)
end

AB.Impl.framework = F
AB.Loaded = ESX.IsPlayerLoaded()

RegisterNetEvent('esx:playerLoaded', function(data) AB.EmitLoaded(data) end)
RegisterNetEvent('esx:onPlayerLogout', function() AB.EmitUnloaded() end)
RegisterNetEvent('esx:setJob', function(job, lastJob) AB.EmitJob(normJob(job), normJob(lastJob)) end)
