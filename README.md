# djfivem-robbery v2 — NEXUS

Qbox heist pack: a crime tablet, 15 contract types, a built-in kit store, Wasabi police / MDT / dispatch alerts, armed guards on the heavy jobs, and server-side anti-exploit checks.

Folder name must stay `djfivem-robbery` (the tablet item export points at that name).

## What players get

Use a `robbery_tablet` from ox_inventory. The tablet has three tabs:

- **Contracts** — pick a job type, pick a location, form a crew
- **Market** — buy lockpicks, drills, thermite, C4, laptops, and a spare tablet
- **Crew** — invite nearby players and start when kit + police counts are met

A world dealer (Nexus Supply) also opens the Market tab. GPS waypoint is set on start. ox_target handles every objective. Heavy jobs spawn armed guards. Police get a Wasabi MDT dispatch on the first noisy action.

## Contract types

| Type | Max crew | Default PD | Notes |
| --- | --- | --- | --- |
| ATM | 2 | 0 | Drill cassette |
| Store | 4 | 1 | Tills then office safe |
| House | 3 | 1 | Lockpick door, search rooms |
| Vehicle | 2 | 1 | Boost and deliver |
| Ammunation | 4 | 2 | Cameras, cases, locker + guards |
| Fleeca | 4 | 2 | Hack, thermite, boxes + guards |
| Money truck | 4 | 3 | Stop Stockade, thermite rear |
| Cargo truck | 4 | 2 | Hijack mule/benson, crack crate |
| Paleto | 5 | 4 | Cut power, vault, **armed on start** |
| Vangelico | 5 | 4 | Gallery alarm, cases, office safe |
| Train | 5 | 4 | Davis Quartz freight + guards |
| Yacht | 5 | 4 | Aquarius board, cabins, owner safe |
| Cargo ship | 6 | 4 | Elysian freighter containers |
| Bobcat | 6 | 5 | Yard assault, C4 vault |
| Pacific | 6 | 6 | Power, keypad, C4, trolleys |

Locations use **vanilla GTA V interiors**. If you run Gabz or other MLOs, move coords in `shared/locations.lua`.

Set `Config.Types.<id>.enabled = false` to hide a type.

## Requirements

- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_target](https://github.com/overextended/ox_target)

### Wasabi (recommended)

- `wasabi_police` or `wasabi_police_v2` — on-duty count via `getPoliceOnline`
- `wasabi_mdt` — live dispatch via `CreateDispatch` (MDT v2 includes dispatch)

If Wasabi is not started, the script falls back to qbx job counts and a builtin ox_lib + map-blip alert.

## Install

1. Drop the folder into `resources` (keep the name `djfivem-robbery`).
2. Copy `install/images/robbery_tablet.png` into `ox_inventory/web/images/` if you have it.
3. Merge `install/ox_inventory_items.lua` into `ox_inventory/data/items.lua`.
   - Required: `robbery_tablet`
   - New v2 items: `hacking_laptop`, `c4_charge`, `advancedlockpick`, `trojan_usb`, `diamond`
   - Skip extras you already have
4. Restart `ox_inventory`, then this resource.

```cfg
ensure ox_lib
ensure ox_target
ensure qbx_core
ensure ox_inventory
ensure wasabi_police
ensure wasabi_mdt
ensure djfivem-robbery
```

Give a tablet:

```
/giveitem [id] robbery_tablet 1
```

Or buy one from Nexus Supply.

## How a contract plays

1. Open the tablet, pick a type and location (creates a crew).
2. Invite nearby players (8m). On-duty cops cannot join.
3. Start when the crew has the listed kit, enough police, and the site is not on cooldown.
4. GPS is set. ox_target appears **only for that live job** (idle clients do not keep every zone registered).
5. Harder jobs use keypad / thermite-grid / circuit minigames, then a progress bar.
6. First noisy step fires Wasabi MDT dispatch. Some sites spawn armed guards on start; others spawn on the alarm.
7. Location cooldown starts when the contract **starts**. Personal cooldown is 8 minutes by default.

## Kit store

`shared/store.lua`

- Ped + optional blip behind the garment factory (`707.34, -966.84, 30.41`)
- Prices, stock, and currency are config
- `useDirtyCash = true` charges `black_money` instead of cash
- `requireProximity = true` if you want tablet purchases to only work at the dealer
- Server validates quantity, stock, funds, and refunds if the inventory add fails

## Police / MDT / dispatch

`shared/config.lua`

```lua
Config.Police = {
    countResource = 'auto', -- wasabi_police | wasabi_police_v2 | auto | qbx
    blockOfficersFromTablet = true,
    useWasabiMdtOfficerCheck = true,
}

Config.Dispatch = {
    enabled = true,
    resource = 'wasabi_mdt', -- wasabi_mdt | wasabi_dispatch | ps-dispatch | cd_dispatch | qs-dispatch | builtin | custom
    code = '10-90',
    senderName = 'Silent Alarm',
    fallbackBuiltin = true,
}
```

Per-type titles, codes, and priorities live in `Config.DispatchProfiles`.

## Guards

`Config.Guards.enabled` is the global switch. Per-location blocks in `shared/locations.lua`:

```lua
guards = {
    enabled = true,
    spawnOn = 'start', -- or 'alarm'
    model = 's_m_m_armoured_01',
    weapon = 'WEAPON_CARBINERIFLE',
    accuracy = 48,
    armour = 80,
    peds = { vector4(x, y, z, heading), ... },
}
```

Paleto, Pacific, Bobcat, yacht, train, cargo ship, some houses/vehicles, and Ammunation spawn armed peds.

## Anti-exploit

- Rewards are granted only on the server
- Interaction tokens expire (default 90s); finish must match begin
- Distance + item re-check on finish
- Rate limits on tablet, start, loot, and shop callbacks
- Crate IDs must match the job's loot-spot count
- Police cannot open the tablet or join a crew
- Target zones exist only while a job is live
- Shop refunds if `AddItem` fails

## Config you will actually touch

`shared/config.lua` — police jobs, cooldowns, min police, skill checks, minigame difficulty, dispatch, anti-exploit, webhook, UI brand

`shared/store.lua` — dealer coords, prices, stock

`shared/locations.lua` — coords, payouts, guard posts, vault doors

Admin cooldown reset (`group.admin`):

```
/robberyreset all
/robberyreset fleeca_legion
```

## Notes

- Vault doors rotate on vanilla models. Doorlock resources are not required.
- Money / cargo trucks spawn with armed occupants. Kill or stop the vehicle, then loot the rear.
- Raise `Config.Types.*.minPolice` if your city is busy; lower it for testing.
- `Config.Debug = true` unlocks `/robberytab` without the item.
