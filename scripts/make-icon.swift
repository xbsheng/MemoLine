// Draws the MemoLine app icon: one memo on ruled paper, held by an
// aluminium clip on a thin line, over a soft gradient.
// Usage: swift scripts/make-icon.swift out.png
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.dropFirst().first ?? "icon.png"

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

func shadow(_ alpha: CGFloat, blur: CGFloat, y: CGFloat) {
    let s = NSShadow()
    s.shadowColor = color(24, 26, 60, alpha)
    s.shadowBlurRadius = blur
    s.shadowOffset = NSSize(width: 0, height: y)
    s.set()
}

// Body, following the macOS icon grid: 824pt square, 100pt margin.
let body = NSRect(x: 100, y: 100, width: 824, height: 824)
let shape = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)

ctx.saveGState()
shadow(0.30, blur: 26, y: -12)
color(206, 208, 236).setFill()
shape.fill()
ctx.restoreGState()

ctx.saveGState()
shape.addClip()
NSGradient(colors: [color(122, 166, 255), color(168, 158, 250), color(255, 186, 190)],
           atLocations: [0, 0.55, 1], colorSpace: .sRGB)!
    .draw(in: body, angle: -60)
NSGradient(colors: [color(255, 255, 255, 0.35), color(255, 255, 255, 0)])!
    .draw(in: NSRect(x: body.minX, y: body.midY, width: body.width, height: body.height / 2), angle: -90)
ctx.restoreGState()

// The line
let left = NSPoint(x: 70, y: 706), right = NSPoint(x: 954, y: 706)
let control = NSPoint(x: 512, y: 598)
func lineY(_ x: CGFloat) -> CGFloat {
    let t = (x - left.x) / (right.x - left.x)
    return (1 - t) * (1 - t) * left.y + 2 * (1 - t) * t * control.y + t * t * right.y
}
let rope = NSBezierPath()
rope.move(to: left)
rope.curve(to: right,
           controlPoint1: NSPoint(x: left.x + (control.x - left.x) * 2 / 3, y: left.y + (control.y - left.y) * 2 / 3),
           controlPoint2: NSPoint(x: right.x + (control.x - right.x) * 2 / 3, y: right.y + (control.y - right.y) * 2 / 3))
rope.lineWidth = 7
rope.lineCapStyle = .round
color(255, 255, 255, 0.85).setStroke()
rope.stroke()

// The card: 470x330, hanging from the middle of the line.
let card = NSRect(x: 512 - 235, y: 300, width: 470, height: 330)
let cardShape = NSBezierPath(roundedRect: card, xRadius: 34, yRadius: 34)
ctx.saveGState()
shadow(0.32, blur: 30, y: -18)
color(255, 250, 233).setFill()
cardShape.fill()
ctx.restoreGState()

// Ruled lines, one for each line of a memo.
color(70, 78, 110, 0.20).setStroke()
for i in 0..<5 {
    let y = card.maxY - 84 - CGFloat(i) * 52
    let rule = NSBezierPath()
    rule.move(to: NSPoint(x: card.minX + 52, y: y))
    rule.line(to: NSPoint(x: card.maxX - 52 - (i == 4 ? 96 : 0), y: y))
    rule.lineWidth = 9
    rule.lineCapStyle = .round
    rule.stroke()
}

// The clip, straddling the line just above the card.
let clip = NSRect(x: 512 - 22, y: card.maxY - 34, width: 44, height: 128)
let clipShape = NSBezierPath(roundedRect: clip, xRadius: 16, yRadius: 16)
ctx.saveGState()
shadow(0.30, blur: 14, y: -6)
NSGradient(colors: [color(236, 238, 244), color(150, 155, 170)])!.draw(in: clipShape, angle: -90)
ctx.restoreGState()
color(60, 62, 74, 0.45).setFill()
NSBezierPath(roundedRect: NSRect(x: clip.midX - 12, y: lineY(512) - 7, width: 24, height: 14),
             xRadius: 7, yRadius: 7).fill()

NSGraphicsContext.restoreGraphicsState()

let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
