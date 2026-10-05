# Ultra Speaker simulator (Lord of Order)

A browser simulator of the Ultra Speaker fight where you play the **Lord of Order**, using
art and animations pulled from the Flash files:

| SWF | Used for |
| --- | --- |
| `town-ultraspeaker-6oct23.swf` | The **Boss** frame: background, `BossPad`, `Left` spawn pad, the `SafeA` box, the `rune1` / `safe1` Equal-zone clips |
| `monster-UltraMalg.swf` | The boss clip with all animation labels (Attack1, Shadowflame, ChargeA/Loop, Absorption, Magic, Die, …) |
| `Assets_20260731.swf` | Lord of Order skill icons (`LoO1`–`LoO4`, `LoOaa`, `LoOp`) and the LoO cast effect (`Symbol3aaaaa_loo_757`) |
| `Game3.swf` | Used while building the first version (combat pipeline, 24 fps); the class has no `sp_*` effect clips in `Assets`, so none are used |

## Run

```sh
cd sim
python3 -m http.server 8000
# open http://localhost:8000      (?bot=1 auto-pilot, ?speed=4 fast-forward)
```

Controls: WASD / arrows / click to move, `1`–`6` skills, `P` pause.
`1` Attack (walks you to the boss; auto attacks while in range), `2` Harmony, `3` Ordinance,
`4` Axiom, `5` Quix, `6` Taunt.

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
* The characters are placeholders, not rendered avatars.

## Regenerating assets

```sh
FFDEC_DIR=/path/to/ffdec ./tools/build_assets.sh Game3.swf town-ultraspeaker-6oct23.swf Assets_20260731.swf monster-UltraMalg.swf
```

Needs JPEXS FFDec, a JDK and `pip install pillow`.
