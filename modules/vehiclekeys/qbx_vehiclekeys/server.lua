-- Clés de véhicule qbx_vehiclekeys (côté serveur)
-- L'export attend l'entité du véhicule : on la retrouve à partir de la plaque.
if not AB.Is('vehiclekeys', 'qbx_vehiclekeys') then return end

local function findByPlate(plate)
    local wanted = AB.TrimPlate(plate)
    for _, veh in ipairs(GetAllVehicles()) do
        if AB.TrimPlate(GetVehicleNumberPlateText(veh)) == wanted then return veh end
    end
end

AB.Impl.vehiclekeys = {
    Give = function(src, plate)
        local veh = findByPlate(plate)
        if not veh then
            AB.Debug('qbx_vehiclekeys : aucun véhicule avec la plaque %s', tostring(plate))
            return false
        end
        local ok, err = pcall(function() exports.qbx_vehiclekeys:GiveKeys(src, veh) end)
        if not ok then AB.Warn('qbx_vehiclekeys:GiveKeys a échoué : %s', tostring(err)) end
        return ok
    end,
}
