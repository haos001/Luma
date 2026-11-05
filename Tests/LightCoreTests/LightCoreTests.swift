import Foundation
import LightCore

// A standalone harness so the checks also run with Command Line Tools, without XCTest/Xcode.
private var failures = 0
private var assertions = 0
private func check(_ value: Bool, file: StaticString = #filePath, line: UInt = #line) {
    assertions += 1
    if !value { failures += 1; print("FAIL \(file):\(line)") }
}
private func equal<T: Equatable>(_ lhs: T, _ rhs: T, file: StaticString = #filePath, line: UInt = #line) {
    assertions += 1
    if lhs != rhs { failures += 1; print("FAIL \(file):\(line): \(lhs) != \(rhs)") }
}

final class LightCoreTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Moscow")!
        calendar.locale = Locale(identifier: "ru_RU")
        return calendar
    }
    private func date(_ month: Int, _ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    func testHexParsingAndInvalidInput() {
        equal(RGB(hex: " #c98758 \n"), RGB(201, 135, 88))
        equal(RGB(hex: "C98758")?.hex, "#C98758")
        for invalid in ["", "#123", "#1234567", "GG0000", "##123456", "１２３４５６"] { check(RGB(hex: invalid) == nil) }
    }

    func testKnownProtocolPacket() {
        let packet = LightProtocol.color(RGB(189, 0, 255))
        equal(packet, [82, 66, 16, 2, 134, 1, 189, 0, 255, 96, 97, 0, 0, 0, 254, 168])
        equal(packet.count, 16)
        equal(packet.last, packet.dropLast().reduce(0, &+))
    }

    func testBrightnessScalingAndOff() {
        equal(RGB(255, 154, 77).scaled(percent: 28), RGB(71, 43, 22))
        equal(RGB(255, 154, 77).scaled(percent: 100), RGB(255, 154, 77))
        equal(RGB(255, 154, 77).scaled(percent: -5), .black)
        equal(RGB(255, 154, 77).scaled(percent: 500), RGB(255, 154, 77))
        equal(LightProtocol.off, LightProtocol.color(.black))
    }

    func testHSVRoundTrip() {
        for preset in PresetCatalog.all {
            let hsv = preset.color.hsv
            equal(RGB.hsv(hue: hsv.hue, saturation: hsv.saturation, value: hsv.value), preset.color)
        }
        equal(RGB.hsv(hue: 1, saturation: 1, value: 1), RGB(255, 0, 0))
        equal(RGB.hsv(hue: .nan, saturation: 1, value: 1), .black)
    }

    func testCatalogHasFortyUniquePresets() {
        equal(PresetCatalog.all.count, 40)
        equal(Set(PresetCatalog.all.map(\.id)).count, 40)
        for group in PresetGroup.allCases { equal(PresetCatalog.all.filter { $0.group == group }.count, 5) }
        check(PresetCatalog.all.allSatisfy { (0...100).contains($0.brightness) })
    }

    func testSeasonAndTimeBoundaries() {
        equal(Season.forMonth(12), .winter)
        equal(Season.forMonth(3), .spring)
        equal(Season.forMonth(6), .summer)
        equal(Season.forMonth(9), .autumn)
        for (hour, period) in [(0, DayPeriod.night), (5, .night), (6, .dawn), (9, .dawn), (10, .day), (14, .day), (15, .afternoon), (18, .evening), (23, .night)] {
            equal(DayPeriod.forHour(hour), period)
        }
    }

    func testRecommendationsAlwaysMatchSeasonAndTime() {
        let start = date(1, 1, 0)
        for day in 0..<365 {
            for hour in [0, 6, 10, 15, 18, 23] {
                let instant = calendar.date(byAdding: .hour, value: day * 24 + hour, to: start)!
                let recommendation = RecommendationEngine.recommend(at: instant, calendar: calendar)
                check(recommendation.preset.recommended)
                check(recommendation.preset.seasons.contains(Season.forMonth(calendar.component(.month, from: instant))))
                check(recommendation.preset.periods.contains(DayPeriod.forHour(hour)))
            }
        }
    }

    func testRecommendationsStableAndWeekendAware() {
        let tuesday = date(10, 20, 12)
        let sunday = date(10, 25, 12)
        equal(RecommendationEngine.recommend(at: tuesday, calendar: calendar).preset.group, .work)
        equal(RecommendationEngine.recommend(at: sunday, calendar: calendar).preset.group, .rest)
        equal(RecommendationEngine.recommend(at: tuesday, calendar: calendar), RecommendationEngine.recommend(at: tuesday, calendar: calendar))
        let ids = Set((1...31).map { RecommendationEngine.recommend(at: date(10, $0, 0), calendar: calendar).preset.id })
        check(ids.count > 1)
    }

    func testRecommendationUsesProvidedTimezone() {
        let instant = date(10, 20, 0)
        var utc = calendar
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        check(RecommendationEngine.recommend(at: instant, calendar: calendar).preset.periods.contains(.night))
        check(RecommendationEngine.recommend(at: instant, calendar: utc).preset.periods.contains(.evening))
    }

    func testStateRoundTripAndCorruptionFallback() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = StateStore(url: folder.appendingPathComponent("test.json"))
        let state = SavedState(color: RGB(5, 20, 80), brightness: 28, favorites: [PresetCatalog.all[0]], lastApplied: Date(timeIntervalSince1970: 123), lastCommandWasOff: true)
        try store.save(state)
        equal(store.load(), state)
        try Data("invalid".utf8).write(to: store.url)
        equal(store.load(), SavedState())
    }

    func testSmoothTransitionFrames() {
        let from = RGB(201, 135, 88), to = RGB(180, 126, 150)
        let frames = LightTransition.frames(from: from, to: to)
        equal(frames.count, 31)
        equal(frames.first, from); equal(frames.last, to)
        for (a, b) in zip(frames, frames.dropFirst()) {
            check(b.red <= a.red && b.green <= a.green && b.blue >= a.blue)
            check(b != .black)
            check(abs(Int(a.blue) - Int(b.blue)) <= 4)
        }
        let on = LightTransition.frames(from: .black, to: to)
        equal(on.first, .black); equal(on.last, to)
        for (a, b) in zip(on, on.dropFirst()) { check(b.red >= a.red && b.green >= a.green && b.blue >= a.blue) }
        check(LightTransition.frames(from: from, to: from).allSatisfy { $0 == from })
        equal(LightTransition.frames(from: from, to: to, steps: 0).count, 2)
        equal(LightTransition.eased(-1), 0); equal(LightTransition.eased(2), 1)
    }

    func testBlackoutTransition() {
        let from = RGB(201, 135, 88), to = RGB(142, 201, 179)
        let frames = LightTransition.blackoutFrames(from: from, to: to)
        equal(frames.count, 72)
        equal(frames.first?.color, from)
        equal(frames.last?.color, to)
        equal(frames[30].color, .black)
        equal(frames[31].color, .black)
        equal(frames[31].stage, .dark)
        equal(frames[31].delayBefore, LightTransition.darkPause)
        check(abs(frames.reduce(0) { $0 + $1.delayBefore } - 2.92) < 0.000001)
        check(frames.allSatisfy { $0.delayBefore >= 0 })
        for (a, b) in zip(frames.prefix(31), frames.prefix(31).dropFirst()) {
            check(b.color.red <= a.color.red && b.color.green <= a.color.green && b.color.blue <= a.color.blue)
            equal(b.stage, .dimming)
        }
        for (a, b) in zip(frames.dropFirst(31), frames.dropFirst(32)) {
            check(b.color.red >= a.color.red && b.color.green >= a.color.green && b.color.blue >= a.color.blue)
            equal(b.stage, .brightening)
        }
        let on = LightTransition.blackoutFrames(from: .black, to: to)
        equal(on.count, 41)
        equal(on.first?.color, .black); equal(on.last?.color, to)
        check(abs(on.reduce(0) { $0 + $1.delayBefore } - 1.6) < 0.000001)
        let off = LightTransition.blackoutFrames(from: from, to: .black)
        equal(off.count, 31)
        equal(off.last?.color, .black)
        check(abs(off.reduce(0) { $0 + $1.delayBefore } - 1.2) < 0.000001)
        let same = LightTransition.blackoutFrames(from: from, to: from)
        check(same.contains { $0.color == .black })
        equal(same.last?.color, from)
        let dark = LightTransition.blackoutFrames(from: .black, to: .black)
        equal(dark.count, 1)
        equal(dark.first?.color, .black)
        equal(dark.first?.delayBefore, 0)
    }

    func testRecommendationFlowGatesUSB() {
        var flow = RecommendationFlow()
        equal(flow.phase, .idle)
        let first = flow.begin()!
        equal(flow.phase, .spreading)
        check(flow.begin() == nil)
        check(!flow.reachedEdges(token: UUID()))
        equal(flow.phase, .spreading)
        check(flow.reachedEdges(token: first))
        equal(flow.phase, .transitioning)
        check(!flow.reachedEdges(token: first))
        check(flow.begin() == nil)
        flow.finish()
        let cancelled = flow.begin()!
        flow.cancelRipple()
        equal(flow.phase, .idle)
        check(!flow.reachedEdges(token: cancelled))
        let next = flow.begin()!
        check(next != cancelled)
        check(!flow.reachedEdges(token: cancelled))
        check(flow.reachedEdges(token: next))
    }
}

