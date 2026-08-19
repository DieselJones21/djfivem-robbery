local resource = GetCurrentResourceName()

lib.locale(Config.Locale)

function Notify(src, key, nType, ...)
    local msg = locale(key, ...)
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('tablet_title'),
        description = msg,
        type = nType or 'inform',
    })
end

function GetPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

function CharacterName(src)
    local player = GetPlayer(src)
    if not player then
        return GetPlayerName(src) or ('ID %s'):format(src)
    end
    local info = player.PlayerData.charinfo
    if info and info.firstname then
        return ('%s %s'):format(info.firstname, info.lastname)
    end
    return GetPlayerName(src) or ('ID %s'):format(src)
end

function IsPoliceJob(name)
    return Config.PoliceJobs[name] == true
end

function IsOnDutyPolice(src)
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

function PlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

function Distance(src, coords)
    local pos = PlayerCoords(src)
    if not pos or not coords then return 9999.0 end
    return #(pos - vec3(coords.x, coords.y, coords.z))
end

function HasItem(src, item, count)
    count = count or 1
    if not item then return true end
    local found = exports.ox_inventory:Search(src, 'count', item)
    return (found or 0) >= count
end

function ConsumeItem(src, item, chance)
    if not item then return true end
    chance = chance or 100
    if chance < 100 and math.random(100) > chance then
        return true
    end
    return exports.ox_inventory:RemoveItem(src, item, 1) == true
end

function ItemLabel(item)
    if not item then return '' end
    local data = exports.ox_inventory:Items(item)
    return (data and data.label) or item
end

function IsDead(src)
    local player = GetPlayer(src)
    if not player then return true end
    local meta = player.PlayerData.metadata or {}
    return meta.isdead == true or meta.inlaststand == true
end

function FormatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    if m <= 0 then
        return ('%ss'):format(s)
    end
    return ('%sm %ss'):format(m, s)
end

function Vec(coords)
    if not coords then return nil end
    return { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 }
end

function SendWebhook(title, description)
    if not Config.Webhook.enabled or Config.Webhook.url == '' then return end
    PerformHttpRequest(Config.Webhook.url, function() end, 'POST', json.encode({
        username = 'Robbery Tablet',
        embeds = {{
            title = title,
            description = description,
            color = 15105570,
        }},
    }), { ['Content-Type'] = 'application/json' })
end

function Debug(...)
    if Config.Debug then
        print(('[%s]'):format(resource), ...)
    end
end
