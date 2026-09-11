--[[
    Paste these entries into ox_inventory/data/items.lua
    Copy install/images/robbery_tablet.png into ox_inventory/web/images/

    The client export must match this resource folder name:
    export = 'djfivem-robbery.useTablet'
]]

return {
    ['robbery_tablet'] = {
        label = 'Crime Tablet',
        weight = 400,
        stack = false,
        consume = 0,
        description = 'Encrypted handheld used to browse Nexus contracts and the kit market.',
        client = {
            export = 'djfivem-robbery.useTablet',
            image = 'robbery_tablet.png',
        },
    },

    ['lockpick'] = {
        label = 'Lockpick',
        weight = 160,
        stack = true,
        close = true,
        description = 'Opens store registers, house doors, and stolen cars.',
    },
    ['advancedlockpick'] = {
        label = 'Advanced Lockpick',
        weight = 180,
        stack = true,
        close = true,
        description = 'Harder locks. Lower break chance.',
    },
    ['electronickit'] = {
        label = 'Electronic Kit',
        weight = 300,
        stack = true,
        close = true,
        description = 'Used to bypass security keypads and cameras.',
    },
    ['hacking_laptop'] = {
        label = 'Hacking Laptop',
        weight = 1500,
        stack = false,
        close = true,
        description = 'Required for Pacific Standard and cargo-ship mainframes.',
    },
    ['trojan_usb'] = {
        label = 'Trojan USB',
        weight = 80,
        stack = true,
        close = true,
        description = 'Optional payload stick found in house jobs or bought from Nexus Supply.',
    },
    ['thermite'] = {
        label = 'Thermite',
        weight = 500,
        stack = true,
        close = true,
        description = 'Burns through vault doors and armored plating.',
    },
    ['c4_charge'] = {
        label = 'C4 Charge',
        weight = 750,
        stack = true,
        close = true,
        description = 'Breaches Pacific vault doors and Bobcat cages.',
    },
    ['drill'] = {
        label = 'Drill',
        weight = 1200,
        stack = false,
        close = true,
        description = 'Used on ATMs, safes, lockers, and freight seals.',
    },
    ['crowbar'] = {
        label = 'Crowbar',
        weight = 800,
        stack = false,
        close = true,
        description = 'Smashes display cases and pries cargo.',
    },
    ['black_money'] = {
        label = 'Dirty Cash',
        weight = 0,
        stack = true,
        description = 'Unmarked bills from a robbery.',
    },
    ['goldbar'] = {
        label = 'Gold Bar',
        weight = 500,
        stack = true,
    },
    ['goldwatch'] = {
        label = 'Gold Watch',
        weight = 150,
        stack = true,
    },
    ['diamond'] = {
        label = 'Diamond',
        weight = 80,
        stack = true,
        description = 'Cut stone lifted from jewelry and vault jobs.',
    },
}
