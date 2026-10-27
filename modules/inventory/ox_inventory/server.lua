-- Inventaire ox_inventory (côté serveur)
if not AB.Is('inventory', 'ox_inventory') then return end

local I = {}

function I.AddItem(src, item, count, metadata)
    -- On vérifie d'abord la place disponible : pas d'item perdu en silence.
    if not exports.ox_inventory:CanCarryItem(src, item, count, metadata) then return false end
    local ok = exports.ox_inventory:AddItem(src, item, count, metadata)
    return ok and true or false
end

function I.RemoveItem(src, item, count)
    return exports.ox_inventory:RemoveItem(src, item, count) and true or false
end

function I.GetItemCount(src, item)
    return exports.ox_inventory:GetItemCount(src, item) or 0
end

AB.Impl.inventory = I
