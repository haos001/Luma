import Foundation

public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case system, english = "en", russian = "ru"

    public func resolved(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        guard self == .system else { return self }
        for identifier in preferredLanguages {
            switch identifier.lowercased().split(separator: "-").first?.split(separator: "_").first {
            case "ru": return .russian
            case "en": return .english
            default: continue
            }
        }
        return .english
    }

    public var locale: Locale { Locale(identifier: resolved() == .russian ? "ru_RU" : "en_US") }

    public func text(_ key: LumaText, _ arguments: String...) -> String {
        format(key, arguments: arguments)
    }

    public func format(_ key: LumaText, arguments: [String]) -> String {
        let template = resolved() == .russian ? key.rawValue : key.english
        return String(format: template, locale: locale, arguments: arguments)
    }

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = AppLanguage(rawValue: value) ?? .system
    }
}

/// Typed keys make English coverage exhaustive at compile time. All format arguments are strings.
public enum LumaText: String, CaseIterable, Sendable {
    case customColor = "Свой цвет", checking = "Проверяем подключение…", ready = "Готово к включению."
    case demoDevice = "Демо · команды USB отключены", disconnectedDevice = "Подсветка не подключена"
    case invalidHex = "Введите шесть HEX-цифр, например #C98758."
    case demoCommand = "Демо: USB-команда не отправлялась."
    case offSent = "Команда выключения отправлена."
    case colorSent = "Отправлено: %@ · %@%%. Можно закрыть приложение."
    case notSent = "Команда не отправлена.", waveStatus = "Цвет мягко заполняет окно…"
    case demoWave = "Демо: волна завершена, USB-команда не отправлялась."
    case dimming = "Мягко гасим прежний цвет…", dark = "Прежний цвет погас…"
    case brightening = "Плавно включаем «%@»…", applied = "Плавно включён: %@ · %@ · %@%%."
    case interrupted = "Переход прерван. Проверьте подключение."
    case favoriteLimit = "Можно сохранить до 100 своих пресетов.", myPreset = "Мой пресет"
    case saveError = "Не удалось сохранить настройки: %@"
    case okay = "Понятно", library = "Библиотека", allColors = "Все цвета", myColors = "Мои цвета"
    case mood = "Настроение", keepLight = "Свет останется,\nкогда вы закроете Luma."
    case selectionMode = "Режим выбора", presets = "Пресеты", connected = "Подключено", disconnected = "Нет подключения"
    case livePreview = "Предпросмотр на подсветке", refresh = "Обновить подключение и рекомендацию"
    case turnOff = "Выключить свет", settings = "Настройки подсветки", systemLanguage = "Как в macOS"
    case recommendedNow = "Рекомендуется сейчас", selectRecommendation = "Выбрать рекомендованный цвет"
    case selectRecommendationNamed = "Выбрать рекомендацию: %@"
    case wave = "Цвет заполняет окно", transition = "Плавный переход", tapToTurnOn = "Нажмите, чтобы включить"
    case orbHelp = "Плавно включить «%@» · %@", orbAccessibility = "Включить выбранный цвет: %@, %@"
    case moodPalette = "Палитра настроений", findColor = "Найти цвет", clearSearch = "Очистить поиск"
    case favoriteEmpty = "Ваши любимые оттенки", noResults = "Цвет не найден"
    case favoriteHint = "Создайте оттенок во вкладке «Свой цвет» и сохраните его здесь."
    case searchHint = "Попробуйте другое название.", presetAccessibility = "%@, %@, %@ процентов"
    case deletePreset = "Удалить пресет", yourShade = "Ваш оттенок", save = "Сохранить"
    case channel = "Канал %@", brightness = "Яркость", turnOn = "Включить"
    case applyHelp = "Плавно включить выбранный цвет · ⌘↩", apply = "Плавно включить выбранный цвет"
    case applyAndQuit = "Включить и закрыть", saveFavorite = "Сохранить в мои цвета"
    case moreActions = "Дополнительные действия", preview = "Предпросмотр", saveShade = "Сохранить оттенок"
    case name = "Название", cancel = "Отмена", hue = "Оттенок", backlight = "Подсветка"
    case colorSquare = "Цветовой квадрат. Для точного выбора используйте HEX или RGB-ползунки."
    case notFound = "Подсветка не найдена. Проверьте подключение USB и нажмите «Обновить»."
    case multipleDevices = "Найдено несколько подходящих контроллеров. Оставьте подключённым один."
    case deviceBusy = "Не удалось открыть контроллер (%@). Закройте другие приложения подсветки и повторите."
    case writeFailed = "USB-команда не отправлена (%@). Проверьте кабель и закройте другие приложения подсветки."
    case work = "Работа", morning = "Утро", evening = "Вечер", night = "Ночь", seasons = "Сезоны"
    case rest = "Отдых", creative = "Творчество", cinema = "Кино и игры"
    case winter = "Зима", spring = "Весна", summer = "Лето", autumn = "Осень"
    case dawn = "Раннее утро", day = "День", afternoon = "Вторая половина дня"
    case weekend = "неспешный выходной", weekday = "рабочий ритм"
    case cliColor = "Нужен цвет #RRGGBB", cliBrightness = "Яркость должна быть 0…100"

