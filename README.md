# aeom-bridge

Bridge partagé pour FiveM : tes scripts parlent à **un seul** API, le bridge détecte et utilise le bon framework, inventaire, target, système de notifications, TextUI et clés de véhicule.

| Catégorie | Supporté |
|---|---|
| Framework | `es_extended` (ESX Legacy), `qb-core`, `qbx_core` |
| Inventaire | `ox_inventory`, `qb-inventory`, inventaire natif du framework |
| Target | `ox_target`, `qb-target` |
| Notifications | `ox_lib`, notifs du framework, natif GTA |
| TextUI | `ox_lib`, natif GTA |
| Clés de véhicule | `qb-vehiclekeys`, `qbx_vehiclekeys` |
| Callbacks | système maison client → serveur |

Si un système est absent : repli propre (notif GTA, TextUI native…) ou fonction inactive avec un message en console. Aucune erreur bloquante.

## Installation

1. Copie `aeom-bridge` dans `resources/`.
2. Dans `server.cfg`, **après** le framework/inventaire/target/ox_lib et **avant** tes scripts :

```cfg
ensure ox_lib
ensure es_extended      # ou qb-core / qbx_core
ensure ox_inventory
ensure ox_target
ensure aeom-bridge
ensure mon_script
```

3. Dans le `fxmanifest.lua` de chaque script qui l'utilise :

```lua
shared_script '@aeom-bridge/init.lua'
```

Tu disposes alors d'un objet global `Bridge` (client et serveur). `Bridge.AddMoney(...)` équivaut à `exports['aeom-bridge']:AddMoney(...)`. Les deux écritures sont possibles ; `Bridge` ne plante pas si le bridge est arrêté (avertissement + `nil`).

Au démarrage, la console indique les systèmes retenus :
`[aeom-bridge] Systèmes retenus : framework=esx | inventaire=ox_inventory | target=ox_target | ...`

## Configuration (`config.lua`)

- `Config.Debug` : logs détaillés.
- `Config.Framework / Inventory / Target / Notify / TextUI / VehicleKeys` : `'auto'` ou choix manuel.
- `Config.Accounts` : traduction `cash / bank / black_money` vers le nom natif de chaque framework. QB/QBX n'ont pas d'argent sale par défaut : ajoute le type dans leur config ou adapte la valeur.
- `Config.MaxMoneyPerCall`, `Config.MaxItemPerCall` : plafonds par appel.
- `Config.LogTransactions` : trace chaque mouvement d'argent/d'item en console.
- `Config.CallbackTimeout`, `Config.CallbackRateLimit`, `Config.TargetDistance`.

## Sécurité

