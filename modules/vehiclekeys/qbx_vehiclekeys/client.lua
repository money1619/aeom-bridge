-- Clés de véhicule qbx_vehiclekeys (côté client)
if not AB.Is('vehiclekeys', 'qbx_vehiclekeys') then return end

-- Retrouve un véhicule proche à partir de sa plaque.
local function findByPlate(plate)
    local wanted = AB.TrimPlate(plate)
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if AB.TrimPlate(GetVehicleNumberPlateText(veh)) == wanted then return veh end
    end
end

AB.Impl.vehiclekeys = {
    Give = function(plate)
        local veh = findByPlate(plate)
        if not veh then return false end
        local ok, err = pcall(function() exports.qbx_vehiclekeys:GiveKeys(veh) end)
        if not ok then AB.Warn('qbx_vehiclekeys:GiveKeys a échoué : %s', tostring(err)) end
        return ok
    end,
}
