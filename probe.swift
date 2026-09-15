#!/usr/bin/env swift
//
// probe.swift — prints the screen constants norch.sh needs.
// Run on the Mac you want to adapt norch.sh to:  ./probe.swift
//
import AppKit

let screen = NSScreen.main!
let f = screen.frame
let scale = screen.backingScaleFactor

// Standard window corner radius: ask a real window's frame view for it.
let probeWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 120),
                           styleMask: [.titled, .closable], backing: .buffered, defer: false)
probeWindow.orderFront(nil)
let frameView = probeWindow.contentView?.superview
let radius = (frameView?.value(forKey: "_cornerRadius") as? CGFloat) ?? 16

// Where the top of a maximised window sits: a good starting guess for the strip.
let visibleTopGap = f.height - (screen.visibleFrame.origin.y + screen.visibleFrame.height)

print("""

Paste into norch.sh:

    SCREEN_PT_W=\(Int(f.width))
    SCREEN_PT_H=\(Int(f.height))
    SCALE=\(Int(scale))
    NOTCH_PT=\(Int(visibleTopGap.rounded()) + 1)
    RADIUS_PT=\(Int(radius))

For reference:
    safe area inset (notch height) : \(screen.safeAreaInsets.top) pt
    top of maximised windows       : \(visibleTopGap) pt
    window corner radius           : \(radius) pt

NOTCH_PT above is a guess (window top + 1 pt of slack). Verify it with
./measure.sh — see README.md.

""")
