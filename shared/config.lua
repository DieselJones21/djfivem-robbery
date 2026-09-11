Config = {}

Config.Debug = false
Config.Locale = 'en'
Config.Version = '2.0.0'

-- Jobs counted as police when Wasabi is unavailable
Config.PoliceJobs = {
    police = true,
    sheriff = true,
    bcso = true,
    lssd = true,
    sahp = true,
    sasp = true,
}

Config.RequireOnDuty = true
Config.InviteDistance = 8.0
Config.InteractDistance = 3.25
Config.JobTimeout = 25 * 60
Config.FailIfCrewWiped = true
Config.PlayerCooldown = 8 * 60
Config.RewardMode = 'looter' -- looter | split

Config.Tablet = {
    item = 'robbery_tablet',
    consume = false,
    anim = { dict = 'amb@world_human_seat_wall_tablet@female@base', clip = 'base', flag = 49 },
}

--[[
    Police / MDT / dispatch
    Count: wasabi_police | wasabi_police_v2 | auto | qbx
    Dispatch: wasabi_mdt | wasabi_dispatch | ps-dispatch | cd_dispatch | qs-dispatch | linden | builtin | custom
]]
Config.Police = {
    countResource = 'auto',
    blockOfficersFromTablet = true,
    useWasabiMdtOfficerCheck = true,
}

Config.Dispatch = {
    enabled = true,
    resource = 'wasabi_mdt',
    code = '10-90',
    senderName = 'Silent Alarm',
    blipTime = 140,
    fallbackBuiltin = true, -- also notify on-duty cops if the dispatch resource is missing
    custom = function(payload) end,
}

Config.DispatchProfiles = {
    atm =         { type = 'robbery', priority = 2, code = '10-90', title = 'ATM being drilled' },
    store =       { type = 'robbery', priority = 3, code = '10-90', title = 'Store robbery in progress' },
    house =       { type = 'theft',   priority = 2, code = '10-31', title = 'Residential burglary' },
    vehicle =     { type = 'theft',   priority = 3, code = '10-60', title = 'Vehicle theft in progress' },
    ammunation =  { type = 'robbery', priority = 4, code = '10-90', title = 'Ammunation robbery' },
    bank =        { type = 'robbery', priority = 4, code = '10-90', title = 'Bank alarm triggered' },
    paleto =      { type = 'robbery', priority = 5, code = '10-90', title = 'Paleto bank under attack' },
    moneytruck =  { type = 'robbery', priority = 4, code = '10-90', title = 'Armored truck under attack' },
    cargotruck =  { type = 'robbery', priority = 3, code = '10-90', title = 'Cargo truck hijack' },
    jewelry =     { type = 'robbery', priority = 5, code = '10-90', title = 'Vangelico jewelry heist' },
    pacific =     { type = 'robbery', priority = 5, code = '10-90', title = 'Pacific Standard vault alarm' },
    bobcat =      { type = 'robbery', priority = 5, code = '10-90', title = 'Bobcat Security raid' },
    yacht =       { type = 'robbery', priority = 4, code = '10-90', title = 'Yacht boarded — shots reported' },
    train =       { type = 'robbery', priority = 4, code = '10-90', title = 'Freight train robbery' },
    cargoship =   { type = 'robbery', priority = 4, code = '10-90', title = 'Cargo ship boarded' },
}

Config.AntiExploit = {
    callbackWindow = 1.25,      -- seconds between identical callbacks
    maxCallbacksPerWindow = 8,  -- per player, per 4s bucket
    interactionTokenTtl = 90,   -- seconds to finish a minigame
    maxShopQty = 20,
    requireItemOnFinish = true,
    validateDistanceOnFinish = true,
    busyTimeout = 95,
}

Config.Guards = {
    enabled = true,
    defaultModel = 's_m_y_security_01',
    defaultWeapon = 'WEAPON_PUMPSHOTGUN',
    accuracy = 42,
    armour = 55,
    health = 200,
    combatRange = 70.0,
}

Config.Items = {
    lockpick = 'lockpick',
    advancedLockpick = 'advancedlockpick',
    hack = 'electronickit',
    laptop = 'hacking_laptop',
    thermite = 'thermite',
    c4 = 'c4_charge',
    drill = 'drill',
    crowbar = 'crowbar',
    dirtyCash = 'black_money',
    goldbar = 'goldbar',
    goldwatch = 'goldwatch',
    diamond = 'diamond',
    usb = 'trojan_usb',
}

Config.CashAccount = 'cash'

