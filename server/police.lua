local policeCache = { count = 0, at = 0 }

local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

local function pcallExport(res, exportName, ...)
    if not resourceStarted(res) then return false, nil end
    local ok, result = pcall(function(...)
        return exports[res][exportName](exports[res], ...)
    end, ...)
    if ok then return true, result end
    return false, nil
end

local function qbxPoliceCount()
    local count = 0
    local players = exports.qbx_core:GetQBPlayers()
    for src in pairs(players) do
        src = tonumber(src) or src
        if IsOnDutyPolice(src) then
            count += 1
        end
    end
    return count
end

function IsOnDutyPolice(src)
    if Config.Police.useWasabiMdtOfficerCheck and resourceStarted('wasabi_mdt') then
        local ok, isOfficer = pcallExport('wasabi_mdt', 'IsOfficer', src)
        if ok and isOfficer then
            local player = GetPlayer(src)
            if player then
                local job = player.PlayerData.job
                if job and IsPoliceJob(job.name) then
                    if Config.RequireOnDuty then
                        return job.onduty == true
                    end
                    return true
                end
            end
        end
    end

    local player = GetPlayer(src)
    if not player then return false end
    local job = player.PlayerData.job
    if not job or not IsPoliceJob(job.name) then return false end
    if Config.RequireOnDuty then
        return job.onduty == true
    end
    return true
end

function CountPolice()
    local now = GetGameTimer()
    if now - policeCache.at < 2000 then
        return policeCache.count
    end

    local mode = Config.Police.countResource or 'auto'
    local count

    local function tryWasabi(name)
        local ok, result = pcallExport(name, 'getPoliceOnline')
        if ok and type(result) == 'number' then return result end
        ok, result = pcallExport(name, 'GetPoliceOnline')
        if ok and type(result) == 'number' then return result end
        ok, result = pcallExport(name, 'getPoliceCount')
        if ok and type(result) == 'number' then return result end
        return nil
    end

    if mode == 'wasabi_police' or mode == 'auto' then
        count = tryWasabi('wasabi_police')
    end
    if not count and (mode == 'wasabi_police_v2' or mode == 'auto') then
        count = tryWasabi('wasabi_police_v2')
    end
    if not count then
        count = qbxPoliceCount()
    end

    policeCache.count = count or 0
    policeCache.at = now
    return policeCache.count
end

local function dispatchPayload(job, loc, extra)
    local profile = Config.DispatchProfiles[loc.type] or {
        type = 'robbery',
        priority = 3,
        code = Config.Dispatch.code,
        title = locale(('alert_%s'):format(loc.type)) or loc.label,
    }
    local coords = loc.coords
    return {
        type = profile.type or 'robbery',
        title = extra and extra.title or profile.title or loc.label,
        description = ('%s — silent alarm. Crew size unknown.'):format(loc.label),
        location = loc.label,
        coords = coords,
        priority = profile.priority or 3,
        code = profile.code or Config.Dispatch.code,
        senderName = Config.Dispatch.senderName,
        source = job.host,
        jobType = loc.type,
        label = loc.label,
        message = profile.title,
    }
end

local function sendWasabiDispatch(resName, payload)
    local data = {
        type = payload.type,
        title = payload.title,
        description = payload.description,
        location = payload.location,
        coords = payload.coords,
        priority = payload.priority,
        code = payload.code,
        senderName = payload.senderName,
    }
    local ok, result = pcall(function()
        return exports[resName]:CreateDispatch(data)
    end)
    return ok and result ~= false
end

local function sendBuiltin(payload)
    local players = exports.qbx_core:GetQBPlayers()
    for src in pairs(players) do
        src = tonumber(src) or src
        if IsOnDutyPolice(src) then
            TriggerClientEvent('djfivem-robbery:client:policeAlert', src, {
                coords = Vec(payload.coords),
                title = payload.title,
                description = payload.description,
                duration = Config.Dispatch.blipTime,
            })
        end
    end
end

function AlertPolice(job, loc, interaction)
    if not Config.Dispatch.enabled then return end
    if interaction and interaction.alertsPolice == false then return end
    if job.alerted then return end
    job.alerted = true

    local payload = dispatchPayload(job, loc)

    if Config.Dispatch.resource == 'custom' and Config.Dispatch.custom then
        Config.Dispatch.custom(payload)
        return
    end

    local sent = false
    local resource = Config.Dispatch.resource

    if resource == 'wasabi_mdt' or resource == 'auto' then
        if resourceStarted('wasabi_mdt') then
            sent = sendWasabiDispatch('wasabi_mdt', payload)
        end
    end

    if not sent and (resource == 'wasabi_dispatch' or resource == 'auto') then
        if resourceStarted('wasabi_dispatch') then
            sent = sendWasabiDispatch('wasabi_dispatch', payload)
        elseif resourceStarted('wasabi_mdt') then
            sent = sendWasabiDispatch('wasabi_mdt', payload)
        end
    end

    if not sent and resource == 'ps-dispatch' then
        TriggerEvent('ps-dispatch:server:notify', {
            dispatchCode = payload.code or '10-90',
            message = payload.title,
            coords = payload.coords,
            description = loc.label,
        })
        sent = true
    elseif not sent and resource == 'cd_dispatch' then
        TriggerEvent('cd_dispatch:AddNotification', {
            job_table = { 'police', 'sheriff', 'bcso', 'lssd', 'sahp' },
            coords = payload.coords,
            title = payload.title,
            message = loc.label,
            flash = 0,
            unique_id = tostring(job.id),
            blip = {
                sprite = 161,
                scale = 1.2,
                colour = 1,
                flashes = false,
                text = payload.title,
                time = (Config.Dispatch.blipTime or 120) * 1000,
            },
        })
        sent = true
    elseif not sent and resource == 'qs-dispatch' then
        TriggerEvent('qs-dispatch:server:CreateDispatchCall', {
            job = { 'police', 'sheriff', 'bcso' },
            callLocation = payload.coords,
            callCode = { code = payload.code or '10-90', snippet = payload.title },
            message = loc.label,
        })
        sent = true
    elseif not sent and resource == 'linden' then
        TriggerEvent('linden_outlawalert:alerts', 'police', payload.title, loc.label, payload.coords)
        sent = true
    end

    if (not sent and Config.Dispatch.fallbackBuiltin) or resource == 'builtin' then
        sendBuiltin(payload)
    end

    SendWebhook('Dispatch', ('%s — %s'):format(payload.title, loc.label))
end
