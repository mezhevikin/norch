#!/bin/bash
#
# measure.sh — checks NOTCH_PT against the real screen.
#
# Apply a norch wallpaper, leave a window sitting at the top of the screen,
# then run this. It screenshots the desktop and prints the pixel rows around
# the bottom edge of the black strip.
#
# Needs Screen Recording permission for your terminal
# (System Settings > Privacy & Security > Screen & System Audio Recording).
#
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
NOTCH_PT=$(awk -F= '/^NOTCH_PT=/{print $2+0}' "$DIR/norch.sh")
SCALE=$(awk -F= '/^SCALE=/{print $2+0}' "$DIR/norch.sh")
EXPECTED=$(printf '%.0f' "$(echo "$NOTCH_PT * $SCALE" | bc -l)")

SHOT=$(mktemp -t norch).png
screencapture -x -t png "$SHOT"
W=$(magick identify -format '%w' "$SHOT")

echo "strip is $NOTCH_PT pt x $SCALE = $EXPECTED px; image should start at row $EXPECTED"
echo

for COL in $((W/4)) $((W/2)) $((W*3/4)); do
  echo "column x=$COL"
  magick "$SHOT" -depth 8 -crop "1x$((EXPECTED+8))+$COL+0" +repage txt:- 2>/dev/null \
  | tail -n +2 \
  | sed 's/^[0-9]*,\([0-9]*\):[^(]*(\([0-9]*\),\([0-9]*\),\([0-9]*\).*/\1 \2 \3 \4/' \
  | awk -v want="$EXPECTED" '
      { y=$1; r=$2; g=$3; b=$4; m=(r>g?r:g); m=(m>b?m:b)
        if (m>12 && first=="") first=y
        row[y]=sprintf("  y=%-4d rgb(%3d,%3d,%3d)", y, r, g, b) }
      END {
        for (y=first-2; y<=first+5; y++) if (y in row)
          print row[y] (y+0==want+0 ? "   <- strip ends here, as configured" : "")
        if (first+0==want+0) print "  OK: no wallpaper visible above the windows"
        else printf "  ADJUST: image starts at row %d, not %d -> set NOTCH_PT=%g\n", \
                    first+0, want+0, first/'"$SCALE"'
      }'
  echo
done

rm -f "$SHOT"
