Jobs = {}
Cooldowns = {}
PlayerCooldowns = {}
local jobSeq = 0

local function nextJobId()
    jobSeq += 1
    return ('job_%s_%s'):format(os.time(), jobSeq)
end

function CooldownRemaining(locationId)
    local untilTime = Cooldowns[locationId]
    if not untilTime then return 0 end
    return math.max(0, untilTime - os.time())
end

function SetCooldown(locationId, seconds)
    Cooldowns[locationId] = os.time() + (seconds or 0)
end

function ResetCooldown(locationId)
    if locationId == 'all' or not locationId then
        Cooldowns = {}
        PlayerCooldowns = {}
        return
    end
    Cooldowns[locationId] = nil
end

local function citizenId(src)
    local player = GetPlayer(src)
    return player and player.PlayerData.citizenid or nil
end

function PlayerCooldownRemaining(src)
    if not Config.PlayerCooldown or Config.PlayerCooldown <= 0 then return 0 end
    local cid = citizenId(src)
    if not cid then return 0 end
    return math.max(0, (PlayerCooldowns[cid] or 0) - os.time())
end

function SetPlayerCooldown(src)
    if not Config.PlayerCooldown or Config.PlayerCooldown <= 0 then return end
    local cid = citizenId(src)
    if cid then
        PlayerCooldowns[cid] = os.time() + Config.PlayerCooldown
    end
end

local function crewMissingItem(crew, loc)
    local required = GetRequiredItems(loc)
    for i = 1, #required do
        local req = required[i]
        local have = 0
        for src in pairs(crew.members) do
            local count = exports.ox_inventory:Search(src, 'count', req.item) or 0
            have += count
        end
        if have < (req.count or 1) then
            return req
        end
    end
end

local function interactionById(loc, id)
    if not loc.interactions then return nil end
    for i = 1, #loc.interactions do
        if loc.interactions[i].id == id then
            return loc.interactions[i]
        end
    end
end

local function isTruckType(typeId)
    return typeId == 'moneytruck' or typeId == 'cargotruck'
end

local function allLootDone(job, loc)
    if loc.type == 'vehicle' then
        return job.stage == 'delivered'
    end
    if isTruckType(loc.type) then
        local needed = loc.truck.lootSpots or 1
        local done = 0
        for id in pairs(job.completed) do
            if id:find('^crate_') then done += 1 end
        end
        return done >= needed
    end
    if not loc.interactions then return false end
    for i = 1, #loc.interactions do
        local int = loc.interactions[i]
        if int.kind == 'loot' or int.rewards then
            if not job.completed[int.id] then
                return false
            end
        end
    end
    return true
end

function SerializeJob(job)
    if not job then return nil end
    local loc = GetRobberyLocation(job.locationId)
    if not loc then return nil end
    return {
        id = job.id,
        locationId = job.locationId,
        type = loc.type,
        label = loc.label,
        startedAt = job.startedAt,
        timeout = job.timeout,
        completed = job.completed,
        busy = job.busy,
        stage = job.stage,
        vehicleNetId = job.vehicleNetId,
        truckNetId = job.truckNetId,
        dropoff = loc.vehicle and Vec(loc.vehicle.dropoff) or nil,
        gps = Vec(loc.coords),
        stages = loc.stages,
        hasGuards = LocationHasGuards(loc) == true,
        remaining = math.max(0, job.timeout - os.time()),
    }
end

local function broadcastJob(job)
    local crew = Crews[job.crewId]
    if not crew then return end
    local payload = SerializeJob(job)
    EachCrewMember(crew, function(src)
        TriggerClientEvent('djfivem-robbery:client:jobSync', src, payload)
    end)
end

