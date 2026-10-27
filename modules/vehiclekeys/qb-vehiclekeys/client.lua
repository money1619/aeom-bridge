-- Clés de véhicule qb-vehiclekeys (côté client)
if not AB.Is('vehiclekeys', 'qb-vehiclekeys') then return end

AB.Impl.vehiclekeys = {
    Give = function(plate)
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
        return true
    end,
}
