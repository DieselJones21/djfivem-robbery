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

local function lockerExtra()
    return {
        { type = 'item', name = 'goldbar', min = 1, max = 2, chance = 35 },
        { type = 'item', name = 'goldwatch', min = 1, max = 3, chance = 50 },
    }
end

--- Shared Fleeca / Paleto interaction builder
local function bankJob(opts)
    local lockers = {}
    for i, coords in ipairs(opts.lockers) do
        lockers[#lockers + 1] = {
            id = ('locker_%s'):format(i),
            kind = 'loot',
            coords = coords,
            label = 'Loot deposit box',
            icon = 'box-open',
            duration = 8500,
            anim = Config.Anims.loot,
            requires = { 'vault' },
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
            consumeChance = 35,
            skill = Config.Skill.bankHack,
            duration = 7500,
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
            skill = Config.Skill.bankVault,
            duration = 11000,
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
        description = 'Crew up, hack the panel, burn the vault, then split the boxes.',
        coords = opts.gps,
        heading = opts.heading or 0.0,
        cooldown = opts.cooldown or Config.Types.bank.cooldown,
        minPolice = opts.minPolice or Config.Types.bank.minPolice,
        requiredItems = Config.Types.bank.requiredItems,
        payoutLabel = opts.payoutLabel,
        vaultDoor = opts.vaultDoor,
        interactions = interactions,
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
            consumeChance = 45,
            skill = Config.Skill.storeRegister,
            duration = 6500,
            anim = Config.Anims.lockpick,
            alertsPolice = i == 1,
            rewards = lootCash(350, 900),
        }
    end

    interactions[#interactions + 1] = {
        id = 'safe',
        kind = 'breach',
        coords = opts.safe,
        label = 'Crack the safe',
        icon = 'vault',
        item = I.drill,
        consumeChance = 25,
        skill = Config.Skill.storeSafe,
        duration = 14000,
        anim = Config.Anims.drill,
        requires = { 'register_1' },
        rewards = lootCash(opts.safeMin or 2200, opts.safeMax or 4800),
    }

    return {
        id = opts.id,
        type = 'store',
        label = opts.label,
        description = 'Clean the till, then drill the office safe.',
        coords = opts.gps,
        cooldown = opts.cooldown or Config.Types.store.cooldown,
        minPolice = Config.Types.store.minPolice,
        requiredItems = Config.Types.store.requiredItems,
        payoutLabel = opts.payoutLabel or '$2,500 – $6,500',
        interactions = interactions,
    }
end

