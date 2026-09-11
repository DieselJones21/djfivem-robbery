-- Black-market kit dealer. Prices and stock are fully configurable.
Config.Store = {
    enabled = true,
    label = 'Nexus Supply',
    subtitle = 'Untraceable kit. Cash only. No receipts.',
    account = 'cash', -- cash account, or set useDirtyCash = true
    useDirtyCash = false,
    maxQty = 10,
    ped = {
        model = 'g_m_m_armboss_01',
        coords = vector4(707.34, -966.84, 30.41, 275.0), -- behind Digital Den / garment factory
        scenario = 'WORLD_HUMAN_SMOKING',
    },
    blip = {
        enabled = true,
        sprite = 110,
        color = 1,
        scale = 0.75,
        label = 'Black Market Kit',
    },
    interactDistance = 2.4,
    -- true = must stand at the dealer to buy (even from the tablet Market tab)
    requireProximity = false,
    items = {
        {
            item = 'lockpick',
            label = 'Lockpick',
            description = 'Tills, house doors, and boost cars.',
            price = 250,
            stock = -1,
        },
        {
            item = 'advancedlockpick',
            label = 'Advanced Lockpick',
            description = 'Harder locks. Lower break chance.',
            price = 900,
            stock = -1,
        },
        {
            item = 'electronickit',
            label = 'Electronic Kit',
            description = 'Keypads, cameras, and alarm panels.',
            price = 1450,
            stock = -1,
        },
        {
            item = 'hacking_laptop',
            label = 'Hacking Laptop',
            description = 'Required for Pacific and cargo-ship mainframes.',
            price = 4200,
            stock = 8,
        },
        {
            item = 'trojan_usb',
            label = 'Trojan USB',
            description = 'Optional payload stick for long hacks.',
            price = 1800,
            stock = 12,
        },
        {
            item = 'drill',
            label = 'Industrial Drill',
            description = 'ATMs, safes, lockers, freight seals.',
            price = 2800,
            stock = -1,
        },
        {
            item = 'crowbar',
            label = 'Crowbar',
            description = 'Display cases, house rooms, cargo doors.',
            price = 650,
            stock = -1,
        },
        {
            item = 'thermite',
            label = 'Thermite Charge',
            description = 'Vault doors and armored truck plating.',
            price = 3600,
            stock = 10,
        },
        {
            item = 'c4_charge',
            label = 'C4 Charge',
            description = 'Pacific vault and Bobcat cage doors.',
            price = 5200,
            stock = 6,
        },
        {
            item = 'robbery_tablet',
            label = 'Crime Tablet',
            description = 'Opens the Nexus contract network.',
            price = 8500,
            stock = 4,
        },
    },
}
