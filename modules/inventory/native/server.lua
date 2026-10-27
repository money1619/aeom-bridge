-- Inventaire "natif" : utilise celui du framework (ESX standard, QB/QBX sans module dédié).
if not AB.Is('inventory', 'native') then return end

local F = AB.Impl.framework
if not F then return end

local I = {}

function I.AddItem(src, item, count, metadata)
    return F.NativeAddItem(src, item, count, metadata) and true or false
end

function I.RemoveItem(src, item, count)
    return F.NativeRemoveItem(src, item, count) and true or false
end

function I.GetItemCount(src, item)
    return F.NativeGetItemCount(src, item) or 0
end

AB.Impl.inventory = I
