local I = Config.Items

local function lootCash(min, max, extra)
    local rewards = {
        { type = 'item', name = I.dirtyCash, min = min, max = max },
    }
    if extra then
        for i = 1, #extra do
            rewards[#rewards + 1] = extra[i]
        end
    end
    return rewards
end

local function jewelryExtra()
    return {
        { type = 'item', name = I.goldwatch, min = 1, max = 3, chance = 70 },
        { type = 'item', name = I.diamond, min = 1, max = 2, chance = 28 },
        { type = 'item', name = I.goldbar, min = 1, max = 1, chance = 18 },
    }
end

local function lockerExtra()
    return {
        { type = 'item', name = I.goldbar, min = 1, max = 2, chance = 38 },
        { type = 'item', name = I.goldwatch, min = 1, max = 3, chance = 52 },
    }
end

local function guardSet(opts)
    if not opts then return nil end
    return {
        enabled = opts.enabled ~= false,
        spawnOn = opts.spawnOn or 'alarm',
        model = opts.model or Config.Guards.defaultModel,
        weapon = opts.weapon or Config.Guards.defaultWeapon,
        accuracy = opts.accuracy or Config.Guards.accuracy,
        armour = opts.armour or Config.Guards.armour,
        health = opts.health or Config.Guards.health,
        peds = opts.peds or {},
    }
end

local function bankJob(opts)
    local lockers = {}
    for i, coords in ipairs(opts.lockers) do
        lockers[#lockers + 1] = {
            id = ('locker_%s'):format(i),
            kind = 'loot',
            coords = coords,
            label = 'Loot deposit box',
            icon = 'box-open',
            duration = 9000,
            anim = Config.Anims.loot,
            requires = { 'vault' },
            minigame = 'skill',
            skill = { 'medium' },
            rewards = lootCash(opts.lockerMin, opts.lockerMax, lockerExtra()),
        }
    end

    local interactions = {
        {
            id = 'hack',
            kind = 'hack',
            coords = opts.hack,
            label = 'Hack security keypad',
            icon = 'laptop-code',
            item = I.hack,
            consumeChance = 40,
            minigame = 'circuit',
            skill = Config.Skill.bankHack,
            duration = 8500,
            anim = Config.Anims.hack,
            alertsPolice = true,
        },
        {
            id = 'vault',
            kind = 'breach',
            coords = opts.vault,
            label = 'Plant thermite on vault',
            icon = 'bomb',
            item = I.thermite,
            consumeChance = 100,
            minigame = 'thermite',
            skill = Config.Skill.bankVault,
            duration = 12000,
            anim = Config.Anims.thermite,
            requires = { 'hack' },
        },
    }

    for i = 1, #lockers do
        interactions[#interactions + 1] = lockers[i]
    end

    return {
        id = opts.id,
        type = 'bank',
        label = opts.label,
        description = 'Hack the panel, burn the vault, then split the boxes before security stacks.',
        coords = opts.gps,
        heading = opts.heading or 0.0,
        cooldown = opts.cooldown or Config.Types.bank.cooldown,
        minPolice = opts.minPolice or Config.Types.bank.minPolice,
        requiredItems = Config.Types.bank.requiredItems,
        payoutLabel = opts.payoutLabel,
        difficulty = Config.Types.bank.difficulty,
        vaultDoor = opts.vaultDoor,
        guards = guardSet(opts.guards),
        interactions = interactions,
        stages = { 'Hack keypad', 'Thermite vault', 'Loot deposit boxes' },
    }
end

local function storeJob(opts)
    local interactions = {}
    for i, coords in ipairs(opts.registers) do
        interactions[#interactions + 1] = {
            id = ('register_%s'):format(i),
            kind = 'hack',
            coords = coords,
            label = 'Empty cash register',
            icon = 'cash-register',
            item = I.lockpick,
            consumeChance = 50,
            minigame = 'skill',
            skill = Config.Skill.storeRegister,
            duration = 7000,
            anim = Config.Anims.lockpick,
            alertsPolice = i == 1,
            rewards = lootCash(450, 1100),
        }
    end

    interactions[#interactions + 1] = {
        id = 'safe',
        kind = 'breach',
        coords = opts.safe,
        label = 'Crack the office safe',
        icon = 'vault',
        item = I.drill,
        consumeChance = 30,
        minigame = 'keypad',
        skill = Config.Skill.storeSafe,
        duration = 15000,
        anim = Config.Anims.drill,
        requires = { 'register_1' },
        rewards = lootCash(opts.safeMin or 2800, opts.safeMax or 5600),
    }

    return {
        id = opts.id,
        type = 'store',
        label = opts.label,
        description = 'Clean the tills, then drill the office safe before units roll up.',
        coords = opts.gps,
        cooldown = Config.Types.store.cooldown,
        minPolice = Config.Types.store.minPolice,
        requiredItems = Config.Types.store.requiredItems,
        payoutLabel = opts.payoutLabel or '$3,200 – $7,800',
        difficulty = Config.Types.store.difficulty,
        guards = guardSet(opts.guards),
        interactions = interactions,
        stages = { 'Empty registers', 'Drill office safe' },
    }
end

local function atmJob(opts)
    return {
        id = opts.id,
        type = 'atm',
        label = opts.label,
        description = 'Drill the cassette and grab the cash before patrols close the street.',
        coords = opts.coords,
        cooldown = Config.Types.atm.cooldown,
        minPolice = Config.Types.atm.minPolice,
        requiredItems = Config.Types.atm.requiredItems,
        payoutLabel = '$1,400 – $2,800',
        difficulty = Config.Types.atm.difficulty,
        interactions = {
            {
                id = 'drill',
                kind = 'breach',
                coords = opts.coords,
                label = 'Drill ATM',
                icon = 'screwdriver-wrench',
                item = I.drill,
                consumeChance = 25,
                minigame = 'skill',
                skill = Config.Skill.atm,
                duration = 13000,
                anim = Config.Anims.drill,
                alertsPolice = true,
                rewards = lootCash(1400, 2800),
            },
        },
        stages = { 'Drill cassette' },
    }
end

local function ammuJob(opts)
    local interactions = {
        {
            id = 'hack',
            kind = 'hack',
            coords = opts.hack,
            label = 'Disable store security',
            icon = 'laptop-code',
            item = I.hack,
            consumeChance = 35,
            minigame = 'circuit',
            skill = Config.Skill.ammuHack,
            duration = 8000,
            anim = Config.Anims.hack,
            alertsPolice = true,
        },
    }

    for i, coords in ipairs(opts.cases) do
        interactions[#interactions + 1] = {
            id = ('case_%s'):format(i),
            kind = 'loot',
            coords = coords,
            label = 'Smash display case',
            icon = 'hammer',
            item = I.crowbar,
            consumeChance = 12,
            minigame = 'skill',
            skill = Config.Skill.ammuCase,
            duration = 5500,
            anim = Config.Anims.smash,
            requires = { 'hack' },
            rewards = {
                { type = 'item', name = 'ammo-9', min = 24, max = 60, chance = 85 },
                { type = 'item', name = 'WEAPON_SNSPISTOL', min = 1, max = 1, chance = 16 },
                { type = 'item', name = I.dirtyCash, min = 500, max = 1100, chance = 100 },
            },
        }
    end

    interactions[#interactions + 1] = {
        id = 'locker',
        kind = 'loot',
        coords = opts.locker,
        label = 'Drill weapon locker',
        icon = 'gun',
        item = I.drill,
        consumeChance = 35,
        minigame = 'thermite',
        skill = Config.Skill.ammuLocker,
        duration = 14000,
        anim = Config.Anims.drill,
        requires = { 'hack' },
        rewards = {
            { type = 'item', name = 'WEAPON_PISTOL', min = 1, max = 1, chance = 58 },
            { type = 'item', name = 'WEAPON_COMBATPISTOL', min = 1, max = 1, chance = 22 },
            { type = 'item', name = 'ammo-9', min = 40, max = 80, chance = 100 },
            { type = 'item', name = I.dirtyCash, min = 2200, max = 4200, chance = 100 },
        },
    }

    return {
        id = opts.id,
        type = 'ammunation',
        label = opts.label,
        description = 'Kill cameras, smash cases, drill the locker. Armed security on site.',
        coords = opts.gps,
        cooldown = Config.Types.ammunation.cooldown,
        minPolice = Config.Types.ammunation.minPolice,
        requiredItems = Config.Types.ammunation.requiredItems,
        payoutLabel = 'Guns, ammo, $2,700 – $6,000',
        difficulty = Config.Types.ammunation.difficulty,
        guards = guardSet(opts.guards),
        interactions = interactions,
        stages = { 'Disable cameras', 'Smash cases', 'Drill locker' },
    }
end

local function houseJob(opts)
    local interactions = {
        {
            id = 'door',
            kind = 'hack',
            coords = opts.door,
            label = 'Lockpick the door',
            icon = 'key',
            item = I.lockpick,
            consumeChance = 55,
            minigame = 'skill',
            skill = Config.Skill.houseDoor,
            duration = 8000,
            anim = Config.Anims.lockpick,
            alertsPolice = true,
        },
    }
    for i, coords in ipairs(opts.loot) do
        interactions[#interactions + 1] = {
            id = ('room_%s'):format(i),
            kind = 'loot',
            coords = coords,
            label = opts.lootLabels and opts.lootLabels[i] or 'Search the room',
            icon = 'box-open',
            item = I.crowbar,
            consumeChance = 8,
            minigame = 'skill',
            skill = Config.Skill.houseLoot,
            duration = 6500,
            anim = Config.Anims.loot,
            requires = { 'door' },
            rewards = lootCash(opts.lootMin or 900, opts.lootMax or 2200, {
                { type = 'item', name = I.goldwatch, min = 1, max = 2, chance = 40 },
                { type = 'item', name = 'trojan_usb', min = 1, max = 1, chance = 12 },
            }),
        }
    end
    return {
        id = opts.id,
        type = 'house',
        label = opts.label,
        description = 'Quiet entry, search every room, leave before the alarm stacks units.',
        coords = opts.gps,
        cooldown = Config.Types.house.cooldown,
        minPolice = Config.Types.house.minPolice,
        requiredItems = Config.Types.house.requiredItems,
        payoutLabel = opts.payoutLabel or '$4,000 – $9,000',
        difficulty = Config.Types.house.difficulty,
        guards = guardSet(opts.guards),
        interactions = interactions,
        stages = { 'Lockpick door', 'Search rooms' },
    }
end

Config.Locations = {
    -- Fleeca / Paleto
    bankJob({
        id = 'fleeca_legion',
        label = 'Fleeca — Legion Square',
        gps = vector3(150.87, -1037.16, 29.34),
        heading = 160.0,
        payoutLabel = '$42,000 – $95,000',
        lockerMin = 8500,
        lockerMax = 15500,
        hack = vector3(147.35, -1046.24, 29.37),
        vault = vector3(148.03, -1044.36, 29.51),
        vaultDoor = {
            model = `v_ilev_gb_vauldr`,
            coords = vector3(148.03, -1044.36, 29.51),
            closed = 249.85,
            open = 160.0,
        },
        lockers = {
            vector3(146.48, -1048.44, 29.34),
            vector3(148.10, -1051.24, 29.34),
            vector3(150.77, -1050.02, 29.34),
            vector3(149.78, -1044.55, 29.34),
        },
        guards = {
            spawnOn = 'alarm',
            weapon = 'WEAPON_COMBATPISTOL',
            peds = {
                vector4(151.90, -1036.40, 29.34, 160.0),
                vector4(145.20, -1041.80, 29.37, 250.0),
            },
        },
    }),
    bankJob({
        id = 'fleeca_alta',
        label = 'Fleeca — Alta',
        gps = vector3(315.32, -275.55, 53.92),
        heading = 160.0,
        payoutLabel = '$42,000 – $95,000',
        lockerMin = 8500,
        lockerMax = 15500,
        hack = vector3(311.69, -284.55, 54.16),
        vault = vector3(312.36, -282.73, 54.30),
        vaultDoor = {
            model = `v_ilev_gb_vauldr`,
            coords = vector3(312.36, -282.73, 54.30),
            closed = 249.86,
            open = 160.0,
        },
        lockers = {
            vector3(310.70, -286.80, 54.14),
            vector3(312.50, -289.59, 54.14),
            vector3(315.26, -288.29, 54.14),
            vector3(314.25, -282.97, 54.14),
        },
        guards = {
            spawnOn = 'alarm',
            weapon = 'WEAPON_COMBATPISTOL',
            peds = {
                vector4(314.20, -278.90, 54.17, 160.0),
                vector4(309.80, -280.40, 54.16, 250.0),
            },
        },
    }),
    bankJob({
        id = 'fleeca_burton',
        label = 'Fleeca — Burton',
        gps = vector3(-349.89, -46.44, 49.04),
        heading = 160.0,
        payoutLabel = '$42,000 – $95,000',
        lockerMin = 8500,
        lockerMax = 15500,
        hack = vector3(-353.52, -55.47, 49.20),
        vault = vector3(-352.74, -53.57, 49.18),
        vaultDoor = {
            model = `v_ilev_gb_vauldr`,
            coords = vector3(-352.74, -53.57, 49.18),
            closed = 250.85,
            open = 160.0,
        },
        lockers = {
            vector3(-354.30, -57.70, 49.01),
            vector3(-352.51, -60.42, 49.01),
            vector3(-349.62, -59.11, 49.01),
            vector3(-350.79, -53.70, 49.01),
        },
        guards = {
            spawnOn = 'alarm',
            weapon = 'WEAPON_COMBATPISTOL',
            peds = {
                vector4(-348.40, -49.10, 49.04, 160.0),
                vector4(-355.10, -50.80, 49.04, 250.0),
            },
        },
    }),

    -- Paleto (harder, own type)
    {
        id = 'paleto_savings',
        type = 'paleto',
        label = 'Blaine County Savings — Paleto',
        description = 'Cut the rear power, thermite the vault, drill leftover boxes. County security is armed.',
        coords = vector3(-110.94, 6462.53, 31.64),
        heading = 45.0,
        cooldown = Config.Types.paleto.cooldown,
        minPolice = Config.Types.paleto.minPolice,
        requiredItems = Config.Types.paleto.requiredItems,
        payoutLabel = '$70,000 – $140,000',
        difficulty = Config.Types.paleto.difficulty,
        vaultDoor = {
            model = `v_ilev_cbankvauldoor`,
            coords = vector3(-104.60, 6473.44, 31.80),
            closed = 45.0,
            open = 150.0,
        },
        stages = { 'Cut power', 'Hack keypad', 'Thermite vault', 'Loot boxes' },
        guards = guardSet({
            spawnOn = 'start',
            model = 's_m_m_armoured_01',
            weapon = 'WEAPON_CARBINERIFLE',
            accuracy = 48,
            armour = 80,
            peds = {
                vector4(-109.40, 6461.20, 31.64, 45.0),
                vector4(-105.20, 6468.80, 31.63, 220.0),
                vector4(-115.80, 6468.10, 31.63, 310.0),
                vector4(-97.90, 6465.40, 31.63, 140.0),
            },
        }),
        interactions = {
            {
                id = 'power',
                kind = 'hack',
                coords = vector3(-93.80, 6471.90, 31.63),
                label = 'Cut security power',
                icon = 'bolt',
                item = I.hack,
                consumeChance = 30,
                minigame = 'circuit',
                skill = Config.Skill.paletoPower,
                duration = 9000,
                anim = Config.Anims.hack,
                alertsPolice = true,
            },
            {
                id = 'hack',
                kind = 'hack',
                coords = vector3(-105.90, 6472.11, 31.90),
                label = 'Hack vault keypad',
                icon = 'laptop-code',
                item = I.hack,
                consumeChance = 40,
                minigame = 'keypad',
                skill = Config.Skill.bankHack,
                duration = 8000,
                anim = Config.Anims.hack,
                requires = { 'power' },
            },
            {
                id = 'vault',
                kind = 'breach',
                coords = vector3(-105.51, 6475.23, 32.00),
                label = 'Plant thermite on vault',
                icon = 'bomb',
                item = I.thermite,
                consumeChance = 100,
                minigame = 'thermite',
                skill = Config.Skill.paletoVault,
                duration = 13000,
                anim = Config.Anims.thermite,
                requires = { 'hack' },
            },
            {
                id = 'locker_1',
                kind = 'loot',
                coords = vector3(-102.59, 6475.23, 31.62),
                label = 'Loot deposit box',
                icon = 'box-open',
                duration = 9000,
                anim = Config.Anims.loot,
                requires = { 'vault' },
                item = I.drill,
                consumeChance = 20,
                minigame = 'skill',
                skill = { 'medium', 'hard' },
                rewards = lootCash(12000, 20000, lockerExtra()),
            },
            {
                id = 'locker_2',
                kind = 'loot',
                coords = vector3(-103.08, 6478.67, 31.62),
                label = 'Loot deposit box',
                icon = 'box-open',
                duration = 9000,
                anim = Config.Anims.loot,
                requires = { 'vault' },
                rewards = lootCash(12000, 20000, lockerExtra()),
            },
            {
                id = 'locker_3',
                kind = 'loot',
                coords = vector3(-106.88, 6478.35, 31.62),
                label = 'Loot deposit box',
                icon = 'box-open',
                duration = 9000,
                anim = Config.Anims.loot,
                requires = { 'vault' },
                rewards = lootCash(12000, 20000, lockerExtra()),
            },
            {
                id = 'locker_4',
                kind = 'loot',
                coords = vector3(-107.31, 6473.15, 31.62),
                label = 'Loot trolley',
                icon = 'box-open',
                duration = 10000,
                anim = Config.Anims.loot,
                requires = { 'vault' },
                rewards = lootCash(14000, 24000, lockerExtra()),
            },
        },
    },

    -- Pacific Standard
    {
        id = 'pacific_standard',
        type = 'pacific',
        label = 'Pacific Standard — Downtown',
        description = 'Kill rooftop power, crack the inner pad, C4 the vault, empty every trolley.',
        coords = vector3(235.57, 216.95, 106.29),
        cooldown = Config.Types.pacific.cooldown,
        minPolice = Config.Types.pacific.minPolice,
        requiredItems = Config.Types.pacific.requiredItems,
        payoutLabel = '$180,000 – $320,000',
        difficulty = Config.Types.pacific.difficulty,
        stages = { 'Cut rooftop power', 'Hack inner keypad', 'C4 vault', 'Loot trolleys' },
        vaultDoor = {
            model = `v_ilev_bk_vaultdoor`,
            coords = vector3(255.23, 224.00, 101.88),
            closed = 160.0,
            open = 70.0,
        },
        guards = guardSet({
            spawnOn = 'start',
            model = 's_m_m_armoured_02',
            weapon = 'WEAPON_CARBINERIFLE',
            accuracy = 55,
            armour = 100,
            health = 250,
            peds = {
                vector4(237.40, 215.10, 106.29, 120.0),
                vector4(232.10, 214.80, 106.29, 250.0),
                vector4(256.80, 218.40, 106.29, 70.0),
                vector4(261.90, 205.70, 110.29, 20.0),
                vector4(252.40, 228.60, 101.68, 340.0),
                vector4(247.10, 225.40, 101.68, 160.0),
            },
        }),
        interactions = {
            {
                id = 'power',
                kind = 'hack',
                coords = vector3(259.90, 204.50, 110.29),
                label = 'Sabotage rooftop power',
                icon = 'bolt',
                item = I.laptop,
                consumeChance = 25,
                minigame = 'circuit',
                skill = Config.Skill.pacificPower,
                duration = 11000,
                anim = Config.Anims.hack,
                alertsPolice = true,
            },
            {
                id = 'hack',
                kind = 'hack',
                coords = vector3(261.70, 223.10, 106.28),
                label = 'Crack inner keypad',
                icon = 'laptop-code',
                item = I.hack,
                consumeChance = 45,
                minigame = 'keypad',
                skill = Config.Skill.pacificPad,
                duration = 10000,
                anim = Config.Anims.hack,
                requires = { 'power' },
            },
            {
                id = 'vault',
                kind = 'breach',
                coords = vector3(255.23, 224.00, 101.88),
                label = 'Plant C4 on vault',
                icon = 'bomb',
                item = I.c4,
                consumeChance = 100,
                minigame = 'thermite',
                skill = Config.Skill.pacificVault,
                duration = 14000,
                anim = Config.Anims.plant,
                requires = { 'hack' },
            },
            {
                id = 'trolley_1',
                kind = 'loot',
                coords = vector3(252.80, 222.10, 101.68),
                label = 'Grab cash trolley',
                icon = 'box-open',
                duration = 11000,
                anim = Config.Anims.loot,
                requires = { 'vault' },
                rewards = lootCash(28000, 42000, lockerExtra()),
            },
            {
                id = 'trolley_2',
                kind = 'loot',
                coords = vector3(249.90, 226.40, 101.68),
                label = 'Grab cash trolley',
                icon = 'box-open',
                duration = 11000,
                anim = Config.Anims.loot,
                requires = { 'vault' },
                rewards = lootCash(28000, 42000, lockerExtra()),
            },
            {
                id = 'trolley_3',
                kind = 'loot',
                coords = vector3(247.20, 220.80, 101.68),
                label = 'Grab gold trolley',
                icon = 'box-open',
                duration = 12000,
                anim = Config.Anims.loot,
                requires = { 'vault' },
                rewards = lootCash(22000, 36000, {
                    { type = 'item', name = I.goldbar, min = 2, max = 4, chance = 80 },
                    { type = 'item', name = I.diamond, min = 1, max = 3, chance = 45 },
                }),
            },
            {
                id = 'trolley_4',
                kind = 'loot',
                coords = vector3(244.80, 226.00, 101.68),
                label = 'Grab cash trolley',
                icon = 'box-open',
                duration = 11000,
                anim = Config.Anims.loot,
                requires = { 'vault' },
                rewards = lootCash(26000, 40000, lockerExtra()),
            },
        },
    },

    -- Vangelico
    {
        id = 'vangelico_rockford',
        type = 'jewelry',
        label = 'Vangelico — Rockford Hills',
        description = 'Bypass gallery security, smash every case, thermite the office safe.',
        coords = vector3(-622.26, -230.90, 38.06),
        cooldown = Config.Types.jewelry.cooldown,
        minPolice = Config.Types.jewelry.minPolice,
        requiredItems = Config.Types.jewelry.requiredItems,
        payoutLabel = '$55,000 – $110,000',
        difficulty = Config.Types.jewelry.difficulty,
        stages = { 'Hack gallery alarm', 'Smash displays', 'Thermite office safe' },
        guards = guardSet({
            spawnOn = 'alarm',
            model = 's_m_y_doorman_01',
            weapon = 'WEAPON_PUMPSHOTGUN',
            accuracy = 50,
            armour = 60,
            peds = {
                vector4(-628.90, -235.20, 38.06, 35.0),
                vector4(-623.40, -228.80, 38.06, 210.0),
                vector4(-620.10, -237.70, 38.06, 300.0),
                vector4(-631.40, -229.10, 38.06, 120.0),
            },
        }),
        interactions = {
            {
                id = 'hack',
                kind = 'hack',
                coords = vector3(-631.02, -230.06, 38.06),
                label = 'Disable gallery alarm',
                icon = 'laptop-code',
                item = I.hack,
                consumeChance = 40,
                minigame = 'circuit',
                skill = Config.Skill.jewelryHack,
                duration = 9000,
                anim = Config.Anims.hack,
                alertsPolice = true,
            },
            {
                id = 'case_1',
                kind = 'loot',
                coords = vector3(-626.72, -238.54, 38.06),
                label = 'Smash jewelry case',
                icon = 'gem',
                item = I.crowbar,
                consumeChance = 10,
                minigame = 'skill',
                skill = Config.Skill.jewelryCase,
                duration = 5500,
                anim = Config.Anims.smash,
                requires = { 'hack' },
                rewards = lootCash(3500, 6200, jewelryExtra()),
            },
            {
                id = 'case_2',
                kind = 'loot',
                coords = vector3(-625.28, -227.43, 38.06),
                label = 'Smash jewelry case',
                icon = 'gem',
                item = I.crowbar,
                consumeChance = 10,
                minigame = 'skill',
                skill = Config.Skill.jewelryCase,
                duration = 5500,
                anim = Config.Anims.smash,
                requires = { 'hack' },
                rewards = lootCash(3500, 6200, jewelryExtra()),
            },
            {
                id = 'case_3',
                kind = 'loot',
                coords = vector3(-620.22, -234.38, 38.06),
                label = 'Smash jewelry case',
                icon = 'gem',
                item = I.crowbar,
                consumeChance = 10,
                minigame = 'skill',
                skill = Config.Skill.jewelryCase,
                duration = 5500,
                anim = Config.Anims.smash,
                requires = { 'hack' },
                rewards = lootCash(3500, 6200, jewelryExtra()),
            },
            {
                id = 'case_4',
                kind = 'loot',
                coords = vector3(-617.52, -230.43, 38.06),
                label = 'Smash jewelry case',
                icon = 'gem',
                item = I.crowbar,
                consumeChance = 10,
                minigame = 'skill',
                skill = Config.Skill.jewelryCase,
                duration = 5500,
                anim = Config.Anims.smash,
                requires = { 'hack' },
                rewards = lootCash(3500, 6200, jewelryExtra()),
            },
            {
                id = 'safe',
                kind = 'breach',
                coords = vector3(-622.26, -216.52, 38.06),
                label = 'Thermite office safe',
                icon = 'vault',
                item = I.thermite,
                consumeChance = 100,
                minigame = 'thermite',
                skill = Config.Skill.jewelrySafe,
                duration = 13000,
                anim = Config.Anims.thermite,
                requires = { 'hack' },
                rewards = lootCash(12000, 22000, {
                    { type = 'item', name = I.diamond, min = 2, max = 4, chance = 70 },
                    { type = 'item', name = I.goldbar, min = 1, max = 2, chance = 50 },
                }),
            },
        },
    },

    -- Stores
    storeJob({
        id = 'store_grove',
        label = 'LTD — Grove Street',
        gps = vector3(-47.20, -1757.70, 29.42),
        registers = { vector3(-47.24, -1757.65, 29.53), vector3(-48.58, -1759.21, 29.59) },
        safe = vector3(-43.43, -1748.30, 29.42),
    }),
    storeJob({
        id = 'store_innocence',
        label = '24/7 — Innocence Blvd',
        gps = vector3(25.70, -1346.80, 29.50),
        registers = { vector3(24.47, -1344.99, 29.49), vector3(24.45, -1347.37, 29.49) },
        safe = vector3(28.21, -1339.14, 29.49),
    }),
    storeJob({
        id = 'store_seoul',
        label = 'LTD — Little Seoul',
        gps = vector3(-706.10, -914.50, 19.22),
        registers = { vector3(-706.08, -915.42, 19.21), vector3(-706.16, -913.50, 19.21) },
        safe = vector3(-709.74, -904.15, 19.21),
    }),
    storeJob({
        id = 'store_vinewood',
        label = '24/7 — Downtown Vinewood',
        gps = vector3(373.80, 327.90, 103.57),
        registers = { vector3(373.14, 328.62, 103.56), vector3(372.57, 326.42, 103.56) },
        safe = vector3(378.17, 333.44, 103.56),
    }),
    storeJob({
        id = 'store_sandy',
        label = '24/7 — Sandy Shores',
        gps = vector3(1960.20, 3741.50, 32.34),
        registers = { vector3(1958.96, 3741.98, 32.34), vector3(1960.13, 3740.00, 32.34) },
        safe = vector3(1959.26, 3748.92, 32.34),
    }),
    storeJob({
        id = 'store_paleto',
        label = '24/7 — Paleto Bay',
        gps = vector3(161.20, 6641.90, 31.70),
        registers = { vector3(160.52, 6641.74, 31.60), vector3(162.16, 6643.22, 31.60) },
        safe = vector3(168.95, 6644.74, 31.70),
    }),

    -- Houses
    houseJob({
        id = 'house_grove',
        label = 'Grove bungalow',
        gps = vector3(-14.17, -1441.18, 31.10),
        door = vector3(-14.17, -1441.18, 31.10),
        loot = {
            vector3(-9.50, -1433.40, 31.10),
            vector3(-17.80, -1432.20, 31.10),
            vector3(-11.40, -1428.60, 31.10),
        },
        lootLabels = { 'Search living room', 'Search bedroom', 'Crack jewelry box' },
        payoutLabel = '$4,200 – $8,500',
        guards = {
            spawnOn = 'alarm',
            model = 'a_m_m_eastsa_02',
            weapon = 'WEAPON_PISTOL',
            peds = { vector4(-6.80, -1435.90, 31.10, 90.0) },
        },
    }),
    houseJob({
        id = 'house_mirror',
        label = 'Mirror Park residence',
        gps = vector3(1259.55, -1761.90, 49.66),
        door = vector3(1259.55, -1761.90, 49.66),
        loot = {
            vector3(1264.20, -1757.10, 49.66),
            vector3(1256.40, -1754.80, 49.66),
            vector3(1261.80, -1752.40, 49.66),
        },
        lootLabels = { 'Search office', 'Search bedroom', 'Loot cabinet' },
        payoutLabel = '$5,000 – $9,800',
        guards = {
            spawnOn = 'alarm',
            model = 'a_m_y_hipster_01',
            weapon = 'WEAPON_PISTOL',
            peds = { vector4(1254.10, -1762.80, 49.66, 30.0) },
        },
    }),
    houseJob({
        id = 'house_paleto',
        label = 'Paleto cabin',
        gps = vector3(-360.80, 6260.55, 31.90),
        door = vector3(-360.80, 6260.55, 31.90),
        loot = {
            vector3(-364.10, 6264.20, 31.90),
            vector3(-357.40, 6265.10, 31.90),
            vector3(-362.20, 6268.40, 31.90),
        },
        lootLabels = { 'Search kitchen', 'Search bedroom', 'Loot gun cabinet' },
        payoutLabel = '$4,800 – $9,200',
        guards = {
            spawnOn = 'start',
            model = 'a_m_m_hillbilly_01',
            weapon = 'WEAPON_PUMPSHOTGUN',
            peds = { vector4(-355.20, 6261.80, 31.90, 220.0) },
        },
    }),
    houseJob({
        id = 'house_vinewood',
        label = 'Vinewood Hills terrace',
        gps = vector3(232.84, 672.21, 189.95),
        door = vector3(232.84, 672.21, 189.95),
        loot = {
            vector3(228.40, 676.80, 189.95),
            vector3(235.90, 678.20, 189.95),
            vector3(230.10, 681.40, 189.95),
        },
        lootLabels = { 'Search lounge', 'Crack wall safe', 'Loot closet' },
        lootMin = 1400,
        lootMax = 3200,
        payoutLabel = '$6,500 – $12,000',
        guards = {
            spawnOn = 'alarm',
            model = 's_m_y_doorman_01',
            weapon = 'WEAPON_COMBATPISTOL',
            peds = {
                vector4(229.10, 669.40, 189.95, 10.0),
                vector4(237.40, 670.80, 189.95, 280.0),
            },
        },
    }),

    -- ATMs
    atmJob({ id = 'atm_legion', label = 'ATM — Legion Square', coords = vector3(147.47, -1035.68, 29.34) }),
    atmJob({ id = 'atm_pillbox', label = 'ATM — Pillbox Hospital', coords = vector3(296.47, -591.31, 43.27) }),
    atmJob({ id = 'atm_paleto', label = 'ATM — Paleto Bay', coords = vector3(-386.73, 6046.08, 31.50) }),
    atmJob({ id = 'atm_grove', label = 'ATM — Grove LTD', coords = vector3(-56.72, -1752.12, 29.42) }),
    atmJob({ id = 'atm_sandy', label = 'ATM — Sandy 24/7', coords = vector3(1968.17, 3743.55, 32.34) }),
    atmJob({ id = 'atm_vinewood', label = 'ATM — Vinewood 24/7', coords = vector3(380.78, 323.40, 103.57) }),

    -- Vehicles
    {
        id = 'veh_sultan_city',
        type = 'vehicle',
        label = 'Sultan — La Mesa lot',
        description = 'Lockpick the marked Sultan and drop it at the docks warehouse.',
        coords = vector3(915.21, -1554.38, 30.75),
        cooldown = Config.Types.vehicle.cooldown,
        minPolice = Config.Types.vehicle.minPolice,
        requiredItems = Config.Types.vehicle.requiredItems,
        payoutLabel = '$7,000 – $11,000',
        difficulty = Config.Types.vehicle.difficulty,
        stages = { 'Lockpick target', 'Deliver to chop' },
        vehicle = {
            model = 'sultan',
            spawn = vector4(915.21, -1554.38, 30.75, 175.0),
            dropoff = vector3(1208.55, -3114.98, 5.54),
            plate = 'BOOST',
        },
        rewards = lootCash(7000, 11000),
    },
    {
        id = 'veh_buffalo_vinewood',
        type = 'vehicle',
        label = 'Buffalo — Vinewood Hills',
        description = 'Boost the parked Buffalo and dump it in the LS River tunnel.',
        coords = vector3(232.84, 641.92, 186.40),
        cooldown = Config.Types.vehicle.cooldown,
        minPolice = Config.Types.vehicle.minPolice,
        requiredItems = Config.Types.vehicle.requiredItems,
        payoutLabel = '$8,000 – $12,500',
        difficulty = Config.Types.vehicle.difficulty,
        stages = { 'Lockpick target', 'Deliver to chop' },
        vehicle = {
            model = 'buffalo2',
            spawn = vector4(232.84, 641.92, 186.40, 200.0),
            dropoff = vector3(1003.12, -2160.40, 30.55),
            plate = 'BOOST',
        },
        rewards = lootCash(8000, 12500),
        guards = guardSet({
            spawnOn = 'start',
            model = 's_m_y_devinsec_01',
            weapon = 'WEAPON_PISTOL',
            peds = { vector4(228.40, 644.10, 186.40, 200.0) },
        }),
    },
    {
        id = 'veh_banshee_docks',
        type = 'vehicle',
        label = 'Banshee — Elysian docks',
        description = 'Grab the Banshee off the dock and deliver it to the scrapyard.',
        coords = vector3(1204.48, -3117.20, 5.54),
        cooldown = 22 * 60,
        minPolice = Config.Types.vehicle.minPolice,
        requiredItems = Config.Types.vehicle.requiredItems,
        payoutLabel = '$9,500 – $14,500',
        difficulty = 3,
        stages = { 'Lockpick target', 'Deliver to chop' },
        vehicle = {
            model = 'banshee',
            spawn = vector4(1204.48, -3117.20, 5.80, 270.0),
            dropoff = vector3(2350.90, 3133.40, 48.21),
            plate = 'BOOST',
        },
        rewards = lootCash(9500, 14500),
    },
    {
        id = 'veh_sultanrs_sandy',
        type = 'vehicle',
        label = 'Sultan RS — Sandy airfield',
        description = 'Lift the Sultan RS from the hangar strip and drop it in Paleto.',
        coords = vector3(1738.21, 3326.10, 41.22),
        cooldown = 22 * 60,
        minPolice = Config.Types.vehicle.minPolice,
        requiredItems = Config.Types.vehicle.requiredItems,
        payoutLabel = '$9,000 – $14,000',
        difficulty = 3,
        stages = { 'Lockpick target', 'Deliver to chop' },
        vehicle = {
            model = 'sultanrs',
            spawn = vector4(1738.21, 3326.10, 41.22, 195.0),
            dropoff = vector3(-360.40, 6065.80, 31.50),
            plate = 'BOOST',
        },
        rewards = lootCash(9000, 14000),
        guards = guardSet({
            spawnOn = 'start',
            model = 's_m_y_blackops_01',
            weapon = 'WEAPON_SMG',
            peds = {
                vector4(1734.10, 3323.40, 41.22, 100.0),
                vector4(1743.20, 3328.80, 41.22, 250.0),
            },
        }),
    },

    -- Money trucks
    {
        id = 'truck_paleto',
        type = 'moneytruck',
        label = 'Gruppe Sechs — Paleto run',
        description = 'The truck leaves Paleto Bank heading south. Stop it, clear the guards, loot the rear.',
        coords = vector3(-113.40, 6469.90, 31.63),
        cooldown = Config.Types.moneytruck.cooldown,
        minPolice = Config.Types.moneytruck.minPolice,
        requiredItems = Config.Types.moneytruck.requiredItems,
        payoutLabel = '$32,000 – $54,000',
        difficulty = Config.Types.moneytruck.difficulty,
        stages = { 'Intercept truck', 'Drop guards', 'Thermite rear', 'Loot crates' },
        truck = {
            model = 'stockade',
            guardModel = 's_m_m_armoured_01',
            guardWeapon = 'WEAPON_SMG',
            spawn = vector4(-141.80, 6357.20, 31.49, 225.0),
            speed = 18.0,
            waypoints = {
                vector3(-84.20, 6305.40, 31.49),
                vector3(171.40, 6518.10, 31.90),
                vector3(1420.60, 4494.80, 53.70),
                vector3(1965.40, 3750.20, 32.25),
            },
            lootSpots = 3,
            breachItem = I.thermite,
            loot = lootCash(10000, 17000, {
                { type = 'item', name = I.goldbar, min = 1, max = 2, chance = 45 },
            }),
        },
    },
    {
        id = 'truck_city',
        type = 'moneytruck',
        label = 'Gruppe Sechs — Legion run',
        description = 'Armored truck rolling from Legion Fleeca toward the docks.',
        coords = vector3(151.20, -1040.40, 29.37),
        cooldown = Config.Types.moneytruck.cooldown,
        minPolice = Config.Types.moneytruck.minPolice,
        requiredItems = Config.Types.moneytruck.requiredItems,
        payoutLabel = '$34,000 – $58,000',
        difficulty = Config.Types.moneytruck.difficulty,
        stages = { 'Intercept truck', 'Drop guards', 'Thermite rear', 'Loot crates' },
        truck = {
            model = 'stockade',
            guardModel = 's_m_m_armoured_02',
            guardWeapon = 'WEAPON_SMG',
            spawn = vector4(220.80, -806.40, 30.70, 250.0),
            speed = 20.0,
            waypoints = {
                vector3(150.10, -1036.20, 29.34),
                vector3(393.80, -990.40, 29.42),
                vector3(819.40, -1040.10, 26.75),
                vector3(1204.80, -3104.50, 5.80),
            },
            lootSpots = 3,
            breachItem = I.thermite,
            loot = lootCash(11000, 18000, {
                { type = 'item', name = I.goldbar, min = 1, max = 2, chance = 50 },
            }),
        },
    },
    {
        id = 'truck_sandy',
        type = 'moneytruck',
        label = 'Gruppe Sechs — Sandy run',
        description = 'County truck leaving Sandy 24/7 toward Grapeseed.',
        coords = vector3(1961.10, 3740.20, 32.34),
        cooldown = Config.Types.moneytruck.cooldown,
        minPolice = Config.Types.moneytruck.minPolice,
        requiredItems = Config.Types.moneytruck.requiredItems,
        payoutLabel = '$30,000 – $50,000',
        difficulty = Config.Types.moneytruck.difficulty,
        stages = { 'Intercept truck', 'Drop guards', 'Thermite rear', 'Loot crates' },
        truck = {
            model = 'stockade',
            guardModel = 's_m_m_armoured_01',
            guardWeapon = 'WEAPON_SMG',
            spawn = vector4(1980.40, 3778.80, 32.18, 210.0),
            speed = 19.0,
            waypoints = {
                vector3(1968.40, 3744.10, 32.21),
                vector3(1702.80, 3595.40, 35.45),
                vector3(1684.20, 4920.10, 42.08),
                vector3(1706.40, 6425.80, 32.77),
            },
            lootSpots = 3,
            breachItem = I.thermite,
            loot = lootCash(9500, 16000, {
                { type = 'item', name = I.goldbar, min = 1, max = 1, chance = 40 },
            }),
        },
    },

    -- Cargo trucks
    {
        id = 'cargo_docks',
        type = 'cargotruck',
        label = 'Sealed mule — Elysian',
        description = 'Hijack the freight mule, drop the escort, crack the container at the scrapyard.',
        coords = vector3(1180.40, -3113.80, 5.80),
        cooldown = Config.Types.cargotruck.cooldown,
        minPolice = Config.Types.cargotruck.minPolice,
        requiredItems = Config.Types.cargotruck.requiredItems,
        payoutLabel = '$18,000 – $32,000',
        difficulty = Config.Types.cargotruck.difficulty,
        stages = { 'Stop the mule', 'Clear escort', 'Crack container' },
        truck = {
            model = 'mule',
            guardModel = 's_m_m_security_01',
            guardWeapon = 'WEAPON_PISTOL',
            extraGuards = 1,
            spawn = vector4(1180.40, -3113.80, 5.80, 90.0),
            speed = 17.0,
            waypoints = {
                vector3(1012.40, -2508.20, 28.40),
                vector3(812.10, -1624.80, 31.20),
                vector3(2350.90, 3133.40, 48.21),
            },
            lootSpots = 2,
            breachItem = I.crowbar,
            loot = lootCash(8000, 14000, {
                { type = 'item', name = I.goldwatch, min = 1, max = 3, chance = 60 },
                { type = 'item', name = I.usb, min = 1, max = 1, chance = 25 },
            }),
        },
    },
    {
        id = 'cargo_sandy',
        type = 'cargotruck',
        label = 'Sealed benson — Sandy',
        description = 'Ambush the desert freight run and drill the sealed crate.',
        coords = vector3(1982.10, 3782.40, 32.18),
        cooldown = Config.Types.cargotruck.cooldown,
        minPolice = Config.Types.cargotruck.minPolice,
        requiredItems = Config.Types.cargotruck.requiredItems,
        payoutLabel = '$16,000 – $28,000',
        difficulty = Config.Types.cargotruck.difficulty,
        stages = { 'Stop the benson', 'Clear escort', 'Drill crate' },
        truck = {
            model = 'benson',
            guardModel = 's_m_m_security_01',
            guardWeapon = 'WEAPON_PUMPSHOTGUN',
            extraGuards = 1,
            spawn = vector4(1982.10, 3782.40, 32.18, 210.0),
            speed = 16.0,
            waypoints = {
                vector3(1702.80, 3595.40, 35.45),
                vector3(1392.40, 3598.10, 34.90),
                vector3(2350.90, 3133.40, 48.21),
            },
            lootSpots = 2,
            breachItem = I.drill,
            loot = lootCash(7500, 13000, {
                { type = 'item', name = I.goldbar, min = 1, max = 1, chance = 30 },
            }),
        },
    },

    -- Ammunation
    ammuJob({
        id = 'ammu_pillbox',
        label = 'Ammunation — Pillbox Hill',
        gps = vector3(18.75, -1110.20, 29.80),
        hack = vector3(16.48, -1108.40, 29.80),
        cases = {
            vector3(20.92, -1106.40, 29.80),
            vector3(22.96, -1105.55, 29.80),
            vector3(19.27, -1109.95, 29.80),
        },
        locker = vector3(6.37, -1100.31, 29.80),
        guards = {
            spawnOn = 'alarm',
            model = 's_m_y_ammucity_01',
            weapon = 'WEAPON_PUMPSHOTGUN',
            peds = {
                vector4(21.40, -1105.20, 29.80, 160.0),
                vector4(8.90, -1103.40, 29.80, 250.0),
            },
        },
    }),
    ammuJob({
        id = 'ammu_sandy',
        label = 'Ammunation — Sandy Shores',
        gps = vector3(1693.40, 3759.50, 34.71),
        hack = vector3(1692.18, 3760.82, 34.71),
        cases = { vector3(1693.55, 3758.20, 34.71), vector3(1695.40, 3757.40, 34.71) },
        locker = vector3(1690.10, 3754.80, 34.71),
        guards = {
            spawnOn = 'start',
            model = 's_m_y_ammucity_01',
            weapon = 'WEAPON_PUMPSHOTGUN',
            peds = { vector4(1696.80, 3759.10, 34.71, 227.0) },
        },
    }),
    ammuJob({
        id = 'ammu_paleto',
        label = 'Ammunation — Paleto Bay',
        gps = vector3(-330.28, 6083.91, 31.45),
        hack = vector3(-330.90, 6085.84, 31.45),
        cases = { vector3(-328.70, 6082.10, 31.45), vector3(-326.95, 6081.40, 31.45) },
        locker = vector3(-334.40, 6082.20, 31.45),
        guards = {
            spawnOn = 'alarm',
            model = 's_m_y_ammucity_01',
            weapon = 'WEAPON_PUMPSHOTGUN',
            peds = { vector4(-326.20, 6084.80, 31.45, 225.0) },
        },
    }),
    ammuJob({
        id = 'ammu_seoul',
        label = 'Ammunation — Little Seoul',
        gps = vector3(-662.10, -933.55, 21.83),
        hack = vector3(-662.99, -932.44, 21.83),
        cases = { vector3(-660.40, -934.80, 21.83), vector3(-658.90, -937.10, 21.83) },
        locker = vector3(-665.80, -933.70, 21.83),
        guards = {
            spawnOn = 'alarm',
            model = 's_m_y_ammucity_01',
            weapon = 'WEAPON_COMBATPISTOL',
            peds = { vector4(-659.20, -933.10, 21.83, 180.0) },
        },
    }),
    ammuJob({
        id = 'ammu_vinewood',
        label = 'Ammunation — Vinewood Plaza',
        gps = vector3(247.45, -45.70, 69.94),
        hack = vector3(246.10, -46.85, 69.94),
        cases = { vector3(249.40, -46.20, 69.94), vector3(251.20, -48.10, 69.94) },
        locker = vector3(243.80, -44.60, 69.94),
        guards = {
            spawnOn = 'alarm',
            model = 's_m_y_ammucity_01',
            weapon = 'WEAPON_PUMPSHOTGUN',
            peds = { vector4(250.10, -49.80, 69.94, 70.0) },
        },
    }),

    -- Bobcat
    {
        id = 'bobcat_cypress',
        type = 'bobcat',
        label = 'Bobcat Security — Cypress Flats',
        description = 'Fight through the yard, hack the cage, C4 the vault, empty the cages.',
        coords = vector3(914.52, -2121.86, 30.46),
        cooldown = Config.Types.bobcat.cooldown,
        minPolice = Config.Types.bobcat.minPolice,
        requiredItems = Config.Types.bobcat.requiredItems,
        payoutLabel = '$90,000 – $160,000',
        difficulty = Config.Types.bobcat.difficulty,
        stages = { 'Hack gate panel', 'C4 vault', 'Loot cages' },
        guards = guardSet({
            spawnOn = 'start',
            model = 's_m_m_armoured_02',
            weapon = 'WEAPON_CARBINERIFLE',
            accuracy = 58,
            armour = 110,
            health = 250,
            peds = {
                vector4(910.20, -2117.40, 30.46, 85.0),
                vector4(918.80, -2126.10, 30.46, 350.0),
                vector4(904.40, -2124.80, 30.46, 270.0),
                vector4(915.10, -2112.20, 30.46, 175.0),
                vector4(889.70, -2131.90, 31.23, 0.0),
                vector4(888.20, -2107.60, 30.46, 180.0),
            },
        }),
        interactions = {
            {
                id = 'hack',
                kind = 'hack',
                coords = vector3(904.80, -2113.90, 31.23),
                label = 'Hack yard access panel',
                icon = 'laptop-code',
                item = I.hack,
                consumeChance = 40,
                minigame = 'circuit',
                skill = Config.Skill.bobcatHack,
                duration = 10000,
                anim = Config.Anims.hack,
                alertsPolice = true,
            },
            {
                id = 'vault',
                kind = 'breach',
                coords = vector3(888.12, -2129.80, 31.23),
                label = 'Plant C4 on vault cage',
                icon = 'bomb',
                item = I.c4,
                consumeChance = 100,
                minigame = 'thermite',
                skill = Config.Skill.bobcatVault,
                duration = 14000,
                anim = Config.Anims.plant,
                requires = { 'hack' },
            },
            {
                id = 'cage_1',
                kind = 'loot',
                coords = vector3(884.40, -2127.10, 31.23),
                label = 'Loot weapon cage',
                icon = 'gun',
                item = I.crowbar,
                consumeChance = 15,
                duration = 9000,
                anim = Config.Anims.loot,
                requires = { 'vault' },
                rewards = {
                    { type = 'item', name = 'WEAPON_CARBINERIFLE', min = 1, max = 1, chance = 35 },
                    { type = 'item', name = 'WEAPON_SMG', min = 1, max = 1, chance = 50 },
                    { type = 'item', name = I.dirtyCash, min = 18000, max = 28000, chance = 100 },
                },
            },
            {
                id = 'cage_2',
                kind = 'loot',
                coords = vector3(882.10, -2132.40, 31.23),
                label = 'Loot cash cage',
                icon = 'box-open',
                duration = 10000,
                anim = Config.Anims.loot,
                requires = { 'vault' },
                rewards = lootCash(22000, 36000, lockerExtra()),
            },
            {
                id = 'cage_3',
                kind = 'loot',
                coords = vector3(890.60, -2134.80, 31.23),
                label = 'Loot gold cage',
                icon = 'box-open',
                duration = 10000,
                anim = Config.Anims.loot,
                requires = { 'vault' },
                rewards = lootCash(16000, 26000, {
                    { type = 'item', name = I.goldbar, min = 2, max = 4, chance = 75 },
                }),
            },
        },
    },

    -- Yacht
    {
        id = 'yacht_aquarius',
        type = 'yacht',
        label = 'Aquarius yacht — Del Perro',
        description = 'Board the yacht, clear the armed crew, loot cabins and drill the owner safe.',
        coords = vector3(-2041.50, -1032.10, 11.91),
        cooldown = Config.Types.yacht.cooldown,
        minPolice = Config.Types.yacht.minPolice,
        requiredItems = Config.Types.yacht.requiredItems,
        payoutLabel = '$48,000 – $95,000',
        difficulty = Config.Types.yacht.difficulty,
        stages = { 'Board & lockpick hatch', 'Hack bridge', 'Loot cabins', 'Drill owner safe' },
        guards = guardSet({
            spawnOn = 'start',
            model = 's_m_y_blackops_01',
            weapon = 'WEAPON_SMG',
            accuracy = 50,
            armour = 70,
            peds = {
                vector4(-2044.80, -1034.20, 11.98, 60.0),
                vector4(-2036.10, -1030.40, 5.88, 240.0),
                vector4(-2026.40, -1038.70, 5.88, 20.0),
                vector4(-2082.90, -1018.40, 8.97, 70.0),
                vector4(-2055.20, -1025.10, 8.97, 250.0),
            },
        }),
        interactions = {
            {
                id = 'hatch',
                kind = 'hack',
                coords = vector3(-2023.80, -1036.90, 5.88),
                label = 'Lockpick lower hatch',
                icon = 'key',
                item = I.lockpick,
                consumeChance = 50,
                minigame = 'skill',
                skill = Config.Skill.houseDoor,
                duration = 8000,
                anim = Config.Anims.lockpick,
                alertsPolice = true,
            },
            {
                id = 'hack',
                kind = 'hack',
                coords = vector3(-2045.70, -1031.40, 11.98),
                label = 'Hack bridge terminal',
                icon = 'laptop-code',
                item = I.hack,
                consumeChance = 35,
                minigame = 'circuit',
                skill = Config.Skill.yachtHack,
                duration = 9000,
                anim = Config.Anims.hack,
                requires = { 'hatch' },
            },
            {
                id = 'cabin_1',
                kind = 'loot',
                coords = vector3(-2061.40, -1023.80, 8.97),
                label = 'Loot guest cabin',
                icon = 'box-open',
                duration = 7500,
                anim = Config.Anims.loot,
                requires = { 'hack' },
                rewards = lootCash(7000, 12000, jewelryExtra()),
            },
            {
                id = 'cabin_2',
                kind = 'loot',
                coords = vector3(-2074.20, -1018.90, 8.97),
                label = 'Loot master cabin',
                icon = 'box-open',
                duration = 8000,
                anim = Config.Anims.loot,
                requires = { 'hack' },
                rewards = lootCash(8000, 14000, jewelryExtra()),
            },
            {
                id = 'safe',
                kind = 'breach',
                coords = vector3(-2086.10, -1016.40, 8.97),
                label = 'Drill owner safe',
                icon = 'vault',
                item = I.drill,
                consumeChance = 30,
                minigame = 'keypad',
                skill = Config.Skill.yachtSafe,
                duration = 14000,
                anim = Config.Anims.drill,
                requires = { 'hack' },
                rewards = lootCash(14000, 24000, {
                    { type = 'item', name = I.diamond, min = 1, max = 3, chance = 55 },
                    { type = 'item', name = I.goldbar, min = 1, max = 2, chance = 40 },
                }),
            },
        },
    },

    -- Train
    {
        id = 'train_quartz',
        type = 'train',
        label = 'Davis Quartz freight',
        description = 'Board the parked freight, drop car guards, grind the sealed cash car.',
        coords = vector3(2878.40, 4489.10, 48.22),
        cooldown = Config.Types.train.cooldown,
        minPolice = Config.Types.train.minPolice,
        requiredItems = Config.Types.train.requiredItems,
        payoutLabel = '$40,000 – $78,000',
        difficulty = Config.Types.train.difficulty,
        stages = { 'Crowbar first car', 'Clear remaining cars', 'Drill cash car' },
        guards = guardSet({
            spawnOn = 'start',
            model = 's_m_m_armoured_01',
            weapon = 'WEAPON_CARBINERIFLE',
            accuracy = 50,
            armour = 80,
            peds = {
                vector4(2874.20, 4484.60, 48.22, 20.0),
                vector4(2884.10, 4494.80, 48.22, 200.0),
                vector4(2868.90, 4496.20, 48.22, 110.0),
                vector4(2888.40, 4482.10, 48.22, 300.0),
            },
        }),
        interactions = {
            {
                id = 'car_1',
                kind = 'hack',
                coords = vector3(2876.10, 4486.40, 48.22),
                label = 'Crowbar first car',
                icon = 'hammer',
                item = I.crowbar,
                consumeChance = 20,
                minigame = 'skill',
                skill = Config.Skill.trainCut,
                duration = 8000,
                anim = Config.Anims.weld,
                alertsPolice = true,
            },
            {
                id = 'car_2',
                kind = 'loot',
                coords = vector3(2882.40, 4492.20, 48.22),
                label = 'Loot parts car',
                icon = 'box-open',
                duration = 8000,
                anim = Config.Anims.loot,
                requires = { 'car_1' },
                rewards = lootCash(7000, 12000, {
                    { type = 'item', name = I.goldwatch, min = 1, max = 2, chance = 40 },
                }),
            },
            {
                id = 'car_3',
                kind = 'loot',
                coords = vector3(2869.80, 4491.10, 48.22),
                label = 'Loot crate car',
                icon = 'box-open',
                duration = 8000,
                anim = Config.Anims.loot,
                requires = { 'car_1' },
                rewards = lootCash(7000, 12000),
            },
            {
                id = 'cashcar',
                kind = 'breach',
                coords = vector3(2886.70, 4480.90, 48.22),
                label = 'Drill sealed cash car',
                icon = 'vault',
                item = I.drill,
                consumeChance = 35,
                minigame = 'thermite',
                skill = Config.Skill.trainCut,
                duration = 15000,
                anim = Config.Anims.drill,
                requires = { 'car_1' },
                rewards = lootCash(18000, 30000, lockerExtra()),
            },
        },
    },

    -- Cargo ship
    {
        id = 'ship_elysian',
        type = 'cargoship',
        label = 'Elysian Island freighter',
        description = 'Board the freighter, hack the container mainframe, lift sealed crates.',
        coords = vector3(1234.80, -3234.60, 5.80),
        cooldown = Config.Types.cargoship.cooldown,
        minPolice = Config.Types.cargoship.minPolice,
        requiredItems = Config.Types.cargoship.requiredItems,
        payoutLabel = '$55,000 – $105,000',
        difficulty = Config.Types.cargoship.difficulty,
        stages = { 'Hack mainframe', 'Crowbar containers', 'Drill high-value crate' },
        guards = guardSet({
            spawnOn = 'start',
            model = 's_m_y_blackops_01',
            weapon = 'WEAPON_CARBINERIFLE',
            accuracy = 52,
            armour = 85,
            peds = {
                vector4(1230.40, -3230.10, 5.80, 90.0),
                vector4(1242.80, -3238.40, 5.80, 270.0),
                vector4(1224.10, -3244.20, 5.80, 10.0),
                vector4(1248.60, -3226.80, 5.80, 180.0),
                vector4(1216.90, -3222.40, 7.10, 140.0),
            },
        }),
        interactions = {
            {
                id = 'hack',
                kind = 'hack',
                coords = vector3(1228.20, -3225.40, 7.10),
                label = 'Hack container mainframe',
                icon = 'laptop-code',
                item = I.laptop,
                consumeChance = 30,
                minigame = 'circuit',
                skill = Config.Skill.shipHack,
                duration = 11000,
                anim = Config.Anims.hack,
                alertsPolice = true,
            },
            {
                id = 'crate_1',
                kind = 'loot',
                coords = vector3(1240.10, -3240.80, 5.80),
                label = 'Crowbar container',
                icon = 'box-open',
                item = I.crowbar,
                consumeChance = 15,
                duration = 8500,
                anim = Config.Anims.weld,
                requires = { 'hack' },
                rewards = lootCash(9000, 15000, {
                    { type = 'item', name = I.goldwatch, min = 1, max = 3, chance = 50 },
                }),
            },
            {
                id = 'crate_2',
                kind = 'loot',
                coords = vector3(1222.40, -3246.10, 5.80),
                label = 'Crowbar container',
                icon = 'box-open',
                item = I.crowbar,
                consumeChance = 15,
                duration = 8500,
                anim = Config.Anims.weld,
                requires = { 'hack' },
                rewards = lootCash(9000, 15000),
            },
            {
                id = 'crate_3',
                kind = 'loot',
                coords = vector3(1246.80, -3224.20, 5.80),
                label = 'Crowbar container',
                icon = 'box-open',
                item = I.crowbar,
                consumeChance = 15,
                duration = 8500,
                anim = Config.Anims.weld,
                requires = { 'hack' },
                rewards = lootCash(9000, 15000, jewelryExtra()),
            },
            {
                id = 'highvalue',
                kind = 'breach',
                coords = vector3(1214.80, -3220.90, 7.10),
                label = 'Drill high-value crate',
                icon = 'vault',
                item = I.drill,
                consumeChance = 35,
                minigame = 'thermite',
                skill = Config.Skill.shipHack,
                duration = 14000,
                anim = Config.Anims.drill,
                requires = { 'hack' },
                rewards = lootCash(18000, 30000, {
                    { type = 'item', name = I.goldbar, min = 1, max = 3, chance = 60 },
                    { type = 'item', name = I.diamond, min = 1, max = 2, chance = 35 },
                }),
            },
        },
    },
}

Config.LocationIndex = {}
for i = 1, #Config.Locations do
    local loc = Config.Locations[i]
    local typeCfg = Config.Types[loc.type]
    if typeCfg and typeCfg.enabled == false then
        -- still indexed so admins can re-enable without a restart of this table
    end
    Config.LocationIndex[loc.id] = loc
end

function IsTypeEnabled(typeId)
    local cfg = Config.Types[typeId]
    return cfg and cfg.enabled ~= false
end

function GetRobberyLocation(id)
    local loc = Config.LocationIndex[id]
    if not loc then return nil end
    if not IsTypeEnabled(loc.type) then return nil end
    return loc
end

function GetRobberyType(id)
    local loc = GetRobberyLocation(id)
    return loc and Config.Types[loc.type] or nil
end

function GetRequiredItems(loc)
    if type(loc) == 'string' then
        loc = GetRobberyLocation(loc)
    end
    if not loc then return {} end
    if loc.requiredItems then return loc.requiredItems end
    local typeCfg = Config.Types[loc.type]
    return (typeCfg and typeCfg.requiredItems) or {}
end

function GetLocationCooldown(loc)
    if type(loc) == 'string' then
        loc = GetRobberyLocation(loc)
    end
    if not loc then return 30 * 60 end
    if loc.cooldown then return loc.cooldown end
    local typeCfg = Config.Types[loc.type]
    return (typeCfg and typeCfg.cooldown) or (30 * 60)
end

function GetLocationTimeout(loc)
    if type(loc) == 'string' then
        loc = GetRobberyLocation(loc)
    end
    local typeCfg = loc and Config.Types[loc.type]
    return (typeCfg and typeCfg.timeout) or Config.JobTimeout
end

function LocationHasGuards(loc)
    return loc and loc.guards and loc.guards.enabled and Config.Guards.enabled
end
