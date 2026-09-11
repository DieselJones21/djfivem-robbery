local minigamePromise

function SkillCheck(skill)
    if not skill then return true end
    return lib.skillCheck(skill, Config.Skill.keys)
end

function Progress(label, duration, anim)
    local data = {
        duration = duration or 5000,
        label = label or 'Working...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    }
    if anim then
        data.anim = {
            dict = anim.dict,
            clip = anim.clip,
            flag = anim.flag or 49,
        }
    end
    return lib.progressBar(data)
end

function RunNuiMinigame(kind)
    if minigamePromise then return false end
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'minigame',
        kind = kind,
        config = Config.Minigames,
    })
    minigamePromise = promise.new()
    local ok = Citizen.Await(minigamePromise)
    minigamePromise = nil
    SetNuiFocus(false, false)
    return ok == true
end

RegisterNUICallback('minigameResult', function(body, cb)
    if minigamePromise then
        minigamePromise:resolve(body and body.ok == true)
    end
    cb({ ok = true })
end)

function RunMinigame(interaction)
    local kind = interaction.minigame or 'skill'
    local ok = true

    if kind == 'keypad' or kind == 'thermite' or kind == 'circuit' then
        ok = RunNuiMinigame(kind)
        if not ok then
            NotifyClient('minigame_fail', 'error')
            return false
        end
    elseif interaction.skill then
        ok = SkillCheck(interaction.skill)
        if not ok then
            NotifyClient('hack_fail', 'error')
            return false
        end
    end

    return Progress(interaction.label, interaction.duration, interaction.anim)
end
