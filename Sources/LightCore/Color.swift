import Foundation

public struct RGB: Codable, Equatable, Hashable, Sendable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8

    public init(_ red: UInt8, _ green: UInt8, _ blue: UInt8) {
        self.red = red; self.green = green; self.blue = blue
    }

    public init?(hex: String) {
        let value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = value.hasPrefix("#") ? String(value.dropFirst()) : value
        guard digits.count == 6, digits.allSatisfy({ $0.isASCII && $0.isHexDigit }),
              let number = UInt32(digits, radix: 16) else { return nil }
        self.init(UInt8((number >> 16) & 255), UInt8((number >> 8) & 255), UInt8(number & 255))
    }

    public var hex: String { String(format: "#%02X%02X%02X", red, green, blue) }
    public var channels: [UInt8] { [red, green, blue] }
    public static let black = RGB(0, 0, 0)

    public func scaled(percent: Int) -> RGB {
        let scale = Double(min(100, max(0, percent))) / 100
        return RGB(UInt8((Double(red) * scale).rounded()),
                   UInt8((Double(green) * scale).rounded()),
                   UInt8((Double(blue) * scale).rounded()))
    }

    public var hsv: (hue: Double, saturation: Double, value: Double) {
        let r = Double(red) / 255, g = Double(green) / 255, b = Double(blue) / 255
        let high = max(r, g, b), low = min(r, g, b), delta = high - low
        var hue: Double = 0
        if delta > 0 {
            if high == r { hue = ((g - b) / delta).truncatingRemainder(dividingBy: 6) }
            else if high == g { hue = (b - r) / delta + 2 }
            else { hue = (r - g) / delta + 4 }
            hue /= 6
            if hue < 0 { hue += 1 }
        }
        return (hue, high == 0 ? 0 : delta / high, high)
    }

    public static func hsv(hue: Double, saturation: Double, value: Double) -> RGB {
        guard hue.isFinite, saturation.isFinite, value.isFinite else { return .black }
        let h = (hue - floor(hue)) * 6
        let s = min(1, max(0, saturation)), v = min(1, max(0, value))
        let c = v * s, x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1)), m = v - c
        let rgb: (Double, Double, Double)
        switch Int(h) {
        case 0: rgb = (c, x, 0)
        case 1: rgb = (x, c, 0)
        case 2: rgb = (0, c, x)
        case 3: rgb = (0, x, c)
        case 4: rgb = (x, 0, c)
        default: rgb = (c, 0, x)
        }
        return RGB(UInt8(((rgb.0 + m) * 255).rounded()),
                   UInt8(((rgb.1 + m) * 255).rounded()),
                   UInt8(((rgb.2 + m) * 255).rounded()))
    }
}

public enum LightProtocol {
    public static let vendorID = 0x1A86
    public static let productID = 0xFE07

    public static func color(_ color: RGB, brightness: Int = 100) -> [UInt8] {
        let rgb = color.scaled(percent: brightness)
        // This is the raw report, not node-hid's ID-prefixed buffer.
        // IOKit receives report ID 0 separately; do not prepend a zero byte.
        var bytes: [UInt8] = [0x52, 0x42, 16, 2, 134, 1] + rgb.channels + [96, 97, 0, 0, 0, 254]
        bytes.append(bytes.reduce(0, &+))
        return bytes
    }

    public static var off: [UInt8] { color(.black) }
}
