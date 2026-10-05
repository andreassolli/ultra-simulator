# Ultra Speaker simulator

A browser simulator of the Ultra Speaker fight where you pick your class (**Lord of Order**, **Arch Paladin** or **Legion Revenant**; the other two plus a DPS are scripted), using
art and animations pulled from the Flash files:

| SWF | Used for |
| --- | --- |
| `town-ultraspeaker-6oct23.swf` | The **Boss** frame: background, `BossPad`, `Left` spawn pad, the `SafeA` box, the `rune1` / `safe1` Equal-zone clips |
| `monster-UltraMalg.swf` | The boss clip with all animation labels (Attack1, Shadowflame, ChargeA/Loop, Absorption, Magic, Die, …) |
| `Assets_20260731.swf` | Class skill icons (`LoO*`, `LR*`, `apal*`) and the cast effect (`Symbol3aaaaa_loo_757`) |
| `Armor.swf`, `Cape.swf`, `Helm.swf`, `Weapon.swf` | The gear on your character (Coastal armor, Necro cape, Steel Seas visage, Noxious Rifle). `tools/equip_skeleton.py` swaps them into the skeleton the same way `AvatarMC.loadArmorPieces()` does, so the player uses RifleFight/RifleAttack poses |
| `_assets/assets.swf` (main branch) | The character: `mcSkel`, the skeleton `AvatarMC` wraps, with the parts `hideOptionalParts()` hides removed — i.e. what `bin/character_test.swf` shows |
| `Game3.swf` | Used while building the first version (combat pipeline, 24 fps); the class has no `sp_*` effect clips in `Assets`, so none are used |

## Run

```sh
cd sim
python3 -m http.server 8000
# open http://localhost:8000      (?bot=1 auto-pilot, ?speed=4 fast-forward)
```

Controls: **left-click the ground to move** (mouse only); click the boss to target it and walk up to it, `1`–`6` skills, `P` pause. `1` walks you to the boss and auto attacks while in range.
With no zone active everyone stacks on one spot in the middle; during Equal only the named role stays there and the rest move to the right of the box.
`?class=ap|lr|loo` picks the class from the URL.

## Boss abilities

The rotation is the one from the author's web simulator (`js/fight.js`, ported from `speaker.js`):

* **Auto attack** — hits the whole party; each hit adds a *Somber* stack (+7% damage) and strips 7% of the
  boss's armor (starts at 80%).
* **Truth** — hits the role holding the boss. Truths #2–4 and #6–8 of a cycle need the Arch Paladin's **Seal**
  to be up, #5 and #9 need your **Quix**; a missed Seal/Quix is counted and the hit is skipped.
* **Listen** — stuns the boss's current target for 6 s (skills 2–6 locked).
* **Equal** (zone, 4 per cycle, zones 1–4 = DPS, LR, AP, LoO) — only that role may stand **inside** the
  SafeA box. Anyone else inside dies; the named role outside loses the run. The correct role takes 2.4–2.9k
  damage and gets its Somber stacks + armor reset.
* Taunt pattern: `MECHANICS` says which role must hold the boss for each cast. When it is the LoO you must
  Taunt yourself within the 2 s cast, otherwise "Missed Taunt".

Arch Paladin (Seal/Eden, heals) and Legion Revenant (Empowerment) follow the author's scripted rotations; the
DPS role and the rest of the raid drain the boss at 42–52k every 0.6–1.1 s, boss HP is 10,000,000.

## What is exact and what is assumed

Exact from the SWFs: map art and coordinates, boss/LoO art, animation labels and frame ranges.
From the web simulator: every number in `js/fight.js`.

Assumptions you may want to correct:

* **Skill order.** The Flash class has `aa` + four numbered skills + a passive; the web version has
  Harmony/Ordinance/Axiom/Quix/Taunt. I mapped `LoO1`→Harmony … `LoO4`→Quix in `js/config.js` (`loo`), and
  Taunt has no icon in `Assets`.
* **Boss animation per ability** (Attack1 = auto, Shadowflame = Truth, Magic = Listen, ChargeA→Absorption =
  Equal) — the clips don't say which is which.
* The aqw.app monster page could not be fetched from this environment, so the encounter was taken from the
  author's code rather than the wiki.
* Damage reduction: Ordinance −30% to everyone, LR Empowerment −30% for LR, Seal −90% / Eden −15% on Truths.
  (The web code computes but mostly ignores these; this is the intended reading.)
* Items are merged without AQW's skin/hair colouring step, so tinted layers keep their default colours; NPCs are the plain default silhouette.

## Regenerating assets

```sh
FFDEC_DIR=/path/to/ffdec GEAR_DIR=/path/to/gear ./tools/build_assets.sh Game3.swf town-ultraspeaker-6oct23.swf Assets_20260731.swf monster-UltraMalg.swf
```

Needs JPEXS FFDec, a JDK and `pip install pillow`.
