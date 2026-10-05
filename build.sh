#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDK="${FLEX_SDK:-$HOME/Downloads/apache-flex-sdk-4.16.1-bin}"
MXMLC="${MXMLC:-$SDK/bin/mxmlc}"

SRC="$PROJECT_DIR/src"
OUT="$PROJECT_DIR/bin"
OUTPUT="$OUT/character_test.swf"

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
echo "Building recovered character test SWF"
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
    -default-size 1280 720 \
    -default-frame-rate=30 \
    -output="$OUTPUT" \
    $CONFIG \
    "$SRC/TestMain.as"

echo
echo "=========================================="
echo "BUILD COMPLETE"
echo "=========================================="
echo "$OUTPUT"
