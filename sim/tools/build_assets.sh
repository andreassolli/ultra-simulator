#!/bin/bash
# Regenerate sim/assets/* from the original SWFs with JPEXS FFDec.
#
#   FFDEC_DIR=/path/to/ffdec_x.y.z \
#   ./build_assets.sh Game3.swf town-ultraspeaker-6oct23.swf Assets_20260731.swf monster-UltraMalg.swf
#
# FFDEC_DIR must contain ffdec-cli.jar and lib/ffdec_lib.jar
# (https://github.com/jindrapetrik/jpexs-decompiler/releases).
# Requires: java (JDK, for javac), python3 + Pillow (pip install pillow).
set -euo pipefail

if [ "$#" -ne 4 ]; then
    echo "usage: FFDEC_DIR=... $0 <Game3.swf> <town.swf> <Assets.swf> <monster.swf>" >&2
    exit 1
fi
FFDEC_DIR="${FFDEC_DIR:?set FFDEC_DIR to the folder holding ffdec-cli.jar}"
TOWN="$2"; ASSETS="$3"; MONSTER="$4"   # Game3.swf ($1) is only read for combat rules, not exported

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/../assets"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
FFDEC=(java -jar "$FFDEC_DIR/ffdec-cli.jar")
CP="$WORK/cls:$FFDEC_DIR/lib/*"

mkdir -p "$WORK/cls" "$OUT"
javac -cp "$FFDEC_DIR/lib/*" -d "$WORK/cls" "$HERE/SwfIndex.java"

# $1 swf, $2 zoom, $3 name, rest: class prefixes / ids  -> assets/<name>
export_pack() {
    local swf="$1" zoom="$2" name="$3"; shift 3
    java -cp "$CP" SwfIndex "$swf" "$@" | grep -v '^Picked up' > "$WORK/$name.rects"
    local ids; ids="$(cut -d' ' -f1 "$WORK/$name.rects" | paste -sd, -)"
    "${FFDEC[@]}" -zoom "$zoom" -selectid "$ids" -format sprite:png -export sprite "$WORK/$name" "$swf" > /dev/null
    python3 "$HERE/pack_sprites.py" "$WORK/$name" "$WORK/$name.rects" "$OUT/$name" "$zoom"
}

echo "== boss (monster-UltraMalg.swf)"
export_pack "$MONSTER" 0.2 boss UltraMalg

echo "== map clips (town-ultraspeaker)"
export_pack "$TOWN" 1.0 map 373 374

echo "== map background"
"${FFDEC[@]}" -selectid 354 -format sprite:png -export sprite "$WORK/bg" "$TOWN" > /dev/null
python3 - "$WORK/bg" "$OUT/map/bg.jpg" <<'PY'
import glob, sys
from PIL import Image
im = Image.open(glob.glob(sys.argv[1] + "/*/1.png")[0]).convert("RGB")
# sprite 354 sits at stage (-355.7, -125); its registration point is at (170, 527) in the export
im.crop((526, 652, 1486, 1152)).save(sys.argv[2], quality=88)
PY

echo "== skill effects (sp_* in Assets)"
export_pack "$ASSETS" 0.5 fx sp_

echo "== skill icons (same names without sp_)"
java -cp "$CP" SwfIndex "$ASSETS" sp_ | grep -v '^Picked up' | awk '{sub(/^sp_/,"",$2); print $2}' > "$WORK/icon_names.txt"
java -cp "$CP" SwfIndex "$ASSETS" $(cat "$WORK/icon_names.txt") | grep -v '^Picked up' \
    | awk 'NR==FNR{want[$1]=1; next} ($2 in want) && !/ sp_/' "$WORK/icon_names.txt" - > "$WORK/icons.rects"
IDS="$(cut -d' ' -f1 "$WORK/icons.rects" | paste -sd, -)"
"${FFDEC[@]}" -zoom 1 -selectid "$IDS" -format sprite:png -export sprite "$WORK/icons" "$ASSETS" > /dev/null
python3 "$HERE/pack_sprites.py" "$WORK/icons" "$WORK/icons.rects" "$OUT/icons" 1.0

echo "done -> $OUT"
