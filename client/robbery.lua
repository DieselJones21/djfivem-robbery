local dropoffZone
local jobZones = {}

local function clearJobZones()
    for i = 1, #jobZones do
        exports.ox_target:removeZone(jobZones[i])
    end
    jobZones = {}
end

local function canUseInteraction(loc, interaction)
    if not ActiveJob then return false end
    if ActiveJob.locationId ~= loc.id then return false end
    if ActiveJob.completed and ActiveJob.completed[interaction.id] then return false end
    if ActiveJob.busy and ActiveJob.busy[interaction.id] then return false end
    if interaction.requires then
        for i = 1, #interaction.requires do
            if not ActiveJob.completed or not ActiveJob.completed[interaction.requires[i]] then
                return false
            end
        end
    end
    return true
end

local function handleInteraction(loc, interaction)
    local begin = lib.callback.await('djfivem-robbery:server:beginInteraction', false, loc.id, interaction.id)
    if not begin or not begin.ok then
        local reason = begin and begin.reason or 'job_failed'
        if reason == 'missing_item' then
            NotifyClient('missing_item', 'error', begin.item or 'item')
        else
            NotifyClient(reason, 'error')
        end
        return
    end

    local success = RunMinigame(begin.interaction or interaction)
    lib.callback.await('djfivem-robbery:server:finishInteraction', false, loc.id, interaction.id, success, begin.token)
end

