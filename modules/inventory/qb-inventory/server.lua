-- Inventaire qb-inventory (côté serveur, exports de la v2+)
if not AB.Is('inventory', 'qb-inventory') then return end

local I = {}

function I.AddItem(src, item, count, metadata)
    local can = exports['qb-inventory']:CanAddItem(src, item, count)
    if not can then return false end
    return exports['qb-inventory']:AddItem(src, item, count, false, metadata, 'aeom-bridge') and true or false
end

function I.RemoveItem(src, item, count)
    return exports['qb-inventory']:RemoveItem(src, item, count, false, 'aeom-bridge') and true or false
end

function I.GetItemCount(src, item)
    return exports['qb-inventory']:GetItemCount(src, item) or 0
end

AB.Impl.inventory = I
