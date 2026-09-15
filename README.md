# norch

Bakes the MacBook notch into your wallpaper.

The menu bar strip is painted solid black, so the notch stops being a cutout and
just becomes part of a black bar. The rest of the picture is clipped to a rounded
rectangle with the same corner radius macOS gives windows, so the wallpaper no
longer peeks out around the corners of a maximised window.

Input is any image, output is a PNG sized for your screen. Nothing runs in the
background — it is one script you run when you change wallpaper.

![A 14-inch MacBook Pro running norch: the menu bar is a solid black strip and the notch is invisible inside it](screenshot.jpg)

*Photographed rather than screenshotted on purpose — a screenshot cannot show the notch, so it cannot show it being hidden either.*

## Requirements

- macOS 27 — the only version this has been built and checked against
- Xcode Command Line Tools, for `swift`: `xcode-select --install`

## Usage

```sh
./norch.swift photo.jpg              # writes photo-norch.png next to the input
./norch.swift photo.jpg out.png      # explicit output path
./norch.swift photo.jpg --set        # write it and apply it as the desktop picture
```

Re-run it whenever you pick a new wallpaper.

There is nothing to configure here, on this Mac or on any other. Screen size,
backing scale, how far down windows begin and the window corner radius are all
read from AppKit at run time.

## How it decides what to draw

**The strip is sized to your windows, not to the notch.** These are not the same
number, and the notch is the smaller one — on a 14" MacBook Pro the notch is
28.5 pt tall while windows start at 29 pt. Sizing the strip to the notch leaves a
seam of wallpaper above every window, which is exactly the thing you were trying
to get rid of. norch takes the top of `visibleFrame` and adds a point of slack:
the overshoot hides under the window, where nobody can see it, and the seam
cannot open up.

**It renders at `points x backingScaleFactor`,** which is the resolution macOS
composites the desktop at. Rendering at the panel's native pixel count — 3024 x
1964 on this machine, against 2704 x 1756 of composited desktop — looks like the
sharper choice, but then the OS rescales the result and the one-pixel edges this
relies on turn to mush.

**The corner radius comes from a real window,** read off a freshly created
`NSWindow` rather than written down as 16. When Apple changes it, norch follows.

**A one-pixel black hairline runs down the left, right and bottom edges.**
Without it the antialiased tail of a rounded corner leaves a faint line of colour
at the very edge of the screen, alongside the matching corner of a window.

## Notes

- **Other macOS versions.** Everything here was measured on macOS 27. Nothing is
  hardcoded to that release, so older ones may well work — they just have not
  been tried.
- **Multiple displays.** norch measures and applies to the main screen, the one
  with the menu bar on it.
- **Earlier versions of this repo** did the same work with a shell script driving
  ImageMagick, plus two helper scripts to read the screen constants and check
  them by hand. `git log` has them if you would rather not install Xcode.