local function giveRewards(src, rewards, crew)
    if not rewards then return end
    local recipients = { src }
    if Config.RewardMode == 'split' and crew then
        recipients = {}
        for member in pairs(crew.members) do
            recipients[#recipients + 1] = member
        end
    end

    local share = math.max(1, #recipients)
    for i = 1, #rewards do
        local reward = rewards[i]
        if not reward.chance or math.random(100) <= reward.chance then
            local amount = math.random(reward.min or 1, reward.max or reward.min or 1)
            if Config.RewardMode == 'split' then
                amount = math.max(1, math.floor(amount / share))
            end
            for r = 1, #recipients do
                local target = recipients[r]
                if reward.type == 'account' then
                    exports.qbx_core:AddMoney(target, reward.name or Config.CashAccount, amount, 'nexus-contract')
                else
                    local added = exports.ox_inventory:AddItem(target, reward.name, amount)
                    if not added and reward.name == Config.Items.dirtyCash then
                        exports.qbx_core:AddMoney(target, Config.CashAccount, amount, 'nexus-contract-fallback')
                    end
                end
            end
        end
    end
end

local function spawnGuardsFor(job, loc, reason)
    if not LocationHasGuards(loc) then return end
    if job.guardsSpawned then return end
    local when = loc.guards.spawnOn or 'alarm'
    if reason == 'start' and when ~= 'start' then return end
    if reason == 'alarm' and when == 'start' and job.guardsSpawned then return end
    job.guardsSpawned = true
    TriggerClientEvent('djfivem-robbery:client:spawnGuards', job.host, job.id, loc.id)
end

function StartJob(src)
    local crew = GetCrew(src)
    if not crew then return false, 'not_in_crew' end
    if crew.host ~= src then return false, 'not_host' end
    if crew.jobId then return false, 'location_busy' end

    local loc = GetRobberyLocation(crew.locationId)
    if not loc then return false, 'invalid' end
    if not IsTypeEnabled(loc.type) then return false, 'type_disabled' end
    local typeCfg = Config.Types[loc.type]

    if CrewSize(crew) < (typeCfg.minPlayers or 1) then
        return false, 'min_players', typeCfg.minPlayers
    end

    local remaining = CooldownRemaining(loc.id)
    if remaining > 0 then
        return false, 'on_cooldown', FormatTime(remaining)
    end

    for member in pairs(crew.members) do
        local playerCd = PlayerCooldownRemaining(member)
        if playerCd > 0 then
            return false, 'player_cooldown', CharacterName(member), FormatTime(playerCd)
        end
    end

    local police = CountPolice()
    local need = loc.minPolice or typeCfg.minPolice or 0
    if need > 0 and police < need then
        return false, 'not_enough_police', police, need
    end

    local missing = crewMissingItem(crew, loc)
    if missing then
        return false, 'missing_item', ItemLabel(missing.item)
    end

    for member in pairs(crew.members) do
        if IsOnDutyPolice(member) then
            return false, 'police_blocked'
        end
        if IsDead(member) then
            return false, 'crew_wiped'
        end
    end

    for _, job in pairs(Jobs) do
        if job.locationId == loc.id then
            return false, 'location_busy'
        end
    end

    local jobId = nextJobId()
    local timeout = GetLocationTimeout(loc)
    local job = {
        id = jobId,
        crewId = crew.id,
        locationId = loc.id,
        host = src,
        members = {},
        completed = {},
        busy = {},
        tokens = {},
        stage = 'active',
        startedAt = os.time(),
        timeout = os.time() + timeout,
        alerted = false,
        vehicleNetId = nil,
        truckNetId = nil,
        truckPeds = {},
        guardsSpawned = false,
        rearOpened = false,
    }

    for member in pairs(crew.members) do
        job.members[member] = true
    end

    Jobs[jobId] = job
    crew.jobId = jobId
    SetCooldown(loc.id, GetLocationCooldown(loc))
    EachCrewMember(crew, function(member)
        SetPlayerCooldown(member)
    end)

    broadcastJob(job)
    EachCrewMember(crew, function(member)
        Notify(member, 'started', 'success')
        TriggerClientEvent('djfivem-robbery:client:jobStarted', member, SerializeJob(job), loc.id)
    end)

    if loc.type == 'vehicle' then
        TriggerClientEvent('djfivem-robbery:client:spawnVehicle', src, jobId, loc.id)
    elseif isTruckType(loc.type) then
        TriggerClientEvent('djfivem-robbery:client:spawnTruck', src, jobId, loc.id)
    end

    spawnGuardsFor(job, loc, 'start')

    SendWebhook('Contract started', ('%s started %s with %s player(s)'):format(
        CharacterName(src), loc.label, CrewSize(crew)
    ))
    return true, job
end

function FailJob(jobId, reason)
    local job = Jobs[jobId]
    if not job then return end
    local crew = Crews[job.crewId]
    local loc = GetRobberyLocation(job.locationId)

    EachCrewMember(crew or { members = job.members }, function(src)
        TriggerClientEvent('djfivem-robbery:client:jobEnded', src, reason or 'job_failed')
        Notify(src, reason or 'job_failed', 'error')
    end)

    if loc and (loc.type == 'vehicle' or isTruckType(loc.type) or LocationHasGuards(loc)) then
        EachCrewMember(crew or { members = job.members }, function(member)
            TriggerClientEvent('djfivem-robbery:client:cleanupEntities', member, jobId)
        end)
    end

    if crew then
        crew.jobId = nil
    end
    Jobs[jobId] = nil
end

function CompleteJob(jobId)
    local job = Jobs[jobId]
    if not job then return end
    local crew = Crews[job.crewId]
    local loc = GetRobberyLocation(job.locationId)
    local members = {}
    if crew then
        for src in pairs(crew.members) do
            members[#members + 1] = src
        end
        crew.jobId = nil
    else
        for src in pairs(job.members) do
            members[#members + 1] = src
        end
    end
    Jobs[jobId] = nil
    for i = 1, #members do
        TriggerClientEvent('djfivem-robbery:client:jobEnded', members[i], 'job_complete')
        Notify(members[i], 'job_complete', 'success')
        TriggerClientEvent('djfivem-robbery:client:cleanupEntities', members[i], jobId)
    end
    SendWebhook('Contract complete', ('%s finished %s'):format(
        loc and loc.label or job.locationId, CharacterName(job.host)
    ))
    if crew then
        for i = 1, #members do
            LeaveCrew(members[i], true)
        end
    end
end

lib.callback.register('djfivem-robbery:server:beginInteraction', function(source, locationId, interactionId)
    if not RateLimit(source, 'begin') then
        return { ok = false, reason = 'rate_limited' }
    end
    local crew = GetCrew(source)
    if not crew or not crew.jobId then return { ok = false, reason = 'not_in_crew' } end
    local job = Jobs[crew.jobId]
    if not job or job.locationId ~= locationId then
        return { ok = false, reason = 'not_in_crew' }
    end
    if not job.members[source] then return { ok = false, reason = 'not_in_crew' } end
    if IsDead(source) then return { ok = false, reason = 'job_failed' } end

    local loc = GetRobberyLocation(locationId)
    if not loc then return { ok = false, reason = 'invalid' } end
    local interaction = interactionById(loc, interactionId)
    if not interaction then return { ok = false, reason = 'invalid' } end

    if job.completed[interactionId] then
        return { ok = false, reason = 'already_done' }
    end
    if job.busy[interactionId] then
        return { ok = false, reason = 'busy' }
    end
    if interaction.requires then
        for i = 1, #interaction.requires do
            if not job.completed[interaction.requires[i]] then
                return { ok = false, reason = 'need_stage' }
            end
        end
    end

    if Distance(source, interaction.coords) > Config.InteractDistance + 1.5 then
        return { ok = false, reason = 'too_far' }
    end

    if interaction.item and not HasItem(source, interaction.item, 1) then
        return { ok = false, reason = 'missing_item', item = ItemLabel(interaction.item) }
    end

    local token = RandomToken()
    job.busy[interactionId] = source
    job.tokens[interactionId] = {
        src = source,
        token = token,
        expires = os.time() + (Config.AntiExploit.interactionTokenTtl or 90),
    }
    broadcastJob(job)
    return {
        ok = true,
        token = token,
        interaction = {
            id = interaction.id,
            kind = interaction.kind,
            label = interaction.label,
            duration = interaction.duration,
            minigame = interaction.minigame,
            skill = interaction.skill,
            anim = interaction.anim,
        },
    }
end)

lib.callback.register('djfivem-robbery:server:finishInteraction', function(source, locationId, interactionId, success, token)
    if not RateLimit(source, 'finish') then
        return { ok = false, reason = 'rate_limited' }
    end
    local crew = GetCrew(source)
    if not crew or not crew.jobId then return { ok = false } end
    local job = Jobs[crew.jobId]
    if not job or job.locationId ~= locationId then return { ok = false } end
    if job.busy[interactionId] ~= source then return { ok = false, reason = 'busy' } end

    local lock = job.tokens[interactionId]
    if not lock or lock.src ~= source or lock.token ~= token or os.time() > lock.expires then
        job.busy[interactionId] = nil
        job.tokens[interactionId] = nil
        broadcastJob(job)
        return { ok = false, reason = 'invalid_token' }
    end

    local loc = GetRobberyLocation(locationId)
    local interaction = interactionById(loc, interactionId)
    job.busy[interactionId] = nil
    job.tokens[interactionId] = nil

    if not interaction then return { ok = false, reason = 'invalid' } end

    if Config.AntiExploit.validateDistanceOnFinish and Distance(source, interaction.coords) > Config.InteractDistance + 2.5 then
        broadcastJob(job)
        return { ok = false, reason = 'too_far' }
    end

    if not success then
        broadcastJob(job)
        return { ok = true, failed = true }
    end

    if job.completed[interactionId] then
        return { ok = false, reason = 'already_done' }
    end

    if Config.AntiExploit.requireItemOnFinish and interaction.item then
        if not HasItem(source, interaction.item, 1) then
            broadcastJob(job)
            return { ok = false, reason = 'missing_item', item = ItemLabel(interaction.item) }
        end
        ConsumeItem(source, interaction.item, interaction.consumeChance or 0)
    elseif interaction.item then
        ConsumeItem(source, interaction.item, interaction.consumeChance or 0)
    end

    job.completed[interactionId] = true
    if interaction.alertsPolice or interaction.kind == 'hack' or interaction.kind == 'breach' then
        AlertPolice(job, loc, interaction)
        spawnGuardsFor(job, loc, 'alarm')
    end

    if interaction.kind == 'breach' and loc.vaultDoor then
        EachCrewMember(crew, function(member)
            TriggerClientEvent('djfivem-robbery:client:openVault', member, loc.id)
        end)
    end

    if interaction.rewards then
        giveRewards(source, interaction.rewards, crew)
        Notify(source, 'loot_success', 'success')
    elseif interaction.kind == 'hack' then
        Notify(source, 'hack_success', 'success')
    else
        Notify(source, 'breach_success', 'success')
    end

    broadcastJob(job)

    if allLootDone(job, loc) then
        SetTimeout(1500, function()
            CompleteJob(job.id)
        end)
    end

    return { ok = true }
end)

lib.callback.register('djfivem-robbery:server:lockpickVehicle', function(source, jobId)
    if not RateLimit(source, 'lockpick') then
        return { ok = false, reason = 'rate_limited' }
    end
    local job = Jobs[jobId]
    if not job or not job.members[source] then return { ok = false } end
    local loc = GetRobberyLocation(job.locationId)
    if loc.type ~= 'vehicle' or job.stage ~= 'spawned' then
        return { ok = false, reason = 'need_stage' }
    end
    if not HasItem(source, Config.Items.lockpick, 1) then
        return { ok = false, reason = 'missing_item', item = ItemLabel(Config.Items.lockpick) }
    end
    if Distance(source, loc.vehicle.spawn) > 6.0 then
        return { ok = false, reason = 'too_far' }
    end
    local token = RandomToken()
    job.tokens.lockpick = { src = source, token = token, expires = os.time() + 90 }
    return { ok = true, token = token }
end)

RegisterNetEvent('djfivem-robbery:server:vehicleReady', function(jobId, netId)
    local src = source
    local job = Jobs[jobId]
    if not job or job.host ~= src then return end
    if type(netId) ~= 'number' then return end
    job.vehicleNetId = netId
    job.stage = 'spawned'
    broadcastJob(job)
    local loc = GetRobberyLocation(job.locationId)
    EachCrewMember(Crews[job.crewId], function(member)
        TriggerClientEvent('djfivem-robbery:client:bindVehicle', member, job.id, netId, loc.id)
    end)
    AlertPolice(job, loc, { alertsPolice = true })
    spawnGuardsFor(job, loc, 'alarm')
end)

RegisterNetEvent('djfivem-robbery:server:vehicleUnlocked', function(jobId, token)
    local src = source
    local job = Jobs[jobId]
    if not job or not job.members[src] then return end
    if job.stage ~= 'spawned' then return end
    local lock = job.tokens.lockpick
    if not lock or lock.src ~= src or lock.token ~= token or os.time() > lock.expires then return end
    job.tokens.lockpick = nil
    ConsumeItem(src, Config.Items.lockpick, 45)
    job.stage = 'stolen'
    job.completed.lockpick = true
    broadcastJob(job)
    EachCrewMember(Crews[job.crewId], function(member)
        TriggerClientEvent('djfivem-robbery:client:unlockVehicle', member, job.vehicleNetId)
        Notify(member, 'vehicle_stolen', 'success')
    end)
end)

RegisterNetEvent('djfivem-robbery:server:deliverVehicle', function(jobId)
    local src = source
    local job = Jobs[jobId]
    if not job or not job.members[src] then return end
    local loc = GetRobberyLocation(job.locationId)
    if job.stage ~= 'stolen' then return end
    if Distance(src, loc.vehicle.dropoff) > 8.0 then
        Notify(src, 'too_far', 'error')
        return
    end
    job.stage = 'delivered'
    local crew = Crews[job.crewId]
    giveRewards(src, loc.rewards, crew)
    Notify(src, 'vehicle_delivered', 'success')
    CompleteJob(job.id)
end)

RegisterNetEvent('djfivem-robbery:server:truckReady', function(jobId, truckNet, pedNets)
    local src = source
    local job = Jobs[jobId]
    if not job or job.host ~= src then return end
    if type(truckNet) ~= 'number' then return end
    job.truckNetId = truckNet
    job.truckPeds = pedNets or {}
    job.stage = 'spawned'
    broadcastJob(job)
    local loc = GetRobberyLocation(job.locationId)
    EachCrewMember(Crews[job.crewId], function(member)
        Notify(member, 'truck_spawned', 'inform')
        TriggerClientEvent('djfivem-robbery:client:trackTruck', member, truckNet, loc.truck.waypoints)
        TriggerClientEvent('djfivem-robbery:client:bindTruck', member, job.id, truckNet, loc.id)
    end)
end)

lib.callback.register('djfivem-robbery:server:lootTruck', function(source, jobId, crateId)
    if not RateLimit(source, 'lootTruck') then
        return { ok = false, reason = 'rate_limited' }
    end
    local job = Jobs[jobId]
    if not job or not job.members[source] then return { ok = false } end
    local loc = GetRobberyLocation(job.locationId)
    if not isTruckType(loc.type) then return { ok = false } end
    if type(crateId) ~= 'string' or not crateId:find('^crate_%d+$') then
        return { ok = false, reason = 'invalid' }
    end
    local crateNum = tonumber(crateId:match('%d+'))
    if not crateNum or crateNum < 1 or crateNum > (loc.truck.lootSpots or 3) then
        return { ok = false, reason = 'invalid' }
    end
    if job.completed[crateId] then return { ok = false, reason = 'already_done' } end
    if job.busy[crateId] then return { ok = false, reason = 'busy' } end

    local veh = job.truckNetId and NetworkGetEntityFromNetworkId(job.truckNetId)
    if veh and veh ~= 0 then
        local coords = GetEntityCoords(veh)
        if Distance(source, coords) > 8.0 then
            return { ok = false, reason = 'too_far' }
        end
    else
        return { ok = false, reason = 'too_far' }
    end

    if not job.rearOpened then
        local item = (loc.truck and loc.truck.breachItem) or Config.Items.thermite
        if not HasItem(source, item, 1) then
            return { ok = false, reason = 'missing_item', item = ItemLabel(item) }
        end
    end

    local token = RandomToken()
    job.busy[crateId] = source
    job.tokens[crateId] = { src = source, token = token, expires = os.time() + 90 }
    return { ok = true, token = token }
end)

RegisterNetEvent('djfivem-robbery:server:finishTruckLoot', function(jobId, crateId, success, token)
    local src = source
    local job = Jobs[jobId]
    if not job or job.busy[crateId] ~= src then return end
    local lock = job.tokens[crateId]
    if not lock or lock.src ~= src or lock.token ~= token or os.time() > lock.expires then
        job.busy[crateId] = nil
        job.tokens[crateId] = nil
        return
    end
    job.busy[crateId] = nil
    job.tokens[crateId] = nil
    if not success then
        broadcastJob(job)
        return
    end
    local loc = GetRobberyLocation(job.locationId)
    local crew = Crews[job.crewId]
    if not job.rearOpened then
        local item = (loc.truck and loc.truck.breachItem) or Config.Items.thermite
        ConsumeItem(src, item, 100)
        job.rearOpened = true
    end
    if job.completed[crateId] then return end
    job.completed[crateId] = true
    AlertPolice(job, loc, { alertsPolice = true })
    giveRewards(src, loc.truck.loot, crew)
    Notify(src, 'truck_loot', 'success')
    broadcastJob(job)
    if allLootDone(job, loc) then
        CompleteJob(job.id)
    end
end)

RegisterNetEvent('djfivem-robbery:server:guardsReady', function(jobId, pedNets)
    local src = source
    local job = Jobs[jobId]
    if not job or job.host ~= src then return end
    job.guardNets = pedNets or {}
    local crew = Crews[job.crewId]
    EachCrewMember(crew, function(member)
        if member ~= src then
            TriggerClientEvent('djfivem-robbery:client:syncGuards', member, job.id, job.guardNets)
        end
        Notify(member, 'guards_spawned', 'error')
    end)
end)

CreateThread(function()
    while true do
        Wait(5000)
        local now = os.time()
        for id, job in pairs(Jobs) do
            if now >= job.timeout then
                FailJob(id, 'job_timeout')
            else
                for intId, lock in pairs(job.tokens) do
                    if now > lock.expires then
                        if job.busy[intId] == lock.src then
                            job.busy[intId] = nil
                        end
                        job.tokens[intId] = nil
                    end
                end
                if Config.FailIfCrewWiped then
                    local alive = false
                    for src in pairs(job.members) do
                        if GetPlayer(src) and not IsDead(src) then
                            alive = true
                            break
                        end
                    end
                    if not alive then
                        FailJob(id, 'crew_wiped')
                    end
                end
            end
        end
    end
end)