    public var english: String {
        switch self {
        case .customColor: return "Custom color"
        case .checking: return "Checking connection…"
        case .ready: return "Ready to turn on."
        case .demoDevice: return "Demo · USB commands disabled"
        case .disconnectedDevice: return "Backlight not connected"
        case .invalidHex: return "Enter six HEX digits, such as #C98758."
        case .demoCommand: return "Demo: no USB command was sent."
        case .offSent: return "Off command sent."
        case .colorSent: return "Sent: %@ · %@%%. You can quit the app."
        case .notSent: return "Command not sent."
        case .waveStatus: return "Color is gently filling the window…"
        case .demoWave: return "Demo: wave complete; no USB command was sent."
        case .dimming: return "Gently fading out the previous color…"
        case .dark: return "The previous color has faded out…"
        case .brightening: return "Gently turning on “%@”…"
        case .applied: return "Faded in: %@ · %@ · %@%%."
        case .interrupted: return "Transition interrupted. Check the connection."
        case .favoriteLimit: return "You can save up to 100 custom presets."
        case .myPreset: return "My preset"
        case .saveError: return "Could not save settings: %@"
        case .okay: return "OK"
        case .library: return "Library"
        case .allColors: return "All colors"
        case .myColors: return "My colors"
        case .mood: return "Mood"
        case .keepLight: return "The light stays on\nwhen you quit Luma."
        case .selectionMode: return "Color selection"
        case .presets: return "Presets"
        case .connected: return "Connected"
        case .disconnected: return "Not connected"
        case .livePreview: return "Live preview on backlight"
        case .refresh: return "Refresh connection and recommendation"
        case .turnOff: return "Turn off light"
        case .settings: return "Backlight settings"
        case .systemLanguage: return "Follow macOS"
        case .recommendedNow: return "Recommended now"
        case .selectRecommendation: return "Select the recommended color"
        case .selectRecommendationNamed: return "Select recommendation: %@"
        case .wave: return "Color fills the window"
        case .transition: return "Smooth transition"
        case .tapToTurnOn: return "Click to turn on"
        case .orbHelp: return "Gently turn on “%@” · %@"
        case .orbAccessibility: return "Turn on selected color: %@, %@"
        case .moodPalette: return "A palette of moods"
        case .findColor: return "Find a color"
        case .clearSearch: return "Clear search"
        case .favoriteEmpty: return "Your favorite shades"
        case .noResults: return "No colors found"
        case .favoriteHint: return "Create a shade in Custom color and save it here."
        case .searchHint: return "Try a different name."
        case .presetAccessibility: return "%@, %@, %@ percent"
        case .deletePreset: return "Delete preset"
        case .yourShade: return "Your shade"
        case .save: return "Save"
        case .channel: return "%@ channel"
        case .brightness: return "Brightness"
        case .turnOn: return "Turn on"
        case .applyHelp: return "Gently turn on the selected color · ⌘↩"
        case .apply: return "Gently turn on the selected color"
        case .applyAndQuit: return "Turn on and quit"
        case .saveFavorite: return "Save to my colors"
        case .moreActions: return "More actions"
        case .preview: return "Live preview"
        case .saveShade: return "Save a shade"
        case .name: return "Name"
        case .cancel: return "Cancel"
        case .hue: return "Hue"
        case .backlight: return "Backlight"
        case .colorSquare: return "Color square. Use HEX or RGB sliders for precise selection."
        case .notFound: return "Backlight not found. Check the USB connection and choose Refresh."
        case .multipleDevices: return "Multiple compatible controllers found. Leave only one connected."
        case .deviceBusy: return "Could not open the controller (%@). Quit other backlight apps and try again."
        case .writeFailed: return "USB command not sent (%@). Check the cable and quit other backlight apps."
        case .work: return "Work"
        case .morning: return "Morning"
        case .evening: return "Evening"
        case .night: return "Night"
        case .seasons: return "Seasons"
        case .rest: return "Rest"
        case .creative: return "Creativity"
        case .cinema: return "Cinema & games"
        case .winter: return "Winter"
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .autumn: return "Autumn"
        case .dawn: return "Early morning"
        case .day: return "Daytime"
        case .afternoon: return "Afternoon"
        case .weekend: return "a slow weekend"
        case .weekday: return "a working rhythm"
        case .cliColor: return "A #RRGGBB color is required"
        case .cliBrightness: return "Brightness must be 0…100"
        }
    }
}

