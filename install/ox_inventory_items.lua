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
        description = 'Encrypted handheld used to browse and start robbery contracts.',
        client = {
            export = 'djfivem-robbery.useTablet',
            image = 'robbery_tablet.png',
        },
    },

    -- Optional extras if your server does not already have them
    ['electronickit'] = {
        label = 'Electronic Kit',
        weight = 300,
        stack = true,
        close = true,
        description = 'Used to bypass security keypads.',
    },
    ['thermite'] = {
        label = 'Thermite',
        weight = 500,
        stack = true,
        close = true,
        description = 'Burns through vault doors and armored plating.',
    },
    ['drill'] = {
        label = 'Drill',
        weight = 1200,
        stack = false,
        close = true,
        description = 'Used on ATMs, safes, and weapon lockers.',
    },
    ['crowbar'] = {
        label = 'Crowbar',
        weight = 800,
        stack = false,
        close = true,
        description = 'Smashes Ammunation display cases.',
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
}
