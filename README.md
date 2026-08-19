# djfivem-robbery

A simpler Qbox robbery tablet. Players use a `robbery_tablet` item from ox_inventory, form a crew, and run a short list of default-map jobs instead of a huge heist pack.

## Crew sizes

| Job | Max players |
| --- | --- |
| Bank heists | 4 |
| Store robberies | 4 |
| Ammunation stores | 4 |
| Money trucks | 4 |
| ATMs | 2 |
| Vehicle robberies | 2 |

Solo is allowed. The tablet just caps the lobby.

## Included contracts

- **Banks:** 3 Fleeca branches (Legion, Alta, Burton) plus Paleto Savings
- **Stores:** 6x 24/7 / LTD (Grove, Innocence, Little Seoul, Vinewood, Sandy, Paleto)
- **ATMs:** 6 street machines
- **Vehicles:** 4 boost-and-deliver jobs
- **Money trucks:** 3 Gruppe Sechs routes
- **Ammunation:** 5 stores (hack, smash cases, drill locker)

Locations use **vanilla GTA V interiors**. If you run Gabz or other MLOs, move the coords in `shared/locations.lua`.

## Requirements

- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_target](https://github.com/overextended/ox_target)

Keep this resource folder named `djfivem-robbery` (the tablet item export points at that name).

## Install

1. Drop the folder into `resources` (or a `[qbx]` pack).
2. Copy `install/images/robbery_tablet.png` into `ox_inventory/web/images/`.
3. Merge the items from `install/ox_inventory_items.lua` into `ox_inventory/data/items.lua`.
   - `robbery_tablet` is required.
   - Skip any extras you already have (`lockpick`, `electronickit`, `thermite`, `drill`, `crowbar`, `black_money`).
4. Restart `ox_inventory` (or the server) after adding items.
5. Start order in `server.cfg`:

```cfg
ensure ox_lib
ensure ox_target
ensure qbx_core
ensure ox_inventory
ensure djfivem-robbery
```

6. Give a tablet in-game, for example:

```
/giveitem [id] robbery_tablet 1
```

## How it plays

1. Use the crime tablet from inventory.
2. Pick a job type, then a location. That creates a crew.
3. **Invite nearby** players (within 8m). They get an ox_lib prompt.
4. **Start contract** when police count, cooldown, and crew size are valid.
5. GPS is set. Use ox_target at the objective.
6. ox_lib skill checks + progress bars handle hacking, lockpicking, thermite, drilling, and looting.
7. Police get a blip/alert on the first noisy action.

Required tools (configurable in `shared/config.lua`):

- Banks: `electronickit`, `thermite`
- Stores: `lockpick`, `drill`
- ATMs: `drill`
- Vehicles: `lockpick`
- Ammunation: `electronickit`, `crowbar`, `drill`

Payouts default to the `black_money` item. If that item is missing, cash is granted instead.

## Config you will actually touch

`shared/config.lua`

- `PoliceJobs` and `RequireOnDuty`
- `Types.*.maxPlayers` / `minPolice`
- `Items` names to match your inventory
- `RewardMode` = `looter` or `split`
- `Dispatch.resource` = `builtin` (default), `ps-dispatch`, `cd_dispatch`, `qs-dispatch`, or `custom`
- `Webhook` for Discord logs
- `JobTimeout` (default 20 minutes)

`shared/locations.lua` — coords, rewards, cooldowns, vault door models.

Admin cooldown reset:

```
/robberyreset all
/robberyreset fleeca_legion
```

Restricted to `group.admin`.

## Dispatch

Default `builtin` notifies on-duty `Config.PoliceJobs` with ox_lib + a map blip.

For ps-dispatch / cd_dispatch / qs-dispatch, set `Config.Dispatch.resource` to that name. Those resources vary by version; if the alert does not fire, keep `builtin` or hook `Config.Dispatch.custom`.

## Notes

- On-duty police cannot open the tablet or join a crew.
- A location goes on cooldown when the contract **starts**, not when it finishes.
- Bank vault doors rotate on the vanilla `v_ilev_gb_vauldr` / Paleto vault model. Doorlock resources are not required.
- Money trucks spawn a Stockade with two armed guards. Kill or stop the truck, then loot the rear crates.
- Vehicle jobs lockpick at the spawn, then deliver to the marked drop-off.