Config.Types = {
    atm = {
        enabled = true,
        label = 'ATM Hits',
        description = 'Drill a street cassette before patrols close the block.',
        maxPlayers = 2,
        minPlayers = 1,
        minPolice = 0,
        cooldown = 12 * 60,
        difficulty = 1,
        timeout = 12 * 60,
        icon = 'credit-card',
        color = '#f5c542',
        requiredItems = { { item = 'drill', count = 1 } },
    },
    store = {
        enabled = true,
        label = 'Store Robberies',
        description = 'Lockpick tills, then drill the office safe while the clerk panics.',
        maxPlayers = 4,
        minPlayers = 1,
        minPolice = 1,
        cooldown = 22 * 60,
        difficulty = 2,
        timeout = 18 * 60,
        icon = 'store',
        color = '#3ee0c6',
        requiredItems = {
            { item = 'lockpick', count = 1 },
            { item = 'drill', count = 1 },
        },
    },
    house = {
        enabled = true,
        label = 'House Burglaries',
        description = 'Quiet entry, room-to-room loot, get out before the alarm stacks.',
        maxPlayers = 3,
        minPlayers = 1,
        minPolice = 1,
        cooldown = 18 * 60,
        difficulty = 2,
        timeout = 16 * 60,
        icon = 'house',
        color = '#9bbcff',
        requiredItems = {
            { item = 'lockpick', count = 1 },
            { item = 'crowbar', count = 1 },
        },
    },
    vehicle = {
        enabled = true,
        label = 'Vehicle Theft',
        description = 'Boost a marked car and dump it at the chop before the tracker pings.',
        maxPlayers = 2,
        minPlayers = 1,
        minPolice = 1,
        cooldown = 18 * 60,
        difficulty = 2,
        timeout = 16 * 60,
        icon = 'car',
        color = '#ff8fab',
        requiredItems = { { item = 'lockpick', count = 1 } },
    },
    ammunation = {
        enabled = true,
        label = 'Ammunation Hits',
        description = 'Kill cameras, smash cases, drill the locker. Security will shoot.',
        maxPlayers = 4,
        minPlayers = 1,
        minPolice = 2,
        cooldown = 36 * 60,
        difficulty = 3,
        timeout = 20 * 60,
        icon = 'gun',
        color = '#d8b4fe',
        requiredItems = {
            { item = 'electronickit', count = 1 },
            { item = 'crowbar', count = 1 },
            { item = 'drill', count = 1 },
        },
    },
    bank = {
        enabled = true,
        label = 'Fleeca Banks',
        description = 'Hack the panel, thermite the vault, empty the boxes under armed response.',
        maxPlayers = 4,
        minPlayers = 1,
        minPolice = 2,
        cooldown = 40 * 60,
        difficulty = 3,
        timeout = 22 * 60,
        icon = 'university',
        color = '#7dd3fc',
        requiredItems = {
            { item = 'electronickit', count = 1 },
            { item = 'thermite', count = 1 },
        },
    },
    paleto = {
        enabled = true,
        label = 'Paleto Savings',
        description = 'Cut power, breach the vault, fight county security.',
        maxPlayers = 5,
        minPlayers = 2,
        minPolice = 4,
        cooldown = 55 * 60,
        difficulty = 4,
        timeout = 24 * 60,
        icon = 'landmark',
        color = '#86efac',
        requiredItems = {
            { item = 'electronickit', count = 1 },
            { item = 'thermite', count = 1 },
            { item = 'drill', count = 1 },
        },
    },
    jewelry = {
        enabled = true,
        label = 'Vangelico',
        description = 'Bypass the gallery alarm, smash displays, drill the office safe.',
        maxPlayers = 5,
        minPlayers = 2,
        minPolice = 4,
        cooldown = 50 * 60,
        difficulty = 4,
        timeout = 22 * 60,
        icon = 'gem',
        color = '#f9a8d4',
        requiredItems = {
            { item = 'electronickit', count = 1 },
            { item = 'crowbar', count = 1 },
            { item = 'thermite', count = 1 },
        },
    },
    pacific = {
        enabled = true,
        label = 'Pacific Standard',
        description = 'Multi-stage downtown vault: power, keypad, C4, trolleys, then run.',
        maxPlayers = 6,
        minPlayers = 3,
        minPolice = 6,
        cooldown = 75 * 60,
        difficulty = 5,
        timeout = 28 * 60,
        icon = 'building-columns',
        color = '#f5c542',
        requiredItems = {
            { item = 'hacking_laptop', count = 1 },
            { item = 'electronickit', count = 1 },
            { item = 'c4_charge', count = 1 },
            { item = 'thermite', count = 1 },
        },
    },
    moneytruck = {
        enabled = true,
        label = 'Money Trucks',
        description = 'Stop the Stockade, drop the guards, thermite the rear.',
        maxPlayers = 4,
        minPlayers = 2,
        minPolice = 3,
        cooldown = 42 * 60,
        difficulty = 3,
        timeout = 20 * 60,
        icon = 'truck',
        color = '#fdba74',
        requiredItems = { { item = 'thermite', count = 1 } },
    },
    cargotruck = {
        enabled = true,
        label = 'Cargo Trucks',
        description = 'Hijack a sealed freight mule and crack the container at the drop.',
        maxPlayers = 4,
        minPlayers = 1,
        minPolice = 2,
        cooldown = 30 * 60,
        difficulty = 3,
        timeout = 18 * 60,
        icon = 'boxes-stacked',
        color = '#fcd34d',
        requiredItems = {
            { item = 'crowbar', count = 1 },
            { item = 'drill', count = 1 },
        },
    },
    bobcat = {
        enabled = true,
        label = 'Bobcat Security',
        description = 'Assault the yard, plant C4 on the vault, empty the cages.',
        maxPlayers = 6,
        minPlayers = 3,
        minPolice = 5,
        cooldown = 70 * 60,
        difficulty = 5,
        timeout = 26 * 60,
        icon = 'shield-halved',
        color = '#fb923c',
        requiredItems = {
            { item = 'c4_charge', count = 1 },
            { item = 'electronickit', count = 1 },
            { item = 'crowbar', count = 1 },
        },
    },
    yacht = {
        enabled = true,
        label = 'Yacht Heist',
        description = 'Board the Aquarius, clear armed crew, loot cabins and the safe.',
        maxPlayers = 5,
        minPlayers = 2,
        minPolice = 4,
        cooldown = 60 * 60,
        difficulty = 4,
        timeout = 24 * 60,
        icon = 'ship',
        color = '#67e8f9',
        requiredItems = {
            { item = 'lockpick', count = 1 },
            { item = 'electronickit', count = 1 },
            { item = 'drill', count = 1 },
        },
    },
    train = {
        enabled = true,
        label = 'Train Heist',
        description = 'Hit the Davis Quartz freight, drop car guards, grind the cash car.',
        maxPlayers = 5,
        minPlayers = 2,
        minPolice = 4,
        cooldown = 55 * 60,
        difficulty = 4,
        timeout = 22 * 60,
        icon = 'train',
        color = '#c4b5fd',
        requiredItems = {
            { item = 'crowbar', count = 1 },
            { item = 'drill', count = 1 },
        },
    },
    cargoship = {
        enabled = true,
        label = 'Cargo Ship',
        description = 'Board the Elysian freighter, hack containers, lift high-value crates.',
        maxPlayers = 6,
        minPlayers = 2,
        minPolice = 4,
        cooldown = 65 * 60,
        difficulty = 4,
        timeout = 26 * 60,
        icon = 'anchor',
        color = '#5eead4',
        requiredItems = {
            { item = 'hacking_laptop', count = 1 },
            { item = 'crowbar', count = 1 },
            { item = 'drill', count = 1 },
        },
    },
}

