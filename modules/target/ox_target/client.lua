-- Target ox_target (côté client)
-- Format d'option unifié : { name, label, icon, distance, job, onSelect(data), canInteract(entity, distance) }
if not AB.Is('target', 'ox_target') then return end

local T = {}
local counter = 0

-- Option unifiée -> option ox_target. Renvoie la liste convertie + les noms (pour le retrait).
local function convert(options)
    local out, names = {}, {}
    for _, o in ipairs(options or {}) do
        counter = counter + 1
        local name = o.name or ('aeom_%d'):format(counter)
        names[#names + 1] = name
        local canInteract = o.canInteract
        out[#out + 1] = {
            name = name, label = o.label, icon = o.icon,
            distance = o.distance or Config.TargetDistance,
            groups = o.job,
            onSelect = o.onSelect,
            canInteract = canInteract and function(entity, distance) return canInteract(entity, distance) end or nil,
        }
    end
    return out, names
end

function T.AddEntity(entity, options)
    local opts, names = convert(options)
    exports.ox_target:addLocalEntity(entity, opts)
    return { kind = 'entity', entity = entity, names = names }
end

function T.AddModel(models, options)
    local opts, names = convert(options)
    exports.ox_target:addModel(models, opts)
    return { kind = 'model', models = models, names = names }
end

-- data : { name, coords, size = vec3(l, w, h), rotation (cap), debug, options }
function T.AddZone(data)
    local opts = convert(data.options)
    local id = exports.ox_target:addBoxZone({
        name = data.name, coords = data.coords, size = data.size or vec3(1.5, 1.5, 2.0),
        rotation = data.rotation or 0.0, debug = data.debug or false, options = opts,
    })
    return { kind = 'zone', id = id }
end

function T.Remove(h)
    if h.kind == 'entity' then exports.ox_target:removeLocalEntity(h.entity, h.names)
    elseif h.kind == 'model' then exports.ox_target:removeModel(h.models, h.names)
    elseif h.kind == 'zone' then exports.ox_target:removeZone(h.id) end
end

AB.Impl.target = T
