ActiveJob = nil
TargetZones = {}
SpawnedEntities = {}
boundEntities = {}

lib.locale(Config.Locale)

function NotifyClient(key, nType, ...)
    lib.notify({
        title = locale('tablet_title'),
        description = locale(key, ...),
        type = nType or 'inform',
    })
end

function LoadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then return false end
    lib.requestModel(hash, 5000)
    return HasModelLoaded(hash)
end

function LoadAnim(dict)
    lib.requestAnimDict(dict, 5000)
    return HasAnimDictLoaded(dict)
end

function PlayAnim(anim)
    if not anim then return end
    if LoadAnim(anim.dict) then
        TaskPlayAnim(cache.ped, anim.dict, anim.clip, 8.0, 8.0, -1, anim.flag or 49, 0.0, false, false, false)
    end
end

function StopAnim()
    ClearPedTasks(cache.ped)
end

function SetGps(coords)
    if not coords then return end
    SetNewWaypoint(coords.x + 0.0, coords.y + 0.0)
end

function Vec3(coords)
    if not coords then return nil end
    if type(coords) == 'vector3' then return coords end
    return vec3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
end

function WaitForNet(netId, timeout)
    timeout = timeout or 5000
    local expires = GetGameTimer() + timeout
    while GetGameTimer() < expires do
        if NetworkDoesEntityExistWithNetworkId(netId) then
            local ent = NetToEnt(netId)
            if ent and ent ~= 0 and DoesEntityExist(ent) then
                return ent
            end
        end
        Wait(50)
    end
    return 0
end

function DeleteLocalEntities(jobId)
    local bundle = SpawnedEntities[jobId]
    if bundle then
        if bundle.blips then
            for i = 1, #bundle.blips do
                if DoesBlipExist(bundle.blips[i]) then
                    RemoveBlip(bundle.blips[i])
                end
            end
        end
        if bundle.vehicle and DoesEntityExist(bundle.vehicle) then
            DeleteEntity(bundle.vehicle)
        end
        if bundle.peds then
            for i = 1, #bundle.peds do
                if DoesEntityExist(bundle.peds[i]) then
                    DeleteEntity(bundle.peds[i])
                end
            end
        end
        SpawnedEntities[jobId] = nil
    end
    for netId in pairs(boundEntities) do
        exports.ox_target:removeEntity(netId)
        boundEntities[netId] = nil
    end
end

function AddJobBlip(coords, sprite, colour, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite or 1)
    SetBlipColour(blip, colour or 1)
    SetBlipScale(blip, 0.85)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label or 'Contract')
    EndTextCommandSetBlipName(blip)
    return blip
end
