import SwiftUI
import AppKit

@main
struct LumaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var model = AppModel.shared

    var body: some Scene {
        Window("Luma", id: "main") {
            ContentView(model: model)
                .preferredColorScheme(previewAppearance)
                .onAppear { model.refresh(); NSApp.activate(ignoringOtherApps: true) }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in model.refresh() }
        }
        .defaultSize(width: 1020, height: 760)
        .windowToolbarStyle(.unified)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Подсветка") {
                Button("Плавно включить выбранный цвет") { model.apply() }.keyboardShortcut(.return, modifiers: .command)
                Button("Выключить свет") { model.turnOff() }
                Button("Обновить подключение и рекомендацию") { model.refresh() }.keyboardShortcut("r")
            }
        }
    }

    private var previewAppearance: ColorScheme? {
        guard model.previewOnly else { return nil }
        if CommandLine.arguments.contains("--light") { return .light }
        if CommandLine.arguments.contains("--dark") { return .dark }
        if let appearance = Bundle.main.object(forInfoDictionaryKey: "LumaUIPreviewAppearance") as? String {
            return appearance == "light" ? .light : .dark
        }
        return nil
    }
}
