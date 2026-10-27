--[[
    aeom-bridge : fichier à inclure dans le fxmanifest de tes scripts

        shared_script '@aeom-bridge/init.lua'

    Il expose un objet global `Bridge` (client ET serveur) dont chaque méthode
    appelle l'export du même nom :  Bridge.AddMoney(src, 'cash', 100)
    équivaut à  exports['aeom-bridge']:AddMoney(src, 'cash', 100).

    Si le bridge n'est pas démarré, l'appel affiche un avertissement et renvoie
    nil : aucune erreur bloquante.
]]

Bridge = Bridge or {}

local RES = 'aeom-bridge'

-- Noms des événements unifiés (identiques côté client et serveur).
Bridge.Events = {
    PlayerLoaded   = 'aeom-bridge:playerLoaded',   -- serveur : (src)   | client : (playerData)
    PlayerUnloaded = 'aeom-bridge:playerUnloaded', -- serveur : (src)   | client : ()
    JobUpdated     = 'aeom-bridge:jobUpdated',     -- serveur : (src, job, lastJob) | client : (job, lastJob)
}

-- true si le bridge est démarré.
function Bridge.IsReady()
    return GetResourceState(RES) == 'started'
end

-- Attend (bloquant, dans un thread) que le bridge soit prêt. Renvoie false après le délai.
function Bridge.WaitReady(timeout)
    local limit = GetGameTimer() + (timeout or 15000)
    while not Bridge.IsReady() do
        if GetGameTimer() > limit then return false end
        Wait(100)
    end
    return true
end

-- Toute autre clé devient une fonction qui relaie vers l'export.
setmetatable(Bridge, {
    __index = function(self, name)
        local fn = function(...)
            if GetResourceState(RES) ~= 'started' then
                print(('^3[aeom-bridge]^7 appel de "%s" impossible : le bridge n\'est pas démarré (ensure aeom-bridge avant ce script)'):format(name))
                return nil
            end
            local e = exports[RES]
            return e[name](e, ...)
        end
        rawset(self, name, fn)
        return fn
    end,
})
