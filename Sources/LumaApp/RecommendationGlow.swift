import SwiftUI
import LightCore

struct RecommendationOrbAnchor: PreferenceKey {
    static var defaultValue: Anchor<CGRect>?
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

struct RecommendationGlow: View {
    @ObservedObject var model: AppModel
    let center: CGPoint
    let size: CGSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    private var glowOpacity: Double { colorScheme == .dark ? 0.30 : 0.22 }

    var body: some View {
        ZStack {
            if let started = model.rippleStartedAt {
                let token = model.recommendationFlow.token
                TimelineView(.animation(minimumInterval: 1.0 / 45.0)) { timeline in
                    let duration = reduceMotion ? 0.45 : LightTransition.rippleDuration
                    let progress = min(1, max(0, timeline.date.timeIntervalSince(started) / duration))
                    RippleFrame(color: model.rippleColor.swiftColor, center: center, size: size,
                                progress: progress, reduceMotion: reduceMotion,
                                previous: model.ambientColor?.swiftColor, glowOpacity: glowOpacity) {
                        model.recommendationReachedEdges(token: token)
                    }
                }.id(token)
            } else if let ambient = model.ambientColor {
                ambient.swiftColor.opacity(glowOpacity * 0.26)
            }
        }
        .frame(width: size.width, height: size.height)
        .blendMode(colorScheme == .dark ? .screen : .multiply)
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct RippleFrame: View {
    let color: Color
    let center: CGPoint
    let size: CGSize
    let progress: Double
    let reduceMotion: Bool
    let previous: Color?
    let glowOpacity: Double
    let completed: () -> Void

    private var farthestCorner: Double {
        hypot(max(center.x, size.width - center.x), max(center.y, size.height - center.y))
    }

    private var waveMask: some View {
        return Circle().fill(RadialGradient(stops: [
            .init(color: .white, location: 0),
            .init(color: .white, location: 0.84),
            .init(color: .clear, location: 1)
        ], center: .center, startRadius: 0, endRadius: radius))
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
            .frame(width: size.width, height: size.height)
    }

    private var radius: Double { 38 + (farthestCorner / 0.84 - 38) * LightTransition.eased(progress) }

    var body: some View {
        ZStack {
            // Replaces the previous tint under the advancing wave, instead of accumulating flashes.
            if reduceMotion {
                if let previous { previous.opacity(glowOpacity * 0.26 * (1 - progress)) }
                color.opacity(glowOpacity * 0.26 * progress)
            } else {
                if let previous {
                    previous.opacity(glowOpacity * 0.26).mask {
                        Rectangle().fill(.white)
                            .overlay { waveMask.blendMode(.destinationOut) }.compositingGroup()
                    }
                }
                // Settle into a subtle tint so palette samples stay clear after the visible wave.
                color.opacity(glowOpacity * (1 - 0.74 * LightTransition.eased((progress - 0.7) / 0.3))).mask(waveMask)
                // A broad luminous leading edge makes the spread legible without a hard flash.
                Circle().fill(RadialGradient(stops: [
                    .init(color: .clear, location: 0.65),
                    .init(color: color.opacity(0.35 * sin(.pi * progress)), location: 0.86),
                    .init(color: .clear, location: 1)
                ], center: .center, startRadius: 0, endRadius: radius))
                    .frame(width: radius * 2, height: radius * 2).position(center)
            }
        }
        .frame(width: size.width, height: size.height)
        .onChange(of: progress >= 1) { done in if done { completed() } }
        .onAppear { if progress >= 1 { completed() } }
    }
}
