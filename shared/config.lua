Config = {}

Config.Debug = false
Config.Locale = 'en'

-- Jobs counted as on-duty police for min-police checks and alerts
Config.PoliceJobs = {
    police = true,
    sheriff = true,
    bcso = true,
    lssd = true,
    sahp = true,
}

Config.RequireOnDuty = true
Config.InviteDistance = 8.0
Config.InteractDistance = 3.25
Config.JobTimeout = 20 * 60 -- seconds after start
Config.FailIfCrewWiped = true

-- Personal cooldown after starting any contract (0 disables)
Config.PlayerCooldown = 5 * 60

-- Who receives loot: 'looter' (player who grabs it) or 'split' (evenly among crew)
Config.RewardMode = 'looter'

Config.Tablet = {
    item = 'robbery_tablet',
    consume = false,
}

Config.Types = {
    bank = {
        label = 'Bank Heists',
        description = 'Hack the keypad, burn the vault, empty the boxes.',
        maxPlayers = 4,
        minPlayers = 1,
        minPolice = 0,
        cooldown = 45 * 60,
        icon = 'university',
        color = '#7dd3fc',
        requiredItems = {
            { item = 'electronickit', count = 1 }, -- keypad hack
            { item = 'thermite', count = 1 }, -- vault door
        },
    },
    store = {
        label = 'Store Robberies',
        description = 'Lockpick the till, then drill the back-room safe.',
        maxPlayers = 4,
        minPlayers = 1,
        minPolice = 0,
        cooldown = 25 * 60,
        icon = 'store',
        color = '#86efac',
        requiredItems = {
            { item = 'lockpick', count = 1 }, -- cash registers
            { item = 'drill', count = 1 }, -- office safe
        },
    },
    atm = {
        label = 'ATM Jobs',
        description = 'Drill a street ATM and grab the cassette.',
        maxPlayers = 2,
        minPlayers = 1,
        minPolice = 0,
        cooldown = 15 * 60,
        icon = 'credit-card',
        color = '#fde047',
        requiredItems = {
            { item = 'drill', count = 1 },
        },
    },
    vehicle = {
        label = 'Vehicle Robberies',
        description = 'Lockpick a marked car and drop it at the chop shop.',
        maxPlayers = 2,
        minPlayers = 1,
        minPolice = 0,
        cooldown = 20 * 60,
        icon = 'car',
        color = '#fda4af',
        requiredItems = {
            { item = 'lockpick', count = 1 },
        },
    },
    moneytruck = {
        label = 'Money Trucks',
        description = 'Stop the truck, then thermite the armored rear doors.',
        maxPlayers = 4,
        minPlayers = 1,
        minPolice = 0,
        cooldown = 45 * 60,
        icon = 'truck',
        color = '#fdba74',
        requiredItems = {
            { item = 'thermite', count = 1 }, -- armored doors
        },
    },
    ammunation = {
        label = 'Ammunation Hits',
        description = 'Hack cameras, smash cases, drill the gun locker.',
        maxPlayers = 4,
        minPlayers = 1,
        minPolice = 0,
        cooldown = 40 * 60,
        icon = 'gun',
        color = '#d8b4fe',
        requiredItems = {
            { item = 'electronickit', count = 1 }, -- store security
            { item = 'crowbar', count = 1 }, -- display cases
            { item = 'drill', count = 1 }, -- weapon locker
        },
    },
}

Config.Items = {
    lockpick = 'lockpick',
    hack = 'electronickit',
    thermite = 'thermite',
    drill = 'drill',
    crowbar = 'crowbar',
    dirtyCash = 'black_money',
}

-- Fallback if the dirty-cash item is missing from ox_inventory
Config.CashAccount = 'cash'

Config.Dispatch = {
    enabled = true,
    -- ps-dispatch | cd_dispatch | qs-dispatch | linden | custom | builtin
    resource = 'builtin',
    blipTime = 120,
    custom = function(payload)
        -- payload = { type, label, coords, source }
    end,
}

Config.Webhook = {
    enabled = false,
    url = '',
}

Config.Skill = {
    keys = { 'w', 'a', 's', 'd' },
    bankHack = { 'easy', 'medium', 'medium' },
    bankVault = { 'medium', 'medium', 'hard' },
    storeRegister = { 'easy', 'easy' },
    storeSafe = { 'easy', 'medium', 'medium' },
    atm = { 'easy', 'medium' },
    vehicle = { 'easy', 'medium' },
    truck = { 'medium', 'medium' },
    ammuHack = { 'easy', 'medium' },
    ammuCase = { 'easy' },
    ammuLocker = { 'medium', 'medium', 'hard' },
}

Config.Anims = {
    hack = { dict = 'anim@heists@ornate_bank@hack', clip = 'hack_loop', flag = 49 },
    lockpick = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer', flag = 49 },
    thermite = { dict = 'anim@heists@ornate_bank@thermal_charge', clip = 'thermal_charge', flag = 16 },
    drill = { dict = 'anim@heists@fleeca_bank@drilling', clip = 'drill_straight_idle', flag = 49 },
    loot = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab', flag = 49 },
    smash = { dict = 'missheist_jewel', clip = 'smash_case', flag = 49 },
    weld = { dict = 'amb@world_human_welding@male@base', clip = 'base', flag = 49 },
}

Config.Admin = {
    resetCommand = 'robberyreset',
    group = 'group.admin',
}
