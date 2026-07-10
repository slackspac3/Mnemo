#!/bin/sh

set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
catalog_dir="$script_dir/../../Mnemo/Assets.xcassets/AppIcon.appiconset"
gray_profile="/System/Library/ColorSync/Profiles/Generic Gray Gamma 2.2 Profile.icc"

command -v rsvg-convert >/dev/null 2>&1 || {
    echo "error: rsvg-convert is required" >&2
    exit 1
}

command -v sips >/dev/null 2>&1 || {
    echo "error: sips is required" >&2
    exit 1
}

[ -f "$gray_profile" ] || {
    echo "error: missing Gray Gamma 2.2 ColorSync profile" >&2
    exit 1
}

temporary_dir="$(mktemp -d "${TMPDIR:-/tmp}/mnemo-app-icon.XXXXXX")"
trap 'rm -rf "$temporary_dir"' EXIT HUP INT TERM

rsvg-convert --width 1024 --height 1024 \
    --output "$temporary_dir/MnemoAppIcon-Default.png" \
    "$script_dir/MnemoAppIcon-Default.svg"
rsvg-convert --width 1024 --height 1024 \
    --output "$temporary_dir/MnemoAppIcon-Dark.png" \
    "$script_dir/MnemoAppIcon-Dark.svg"
rsvg-convert --width 1024 --height 1024 \
    --output "$temporary_dir/MnemoAppIcon-Tinted-RGB.png" \
    "$script_dir/MnemoAppIcon-Tinted.svg"
sips --matchTo "$gray_profile" \
    "$temporary_dir/MnemoAppIcon-Tinted-RGB.png" \
    --out "$temporary_dir/MnemoAppIcon-Tinted.png" >/dev/null

assert_metadata() {
    image="$1"
    expected_space="$2"
    expected_alpha="$3"
    metadata="$(sips -g pixelWidth -g pixelHeight -g format -g space -g profile -g hasAlpha "$image")"

    echo "$metadata" | grep -q "pixelWidth: 1024"
    echo "$metadata" | grep -q "pixelHeight: 1024"
    echo "$metadata" | grep -q "format: png"
    echo "$metadata" | grep -q "space: $expected_space"
    echo "$metadata" | grep -q "hasAlpha: $expected_alpha"

    if [ "$expected_space" = "Gray" ]; then
        echo "$metadata" | grep -q "profile: Generic Gray Gamma 2.2 Profile"
    fi
}

assert_metadata "$temporary_dir/MnemoAppIcon-Default.png" "RGB" "no"
assert_metadata "$temporary_dir/MnemoAppIcon-Dark.png" "RGB" "yes"
assert_metadata "$temporary_dir/MnemoAppIcon-Tinted.png" "Gray" "no"

install -m 0644 "$temporary_dir/MnemoAppIcon-Default.png" "$catalog_dir/MnemoAppIcon-Default.png"
install -m 0644 "$temporary_dir/MnemoAppIcon-Dark.png" "$catalog_dir/MnemoAppIcon-Dark.png"
install -m 0644 "$temporary_dir/MnemoAppIcon-Tinted.png" "$catalog_dir/MnemoAppIcon-Tinted.png"

echo "Exported and validated AppIcon asset-catalog PNGs."
