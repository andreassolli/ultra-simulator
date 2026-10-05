# Ultra Speaker boss simulator

A browser simulator of the Ultra Speaker fight, built from the four SWFs:

| SWF | What the sim takes from it |
| --- | --- |
| `town-ultraspeaker-6oct23.swf` | The **Boss** frame: background, `BossPad`, `Left` spawn pad, `SafeA` box, the `rune1` / `safe1` charge clips and the `zoneSet` a/b logic (`MainTimeline.as`) |
| `monster-UltraMalg.swf` | The boss clip `UltraMalg` with every animation label (Idle, Attack1, Shadowflame, PowerUp/PowerLoop, Attack2, ChargeA/B, Absorption, Magic, Hit, Die…) and its frame scripts |
| `Assets_20260731.swf` | 274 skill effect clips (`sp_*`) and the matching skill icons |
| `Game3.swf` | The client combat rules: 24 fps, 1500 ms GCD, `cd`/`mp`/`range` per action, melee box check (`range <= 301`, 30 px vertical tolerance), auto-walk into range, effect cast pipeline (`castSpellFX`, `fx` = `w`, played at the target) |

## Run

```sh
cd sim
python3 -m http.server 8000     # any static server works
# open http://localhost:8000
```

URL options: `?bot=1` (auto-pilot), `?speed=4`, `?mana=1` (infinite MP), `?set=pslayer` (skill set).

Controls: WASD / arrows / click the ground to move, click the boss to target, `1`–`5` skills
(`1` = auto attack, toggled with `Tab`), `6` potion, `P` pause. The skill-set dropdown loads
any of the 100+ `sp_*` sets into the five slots; each slot can also be changed individually.

## The fight (as modelled)

* **Charge A** (`ChargeA` → `ChargeALoop` → `Absorption`): rune lights, `safe1` glows — be *inside* the SafeA box when it resolves.
* **Charge B** (`ChargeB` → `ChargeBLoop` → `Magic`): rune lit, box dark — be *outside* the box.
* **Power up** (`PowerUp` → `PowerLoop` → `Attack2`): raid blast; the rune turns off on the first `Attack2` frame, exactly like the frame script in the SWF.
* Basic rotation: `Attack1` melee swings and telegraphed `Shadowflame` circles.
* Winning plays `Die` → `Dead`; standing in the wrong zone is lethal.

## What is exact and what is assumed

Everything visual and all positions/animation timings come from the SWFs. The client never
sees boss HP, damage numbers, skill damage or the real mechanic schedule — the AQW server
decides those and only sends `zoneSet` / results. Those values are guesses and live in
[`js/config.js`](js/config.js); adjust them to match the real fight. In particular:

* This map's Boss frame only contains `safe1`; there is no `safe2` clip, so zone B is modelled as "outside the SafeA box".
* Skill damage/cooldowns/mana use one template per slot (`config.slots`), not the real class values. Which clip is the auto attack/skill 1–4 comes from the `sp_<set>aa` / `a1`…`a4` names.
* The player is a placeholder figure (no avatar rendering).

## Regenerating assets

`assets/` is generated from the SWFs; the generated files are committed so the sim runs out of the box.

```sh
FFDEC_DIR=/path/to/ffdec ./tools/build_assets.sh Game3.swf town-ultraspeaker-6oct23.swf Assets_20260731.swf monster-UltraMalg.swf
```

Needs JPEXS FFDec, a JDK and `pip install pillow`. `tools/SwfIndex.java` lists symbols + bounds,
`tools/pack_sprites.py` crops the FFDec frame exports into WebP sheets with a JSON atlas.
