local function armPed(ped, cfg)
    local group = EnsureGuardGroup()
    SetPedRelationshipGroupHash(ped, group)
    SetPedArmour(ped, cfg.armour or Config.Guards.armour)
    SetEntityHealth(ped, cfg.health or Config.Guards.health)
    SetPedAccuracy(ped, cfg.accuracy or Config.Guards.accuracy)
    SetPedAsEnemy(ped, true)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 5, true)
    SetPedCombatAbility(ped, 2)
    SetPedCombatMovement(ped, 2)
    SetPedCombatRange(ped, 2)
    SetPedFleeAttributes(ped, 0, false)
    SetPedDropsWeaponsWhenDead(ped, false)
    GiveWeaponToPed(ped, joaat(cfg.weapon or Config.Guards.defaultWeapon), 250, false, true)
    SetPedSeeingRange(ped, Config.Guards.combatRange or 70.0)
    SetPedHearingRange(ped, 80.0)
    TaskCombatHatedTargetsAroundPed(ped, Config.Guards.combatRange or 70.0, 0)
end

RegisterNetEvent('djfivem-robbery:client:spawnGuards', function(jobId, locationId)
    if not Config.Guards.enabled then return end
    local loc = GetRobberyLocation(locationId)
    if not loc or not LocationHasGuards(loc) then return end
    local cfg = loc.guards
    if not LoadModel(cfg.model) then return end

    local bundle = EnsureJobBundle(jobId)
    bundle.peds = bundle.peds or {}
    local nets = {}

    for i = 1, #cfg.peds do
        local spawn = cfg.peds[i]
        local ped = CreatePed(4, joaat(cfg.model), spawn.x, spawn.y, spawn.z, spawn.w or 0.0, true, true)
        SetEntityAsMissionEntity(ped, true, true)
        armPed(ped, cfg)
        bundle.peds[#bundle.peds + 1] = ped
        local netId = NetworkGetNetworkIdFromEntity(ped)
        SetNetworkIdExistsOnAllMachines(netId, true)
        SetNetworkIdCanMigrate(netId, true)
        nets[#nets + 1] = netId
    end

    TriggerServerEvent('djfivem-robbery:server:guardsReady', jobId, nets)
end)

RegisterNetEvent('djfivem-robbery:client:syncGuards', function(jobId, pedNets)
    CreateThread(function()
        local bundle = EnsureJobBundle(jobId)
        bundle.peds = bundle.peds or {}
        for i = 1, #(pedNets or {}) do
            local ped = WaitForNet(pedNets[i], 8000)
            if ped ~= 0 then
                bundle.peds[#bundle.peds + 1] = ped
            end
        end
    end)
end)
