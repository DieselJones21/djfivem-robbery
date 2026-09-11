local resource = GetCurrentResourceName()

lib.locale(Config.Locale)

local itemLabelCache = {}
local rateBuckets = {}
local lastCallback = {}

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

function PlayerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

function Distance(src, coords)
    local pos = PlayerCoords(src)
    if not pos or not coords then return 9999.0 end
    return #(pos - vec3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0))
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
    local cached = itemLabelCache[item]
    if cached then return cached end
    local data = exports.ox_inventory:Items(item)
    local label = (data and data.label) or item
    itemLabelCache[item] = label
    return label
end

function IsDead(src)
    local player = GetPlayer(src)
    if not player then return true end
    local meta = player.PlayerData.metadata or {}
    return meta.isdead == true or meta.inlaststand == true
end

function FormatTime(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
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
        username = 'NEXUS Contracts',
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

function RandomToken()
    return ('%s%s'):format(math.random(100000, 999999), os.time())
end

function RateLimit(src, key)
    local cfg = Config.AntiExploit or {}
    local now = os.clock()
    local stampKey = ('%s:%s'):format(src, key)
    local last = lastCallback[stampKey]
    if last and (now - last) < (cfg.callbackWindow or 1.25) then
        return false
    end
    lastCallback[stampKey] = now

    local bucketKey = tostring(src)
    local bucket = rateBuckets[bucketKey]
    local window = 4.0
    if not bucket or (now - bucket.started) > window then
        rateBuckets[bucketKey] = { started = now, count = 1 }
        return true
    end
    bucket.count += 1
    if bucket.count > (cfg.maxCallbacksPerWindow or 8) then
        return false
    end
    return true
end

function GetAccountMoney(src, account)
    local player = GetPlayer(src)
    if not player then return 0 end
    local money = player.PlayerData.money or {}
    return money[account or Config.CashAccount] or 0
end

function RemoveAccountMoney(src, account, amount)
    local player = GetPlayer(src)
    if not player then return false end
    return player.Functions.RemoveMoney(account or Config.CashAccount, amount, 'nexus-store') == true
end

AddEventHandler('playerDropped', function()
    local src = source
    rateBuckets[tostring(src)] = nil
    for key in pairs(lastCallback) do
        if key:find('^' .. src .. ':') then
            lastCallback[key] = nil
        end
    end
end)
