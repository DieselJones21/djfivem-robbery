local shopPed
local shopBlip

local function spawnShop()
    if not Config.Store.enabled or not Config.Store.ped then return end
    local pedCfg = Config.Store.ped
    if not LoadModel(pedCfg.model) then return end
    local c = pedCfg.coords
    shopPed = CreatePed(4, joaat(pedCfg.model), c.x, c.y, c.z - 1.0, c.w or 0.0, false, true)
    SetEntityInvincible(shopPed, true)
    SetBlockingOfNonTemporaryEvents(shopPed, true)
    FreezeEntityPosition(shopPed, true)
    SetPedCanBeTargetted(shopPed, false)
    if pedCfg.scenario then
        TaskStartScenarioInPlace(shopPed, pedCfg.scenario, 0, true)
    end

    exports.ox_target:addLocalEntity(shopPed, {
        {
            name = 'dj_robbery:shop',
            icon = 'fa-solid fa-store',
            label = Config.Store.label or 'Black Market',
            distance = Config.Store.interactDistance or 2.4,
            onSelect = function()
                TriggerEvent('djfivem-robbery:client:openTablet', 'shop')
            end,
        },
    })

    if Config.Store.blip and Config.Store.blip.enabled then
        shopBlip = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(shopBlip, Config.Store.blip.sprite or 110)
        SetBlipColour(shopBlip, Config.Store.blip.color or 1)
        SetBlipScale(shopBlip, Config.Store.blip.scale or 0.75)
        SetBlipAsShortRange(shopBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Config.Store.blip.label or 'Black Market')
        EndTextCommandSetBlipName(shopBlip)
    end
end

CreateThread(function()
    spawnShop()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if shopPed and DoesEntityExist(shopPed) then
        exports.ox_target:removeLocalEntity(shopPed)
        DeleteEntity(shopPed)
    end
    if shopBlip and DoesBlipExist(shopBlip) then
        RemoveBlip(shopBlip)
    end
end)
