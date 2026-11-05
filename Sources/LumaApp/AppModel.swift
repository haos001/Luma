import AppKit
import SwiftUI
import LightCore

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()
    @Published var color: RGB
    @Published var brightness: Double
    @Published var hue: Double
    @Published var saturation: Double
    @Published var value: Double
    @Published var hexDraft: String
    @Published private var selectedPreset: Preset?
    @Published var language: AppLanguage {
        didSet {
            savedState.language = language
            recommendation = RecommendationEngine.recommend(at: Date(), language: language)
            persist()
        }
    }
    @Published var favorites: [Preset]
    @Published var recommendation = RecommendationEngine.recommend(at: Date())
    @Published private var deviceProductName: String?
    @Published private var deviceChecked = false
    @Published var connected = false
    @Published var isSending = false
    @Published var livePreview = false
    @Published private var statusMessage = LumaMessage(.ready)
    @Published private var statusPreset: Preset?
    @Published var error: String?
    @Published var savedName = ""
    @Published var showSave = false
    @Published var tab = 0
    @Published var category = "Все пресеты"
    @Published var search = ""
    @Published private(set) var recommendationFlow = RecommendationFlow()
    @Published private(set) var rippleStartedAt: Date?
    @Published private(set) var rippleColor = RGB.black
    @Published private(set) var ambientColor: RGB?
    private var pendingSelection: Preset?
    private var quitAfterTransition = false
    private var lastOutput: RGB
    private var previousAmbient: RGB?
    private let store: StateStore
    private var savedState: SavedState
    private let usbQueue = DispatchQueue(label: "local.luma.usb", qos: .userInitiated)
    private var previewTask: Task<Void, Never>?
    private var queuedPreview = false
    var terminationWaiting = false

    private init() {
        let preview = Self.previewConfiguration
        store = preview ? StateStore(url: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("luma-ui-preview.json")) : StateStore()
        savedState = store.load()
        let arguments = CommandLine.arguments
        if preview, let index = arguments.firstIndex(of: "--language"), arguments.indices.contains(index + 1),
           let override = AppLanguage(rawValue: arguments[index + 1]) {
            language = override
        } else { language = savedState.language }
        lastOutput = savedState.lastCommandWasOff ? .black : savedState.color.scaled(percent: savedState.brightness)
        color = savedState.color; brightness = Double(savedState.brightness); favorites = savedState.favorites
        let hsv = savedState.color.hsv
        hue = hsv.hue; saturation = hsv.saturation; value = hsv.value
        hexDraft = savedState.color.hex
        selectedPreset = (savedState.favorites + PresetCatalog.all).first {
            $0.color == savedState.color && $0.brightness == savedState.brightness
        }
        recommendation = RecommendationEngine.recommend(at: Date(), language: language)
    }

    private static var previewConfiguration: Bool {
        CommandLine.arguments.contains("--preview") || Bundle.main.object(forInfoDictionaryKey: "LumaUIPreview") as? Bool == true
    }
    var previewOnly: Bool { Self.previewConfiguration }
    var isBusy: Bool { isSending || recommendationFlow.phase != .idle }
    var selectedName: String { selectedPreset?.localizedName(in: language) ?? text(.customColor) }
    var isCustomColor: Bool { selectedPreset == nil }
    var status: String {
        if let preset = statusPreset {
            let name = preset.id == "pending-selection" ? text(.customColor) : preset.localizedName(in: language)
            if statusMessage.key == .brightening { return text(.brightening, name) }
            if statusMessage.key == .applied { return text(.applied, name, preset.color.hex, String(preset.brightness)) }
        }
        return statusMessage.localized(in: language)
    }
    var deviceName: String {
        if previewOnly { return text(.demoDevice) }
        if connected { return deviceProductName ?? "ROBOBLOQ USBHID" }
        return text(deviceChecked ? .disconnectedDevice : .checking)
    }
    func text(_ key: LumaText, _ arguments: String...) -> String { language.format(key, arguments: arguments) }
    private func errorText(_ error: Error) -> String {
        (error as? LightError)?.localizedDescription(in: language) ?? error.localizedDescription
    }

    func refresh() {
        if !isBusy { recommendation = RecommendationEngine.recommend(at: Date(), language: language) }
        guard !previewOnly else { connected = false; return }
        usbQueue.async {
            let result = Result { try HIDTransport.status() }
            DispatchQueue.main.async {
                self.deviceChecked = true
                switch result {
                case .success(let device): self.connected = true; self.deviceProductName = device.name
                case .failure: self.connected = false; self.deviceProductName = nil
                }
            }
        }
    }

    func select(_ preset: Preset) {
        guard !isBusy else { return }
        selectedPreset = preset
        brightness = Double(preset.brightness)
        setColor(preset.color, custom: false)
    }

    func setColor(_ rgb: RGB, custom: Bool = true) {
        color = rgb; hexDraft = rgb.hex
        let hsv = rgb.hsv
        if hsv.saturation > 0 { hue = hsv.hue }
        saturation = hsv.saturation; value = hsv.value
        if custom { selectedPreset = nil }
        schedulePreview()
    }

    func setHSV(h: Double? = nil, s: Double? = nil, v: Double? = nil) {
        if let h { hue = min(1, max(0, h)) }
        if let s { saturation = min(1, max(0, s)) }
        if let v { value = min(1, max(0, v)) }
        color = RGB.hsv(hue: hue, saturation: saturation, value: value)
        hexDraft = color.hex; selectedPreset = nil
        schedulePreview()
    }

    @discardableResult func commitHex() -> Bool {
        guard let rgb = RGB(hex: hexDraft) else { error = text(.invalidHex); return false }
        if rgb != color { setColor(rgb) } else { hexDraft = rgb.hex }
        return true
    }

    func setChannel(_ index: Int, _ number: Int) {
        var channels = color.channels
        channels[index] = UInt8(min(255, max(0, number)))
        setColor(RGB(channels[0], channels[1], channels[2]))
    }

    func schedulePreview() {
        previewTask?.cancel()
        guard livePreview, recommendationFlow.phase == .idle else { queuedPreview = false; return }
        previewTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 80_000_000)
            guard !Task.isCancelled, let self else { return }
            if self.isSending { self.queuedPreview = true }
            else { self.sendColor(quit: false, preview: true) }
        }
    }

    func apply(quit: Bool = false) {
        beginSelectedLight(quit: quit)
    }

    private func sendColor(quit: Bool, preview: Bool) {
        send(packet: LightProtocol.color(color, brightness: Int(brightness.rounded())), off: false, quit: quit, preview: preview)
    }

    func turnOff() {
        guard !isBusy else { return }
        livePreview = false; previewTask?.cancel(); queuedPreview = false
        send(packet: LightProtocol.off, off: true, quit: false, preview: false)
    }

    private func send(packet: [UInt8], off: Bool, quit: Bool, preview: Bool) {
        guard !previewOnly else { statusMessage = LumaMessage(.demoCommand); return }
        let sentColor = color, sentBrightness = Int(brightness.rounded())
        isSending = true
        usbQueue.async {
            let result = Result { try HIDTransport.send(packet) }
            DispatchQueue.main.async {
                self.isSending = false
                switch result {
                case .success:
                    self.connected = true
                    self.lastOutput = off ? .black : sentColor.scaled(percent: sentBrightness)
                    self.savedState.color = sentColor
                    self.savedState.brightness = sentBrightness
                    self.savedState.lastApplied = Date()
                    self.savedState.lastCommandWasOff = off
                    self.persist()
                    self.statusMessage = off ? LumaMessage(.offSent) : LumaMessage(.colorSent, sentColor.hex, String(sentBrightness))
                    if quit && self.error == nil { NSApp.terminate(nil) }
                case .failure(let failure):
                    self.statusMessage = LumaMessage(.notSent)
                    self.error = self.errorText(failure)
                    self.livePreview = false
                    self.queuedPreview = false
                }
                if self.terminationWaiting {
                    self.terminationWaiting = false
                    NSApp.reply(toApplicationShouldTerminate: true)
                } else if self.queuedPreview && self.livePreview && !quit {
                    self.queuedPreview = false
                    self.sendColor(quit: false, preview: true)
                }
            }
        }
    }

    func prepareToQuit() -> NSApplication.TerminateReply {
        previewTask?.cancel(); queuedPreview = false
        recommendationFlow.cancelRipple()
        rippleStartedAt = nil
        if isSending { terminationWaiting = true; return .terminateLater }
        return .terminateNow
    }

    func beginSelectedLight(quit: Bool = false) {
        guard !isBusy, commitHex(), recommendationFlow.begin() != nil else { return }
        previewTask?.cancel(); queuedPreview = false
        // Snapshot exactly the selected values. Recommendation must never replace this target.
        let preset = Preset(id: selectedPreset?.id ?? "pending-selection", name: selectedPreset?.name ?? selectedName, subtitle: "",
                            color: color, brightness: Int(brightness.rounded()))
        pendingSelection = preset
        quitAfterTransition = quit
        previousAmbient = ambientColor
        rippleColor = preset.color
        statusMessage = LumaMessage(.waveStatus)
        rippleStartedAt = Date()
    }

    /// Called by the rendered wave on its final frame, not by an unrelated delay timer.
    func recommendationReachedEdges(token: UUID) {
        guard recommendationFlow.reachedEdges(token: token), let preset = pendingSelection else { return }
        ambientColor = preset.color
        rippleStartedAt = nil
        guard !previewOnly else {
            recommendationFlow.finish(); pendingSelection = nil
            statusMessage = LumaMessage(.demoWave)
            return
        }
        isSending = true
        statusPreset = preset
        statusMessage = LumaMessage(.dimming)
        let start = lastOutput, end = preset.color.scaled(percent: preset.brightness)
        usbQueue.async {
            var lastWritten = start
            var previousStage: LightTransition.Frame.Stage?
            let result = Result { try HIDTransport.fade(from: start, to: end) { frame in
                lastWritten = frame.color
                if frame.stage != previousStage {
                    previousStage = frame.stage
                    DispatchQueue.main.async {
                        switch frame.stage {
                        case .dimming: self.statusMessage = LumaMessage(.dimming)
                        case .dark: self.statusMessage = LumaMessage(.dark)
                        case .brightening: self.statusMessage = LumaMessage(.brightening, preset.name)
                        }
                    }
                }
            } }
            let actualOutput = lastWritten
            DispatchQueue.main.async {
                self.lastOutput = actualOutput
                self.isSending = false
                self.recommendationFlow.finish()
                self.pendingSelection = nil
                switch result {
                case .success:
                    self.connected = true
                    self.savedState.color = preset.color
                    self.savedState.brightness = preset.brightness
                    self.savedState.lastApplied = Date()
                    self.savedState.lastCommandWasOff = false
                    self.persist()
                    self.statusMessage = LumaMessage(.applied, preset.name, preset.color.hex, String(preset.brightness))
                    if self.quitAfterTransition && self.error == nil && !self.terminationWaiting { NSApp.terminate(nil) }
                case .failure(let failure):
                    self.ambientColor = self.previousAmbient
                    self.livePreview = false
                    self.statusMessage = LumaMessage(.interrupted)
                    self.error = self.errorText(failure)
                }
                if self.terminationWaiting {
                    self.terminationWaiting = false
                    NSApp.reply(toApplicationShouldTerminate: true)
                }
            }
        }
    }

    func saveFavorite() {
        guard commitHex() else { return }
        let name = String(savedName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        guard !name.isEmpty else { return }
        guard favorites.count < 100 else { error = text(.favoriteLimit); return }
        favorites.append(Preset(id: UUID().uuidString, name: name, subtitle: LumaText.myPreset.rawValue, color: color,
                                brightness: Int(brightness.rounded())))
        savedName = ""; showSave = false
        persist()
    }

    func removeFavorite(_ id: String) {
        favorites.removeAll { $0.id == id }; persist()
    }

    private func persist() {
        savedState.favorites = favorites
        do { try store.save(savedState) }
        catch { self.error = text(.saveError, error.localizedDescription) }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        AppModel.shared.prepareToQuit()
    }
}
