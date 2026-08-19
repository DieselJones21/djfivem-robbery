lib.locale(Config.Locale)

local tabletOpen = false

local function closeTablet()
    if not tabletOpen then return end
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function failReason(data)
    if not data or not data.reason then
        return locale('job_failed')
    end
    if data.reason == 'not_enough_police' then
        return locale('not_enough_police', data.arg1 or 0, data.arg2 or 0)
    end
    if data.reason == 'on_cooldown' then
        return locale('on_cooldown', data.arg1 or '?')
    end
    if data.reason == 'player_cooldown' then
        return locale('player_cooldown', data.arg1 or 'You', data.arg2 or '?')
    end
    if data.reason == 'min_players' then
        return locale('min_players', data.arg1 or 1)
    end
    if data.reason == 'missing_item' then
        return locale('missing_kit', data.item or data.arg1 or 'item')
    end
    return locale(data.reason)
end

local function openTablet()
    if IsPauseMenuActive() then return end
    local data = lib.callback.await('djfivem-robbery:server:tabletData', false)
    if not data or not data.ok then
        NotifyClient(data and data.reason or 'no_tablet', 'error')
        return
    end
    tabletOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        payload = data,
    })
end

exports('useTablet', function()
    openTablet()
end)

RegisterNetEvent('djfivem-robbery:client:openTablet', openTablet)

RegisterCommand('robberytab', function()
    if Config.Debug then
        openTablet()
    end
end, false)

RegisterNUICallback('close', function(_, cb)
    closeTablet()
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    local data = lib.callback.await('djfivem-robbery:server:tabletData', false)
    cb(data or { ok = false })
end)

RegisterNUICallback('createCrew', function(body, cb)
    local data = lib.callback.await('djfivem-robbery:server:createCrew', false, body.locationId)
    cb(data or { ok = false })
end)

RegisterNUICallback('leaveCrew', function(_, cb)
    local data = lib.callback.await('djfivem-robbery:server:leaveCrew', false)
    cb(data or { ok = false })
end)

RegisterNUICallback('nearby', function(_, cb)
    local data = lib.callback.await('djfivem-robbery:server:nearbyPlayers', false)
    cb(data or {})
end)

RegisterNUICallback('invite', function(body, cb)
    local data = lib.callback.await('djfivem-robbery:server:invite', false, body.source)
    cb(data or { ok = false })
end)

RegisterNUICallback('startJob', function(_, cb)
    local data = lib.callback.await('djfivem-robbery:server:startJob', false)
    if data and data.ok then
        closeTablet()
    elseif data and data.reason then
        lib.notify({
            title = locale('tablet_title'),
            description = failReason(data),
            type = 'error',
        })
    end
    cb(data or { ok = false })
end)

RegisterNetEvent('djfivem-robbery:client:invite', function(data)
    local result = lib.alertDialog({
        header = locale('invite_header'),
        content = locale('invite_body', data.name, data.label, data.size, data.max),
        centered = true,
        cancel = true,
        labels = { confirm = 'Join', cancel = 'Decline' },
    })
    lib.callback.await('djfivem-robbery:server:inviteResponse', false, result == 'confirm')
end)
