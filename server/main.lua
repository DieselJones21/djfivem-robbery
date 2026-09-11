lib.locale(Config.Locale)

lib.callback.register('djfivem-robbery:server:tabletData', function(source)
    if not RateLimit(source, 'tablet') then
        return { ok = false, reason = 'rate_limited' }
    end
    if not HasItem(source, Config.Tablet.item, 1) then
        return { ok = false, reason = 'no_tablet' }
    end
    if Config.Police.blockOfficersFromTablet and IsOnDutyPolice(source) then
        return { ok = false, reason = 'police_blocked' }
    end

    local playerCd = PlayerCooldownRemaining(source)
    local locations = {}
    for i = 1, #Config.Locations do
        local loc = Config.Locations[i]
        local typeCfg = Config.Types[loc.type]
        if typeCfg and typeCfg.enabled ~= false then
            local remaining = CooldownRemaining(loc.id)
            local items = {}
            local required = GetRequiredItems(loc)
            for n = 1, #required do
                items[#items + 1] = {
                    name = required[n].item,
                    count = required[n].count or 1,
                    label = ItemLabel(required[n].item),
                }
            end
            locations[#locations + 1] = {
                id = loc.id,
                type = loc.type,
                label = loc.label,
                description = loc.description,
                payoutLabel = loc.payoutLabel,
                minPolice = loc.minPolice or typeCfg.minPolice or 0,
                maxPlayers = typeCfg.maxPlayers,
                minPlayers = typeCfg.minPlayers or 1,
                cooldown = remaining,
                cooldownDuration = GetLocationCooldown(loc),
                requiredItems = items,
                available = remaining <= 0 and playerCd <= 0,
                coords = Vec(loc.coords),
                difficulty = loc.difficulty or typeCfg.difficulty or 1,
                stages = loc.stages,
                armed = LocationHasGuards(loc) == true,
            }
        end
    end

    local types = {}
    for id, cfg in pairs(Config.Types) do
        if cfg.enabled ~= false then
            types[#types + 1] = {
                id = id,
                label = cfg.label,
                description = cfg.description,
                maxPlayers = cfg.maxPlayers,
                minPlayers = cfg.minPlayers,
                minPolice = cfg.minPolice,
                cooldown = cfg.cooldown,
                requiredItems = cfg.requiredItems,
                requiredItemLabels = (function()
                    local labels = {}
                    if cfg.requiredItems then
                        for n = 1, #cfg.requiredItems do
                            labels[#labels + 1] = ItemLabel(cfg.requiredItems[n].item)
                        end
                    end
                    return labels
                end)(),
                icon = cfg.icon,
                color = cfg.color,
                difficulty = cfg.difficulty or 1,
            }
        end
    end
    table.sort(types, function(a, b)
        if (a.difficulty or 1) ~= (b.difficulty or 1) then
            return (a.difficulty or 1) < (b.difficulty or 1)
        end
        return a.label < b.label
    end)

    local crew = GetCrew(source)
    local job = crew and crew.jobId and Jobs[crew.jobId] or nil

    return {
        ok = true,
        police = CountPolice(),
        playerCooldown = playerCd,
        types = types,
        locations = locations,
        crew = SerializeCrew(crew),
        job = SerializeJob(job),
        name = CharacterName(source),
        store = SerializeStore(source),
        brand = Config.Ui.brand,
        subtitle = Config.Ui.subtitle,
        version = Config.Version,
    }
end)

lib.callback.register('djfivem-robbery:server:createCrew', function(source, locationId)
    if not RateLimit(source, 'createCrew') then
        return { ok = false, reason = 'rate_limited' }
    end
    if not HasItem(source, Config.Tablet.item, 1) then
        return { ok = false, reason = 'no_tablet' }
    end
    if Config.Police.blockOfficersFromTablet and IsOnDutyPolice(source) then
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
    if not RateLimit(source, 'nearby') then return {} end
    local origin = PlayerCoords(source)
    if not origin then return {} end
    local nearby = {}
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        if src and src ~= source then
            local pos = PlayerCoords(src)
            if pos and #(origin - pos) <= Config.InviteDistance then
                if not IsOnDutyPolice(src) then
                    nearby[#nearby + 1] = {
                        source = src,
                        name = CharacterName(src),
                        distance = #(origin - pos),
                    }
                end
            end
        end
    end
    table.sort(nearby, function(a, b) return a.distance < b.distance end)
    return nearby
end)

lib.callback.register('djfivem-robbery:server:invite', function(source, target)
    if not RateLimit(source, 'invite') then
        return { ok = false, reason = 'rate_limited' }
    end
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
    if not RateLimit(source, 'start') then
        return { ok = false, reason = 'rate_limited' }
    end
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
