#!/bin/bash
#
# norch — hides the MacBook notch by baking it into the wallpaper.
#
#   ./norch.sh photo.jpg              # writes photo-norch.png next to the input
#   ./norch.sh photo.jpg out.png      # explicit output path
#   ./norch.sh photo.jpg --set        # write and apply as the desktop picture
#
# The image is scaled to fill the screen, the menu bar strip is painted solid
# black (so the notch disappears into it) and the remaining picture is masked
# to a rounded rectangle matching the macOS window corner radius, so window
# corners no longer leave slivers of wallpaper showing through.
#
# Constants below describe ONE screen. Run ./probe.swift to get them for
# another Mac — see README.md.
#

set -euo pipefail

# --- screen geometry -------------------------------------------------------
# MacBook Pro 14", macOS 27, "More Space"-ish scaled mode.
SCREEN_PT_W=1352       # NSScreen.frame.width, points
SCREEN_PT_H=878        # NSScreen.frame.height, points
SCALE=2                # NSScreen.backingScaleFactor

# --- look ------------------------------------------------------------------
NOTCH_PT=30            # black strip height; must reach the top edge of windows
RADIUS_PT=16           # NSWindow._cornerRadius on macOS 27
EDGE_PX=1              # black hairline on the left/right/bottom screen edges

# ---------------------------------------------------------------------------
# Render at the resolution macOS actually composites the desktop at
# (points x backing scale). Rendering at the panel's native resolution instead
# would make the OS rescale the result and blur these one-pixel edges.
px() { printf '%.0f' "$(echo "$1 * $SCALE" | bc -l)"; }
W=$(px $SCREEN_PT_W); H=$(px $SCREEN_PT_H)
NOTCH=$(px $NOTCH_PT); RADIUS=$(px $RADIUS_PT)

IN="${1:?usage: ./norch.sh <image> [output.png | --set]}"
if [[ "${2:-}" == "--set" ]]; then SET=1; OUT="${IN%.*}-norch.png"
else SET=0; OUT="${2:-${IN%.*}-norch.png}"; fi

# Picture area: below the strip, inset by the hairline on the other three sides.
L=$EDGE_PX; T=$NOTCH; R=$((W-1-EDGE_PX)); B=$((H-1-EDGE_PX))

echo "-> ${W}x${H}: strip ${NOTCH}px, radius ${RADIUS}px, edge ${EDGE_PX}px"

magick "$IN" \
  -resize "${W}x${H}^" -gravity center -extent "${W}x${H}" \
  -colorspace sRGB \
  \( -size "${W}x${H}" xc:black \
     -fill white -draw "roundrectangle $L,$T $R,$B $RADIUS,$RADIUS" \
     -alpha off \) \
  -compose CopyOpacity -composite \
  -background black -alpha remove -alpha off \
  +profile '*' \
  "$OUT"

echo "OK $OUT"

if [[ $SET == 1 ]]; then
  osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$OUT\"" >/dev/null
  echo "OK applied as desktop picture"
fi
