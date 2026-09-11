local shopStock = {}

local function itemByName(name)
    for i = 1, #Config.Store.items do
        if Config.Store.items[i].item == name then
            return Config.Store.items[i]
        end
    end
end

local function remainingStock(entry)
    if not entry.stock or entry.stock < 0 then return 9999 end
    local used = shopStock[entry.item] or 0
    return math.max(0, entry.stock - used)
end

function SerializeStore(src)
    if not Config.Store.enabled then
        return { enabled = false, items = {} }
    end
    local items = {}
    for i = 1, #Config.Store.items do
        local entry = Config.Store.items[i]
        items[#items + 1] = {
            item = entry.item,
            label = entry.label or ItemLabel(entry.item),
            description = entry.description or '',
            price = entry.price,
            stock = remainingStock(entry),
            infinite = not entry.stock or entry.stock < 0,
        }
    end
    local account = Config.Store.account or Config.CashAccount
    local balance = 0
    if Config.Store.useDirtyCash then
        balance = exports.ox_inventory:Search(src, 'count', Config.Items.dirtyCash) or 0
    else
        balance = GetAccountMoney(src, account)
    end
    return {
        enabled = true,
        label = Config.Store.label,
        subtitle = Config.Store.subtitle,
        account = account,
        useDirtyCash = Config.Store.useDirtyCash,
        balance = balance,
        maxQty = Config.Store.maxQty or Config.AntiExploit.maxShopQty or 10,
        items = items,
        ped = Config.Store.ped and {
            coords = Vec(Config.Store.ped.coords),
        } or nil,
    }
end

lib.callback.register('djfivem-robbery:server:buyItem', function(source, itemName, qty)
    if not RateLimit(source, 'buy') then
        return { ok = false, reason = 'rate_limited' }
    end
    if not Config.Store.enabled then
        return { ok = false, reason = 'shop_disabled' }
    end
    if IsOnDutyPolice(source) then
        return { ok = false, reason = 'police_blocked' }
    end

    qty = math.floor(tonumber(qty) or 0)
    local maxQty = math.min(Config.Store.maxQty or 10, Config.AntiExploit.maxShopQty or 20)
    if qty < 1 or qty > maxQty then
        return { ok = false, reason = 'shop_invalid' }
    end

    local entry = itemByName(itemName)
    if not entry then
        return { ok = false, reason = 'shop_invalid' }
    end

    if Config.Store.requireProximity and Config.Store.ped then
        if Distance(source, Config.Store.ped.coords) > (Config.Store.interactDistance or 2.4) + 2.0 then
            return { ok = false, reason = 'shop_too_far' }
        end
    end

    if remainingStock(entry) < qty then
        return { ok = false, reason = 'shop_stock' }
    end

    local price = (entry.price or 0) * qty
    if price < 0 then
        return { ok = false, reason = 'shop_invalid' }
    end

    if Config.Store.useDirtyCash then
        if not HasItem(source, Config.Items.dirtyCash, price) then
            return { ok = false, reason = 'shop_broke' }
        end
        if not exports.ox_inventory:RemoveItem(source, Config.Items.dirtyCash, price) then
            return { ok = false, reason = 'shop_broke' }
        end
    else
        local account = Config.Store.account or Config.CashAccount
        if GetAccountMoney(source, account) < price then
            return { ok = false, reason = 'shop_broke' }
        end
        if not RemoveAccountMoney(source, account, price) then
            return { ok = false, reason = 'shop_broke' }
        end
    end

    local added = exports.ox_inventory:AddItem(source, entry.item, qty)
    if not added then
        if Config.Store.useDirtyCash then
            exports.ox_inventory:AddItem(source, Config.Items.dirtyCash, price)
        else
            local player = GetPlayer(source)
            if player then
                player.Functions.AddMoney(Config.Store.account or Config.CashAccount, price, 'nexus-store-refund')
            end
        end
        return { ok = false, reason = 'shop_invalid' }
    end

    if entry.stock and entry.stock >= 0 then
        shopStock[entry.item] = (shopStock[entry.item] or 0) + qty
    end

    SendWebhook('Store purchase', ('%s bought %sx %s ($%s)'):format(CharacterName(source), qty, entry.item, price))
    return {
        ok = true,
        label = entry.label or ItemLabel(entry.item),
        qty = qty,
        store = SerializeStore(source),
    }
end)
