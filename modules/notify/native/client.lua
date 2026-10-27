-- Notification native GTA (repli sans aucune dépendance)
if not AB.Is('notify', 'native') then return end

AB.Impl.notify = function(msg, type)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(type == 'error', true)
end
