#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDK="${FLEX_SDK:-$HOME/Downloads/apache-flex-sdk-4.16.1-bin}"
MXMLC="${MXMLC:-$SDK/bin/mxmlc}"

SRC="$PROJECT_DIR/src"
OUT="$PROJECT_DIR/bin"

# ./build.sh        -> bin/ultra_sim.swf       (Ultra Speaker simulator, src/UltraSim.as)
# ./build.sh test   -> bin/character_test.swf  (original character test, src/TestMain.as)
case "${1:-sim}" in
    test) MAIN="$SRC/TestMain.as"; OUTPUT="$OUT/character_test.swf"; WIDTH=1280; HEIGHT=720; FPS=30 ;;
    *)    MAIN="$SRC/UltraSim.as"; OUTPUT="$OUT/ultra_sim.swf";       WIDTH=960;  HEIGHT=550; FPS=24 ;;
esac

if [ ! -x "$MXMLC" ] && [ ! -f "$MXMLC" ]; then
    echo "ERROR: mxmlc was not found:"
    echo "  $MXMLC"
    echo
    echo "Set FLEX_SDK or MXMLC, for example:"
    echo "  export FLEX_SDK=\"$HOME/Downloads/apache-flex-sdk-4.16.1-bin\""
    exit 1
fi

mkdir -p "$OUT"

echo "=========================================="
echo "Building $(basename "$OUTPUT")"
echo "=========================================="
echo "Project: $PROJECT_DIR"
echo "SDK:     $SDK"
echo "MXMLC:   $MXMLC"
echo "Output:  $OUTPUT"
echo

# AvatarMC contains AIR-specific file-loading code. The first build therefore
# uses the AIR configuration if the installed Flex SDK provides it. If this
# SDK has no AIR configuration, fall back to the normal Flex configuration so
# we can see the remaining dependency errors clearly.
if [ -f "$SDK/frameworks/air-config.xml" ]; then
    CONFIG="+configname=air"
else
    CONFIG=""
fi

"$MXMLC" \
    -source-path+="src" \
    -default-size $WIDTH $HEIGHT \
    -default-frame-rate=$FPS \
    -output="$OUTPUT" \
    $CONFIG \
    "$MAIN"

echo
echo "=========================================="
echo "BUILD COMPLETE"
echo "=========================================="
echo "$OUTPUT"
