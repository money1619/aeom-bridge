-- Clés de véhicule qb-vehiclekeys (côté serveur)
if not AB.Is('vehiclekeys', 'qb-vehiclekeys') then return end

AB.Impl.vehiclekeys = {
    Give = function(src, plate)
        -- Versions récentes : export serveur GiveKeys(id, plate). Sinon événement client classique.
        local ok = pcall(function() exports['qb-vehiclekeys']:GiveKeys(src, plate) end)
        if not ok then
            TriggerClientEvent('aeom-bridge:client:giveKeys', src, plate)
        end
        return true
    end,
}
