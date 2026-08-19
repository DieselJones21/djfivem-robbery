Crews = {}
PlayerCrew = {}
PendingInvites = {}

local crewSeq = 0

local function nextCrewId()
    crewSeq += 1
    return ('crew_%s_%s'):format(os.time(), crewSeq)
end

local function memberList(crew)
    local list = {}
    for src, member in pairs(crew.members) do
        list[#list + 1] = {
            source = src,
            name = member.name,
            host = src == crew.host,
        }
    end
    table.sort(list, function(a, b)
        if a.host ~= b.host then return a.host end
        return a.name < b.name
    end)
    return list
end

function GetCrew(src)
    local id = PlayerCrew[src]
    return id and Crews[id] or nil
end

function CrewSize(crew)
    local n = 0
    for _ in pairs(crew.members) do
        n += 1
    end
    return n
end

function EachCrewMember(crew, fn)
    for src in pairs(crew.members) do
        fn(src)
    end
end

function SerializeCrew(crew)
    if not crew then return nil end
    local loc = crew.locationId and GetRobberyLocation(crew.locationId)
    local typeCfg = loc and Config.Types[loc.type]
    return {
        id = crew.id,
        host = crew.host,
        locationId = crew.locationId,
        type = loc and loc.type or nil,
        maxPlayers = typeCfg and typeCfg.maxPlayers or 4,
        members = memberList(crew),
        jobId = crew.jobId,
    }
end

function CreateCrew(src, locationId)
    if PlayerCrew[src] then
        return false, 'already_in_crew'
    end
    local loc = GetRobberyLocation(locationId)
    if not loc then return false, 'invalid' end

    local id = nextCrewId()
    Crews[id] = {
        id = id,
        host = src,
        locationId = locationId,
        members = {
            [src] = { name = CharacterName(src) },
        },
        jobId = nil,
        createdAt = os.time(),
    }
    PlayerCrew[src] = id
    return true, Crews[id]
end

function LeaveCrew(src, silent)
    local crew = GetCrew(src)
    if not crew then return end

    crew.members[src] = nil
    PlayerCrew[src] = nil

    if crew.jobId then
        if src == crew.host or CrewSize(crew) == 0 then
            FailJob(crew.jobId, 'job_failed')
            return
        end
        local job = Jobs[crew.jobId]
        if job then
            job.members[src] = nil
        end
    end

    if CrewSize(crew) == 0 then
        Crews[crew.id] = nil
        return
    end

    if src == crew.host then
        local newHost = next(crew.members)
        crew.host = newHost
    end

    if not silent then
        Notify(src, 'left_crew', 'inform')
        EachCrewMember(crew, function(member)
            Notify(member, 'kicked', 'inform', CharacterName(src))
        end)
    end
end

function InviteToCrew(host, target)
    local crew = GetCrew(host)
    if not crew then return false, 'not_in_crew' end
    if crew.host ~= host then return false, 'not_host' end
    if crew.jobId then return false, 'location_busy' end
    if PlayerCrew[target] then return false, 'already_in_crew' end
    if not GetPlayer(target) then return false, 'invalid' end

    local loc = GetRobberyLocation(crew.locationId)
    local typeCfg = Config.Types[loc.type]
    if CrewSize(crew) >= typeCfg.maxPlayers then
        return false, 'crew_full'
    end

    if Distance(host, PlayerCoords(target)) > Config.InviteDistance then
        return false, 'too_far_invite'
    end

    PendingInvites[target] = {
        crewId = crew.id,
        from = host,
        expires = os.time() + 25,
    }

    TriggerClientEvent('djfivem-robbery:client:invite', target, {
        name = CharacterName(host),
        label = loc.label,
        size = CrewSize(crew),
        max = typeCfg.maxPlayers,
        crewId = crew.id,
    })

    return true
end

lib.callback.register('djfivem-robbery:server:inviteResponse', function(source, accepted)
    local pending = PendingInvites[source]
    PendingInvites[source] = nil
    if not pending then return false end
    if os.time() > pending.expires then return false end

    local crew = Crews[pending.crewId]
    if not crew or crew.jobId then
        Notify(source, 'location_busy', 'error')
        return false
    end

    if not accepted then
        Notify(pending.from, 'invite_declined', 'inform', CharacterName(source))
        return true
    end

    if PlayerCrew[source] then
        Notify(source, 'already_in_crew', 'error')
        return false
    end

    local loc = GetRobberyLocation(crew.locationId)
    local typeCfg = Config.Types[loc.type]
    if CrewSize(crew) >= typeCfg.maxPlayers then
        Notify(source, 'crew_full', 'error')
        return false
    end

    crew.members[source] = { name = CharacterName(source) }
    PlayerCrew[source] = crew.id
    EachCrewMember(crew, function(member)
        Notify(member, 'invite_accepted', 'success', CharacterName(source))
    end)
    return true
end)

AddEventHandler('playerDropped', function()
    local src = source
    PendingInvites[src] = nil
    LeaveCrew(src, true)
end)
