-- Target qb-target (côté client)
-- Format d'option unifié : { name, label, icon, distance, job, onSelect(data), canInteract(entity, distance) }
if not AB.Is('target', 'qb-target') then return end

local T = {}
local counter = 0

-- Option unifiée -> option qb-target. Renvoie aussi les labels (utilisés pour le retrait) et la distance.
local function convert(options)
    local out, labels, distance = {}, {}, nil
    for _, o in ipairs(options or {}) do
        local onSelect, canInteract = o.onSelect, o.canInteract
        labels[#labels + 1] = o.label
        distance = distance or o.distance
        out[#out + 1] = {
            type = 'client', label = o.label, icon = o.icon, job = o.job,
            action = onSelect and function(entity) onSelect({ entity = entity, coords = entity and GetEntityCoords(entity) or nil }) end or nil,
            canInteract = canInteract and function(entity, dist) return canInteract(entity, dist) end or nil,
        }
    end
    return out, labels, distance or Config.TargetDistance
end

function T.AddEntity(entity, options)
    local opts, labels, dist = convert(options)
    exports['qb-target']:AddTargetEntity(entity, { options = opts, distance = dist })
    return { kind = 'entity', entity = entity, labels = labels }
end

function T.AddModel(models, options)
    local opts, labels, dist = convert(options)
    exports['qb-target']:AddTargetModel(models, { options = opts, distance = dist })
    return { kind = 'model', models = models, labels = labels }
end

-- data : { name, coords, size = vec3(largeur, longueur, hauteur), rotation (cap), debug, options }
function T.AddZone(data)
    counter = counter + 1
    local name = data.name or ('aeom_zone_%d'):format(counter)
    local opts, _, dist = convert(data.options)
    local size = data.size or vec3(1.5, 1.5, 2.0)
    local c = data.coords
    exports['qb-target']:AddBoxZone(name, c, size.y, size.x, {
        name = name, heading = data.rotation or 0.0, debugPoly = data.debug or false,
        minZ = c.z - size.z / 2, maxZ = c.z + size.z / 2,
    }, { options = opts, distance = dist })
    return { kind = 'zone', name = name }
end

function T.Remove(h)
    if h.kind == 'entity' then exports['qb-target']:RemoveTargetEntity(h.entity, h.labels)
    elseif h.kind == 'model' then exports['qb-target']:RemoveTargetModel(h.models, h.labels)
    elseif h.kind == 'zone' then exports['qb-target']:RemoveZone(h.name) end
end

AB.Impl.target = T
