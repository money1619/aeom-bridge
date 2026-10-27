-- TextUI ox_lib (côté client)
if not AB.Is('textui', 'ox_lib') then return end

AB.Impl.textui = {
    Show = function(text) exports.ox_lib:showTextUI(text) end,
    Hide = function() exports.ox_lib:hideTextUI() end,
}
