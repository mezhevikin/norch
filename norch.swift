#!/usr/bin/env swift
//
// norch — hides the MacBook notch by baking it into the wallpaper.
//
//   ./norch.swift photo.jpg              writes photo-norch.png next to the input
//   ./norch.swift photo.jpg out.png      explicit output path
//   ./norch.swift photo.jpg --set        write it and apply it as the desktop picture
//
// The picture is scaled to fill the screen, the menu bar strip is painted solid
// black so the notch disappears into it, and the picture is clipped to a rounded
// rectangle with the same corner radius macOS gives windows, so no wallpaper
// shows through around the corners of a maximised window.
//
// Every measurement comes from AppKit at run time. There is nothing to configure
// and nothing to adjust when you run this on a different Mac.
//
import AppKit

func die(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("norch: " + message + "\n").utf8))
    exit(1)
}

// --- arguments -------------------------------------------------------------

var args = Array(CommandLine.arguments.dropFirst())
let shouldApply = args.contains("--set")
args.removeAll { $0 == "--set" }

guard let inputPath = args.first else {
    die("usage: norch.swift <image> [output.png] [--set]")
}
let input = URL(fileURLWithPath: inputPath)
let output: URL = args.count > 1
    ? URL(fileURLWithPath: args[1])
    : input.deletingLastPathComponent()
        .appendingPathComponent(input.deletingPathExtension().lastPathComponent + "-norch.png")

// --- screen ----------------------------------------------------------------

guard let screen = NSScreen.main else { die("no screen to measure") }

// Render at points x backing scale, the resolution macOS composites the desktop
// at. The panel's native pixel count is often larger; rendering there makes the
// OS rescale the result, which blurs the one-pixel edges this relies on.
let scale = screen.backingScaleFactor
let width = Int((screen.frame.width * scale).rounded())
let height = Int((screen.frame.height * scale).rounded())

// The strip has to reach the top edge of windows, not merely cover the notch —
// the notch is the shorter of the two. A window can sit no higher than the top
// of visibleFrame, and one point of slack keeps a sliver of wallpaper out of the
// seam above it. (On this machine: notch 28.5 pt, windows 29 pt, strip 30 pt.)
let windowTop = screen.frame.height - screen.visibleFrame.maxY
let strip = ((windowTop + 1) * scale).rounded()

// Ask a real window for its corner radius instead of hardcoding one, so this
// tracks whatever the current macOS version uses. Falls back to the macOS 27
// value if the accessor ever goes away.
func windowCornerRadius() -> CGFloat {
    let probe = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 120),
                         styleMask: [.titled], backing: .buffered, defer: false)
    guard let frameView = probe.contentView?.superview,
          frameView.responds(to: Selector(("_cornerRadius"))),
          let radius = frameView.value(forKey: "_cornerRadius") as? CGFloat
    else { return 16 }
    return radius
}
let radius = windowCornerRadius() * scale

// A hairline of black down the left, right and bottom edges. Without it the
// antialiased end of the rounded corner leaves a faint line of colour along the
// very edge of the screen, next to the matching corner of a window.
let edge: CGFloat = 1

// --- render ----------------------------------------------------------------

guard let source = CGImageSourceCreateWithURL(input as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
else { die("cannot read an image from \(input.path)") }

guard let context = CGContext(data: nil, width: width, height: height,
                              bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpace(name: CGColorSpace.sRGB)!,
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
else { die("cannot allocate a \(width)x\(height) canvas") }

let canvas = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
context.setFillColor(.black)
context.fill(canvas)

// CoreGraphics puts the origin at the bottom left, so the strip is taken off the
// top by shortening the box rather than by moving it.
let picture = CGRect(x: edge, y: edge,
                     width: canvas.width - 2 * edge,
                     height: canvas.height - strip - edge)
context.addPath(CGPath(roundedRect: picture, cornerWidth: radius,
                       cornerHeight: radius, transform: nil))
context.clip()

// Fill the whole screen and let the strip cover the top of it, the way the
// wallpaper would sit if norch were not involved. Fitting the picture into the
// shorter visible box instead would keep every pixel of it, but would shift the
// framing away from what macOS shows for the same file.
let aspect = CGFloat(image.width) / CGFloat(image.height)
var drawn = canvas
if aspect > canvas.width / canvas.height {
    drawn.size.width = canvas.height * aspect
} else {
    drawn.size.height = canvas.width / aspect
}
drawn.origin = CGPoint(x: canvas.midX - drawn.width / 2, y: canvas.midY - drawn.height / 2)
context.interpolationQuality = .high
context.draw(image, in: drawn)

guard let rendered = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(output as CFURL, "public.png" as CFString, 1, nil)
else { die("cannot write \(output.path)") }
CGImageDestinationAddImage(destination, rendered, nil)
guard CGImageDestinationFinalize(destination) else { die("cannot write \(output.path)") }

print("\(width)x\(height): strip \(Int(strip))px, radius \(Int(radius))px")
print(output.path)

// --- apply -----------------------------------------------------------------

if shouldApply {
    do {
        try NSWorkspace.shared.setDesktopImageURL(output, for: screen, options: [:])
        print("applied as the desktop picture")
    } catch {
        die("written, but could not apply it: \(error.localizedDescription)")
    }
}
