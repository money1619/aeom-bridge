-- TextUI native GTA : texte d'aide en haut à gauche tant qu'il est affiché
if not AB.Is('textui', 'native') then return end

local current = nil

AB.Impl.textui = {
    Show = function(text)
        local starting = current == nil
        current = text
        if not starting then return end
        CreateThread(function()
            while current do
                AddTextEntry('AEOM_BRIDGE_TEXTUI', current)
                BeginTextCommandDisplayHelp('AEOM_BRIDGE_TEXTUI')
                EndTextCommandDisplayHelp(0, false, false, -1)
                Wait(0)
            end
        end)
    end,
    Hide = function() current = nil end,
}
