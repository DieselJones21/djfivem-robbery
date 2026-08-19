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

function RunMinigame(interaction)
    if interaction.skill then
        local ok = SkillCheck(interaction.skill)
        if not ok then
            NotifyClient('hack_fail', 'error')
            return false
        end
    end
    return Progress(interaction.label, interaction.duration, interaction.anim)
end