Toutes les actions sensibles (argent, items, clés) sont des exports **serveur** : aucun événement réseau ne permet à un client de les déclencher. Le bridge valide chaque entrée (joueur connecté, compte connu, montant entier dans les limites, nom d'item sûr), vérifie le solde/le stock avant un retrait et vérifie la place avant un ajout. Les callbacks clients sont limités en débit. À toi de ne jamais exposer un `AddMoney` derrière un événement réseau non vérifié dans tes propres scripts.

## API serveur

```lua
Bridge.GetPlayer(src)                    -- objet natif du framework (ESX xPlayer / QB Player)
Bridge.GetIdentifier(src)                -- identifier ESX ou citizenid
Bridge.GetName(src)                      -- "Prénom Nom"
Bridge.GetJob(src)                       -- { name, label, grade, gradeLabel }
Bridge.GetMoney(src, 'cash')             -- 'cash' | 'bank' | 'black_money'
Bridge.AddMoney(src, 'bank', 2500)       -- true/false
Bridge.RemoveMoney(src, 'cash', 100)     -- false si solde insuffisant
Bridge.AddItem(src, 'water', 2, { note = 'x' })  -- false si pas de place
Bridge.RemoveItem(src, 'water', 1)       -- false si stock insuffisant
Bridge.HasItem(src, 'water', 1)
Bridge.GetItemCount(src, 'water')
Bridge.RegisterUsableItem('bandage', function(src, item) -- item = { name, slot, metadata }
    Bridge.Notify(src, 'Soigné !', 'success')
end)
Bridge.Notify(src, 'Message', 'success', 5000)  -- types : success | error | info | warning ; src -1 = tous
Bridge.GiveVehicleKeys(src, 'ABC 123')
Bridge.RegisterCallback('mon:callback', function(src, a, b) return a + b end)
Bridge.GetSystems()                      -- { framework = 'esx', inventory = 'ox_inventory', ... }
```

### Ajouts 1.2.0 (serveur)

```lua
Bridge.GetVehicleOwner('ABC 123')        -- identifiant du propriétaire (ESX owner / citizenid) ou nil
Bridge.SetDuty(src, true)                -- service QB / Qbox ; false sous ESX (pas de service natif)
Bridge.GetSocietyMoney('society_mechanic')          -- esx_addonaccount, Renewed-Banking, qb-banking, qb-management
Bridge.AddSocietyMoney('society_mechanic', 500, 'motif')
Bridge.RemoveSocietyMoney('society_mechanic', 500)  -- false si le solde ne suffit pas
Bridge.GetJobs()                         -- { [métier] = { label, grades = { [n] = libellé } } }
Bridge.GetJobInfo(src)                   -- { name, label, grade, gradeLabel, onDuty, isBoss }
Bridge.GetPlayers()
Bridge.RegisterStash(id, label, slots, poids, { mechanic = 0 }, { vector3(...) })  -- ox : métiers + coordonnées
Bridge.StashCount(id, item) / Bridge.StashAdd(id, item, n) / Bridge.StashRemove(id, item, n)               -- ox
Bridge.CanCarryItem(src, item, n)
```

## API client

```lua
Bridge.GetPlayerData()                   -- données natives du joueur
Bridge.GetJob()                          -- { name, label, grade, gradeLabel }
Bridge.IsPlayerLoaded()
Bridge.Notify('Message', 'info', 5000)
Bridge.ShowTextUI('[E] Ouvrir')
Bridge.HideTextUI()
Bridge.GiveVehicleKeys('ABC 123')
Bridge.TriggerCallback('mon:callback', function(result) print(result) end, 1, 2)
Bridge.GetSystems()
```

### Target

Format d'option unifié : `{ name, label, icon, distance, job, onSelect = function(data) end, canInteract = function(entity, distance) end }`. `data.entity` contient l'entité visée. Les cibles sont retirées automatiquement quand ta ressource s'arrête.

```lua
local id = Bridge.AddTargetEntity(ped, {
    { label = 'Parler', icon = 'fa-solid fa-comment', onSelect = function(data) print(data.entity) end },
})
Bridge.AddTargetModel({ `prop_vend_soda_01` }, { { label = 'Acheter', icon = 'fa-solid fa-cart-shopping', onSelect = function() end } })
local zone = Bridge.AddTargetZone({
    name = 'garage', coords = vec3(215.0, -810.0, 30.7), size = vec3(2.0, 2.0, 2.0), rotation = 0.0, debug = false,
    options = { { label = 'Garage', icon = 'fa-solid fa-car', job = 'police', onSelect = function() end } },
})
Bridge.RemoveTarget(zone)
```

`job` accepte un nom (`'police'`) ou une table (`{ police = 0 }`) selon le target.

## Événements unifiés

```lua
-- Serveur
AddEventHandler('aeom-bridge:playerLoaded',   function(src) end)
AddEventHandler('aeom-bridge:playerUnloaded', function(src) end)
AddEventHandler('aeom-bridge:jobUpdated',     function(src, job, lastJob) end)
-- Client
AddEventHandler('aeom-bridge:playerLoaded',   function(playerData) end)
AddEventHandler('aeom-bridge:playerUnloaded', function() end)
AddEventHandler('aeom-bridge:jobUpdated',     function(job, lastJob) end)
```

## Callbacks maison

```lua
-- serveur
Bridge.RegisterCallback('shop:getPrice', function(src, item) return 50, true end)
-- client
Bridge.TriggerCallback('shop:getPrice', function(price, ok) print(price, ok) end, 'water')
```

Le callback client reçoit `nil` si le serveur ne répond pas dans `Config.CallbackTimeout` ou si le callback échoue. Les callbacks d'une ressource sont retirés quand elle s'arrête.

## Ajouter un nouveau framework / inventaire / target

Chaque système est un fichier qui s'auto-désactive s'il n'est pas retenu.

1. **Détection** : dans `shared/utils.lua`, ajoute `{ 'mon_systeme', 'nom_ressource' }` à `CANDIDATES[<catégorie>]` (l'ordre = priorité). Ajoute-le aussi dans les valeurs autorisées de `config.lua`.
2. **Module** : crée `modules/<catégorie>/mon_systeme/server.lua` (et/ou `client.lua`) qui commence par :
   ```lua
   if not AB.Is('inventory', 'mon_systeme') then return end
   ```
3. **Interface à remplir** (`AB.Impl.<catégorie>`) :
   - `framework` (serveur) : `GetPlayer, GetIdentifier, GetName, GetJob, GetMoney, AddMoney, RemoveMoney, RegisterUsableItem` (+ `NativeAddItem/NativeRemoveItem/NativeGetItemCount` pour l'inventaire natif). Les comptes reçus sont déjà au nom natif. Branche aussi les événements sur `AB.EmitLoaded / AB.EmitUnloaded / AB.EmitJob`.
   - `framework` (client) : `GetPlayerData, GetJob, IsLoaded, RawNotify` + mêmes émetteurs.
   - `inventory` (serveur) : `AddItem(src, item, count, metadata), RemoveItem(src, item, count), GetItemCount(src, item)`.
   - `target` (client) : `AddEntity, AddModel, AddZone, Remove`.
   - `notify` (client) : une fonction `(msg, type, duration)`. `textui` : `{ Show, Hide }`.
   - `vehiclekeys` : `{ Give(src, plate) }` serveur, `{ Give(plate) }` client.
4. **Manifest** : ajoute le fichier à `client_scripts` / `server_scripts` de `fxmanifest.lua`, avant `main.lua`.

Le bridge s'occupe de la validation, du stock/solde et des logs : le module ne fait que traduire vers l'API de la ressource.

## Tester avec `aeom-test`

```cfg
ensure aeom-test
add_ace group.admin command.aeomtest allow
```

- `/aeomtest [montant]` : argent liquide + item + notification.
- `/aeomcb` : callback + notification + TextUI.
- `/aeomjob` : affiche ton job.

## Limites connues

Écrit à partir de l'API documentée de chaque ressource, mais **non testé en jeu** ici. À vérifier selon tes versions : `qb-vehiclekeys` / `qbx_vehiclekeys` (signatures des exports de clés), `qb-inventory` (exports de la v2+), événements de chargement/déchargement de QB/Qbox. Passe `Config.Debug = true` si un système ne réagit pas.

## Compat : scripts AEOM existants (Bridge.* / Inv.*)

Depuis le 27 oct. 2026, la partie **serveur** du pont des scripts AEOM est centralisée ici (`server/compat.lua`, copie fidèle de l'ancien `bridge/server.lua`). Le `bridge/server.lua` de chaque script n'est plus qu'un petit « shim » (`-- AEOM Shim`) qui relaie `Bridge.*` / `Inv.*` vers `exports['aeom-bridge']:Compat(...)`, avec les mêmes noms : le code des scripts n'a pas changé. Chaque manifest déclare `dependency 'aeom-bridge'`, donc FiveM le démarre avant eux.

- La partie **client** (`bridge/client.lua`, dont `Target.*`) reste dans chaque script : ox_target rattache les cibles à la ressource qui les pose et appelle `canInteract` à chaque image.
- **Attention :** arrêter ou relancer `aeom-bridge` arrête tous les scripts qui en dépendent (`ensure` pour les relancer).
- Réglages : `Config.Compat` dans `config.lua` (framework, inventaire, objet d'argent sale).
- Les rappels (`onLoaded`, `onJobChange`, objets utilisables) d'un script arrêté sont ignorés automatiquement.
- Les scripts d'un serveur qui utilisent le pont n'ont besoin que d'un petit « shim » serveur et de `dependency 'aeom-bridge'` dans leur manifeste.

## Historique

- **1.2.0** (28 oct. 2026) : propriétaire de véhicule, service QB/Qbox, comptes de société (dont Renewed-Banking), métiers et grades, stash ox avec métiers et coordonnées, exports Pascal correspondants (demandés par aeom_mechanic, `docs/bridge-todo.md`).
- **1.1.0** (27 oct. 2026) : pont des scripts AEOM centralisé (`server/compat.lua`, exports `Compat` / `CompatInfo`), nouvelles fonctions (`Inv.item`, `Inv.canCarryWeight`, `Inv.registerUseHook`, `Inv.slotCount`, `Inv.countMany`, `Inv.slotsOf`, `Bridge.getMetadata`, `Bridge.setMetadata`), `files { 'init.lua' }` pour le téléchargement client, `Config.Compat`.
- **1.0.0** : API Pascal (`AddMoney`, `GetJob`...), détection auto, callbacks, événements unifiés.

## Licence

Licence AEOM Development (modification autorisée, revente interdite) : voir le fichier `LICENSE`.