Config.Skill = {
    keys = { 'w', 'a', 's', 'd', 'q', 'e' },
    atm = { 'easy', 'medium', 'medium' },
    storeRegister = { 'easy', 'medium', 'medium' },
    storeSafe = { 'medium', 'medium', 'hard' },
    houseDoor = { 'easy', 'medium', 'medium' },
    houseLoot = { 'easy', 'medium' },
    vehicle = { 'medium', 'medium', 'hard' },
    ammuHack = { 'medium', 'medium' },
    ammuCase = { 'easy', 'medium' },
    ammuLocker = { 'medium', 'hard', 'hard' },
    bankHack = { 'medium', 'medium', 'hard' },
    bankVault = { 'medium', 'hard', 'hard' },
    paletoPower = { 'medium', 'hard' },
    paletoVault = { 'hard', 'hard', 'hard' },
    jewelryHack = { 'medium', 'hard', 'hard' },
    jewelryCase = { 'medium', 'medium' },
    jewelrySafe = { 'hard', 'hard' },
    pacificPower = { 'hard', 'hard' },
    pacificPad = { 'hard', 'hard', 'hard' },
    pacificVault = { 'hard', 'hard', 'hard' },
    truck = { 'medium', 'hard', 'hard' },
    cargo = { 'medium', 'medium', 'hard' },
    bobcatHack = { 'hard', 'hard' },
    bobcatVault = { 'hard', 'hard', 'hard' },
    yachtHack = { 'medium', 'hard', 'hard' },
    yachtSafe = { 'hard', 'hard' },
    trainCut = { 'medium', 'hard', 'hard' },
    shipHack = { 'hard', 'hard', 'hard' },
}

Config.Minigames = {
    keypadLength = 5,
    keypadPreviewMs = 1400,
    thermiteSize = 5,
    thermiteTargets = 7,
    thermiteTime = 9,
    circuitNodes = 6,
    circuitTime = 12,
}

Config.Anims = {
    hack = { dict = 'anim@heists@ornate_bank@hack', clip = 'hack_loop', flag = 49 },
    lockpick = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer', flag = 49 },
    thermite = { dict = 'anim@heists@ornate_bank@thermal_charge', clip = 'thermal_charge', flag = 16 },
    drill = { dict = 'anim@heists@fleeca_bank@drilling', clip = 'drill_straight_idle', flag = 49 },
    loot = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab', flag = 49 },
    smash = { dict = 'missheist_jewel', clip = 'smash_case', flag = 49 },
    weld = { dict = 'amb@world_human_welding@male@base', clip = 'base', flag = 49 },
    plant = { dict = 'weapons@projectile@sticky_bomb', clip = 'plant_vertical', flag = 16 },
}

Config.Webhook = {
    enabled = false,
    url = '',
}

Config.Admin = {
    resetCommand = 'robberyreset',
    group = 'group.admin',
}

Config.Ui = {
    brand = 'NEXUS',
    subtitle = 'Contract Network v2',
    showPoliceCount = true,
    showDifficulty = true,
}
