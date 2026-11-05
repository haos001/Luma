import Foundation

public enum LightTransition {
    public static let rippleDuration: TimeInterval = 2.6
    public static let fadeOutDuration: TimeInterval = 1.2
    public static let fadeInDuration: TimeInterval = 1.6
    public static let darkPause: TimeInterval = 0.12
    public static let steps = 30

    public static func eased(_ progress: Double) -> Double {
        guard progress.isFinite else { return 0 }
        let t = min(1, max(0, progress))
        return t * t * (3 - 2 * t)
    }

    /// Includes both endpoints. RGB interpolation never inserts black between two colors.
    public static func frames(from start: RGB, to end: RGB, steps: Int = steps) -> [RGB] {
        let count = min(300, max(1, steps))
        return (0...count).map { index in
            let t = eased(Double(index) / Double(count))
            let values: [UInt8] = zip(start.channels, end.channels).map { a, b in
                let initial = Double(a)
                let delta = Double(b) - initial
                let interpolated = initial + delta * t
                return UInt8(interpolated.rounded())
            }
            return RGB(values[0], values[1], values[2])
        }
    }

    public struct Frame: Equatable, Sendable {
        public enum Stage: Equatable, Sendable { case dimming, dark, brightening }
        public let color: RGB
        public let delayBefore: TimeInterval
        public let stage: Stage
    }

    /// The chosen target appears only after the previous light has reached black.
    public static func blackoutFrames(from start: RGB, to end: RGB) -> [Frame] {
        var result: [Frame] = []
        if start != .black {
            result = frames(from: start, to: .black, steps: 30).enumerated().map { index, color in
                Frame(color: color, delayBefore: index == 0 ? 0 : fadeOutDuration / 30, stage: .dimming)
            }
        } else {
            result = [Frame(color: .black, delayBefore: 0, stage: .dark)]
        }
        if end != .black {
            if start != .black { result.append(Frame(color: .black, delayBefore: darkPause, stage: .dark)) }
            result += frames(from: .black, to: end, steps: 40).dropFirst().map {
                Frame(color: $0, delayBefore: fadeInDuration / 40, stage: .brightening)
            }
        }
        return result
    }
}

/// Only a completed visible ripple may unlock the hardware transition.
public struct RecommendationFlow: Equatable {
    public enum Phase: Equatable { case idle, spreading, transitioning }
    public private(set) var phase: Phase = .idle
    public private(set) var token = UUID()
    public init() {}

    public mutating func begin() -> UUID? {
        guard phase == .idle else { return nil }
        token = UUID(); phase = .spreading
        return token
    }

    public mutating func reachedEdges(token: UUID) -> Bool {
        guard token == self.token, phase == .spreading else { return false }
        phase = .transitioning
        return true
    }

    public mutating func finish() { phase = .idle }
    public mutating func cancelRipple() {
        guard phase == .spreading else { return }
        token = UUID(); phase = .idle
    }
}
