lib.locale(Config.Locale)

lib.callback.register('djfivem-robbery:server:tabletData', function(source)
    if not HasItem(source, Config.Tablet.item, 1) then
        return { ok = false, reason = 'no_tablet' }
    end
    if IsOnDutyPolice(source) then
        return { ok = false, reason = 'police_blocked' }
    end

    local locations = {}
    for i = 1, #Config.Locations do
        local loc = Config.Locations[i]
        local typeCfg = Config.Types[loc.type]
        local remaining = CooldownRemaining(loc.id)
        locations[#locations + 1] = {
            id = loc.id,
            type = loc.type,
            label = loc.label,
            description = loc.description,
            payoutLabel = loc.payoutLabel,
            minPolice = loc.minPolice or typeCfg.minPolice,
            maxPlayers = typeCfg.maxPlayers,
            cooldown = remaining,
            available = remaining <= 0,
            coords = Vec(loc.coords),
        }
    end

    local types = {}
    for id, cfg in pairs(Config.Types) do
        types[#types + 1] = {
            id = id,
            label = cfg.label,
            description = cfg.description,
            maxPlayers = cfg.maxPlayers,
            minPlayers = cfg.minPlayers,
            minPolice = cfg.minPolice,
            icon = cfg.icon,
            color = cfg.color,
        }
    end
    table.sort(types, function(a, b) return a.label < b.label end)

    local crew = GetCrew(source)
    local job = crew and crew.jobId and Jobs[crew.jobId] or nil

    return {
        ok = true,
        police = CountPolice(),
        types = types,
        locations = locations,
        crew = SerializeCrew(crew),
        job = SerializeJob(job),
        name = CharacterName(source),
    }
end)

lib.callback.register('djfivem-robbery:server:createCrew', function(source, locationId)
    if not HasItem(source, Config.Tablet.item, 1) then
        return { ok = false, reason = 'no_tablet' }
    end
    if IsOnDutyPolice(source) then
        return { ok = false, reason = 'police_blocked' }
    end
    local ok, crewOrReason = CreateCrew(source, locationId)
    if not ok then
        return { ok = false, reason = crewOrReason }
    end
    Notify(source, 'crew_created', 'success')
    return { ok = true, crew = SerializeCrew(crewOrReason) }
end)

lib.callback.register('djfivem-robbery:server:leaveCrew', function(source)
    LeaveCrew(source, false)
    return { ok = true }
end)

lib.callback.register('djfivem-robbery:server:nearbyPlayers', function(source)
    local origin = PlayerCoords(source)
    if not origin then return {} end
    local nearby = {}
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        if src and src ~= source then
            local pos = PlayerCoords(src)
            if pos and #(origin - pos) <= Config.InviteDistance then
                nearby[#nearby + 1] = {
                    source = src,
                    name = CharacterName(src),
                    distance = #(origin - pos),
                }
            end
        end
    end
    table.sort(nearby, function(a, b) return a.distance < b.distance end)
    return nearby
end)

lib.callback.register('djfivem-robbery:server:invite', function(source, target)
    target = tonumber(target)
    if not target then return { ok = false } end
    local ok, reason = InviteToCrew(source, target)
    if not ok then
        return { ok = false, reason = reason }
    end
    Notify(source, 'invite_sent', 'success', CharacterName(target))
    return { ok = true }
end)

lib.callback.register('djfivem-robbery:server:startJob', function(source)
    local ok, a, b, c = StartJob(source)
    if not ok then
        return { ok = false, reason = a, arg1 = b, arg2 = c }
    end
    return { ok = true }
end)

lib.addCommand(Config.Admin.resetCommand, {
    help = 'Reset robbery tablet cooldowns',
    params = {
        { name = 'location', help = 'location id or all', optional = true, type = 'string' },
    },
    restricted = Config.Admin.group,
}, function(source, args)
    ResetCooldown(args.location or 'all')
    if source > 0 then
        Notify(source, 'reset_ok', 'success')
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id in pairs(Jobs) do
        FailJob(id, 'job_failed')
    end
end)
