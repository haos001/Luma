import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let image = NSImage(size: NSSize(width: pixels, height: pixels))
        image.lockFocus()
        let n = CGFloat(pixels)
        let bounds = NSRect(x: n * 0.06, y: n * 0.06, width: n * 0.88, height: n * 0.88)
        let path = NSBezierPath(roundedRect: bounds, xRadius: n * 0.2, yRadius: n * 0.2)
        NSColor(red: 0.075, green: 0.08, blue: 0.11, alpha: 1).setFill()
        path.fill()
        let light = NSBezierPath(roundedRect: NSRect(x: n * 0.22, y: n * 0.29, width: n * 0.56, height: n * 0.45), xRadius: n * 0.08, yRadius: n * 0.08)
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(red: 1, green: 0.55, blue: 0.35, alpha: 0.8)
        shadow.shadowBlurRadius = n * 0.1
        shadow.shadowOffset = .zero
        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        NSColor(red: 0.95, green: 0.69, blue: 0.48, alpha: 1).setStroke()
        light.lineWidth = n * 0.045
        light.stroke()
        NSGraphicsContext.restoreGraphicsState()
        let stand = NSBezierPath()
        stand.move(to: NSPoint(x: n * 0.5, y: n * 0.29)); stand.line(to: NSPoint(x: n * 0.5, y: n * 0.21))
        stand.move(to: NSPoint(x: n * 0.37, y: n * 0.21)); stand.line(to: NSPoint(x: n * 0.63, y: n * 0.21))
        stand.lineWidth = n * 0.035; stand.lineCapStyle = .round
        NSColor(red: 0.95, green: 0.69, blue: 0.48, alpha: 1).setStroke(); stand.stroke()
        image.unlockFocus()
        let data = NSBitmapImageRep(data: image.tiffRepresentation!)!.representation(using: .png, properties: [:])!
        try data.write(to: output.appendingPathComponent("icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"))
    }
}