local function registerJobTargets(loc)
    clearJobZones()
    if not loc.interactions then return end
    for n = 1, #loc.interactions do
        local interaction = loc.interactions[n]
        local zoneName = ('dj_robbery:%s:%s'):format(loc.id, interaction.id)
        local zoneId = exports.ox_target:addSphereZone({
            coords = interaction.coords,
            radius = 1.15,
            debug = Config.Debug,
            options = {
                {
                    name = zoneName,
                    icon = ('fa-solid fa-%s'):format(interaction.icon or 'hand'),
                    label = interaction.label,
                    distance = 2.0,
                    canInteract = function()
                        return canUseInteraction(loc, interaction)
                    end,
                    onSelect = function()
                        handleInteraction(loc, interaction)
                    end,
                },
            },
        })
        jobZones[#jobZones + 1] = zoneId
    end
end

local function clearDropoff()
    if dropoffZone then
        exports.ox_target:removeZone(dropoffZone)
        dropoffZone = nil
    end
end

local function setupDropoff(job, loc)
    clearDropoff()
    if loc.type ~= 'vehicle' or not loc.vehicle then return end
    dropoffZone = exports.ox_target:addSphereZone({
        coords = loc.vehicle.dropoff,
        radius = 3.5,
        debug = Config.Debug,
        options = {
            {
                name = 'dj_robbery:dropoff',
                icon = 'fa-solid fa-warehouse',
                label = 'Deliver stolen vehicle',
                distance = 3.0,
                canInteract = function()
                    return ActiveJob and ActiveJob.id == job.id and ActiveJob.stage == 'stolen'
                end,
                onSelect = function()
                    local veh = cache.vehicle
                    if not veh or veh == 0 then
                        NotifyClient('too_far', 'error')
                        return
                    end
                    TaskLeaveVehicle(cache.ped, veh, 0)
                    Wait(1200)
                    TriggerServerEvent('djfivem-robbery:server:deliverVehicle', job.id)
                end,
            },
        },
    })
end

local function pushHud(job)
    SendNUIMessage({
        action = 'hud',
        job = job,
    })
end

RegisterNetEvent('djfivem-robbery:client:jobSync', function(job)
    ActiveJob = job
    pushHud(job)
end)

RegisterNetEvent('djfivem-robbery:client:jobStarted', function(job, locationId)
    ActiveJob = job
    local loc = GetRobberyLocation(locationId)
    if not loc then return end
    SetGps(loc.coords)
    registerJobTargets(loc)
    local bundle = EnsureJobBundle(job.id)
    local blip = AddJobBlip(loc.coords, 1, 1, loc.label)
    bundle.blips[#bundle.blips + 1] = blip
    if loc.vehicle then
        setupDropoff(job, loc)
        local dropBlip = AddJobBlip(loc.vehicle.dropoff, 50, 5, 'Drop-off')
        bundle.blips[#bundle.blips + 1] = dropBlip
    end
    pushHud(job)
end)

RegisterNetEvent('djfivem-robbery:client:jobEnded', function()
    if ActiveJob then
        DeleteLocalEntities(ActiveJob.id)
    end
    clearJobZones()
    clearDropoff()
    ActiveJob = nil
    pushHud(nil)
end)

RegisterNetEvent('djfivem-robbery:client:openVault', function(locationId)
    local loc = GetRobberyLocation(locationId)
    if not loc or not loc.vaultDoor then return end
    local door = loc.vaultDoor
    local obj = GetClosestObjectOfType(door.coords.x, door.coords.y, door.coords.z, 5.0, door.model, false, false, false)
    if obj and obj ~= 0 then
        CreateThread(function()
            local start = GetEntityHeading(obj)
            local target = door.open
            for i = 1, 80 do
                local heading = start + ((target - start) * (i / 80))
                SetEntityHeading(obj, heading)
                Wait(40)
            end
            SetEntityHeading(obj, target)
        end)
    end
end)

RegisterNetEvent('djfivem-robbery:client:policeAlert', function(data)
    lib.notify({
        title = data.title,
        description = data.description,
        type = 'error',
        duration = 10000,
        icon = 'siren-on',
    })
    local coords = Vec3(data.coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 1.2)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(data.title)
    EndTextCommandSetBlipName(blip)
    SetTimeout((data.duration or 120) * 1000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)

RegisterNetEvent('djfivem-robbery:client:spawnVehicle', function(jobId, locationId)
    local loc = GetRobberyLocation(locationId)
    if not loc or not loc.vehicle then return end
    local spawn = loc.vehicle.spawn
    if not LoadModel(loc.vehicle.model) then return end
    local veh = CreateVehicle(joaat(loc.vehicle.model), spawn.x, spawn.y, spawn.z, spawn.w, true, true)
    Wait(100)
    SetVehicleOnGroundProperly(veh)
    SetVehicleDoorsLocked(veh, 2)
    SetVehicleNumberPlateText(veh, loc.vehicle.plate or 'BOOST')
    SetEntityAsMissionEntity(veh, true, true)
    local bundle = EnsureJobBundle(jobId)
    bundle.vehicle = veh
    local netId = NetworkGetNetworkIdFromEntity(veh)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, true)
    TriggerServerEvent('djfivem-robbery:server:vehicleReady', jobId, netId)
end)

RegisterNetEvent('djfivem-robbery:client:spawnTruck', function(jobId, locationId)
    local loc = GetRobberyLocation(locationId)
    if not loc or not loc.truck then return end
    local truckCfg = loc.truck
    if not LoadModel(truckCfg.model) or not LoadModel(truckCfg.guardModel) then return end

    local spawn = truckCfg.spawn
    local veh = CreateVehicle(joaat(truckCfg.model), spawn.x, spawn.y, spawn.z, spawn.w, true, true)
    Wait(100)
    SetVehicleOnGroundProperly(veh)
    SetVehicleDoorsLocked(veh, 2)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleEngineOn(veh, true, true, false)

    local peds = {}
    local seats = { -1, 0 }
    local extra = truckCfg.extraGuards or 0
    local count = 2 + extra
    for i = 1, math.min(count, 4) do
        local seat = seats[i] or (i - 2)
        local ped
        if seat and seat >= -1 and seat <= 2 then
            ped = CreatePedInsideVehicle(veh, 4, joaat(truckCfg.guardModel), seat, true, true)
        else
            local offset = GetOffsetFromEntityInWorldCoords(veh, i % 2 == 0 and 2.2 or -2.2, -1.0, 0.0)
            ped = CreatePed(4, joaat(truckCfg.guardModel), offset.x, offset.y, offset.z, spawn.w, true, true)
            TaskEnterVehicle(ped, veh, 4000, seat, 2.0, 1, 0)
        end
        SetPedArmour(ped, 60)
        SetPedAccuracy(ped, 45)
        GiveWeaponToPed(ped, joaat(truckCfg.guardWeapon or 'WEAPON_SMG'), 220, false, true)
        SetPedRelationshipGroupHash(ped, EnsureGuardGroup())
        SetPedAsEnemy(ped, true)
        SetPedCombatAttributes(ped, 46, true)
        SetPedDropsWeaponsWhenDead(ped, false)
        peds[#peds + 1] = ped
    end

    local bundle = EnsureJobBundle(jobId)
    bundle.vehicle = veh
    bundle.peds = peds

    local driver = peds[1]
    if driver and truckCfg.waypoints and truckCfg.waypoints[1] then
        TaskVehicleDriveToCoordLongrange(
            driver,
            veh,
            truckCfg.waypoints[1].x,
            truckCfg.waypoints[1].y,
            truckCfg.waypoints[1].z,
            truckCfg.speed or 18.0,
            786603,
            12.0
        )
    end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    local pedNets = {}
    for i = 1, #peds do
        pedNets[i] = NetworkGetNetworkIdFromEntity(peds[i])
    end
    TriggerServerEvent('djfivem-robbery:server:truckReady', jobId, netId, pedNets)

    CreateThread(function()
        local idx = 1
        while ActiveJob and ActiveJob.id == jobId and DoesEntityExist(veh) and DoesEntityExist(driver) and not IsPedDeadOrDying(driver, true) do
            if truckCfg.waypoints[idx] then
                local wp = truckCfg.waypoints[idx]
                if #(GetEntityCoords(veh) - wp) < 20.0 then
                    idx += 1
                    if truckCfg.waypoints[idx] then
                        TaskVehicleDriveToCoordLongrange(driver, veh, truckCfg.waypoints[idx].x, truckCfg.waypoints[idx].y, truckCfg.waypoints[idx].z, truckCfg.speed or 18.0, 786603, 12.0)
                    else
                        TaskVehicleDriveWander(driver, veh, truckCfg.speed or 16.0, 786603)
                    end
                end
            end
            Wait(1500)
        end
        if DoesEntityExist(veh) then
            SetVehicleDoorsLocked(veh, 1)
            SetVehicleDoorOpen(veh, 2, false, false)
            SetVehicleDoorOpen(veh, 3, false, false)
        end
    end)
end)

RegisterNetEvent('djfivem-robbery:client:unlockVehicle', function(netId)
    local veh = WaitForNet(netId, 4000)
    if veh ~= 0 then
        SetVehicleDoorsLocked(veh, 1)
    end
end)

RegisterNetEvent('djfivem-robbery:client:bindVehicle', function(jobId, netId, locationId)
    if boundEntities[netId] then return end
    boundEntities[netId] = true
    CreateThread(function()
        local veh = WaitForNet(netId, 8000)
        if veh == 0 then return end
        local loc = GetRobberyLocation(locationId)
        exports.ox_target:addEntity(netId, {
            {
                name = 'dj_robbery:lockpick_veh',
                icon = 'fa-solid fa-key',
                label = 'Lockpick vehicle',
                distance = 2.2,
                canInteract = function()
                    return ActiveJob and ActiveJob.id == jobId and ActiveJob.stage == 'spawned'
                end,
                onSelect = function()
                    local begin = lib.callback.await('djfivem-robbery:server:lockpickVehicle', false, jobId)
                    if not begin or not begin.ok then
                        if begin and begin.reason == 'missing_item' then
                            NotifyClient('missing_item', 'error', begin.item or 'lockpick')
                        else
                            NotifyClient(begin and begin.reason or 'job_failed', 'error')
                        end
                        return
                    end
                    local ok = SkillCheck(Config.Skill.vehicle) and Progress('Lockpicking', 7500, Config.Anims.lockpick)
                    if ok then
                        SetVehicleDoorsLocked(veh, 1)
                        TriggerServerEvent('djfivem-robbery:server:vehicleUnlocked', jobId, begin.token)
                        if loc and loc.vehicle then
                            SetGps(loc.vehicle.dropoff)
                        end
                    end
                end,
            },
        })
    end)
end)

RegisterNetEvent('djfivem-robbery:client:bindTruck', function(jobId, netId, locationId)
    if boundEntities[netId] then return end
    boundEntities[netId] = true
    CreateThread(function()
        local veh = WaitForNet(netId, 8000)
        if veh == 0 then return end
        local loc = GetRobberyLocation(locationId)
        local crateCount = loc and loc.truck and loc.truck.lootSpots or 3
        local options = {}
        for i = 1, crateCount do
            local crateId = ('crate_%s'):format(i)
            options[#options + 1] = {
                name = 'dj_robbery:truck_' .. crateId,
                icon = 'fa-solid fa-box-open',
                label = ('Loot crate %s'):format(i),
                bones = { 'door_dside_r', 'door_pside_r', 'boot' },
                distance = 2.5,
                canInteract = function()
                    if not ActiveJob or ActiveJob.id ~= jobId then return false end
                    if ActiveJob.completed and ActiveJob.completed[crateId] then return false end
                    local driver = GetPedInVehicleSeat(veh, -1)
                    local driverDown = driver == 0 or not DoesEntityExist(driver) or IsPedDeadOrDying(driver, true)
                    return driverDown or GetVehicleDoorLockStatus(veh) ~= 2 or IsVehicleDoorDamaged(veh, 2) or IsVehicleDoorDamaged(veh, 3)
                end,
                onSelect = function()
                    local begin = lib.callback.await('djfivem-robbery:server:lootTruck', false, jobId, crateId)
                    if not begin or not begin.ok then
                        if begin and begin.reason == 'missing_item' then
                            NotifyClient('missing_item', 'error', begin.item or 'thermite')
                        else
                            NotifyClient(begin and begin.reason or 'job_failed', 'error')
                        end
                        return
                    end
                    local skill = loc.type == 'cargotruck' and Config.Skill.cargo or Config.Skill.truck
                    local ok = SkillCheck(skill) and Progress('Grabbing crates', 8500, Config.Anims.loot)
                    TriggerServerEvent('djfivem-robbery:server:finishTruckLoot', jobId, crateId, ok, begin.token)
                end,
            }
        end
        exports.ox_target:addEntity(netId, options)
    end)
end)

RegisterNetEvent('djfivem-robbery:client:trackTruck', function(netId, waypoints)
    CreateThread(function()
        local veh = WaitForNet(netId, 8000)
        if veh == 0 then return end
        local blip = AddBlipForEntity(veh)
        SetBlipSprite(blip, 67)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 0.9)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Target truck')
        EndTextCommandSetBlipName(blip)
        if ActiveJob then
            local bundle = EnsureJobBundle(ActiveJob.id)
            bundle.blips[#bundle.blips + 1] = blip
        end
        if waypoints and waypoints[1] then
            SetGps(waypoints[1])
        end
    end)
end)

RegisterNetEvent('djfivem-robbery:client:cleanupEntities', function(jobId)
    DeleteLocalEntities(jobId)
    clearJobZones()
    clearDropoff()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearJobZones()
    clearDropoff()
    if ActiveJob then
        DeleteLocalEntities(ActiveJob.id)
    end
end)