public struct LumaMessage: Equatable, Sendable {
    public let key: LumaText
    public let arguments: [String]
    public init(_ key: LumaText, _ arguments: String...) { self.key = key; self.arguments = arguments }
    public func localized(in language: AppLanguage) -> String { language.format(key, arguments: arguments) }
}

extension PresetGroup {
    public func localizedName(in language: AppLanguage) -> String {
        let key: LumaText
        switch self {
        case .work: key = .work
        case .morning: key = .morning
        case .evening: key = .evening
        case .night: key = .night
        case .seasons: key = .seasons
        case .rest: key = .rest
        case .creative: key = .creative
        case .cinema: key = .cinema
        }
        return language.text(key)
    }
}

extension Season {
    public func localizedName(in language: AppLanguage) -> String {
        let key: LumaText
        switch self { case .winter: key = .winter; case .spring: key = .spring; case .summer: key = .summer; case .autumn: key = .autumn }
        return language.text(key)
    }
}

extension DayPeriod {
    public func localizedName(in language: AppLanguage) -> String {
        let key: LumaText
        switch self { case .dawn: key = .dawn; case .day: key = .day; case .afternoon: key = .afternoon; case .evening: key = .evening; case .night: key = .night }
        return language.text(key)
    }
}

extension Preset {
    public func localizedName(in language: AppLanguage) -> String {
        language.resolved() == .english ? Self.english[id]?.0 ?? name : name
    }
    public func localizedSubtitle(in language: AppLanguage) -> String {
        if let translation = Self.english[id] { return language.resolved() == .english ? translation.1 : subtitle }
        // Favorite names remain user-authored; only the app-provided generic subtitle is translated.
        return subtitle == LumaText.myPreset.rawValue || subtitle == LumaText.myPreset.english ? language.text(.myPreset) : subtitle
    }
    public func matches(search: String) -> Bool {
        [name, subtitle, localizedName(in: .english), localizedSubtitle(in: .english)]
            .joined(separator: " ").localizedCaseInsensitiveContains(search)
    }

    private static let english: [String: (String, String)] = [
        "warm-focus": ("Warm Focus", "Gentle light for a long task"),
        "paper": ("Paper & Coffee", "Creamy and almost neutral"),
        "eucalyptus": ("Eucalyptus", "Fresh green without the neon"),
        "clear-sky": ("Clear Thought", "Airy gray-blue"),
        "sand": ("Sandy Desk", "Calm golden beige"),
        "pink-dawn": ("Pink Dawn", "A delicate morning pink"),
        "apricot": ("Apricot Morning", "A warm start to a new day"),
        "morning-mist": ("Morning Mist", "Light sage"),
        "vanilla": ("Vanilla Light", "A sunny, creamy shade"),
        "dew": ("First Dew", "Clean mint green"),
        "amber-desk": ("Amber Study", "Golden hour at your desk"),
        "terracotta": ("Terracotta", "Earthy peach-red"),
        "rose-tea": ("Rose Tea", "A quiet pink with warmth"),
        "peach-hour": ("Peach Hour", "Easy evening comfort"),
        "copper": ("Copper Sunset", "A deep, warm shade"),
        "night-rose": ("Night Poetry", "Dusty rose and lilac"),
        "night-amber": ("Night Lamp", "Warm amber, no animation"),
        "mauve": ("Quiet Lilac", "A calm lilac haze"),
        "moonstone": ("Moonstone", "A gray-blue night accent"),
        "cocoa": ("Midnight Cocoa", "The warm shade of milky cocoa"),
        "autumn-leaf": ("Autumn Leaf", "A warm autumn shade"),
        "maple": ("Maple Syrup", "Golden autumn"),
        "winter-candle": ("Winter Candle", "A warm spot in a cold season"),
        "spring-garden": ("Spring Garden", "Tender new greenery"),
        "summer-dusk": ("Summer Dusk", "Pastel pink and violet"),
        "matcha": ("Matcha Break", "Soft tea green"),
        "latte": ("Slow Latte", "Warm beige for a weekend"),
        "spa": ("Quiet Water", "Sea green for unwinding"),
        "reading": ("An Evening Book", "Honey-cream comfort"),
        "sunday": ("Sunday Cloud", "Unhurried lavender"),
        "orchid": ("Orchid", "Expressive color for new ideas"),
        "coral": ("Coral Spark", "A warm creative accent"),
        "lagoon": ("Lagoon", "A turquoise mood"),
        "periwinkle": ("Periwinkle", "Soft blue-violet"),
        "fuchsia": ("Electric Rose", "A rich pink accent"),
        "cinema-plum": ("Plum Cinema", "Deep color for movie time"),
        "deep-ocean": ("Deep Ocean", "A calm blue atmosphere"),
        "arcade": ("Arcade Iris", "A violet gaming evening"),
        "mars": ("Martian Evening", "Muted copper-red"),
        "aurora": ("Northern Lights", "A static emerald accent")
    ]
}
