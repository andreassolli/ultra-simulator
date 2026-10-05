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

echo "== class skill icons (LoO, LR, AP) from Assets"
export_pack "$ASSETS" 0.3 icons LoO1 LoO2 LoO3 LoO4 LoOaa LoOp LR1 LR2 LR3 LR4 LRaa LRp2 apal1 apal2 apal3 apal4

echo "== cast effect (symbol 9333, Symbol3aaaaa_loo_757)"
export_pack "$ASSETS" 0.5 classfx 9333

echo "== character: mcSkel from the recovered project's _assets/assets.swf, optional parts hidden"
CHAR="$HERE/../../_assets/assets.swf"
"${FFDEC[@]}" -swf2xml "$CHAR" "$WORK/char.xml" > /dev/null
python3 "$HERE/clean_skeleton.py" "$WORK/char.xml" "$WORK/char_clean.xml"
"${FFDEC[@]}" -xml2swf "$WORK/char_clean.xml" "$WORK/char_clean.swf" > /dev/null
java -cp "$CP" SwfIndex "$WORK/char_clean.swf" 2408 | grep -v '^Picked' > "$WORK/chars.rects"
"${FFDEC[@]}" -zoom 0.65 -selectid 2408 -format sprite:png -export sprite "$WORK/chars" "$WORK/char_clean.swf" > /dev/null
python3 "$HERE/pack_sprites.py" "$WORK/chars" "$WORK/chars.rects" "$OUT/chars" 0.65 "8-16,54-68,622-633,703-722,911-931,932-958,495-502,810-827,828-849"

echo "done -> $OUT"
