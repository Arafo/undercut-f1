#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
BUILD_CONFIGURATION=${BUILD_CONFIGURATION:-release}
PRODUCT_NAME=${PRODUCT_NAME:-undercutf1}
OUTPUT_DIR=${OUTPUT_DIR:-"$ROOT_DIR/.dist/$PRODUCT_NAME"}
SWIFT_BUILD_FLAGS=${SWIFT_BUILD_FLAGS:-}

mkdir -p "$OUTPUT_DIR/bin" "$OUTPUT_DIR/assets"

swift build --configuration "$BUILD_CONFIGURATION" --product "$PRODUCT_NAME" $SWIFT_BUILD_FLAGS
BIN_DIR=$(swift build --configuration "$BUILD_CONFIGURATION" --show-bin-path $SWIFT_BUILD_FLAGS)

if [[ ! -x "$BIN_DIR/$PRODUCT_NAME" ]]; then
    echo "error: expected $BIN_DIR/$PRODUCT_NAME after build" >&2
    exit 1
fi

cp "$BIN_DIR/$PRODUCT_NAME" "$OUTPUT_DIR/bin/"

stage_assets() {
    local source_dir="$1"
    local target_dir="$2"

    if [[ -d "$source_dir" ]]; then
        mkdir -p "$target_dir"
        cp -R "$source_dir"/. "$target_dir"/
    fi
}

stage_assets "$ROOT_DIR/Sources/UndercutF1TerminalCLI/Resources" "$OUTPUT_DIR/assets/cli"
stage_assets "$ROOT_DIR/swift/UndercutF1Terminal/Sources/UndercutF1Terminal/Resources" "$OUTPUT_DIR/assets/terminal"

cat <<LOG
Swift distribution staged at: $OUTPUT_DIR
  • Binary: $OUTPUT_DIR/bin/$PRODUCT_NAME
  • CLI assets: $OUTPUT_DIR/assets/cli
  • Terminal assets: $OUTPUT_DIR/assets/terminal
LOG
