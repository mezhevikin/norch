# norch

Bakes the MacBook notch into your wallpaper.

The menu bar strip is painted solid black, so the notch stops being a cutout and
just becomes part of a black bar. The rest of the picture is masked to a rounded
rectangle with the same corner radius macOS uses for windows, so the wallpaper no
longer peeks out around the corners of maximised windows.

Input is any image, output is a PNG sized for your screen. Nothing runs in the
background — it is one shell script you run when you change wallpaper.

![A 14-inch MacBook Pro running norch: the menu bar is a solid black strip and the notch is invisible inside it](screenshot.jpg)

*Photographed rather than screenshotted on purpose — a screenshot cannot show the notch, so it cannot show it being hidden either.*

## Requirements

- macOS 27 — the only version this has been built and checked against
- ImageMagick 7: `brew install imagemagick`

## Usage

```sh
./norch.sh photo.jpg              # writes photo-norch.png next to the input
./norch.sh photo.jpg out.png      # explicit output path
./norch.sh photo.jpg --set        # write it and apply it as the desktop picture
```

Re-run it whenever you pick a new wallpaper.

## Adapting it to another Mac

The screen constants at the top of `norch.sh` describe one machine (a 14"
MacBook Pro). Three steps to retarget it:

**1. Read the constants off your screen.**

```sh
./probe.swift
```

It prints a block ready to paste over the corresponding lines in `norch.sh`:

```
SCREEN_PT_W=1352      # NSScreen.frame.width, points
SCREEN_PT_H=878       # NSScreen.frame.height, points
SCALE=2               # NSScreen.backingScaleFactor
NOTCH_PT=30           # height of the black strip
RADIUS_PT=16          # NSWindow corner radius on this macOS version
```

**2. Generate and apply.**

```sh
./norch.sh photo.jpg --set
```

**3. Check the strip height.**

`NOTCH_PT` is the only value `probe.swift` has to guess at. It must reach the
top edge of your windows — one pixel short and a sliver of wallpaper shows in the
gap above every window. Leave a window at the top of the screen and run:

```sh
./measure.sh
```

It screenshots the desktop and prints the rows around the bottom of the strip:

```
column x=1352
  y=58   rgb(  0,  0,  0)
  y=59   rgb(  0,  0,  0)
  y=60   rgb(129,158,167)   <- strip ends here, as configured
  OK: no wallpaper visible above the windows
```

If it says `ADJUST` instead, it tells you the `NOTCH_PT` to use. Change it in
`norch.sh` and repeat step 2.

`measure.sh` needs Screen Recording permission for your terminal — System
Settings → Privacy & Security → Screen & System Audio Recording.

## Notes

- **Resolution.** Output is `points x backingScaleFactor`, which is what macOS
  composites the desktop at — *not* the panel's native pixel count. Rendering at
  native resolution looks like the sharper choice but the OS then rescales the
  result, which softens the one-pixel edges this relies on.
- **The strip is taller than the notch.** The notch itself is 28.5 pt here, but
  windows start at 30 pt. The strip has to reach the windows, so it is sized to
  them, not to the notch.
- **Changing display scaling** changes every constant. Re-run `./probe.swift`.
- **Other macOS versions.** Everything here is measured on macOS 27, and the
  shipped constants are its numbers. Nothing is hardcoded to that release —
  `probe.swift` reads the corner radius off a live `NSWindow` and `measure.sh`
  checks the strip against your own screen — so older versions may well work,
  they just have not been tried.