local function atmJob(opts)
    return {
        id = opts.id,
        type = 'atm',
        label = opts.label,
        description = 'Drill the cassette and grab the cash before patrols roll up.',
        coords = opts.coords,
        cooldown = Config.Types.atm.cooldown,
        minPolice = Config.Types.atm.minPolice,
        requiredItems = Config.Types.atm.requiredItems,
        payoutLabel = '$1,200 – $2,400',
        interactions = {
            {
                id = 'drill',
                kind = 'breach',
                coords = opts.coords,
                label = 'Drill ATM',
                icon = 'screwdriver-wrench',
                item = I.drill,
                consumeChance = 20,
                skill = Config.Skill.atm,
                duration = 12000,
                anim = Config.Anims.drill,
                alertsPolice = true,
                rewards = lootCash(1200, 2400),
            },
        },
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
            consumeChance = 30,
            skill = Config.Skill.ammuHack,
            duration = 7000,
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
            consumeChance = 10,
            skill = Config.Skill.ammuCase,
            duration = 5000,
            anim = Config.Anims.smash,
            requires = { 'hack' },
            rewards = {
                { type = 'item', name = 'ammo-9', min = 24, max = 48, chance = 80 },
                { type = 'item', name = 'WEAPON_SNSPISTOL', min = 1, max = 1, chance = 18 },
                { type = 'item', name = I.dirtyCash, min = 400, max = 900, chance = 100 },
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
        consumeChance = 30,
        skill = Config.Skill.ammuLocker,
        duration = 13000,
        anim = Config.Anims.drill,
        requires = { 'hack' },
        rewards = {
            { type = 'item', name = 'WEAPON_PISTOL', min = 1, max = 1, chance = 55 },
            { type = 'item', name = 'WEAPON_COMBATPISTOL', min = 1, max = 1, chance = 20 },
            { type = 'item', name = 'ammo-9', min = 36, max = 72, chance = 100 },
            { type = 'item', name = I.dirtyCash, min = 1800, max = 3600, chance = 100 },
        },
    }

    return {
        id = opts.id,
        type = 'ammunation',
        label = opts.label,
        description = 'Kill the cameras, smash the cases, drill the back locker.',
        coords = opts.gps,
        cooldown = Config.Types.ammunation.cooldown,
        minPolice = Config.Types.ammunation.minPolice,
        requiredItems = Config.Types.ammunation.requiredItems,
        payoutLabel = 'Guns, ammo, $2,000 – $5,000',
        interactions = interactions,
    }
end

Config.Locations = {
    -- Banks (max 4)
    bankJob({
        id = 'fleeca_legion',
        label = 'Fleeca Bank — Legion Square',
        gps = vector3(150.87, -1037.16, 29.34),
        heading = 160.0,
        payoutLabel = '$40,000 – $90,000',
        lockerMin = 8000,
        lockerMax = 14500,
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
    }),
    bankJob({
        id = 'fleeca_alta',
        label = 'Fleeca Bank — Alta',
        gps = vector3(315.32, -275.55, 53.92),
        heading = 160.0,
        payoutLabel = '$40,000 – $90,000',
        lockerMin = 8000,
        lockerMax = 14500,
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
    }),
    bankJob({
        id = 'fleeca_burton',
        label = 'Fleeca Bank — Burton',
        gps = vector3(-349.89, -46.44, 49.04),
        heading = 160.0,
        payoutLabel = '$40,000 – $90,000',
        lockerMin = 8000,
        lockerMax = 14500,
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
    }),
    bankJob({
        id = 'paleto_savings',
        label = 'Blaine County Savings — Paleto',
        gps = vector3(-110.94, 6462.53, 31.64),
        heading = 45.0,
        payoutLabel = '$55,000 – $110,000',
        lockerMin = 10000,
        lockerMax = 18000,
        cooldown = 60 * 60,
        hack = vector3(-105.90, 6472.11, 31.90),
        vault = vector3(-105.51, 6475.23, 32.00),
        vaultDoor = {
            model = `v_ilev_cbankvauldoor`,
            coords = vector3(-104.60, 6473.44, 31.80),
            closed = 45.0,
            open = 150.0,
        },
        lockers = {
            vector3(-102.59, 6475.23, 31.62),
            vector3(-103.08, 6478.67, 31.62),
            vector3(-106.88, 6478.35, 31.62),
            vector3(-107.31, 6473.15, 31.62),
        },
    }),

    -- Stores (max 4)
    storeJob({
        id = 'store_grove',
        label = 'LTD Gasoline — Grove Street',
        gps = vector3(-47.20, -1757.70, 29.42),
        registers = {
            vector3(-47.24, -1757.65, 29.53),
            vector3(-48.58, -1759.21, 29.59),
        },
        safe = vector3(-43.43, -1748.30, 29.42),
    }),
    storeJob({
        id = 'store_innocence',
        label = '24/7 — Innocence Blvd',
        gps = vector3(25.70, -1346.80, 29.50),
        registers = {
            vector3(24.47, -1344.99, 29.49),
            vector3(24.45, -1347.37, 29.49),
        },
        safe = vector3(28.21, -1339.14, 29.49),
    }),
    storeJob({
        id = 'store_seoul',
        label = 'LTD Gasoline — Little Seoul',
        gps = vector3(-706.10, -914.50, 19.22),
        registers = {
            vector3(-706.08, -915.42, 19.21),
            vector3(-706.16, -913.50, 19.21),
        },
        safe = vector3(-709.74, -904.15, 19.21),
    }),
    storeJob({
        id = 'store_vinewood',
        label = '24/7 — Downtown Vinewood',
        gps = vector3(373.80, 327.90, 103.57),
        registers = {
            vector3(373.14, 328.62, 103.56),
            vector3(372.57, 326.42, 103.56),
        },
        safe = vector3(378.17, 333.44, 103.56),
    }),
    storeJob({
        id = 'store_sandy',
        label = '24/7 — Sandy Shores',
        gps = vector3(1960.20, 3741.50, 32.34),
        registers = {
            vector3(1958.96, 3741.98, 32.34),
            vector3(1960.13, 3740.00, 32.34),
        },
        safe = vector3(1959.26, 3748.92, 32.34),
    }),
    storeJob({
        id = 'store_paleto',
        label = '24/7 — Paleto Bay',
        gps = vector3(161.20, 6641.90, 31.70),
        registers = {
            vector3(160.52, 6641.74, 31.60),
            vector3(162.16, 6643.22, 31.60),
        },
        safe = vector3(168.95, 6644.74, 31.70),
    }),

    -- ATMs (max 2)
    atmJob({ id = 'atm_legion', label = 'ATM — Legion Square', coords = vector3(147.47, -1035.68, 29.34) }),
    atmJob({ id = 'atm_pillbox', label = 'ATM — Pillbox Hospital', coords = vector3(296.47, -591.31, 43.27) }),
    atmJob({ id = 'atm_paleto', label = 'ATM — Paleto Bay', coords = vector3(-386.73, 6046.08, 31.50) }),
    atmJob({ id = 'atm_grove', label = 'ATM — Grove LTD', coords = vector3(-56.72, -1752.12, 29.42) }),
    atmJob({ id = 'atm_sandy', label = 'ATM — Sandy 24/7', coords = vector3(1968.17, 3743.55, 32.34) }),
    atmJob({ id = 'atm_vinewood', label = 'ATM — Vinewood 24/7', coords = vector3(380.78, 323.40, 103.57) }),

    -- Vehicle robberies (max 2)
    {
        id = 'veh_sultan_city',
        type = 'vehicle',
        label = 'Sultan — La Mesa lot',
        description = 'Lockpick the marked Sultan and drop it at the docks warehouse.',
        coords = vector3(915.21, -1554.38, 30.75),
        cooldown = Config.Types.vehicle.cooldown,
        minPolice = Config.Types.vehicle.minPolice,
        requiredItems = Config.Types.vehicle.requiredItems,
        payoutLabel = '$6,000 – $9,500',
        vehicle = {
            model = 'sultan',
            spawn = vector4(915.21, -1554.38, 30.75, 175.0),
            dropoff = vector3(1208.55, -3114.98, 5.54),
            plate = 'BOOST',
        },
        rewards = lootCash(6000, 9500),
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
        payoutLabel = '$7,000 – $11,000',
        vehicle = {
            model = 'buffalo2',
            spawn = vector4(232.84, 641.92, 186.40, 200.0),
            dropoff = vector3(1003.12, -2160.40, 30.55),
            plate = 'BOOST',
        },
        rewards = lootCash(7000, 11000),
    },
    {
        id = 'veh_banshee_docks',
        type = 'vehicle',
        label = 'Banshee — Elysian docks',
        description = 'Grab the Banshee off the dock and deliver it to the scrapyard.',
        coords = vector3(1204.48, -3117.20, 5.54),
        cooldown = 25 * 60,
        minPolice = Config.Types.vehicle.minPolice,
        requiredItems = Config.Types.vehicle.requiredItems,
        payoutLabel = '$8,500 – $13,000',
        vehicle = {
            model = 'banshee',
            spawn = vector4(1204.48, -3117.20, 5.80, 270.0),
            dropoff = vector3(2350.90, 3133.40, 48.21),
            plate = 'BOOST',
        },
        rewards = lootCash(8500, 13000),
    },
    {
        id = 'veh_sultanrs_sandy',
        type = 'vehicle',
        label = 'Sultan RS — Sandy airfield',
        description = 'Lift the Sultan RS from the hangar strip and drop it in Paleto.',
        coords = vector3(1738.21, 3326.10, 41.22),
        cooldown = 25 * 60,
        minPolice = Config.Types.vehicle.minPolice,
        requiredItems = Config.Types.vehicle.requiredItems,
        payoutLabel = '$8,000 – $12,500',
        vehicle = {
            model = 'sultanrs',
            spawn = vector4(1738.21, 3326.10, 41.22, 195.0),
            dropoff = vector3(-360.40, 6065.80, 31.50),
            plate = 'BOOST',
        },
        rewards = lootCash(8000, 12500),
    },

    -- Money trucks (max 4)
    {
        id = 'truck_paleto',
        type = 'moneytruck',
        label = 'Gruppe Sechs — Paleto run',
        description = 'The truck leaves Paleto Bank heading south. Stop it, clear the guards, loot the rear.',
        coords = vector3(-113.40, 6469.90, 31.63),
        cooldown = Config.Types.moneytruck.cooldown,
        minPolice = Config.Types.moneytruck.minPolice,
        requiredItems = Config.Types.moneytruck.requiredItems,
        payoutLabel = '$28,000 – $48,000',
        truck = {
            model = 'stockade',
            guardModel = 's_m_m_armoured_01',
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
            loot = lootCash(9000, 15000, {
                { type = 'item', name = 'goldbar', min = 1, max = 2, chance = 40 },
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
        payoutLabel = '$30,000 – $52,000',
        truck = {
            model = 'stockade',
            guardModel = 's_m_m_armoured_02',
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
            loot = lootCash(10000, 16500, {
                { type = 'item', name = 'goldbar', min = 1, max = 2, chance = 45 },
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
        payoutLabel = '$26,000 – $44,000',
        truck = {
            model = 'stockade',
            guardModel = 's_m_m_armoured_01',
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
            loot = lootCash(8500, 14000, {
                { type = 'item', name = 'goldbar', min = 1, max = 1, chance = 35 },
            }),
        },
    },

    -- Ammunation (max 4)
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
    }),
    ammuJob({
        id = 'ammu_sandy',
        label = 'Ammunation — Sandy Shores',
        gps = vector3(1693.40, 3759.50, 34.71),
        hack = vector3(1692.18, 3760.82, 34.71),
        cases = {
            vector3(1693.55, 3758.20, 34.71),
            vector3(1695.40, 3757.40, 34.71),
        },
        locker = vector3(1690.10, 3754.80, 34.71),
    }),
    ammuJob({
        id = 'ammu_paleto',
        label = 'Ammunation — Paleto Bay',
        gps = vector3(-330.28, 6083.91, 31.45),
        hack = vector3(-330.90, 6085.84, 31.45),
        cases = {
            vector3(-328.70, 6082.10, 31.45),
            vector3(-326.95, 6081.40, 31.45),
        },
        locker = vector3(-334.40, 6082.20, 31.45),
    }),
    ammuJob({
        id = 'ammu_seoul',
        label = 'Ammunation — Little Seoul',
        gps = vector3(-662.10, -933.55, 21.83),
        hack = vector3(-662.99, -932.44, 21.83),
        cases = {
            vector3(-660.40, -934.80, 21.83),
            vector3(-658.90, -937.10, 21.83),
        },
        locker = vector3(-665.80, -933.70, 21.83),
    }),
    ammuJob({
        id = 'ammu_vinewood',
        label = 'Ammunation — Vinewood Plaza',
        gps = vector3(247.45, -45.70, 69.94),
        hack = vector3(246.10, -46.85, 69.94),
        cases = {
            vector3(249.40, -46.20, 69.94),
            vector3(251.20, -48.10, 69.94),
        },
        locker = vector3(243.80, -44.60, 69.94),
    }),
}

Config.LocationIndex = {}
for i = 1, #Config.Locations do
    local loc = Config.Locations[i]
    Config.LocationIndex[loc.id] = loc
end

function GetRobberyLocation(id)
    return Config.LocationIndex[id]
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