@main
struct TestRunner {
    static func main() {
        let tests = LightCoreTests()
        let cases: [(String, () throws -> Void)] = [
            ("HEX", tests.testHexParsingAndInvalidInput),
            ("USB packet", tests.testKnownProtocolPacket),
            ("Brightness and OFF", tests.testBrightnessScalingAndOff),
            ("HSV round trip", tests.testHSVRoundTrip),
            ("40 presets", tests.testCatalogHasFortyUniquePresets),
            ("Time boundaries", tests.testSeasonAndTimeBoundaries),
            ("365 days / all periods", tests.testRecommendationsAlwaysMatchSeasonAndTime),
            ("Stable and weekend-aware", tests.testRecommendationsStableAndWeekendAware),
            ("Timezone", tests.testRecommendationUsesProvidedTimezone),
            ("Persistence", tests.testStateRoundTripAndCorruptionFallback),
            ("Smooth fade", tests.testSmoothTransitionFrames),
            ("Fade out / black / selected color fade in", tests.testBlackoutTransition),
            ("Ripple gates USB / cancellation / duplicate clicks", tests.testRecommendationFlowGatesUSB)
        ]
        for (name, test) in cases {
            let before = failures
            do { try test() } catch { failures += 1; print("FAIL \(name): \(error)") }
            print("\(failures == before ? "PASS" : "FAIL") \(name)")
        }
        print("\(cases.count) checks, \(assertions) assertions, \(failures) failures")
        exit(failures == 0 ? 0 : 1)
    }
}
