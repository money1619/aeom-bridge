-- Notifications ox_lib (côté client)
if not AB.Is('notify', 'ox_lib') then return end

-- Types unifiés : success | error | info | warning (identiques à ox_lib)
AB.Impl.notify = function(msg, type, duration)
    exports.ox_lib:notify({ description = msg, type = type, duration = duration })
end
