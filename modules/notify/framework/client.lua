-- Notifications du framework (ESX / QB / QBX), via le module framework client
if not AB.Is('notify', 'framework') then return end

local F = AB.Impl.framework
if not F or not F.RawNotify then return end

AB.Impl.notify = function(msg, type, duration)
    F.RawNotify(msg, type, duration)
end
