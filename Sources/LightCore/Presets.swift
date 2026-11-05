import Foundation

public enum Season: String, CaseIterable, Codable, Sendable {
    case winter = "Зима", spring = "Весна", summer = "Лето", autumn = "Осень"
    public static func forMonth(_ month: Int) -> Season {
        switch month { case 3...5: return .spring; case 6...8: return .summer; case 9...11: return .autumn; default: return .winter }
    }
}

public enum DayPeriod: String, CaseIterable, Codable, Sendable {
    case dawn = "Раннее утро", day = "День", afternoon = "Вторая половина дня", evening = "Вечер", night = "Ночь"
    public static func forHour(_ hour: Int) -> DayPeriod {
        switch hour { case 6..<10: return .dawn; case 10..<15: return .day; case 15..<18: return .afternoon; case 18..<23: return .evening; default: return .night }
    }
}

public enum PresetGroup: String, CaseIterable, Codable, Sendable {
    case work = "Работа", morning = "Утро", evening = "Вечер", night = "Ночь"
    case seasons = "Сезоны", rest = "Отдых", creative = "Творчество", cinema = "Кино и игры"
    public var icon: String {
        switch self {
        case .work: return "desktopcomputer"
        case .morning: return "sunrise"
        case .evening: return "sunset"
        case .night: return "moon.stars"
        case .seasons: return "leaf"
        case .rest: return "cup.and.saucer"
        case .creative: return "paintpalette"
        case .cinema: return "film"
        }
    }
}

public struct Preset: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var subtitle: String
    public var color: RGB
    public var brightness: Int
    public var group: PresetGroup
    public var seasons: [Season]
    public var periods: [DayPeriod]
    public var recommended: Bool

    public init(id: String, name: String, subtitle: String, color: RGB, brightness: Int = 100,
                group: PresetGroup = .creative, seasons: [Season] = [], periods: [DayPeriod] = [], recommended: Bool = false) {
        self.id = id; self.name = name; self.subtitle = subtitle; self.color = color
        self.brightness = min(100, max(0, brightness)); self.group = group
        self.seasons = seasons; self.periods = periods; self.recommended = recommended
    }
}

public enum PresetCatalog {
    private static func p(_ id: String, _ name: String, _ hex: String, _ detail: String, _ group: PresetGroup,
                          _ seasons: [Season] = [], _ periods: [DayPeriod] = [], _ recommend: Bool = true) -> Preset {
        Preset(id: id, name: name, subtitle: detail, color: RGB(hex: hex)!, group: group,
               seasons: seasons, periods: periods, recommended: recommend)
    }

    public static let all: [Preset] = [
        p("warm-focus", "Тёплый фокус", "FFCA9C", "Мягкий свет для длинной задачи", .work, [.autumn, .winter], [.day, .afternoon]),
        p("paper", "Бумага и кофе", "F2DABB", "Кремовый, почти нейтральный", .work, [.autumn, .winter], [.day]),
        p("eucalyptus", "Эвкалипт", "8EC9B3", "Свежий зелёный без неона", .work, [.spring, .summer], [.day, .afternoon]),
        p("clear-sky", "Ясная мысль", "AACAD8", "Воздушный серо-голубой", .work, [.summer, .winter], [.day]),
        p("sand", "Песчаный стол", "D9B98C", "Спокойный золотисто-бежевый", .work, [.autumn, .summer], [.afternoon]),
        p("pink-dawn", "Розовый рассвет", "D99BB6", "Нежный утренний розовый", .morning, [.spring, .autumn], [.dawn]),
        p("apricot", "Абрикосовое утро", "FFC19A", "Тёплый старт нового дня", .morning, [.autumn, .winter], [.dawn]),
        p("morning-mist", "Утренний туман", "BCD5CE", "Светлый шалфей", .morning, [.spring, .summer], [.dawn]),
        p("vanilla", "Ванильный свет", "FFE1AD", "Солнечный сливочный оттенок", .morning, [.winter, .autumn], [.dawn]),
        p("dew", "Первая роса", "ACD9C2", "Чистый мятно-зелёный", .morning, [.spring, .summer], [.dawn]),
        p("amber-desk", "Янтарный кабинет", "DDA16D", "Золотой час за рабочим столом", .evening, [.autumn, .winter], [.evening]),
        p("terracotta", "Терракота", "CE8B77", "Землистый красно-персиковый", .evening, [.autumn, .summer], [.evening]),
        p("rose-tea", "Розовый чай", "D99EAA", "Тихий розовый с теплом", .evening, [.spring, .winter], [.evening]),
        p("peach-hour", "Персиковый час", "F0AF93", "Лёгкий вечерний уют", .evening, [.spring, .summer], [.evening]),
        p("copper", "Медный закат", "C98B65", "Глубокий тёплый оттенок", .evening, [.autumn], [.afternoon, .evening]),
        p("night-rose", "Ночная поэзия", "B47E96", "Припылённый розово-лиловый", .night, [.autumn, .spring], [.night]),
        p("night-amber", "Ночная лампа", "BD885E", "Тёплый янтарь без анимации", .night, [.autumn, .winter], [.night]),
        p("mauve", "Тихий лиловый", "A58FAF", "Спокойный сиреневый туман", .night, [.spring, .summer], [.night]),
        p("moonstone", "Лунный камень", "939DB9", "Серо-синий ночной акцент", .night, [.winter, .summer], [.night]),
        p("cocoa", "Какао после полуночи", "BC9380", "Тёплый оттенок молочного какао", .night, [.winter, .autumn], [.night]),
        p("autumn-leaf", "Осенний лист", "C98758", "Тёплый осенний оттенок", .seasons, [.autumn], [.afternoon, .evening]),
        p("maple", "Кленовый сироп", "E0A266", "Золотистая осень", .seasons, [.autumn], [.dawn, .day]),
        p("winter-candle", "Зимняя свеча", "E6BB87", "Тёплая точка в холодный сезон", .seasons, [.winter], [.afternoon, .evening]),
        p("spring-garden", "Весенний сад", "AED2A2", "Нежная молодая зелень", .seasons, [.spring], [.day, .afternoon]),
        p("summer-dusk", "Летние сумерки", "C59AC4", "Пастельный розово-фиолетовый", .seasons, [.summer], [.evening, .night]),
        p("matcha", "Матча-пауза", "B6C497", "Мягкий чайный зелёный", .rest, [.spring, .summer], [.day, .afternoon]),
        p("latte", "Медленный латте", "D4B193", "Тёплый бежевый выходного дня", .rest, [.autumn, .winter], [.dawn, .day]),
        p("spa", "Тихая вода", "8DC3BB", "Морской зелёный для отдыха", .rest, [.summer, .spring], [.afternoon]),
        p("reading", "Вечер с книгой", "D5AE80", "Медово-кремовый уют", .rest, [.autumn, .winter], [.evening]),
        p("sunday", "Воскресное облако", "C7B5CD", "Лавандовый без спешки", .rest, [.spring, .summer], [.evening, .night]),
        p("orchid", "Орхидея", "CB8FC9", "Выразительный цвет для идей", .creative, [], [], false),
        p("coral", "Коралловая искра", "ED8C86", "Тёплый творческий акцент", .creative, [], [], false),
        p("lagoon", "Лагуна", "61BDBB", "Бирюзовое настроение", .creative, [], [], false),
        p("periwinkle", "Барвинок", "9B9EDB", "Мягкий сине-фиолетовый", .creative, [], [], false),
        p("fuchsia", "Электрическая роза", "E06CB1", "Насыщенный розовый акцент", .creative, [], [], false),
        p("cinema-plum", "Сливовый кинотеатр", "9869B0", "Глубокий цвет для кино", .cinema, [], [], false),
        p("deep-ocean", "Глубокий океан", "4D91B0", "Спокойная синяя атмосфера", .cinema, [], [], false),
        p("arcade", "Аркадный ирис", "8871D1", "Фиолетовый игровой вечер", .cinema, [], [], false),
        p("mars", "Марсианский вечер", "C76B58", "Приглушённый красно-медный", .cinema, [], [], false),
        p("aurora", "Северное сияние", "62B99B", "Статический изумрудный акцент", .cinema, [], [], false)
    ]
}

public struct Recommendation: Equatable, Sendable {
    public let preset: Preset
    public let context: String
    public let explanation: String
}

public enum RecommendationEngine {
    public static func recommend(at date: Date, calendar: Calendar = .current) -> Recommendation {
        let season = Season.forMonth(calendar.component(.month, from: date))
        let period = DayPeriod.forHour(calendar.component(.hour, from: date))
        let weekend = calendar.isDateInWeekend(date)
        let candidates = PresetCatalog.all.filter { $0.recommended && $0.seasons.contains(season) && $0.periods.contains(period) }
        let scored = candidates.map { preset -> (Preset, Int) in
            var score = 0
            if weekend && preset.group == .rest { score += 3 }
            if !weekend && [.day, .afternoon].contains(period) && preset.group == .work { score += 3 }
            if period == .night && preset.group == .night { score += 2 }
            return (preset, score)
        }
        let maximum = scored.map(\.1).max() ?? 0
        let best = scored.filter { $0.1 == maximum }.map(\.0)
        let pool = best.isEmpty ? [PresetCatalog.all[0]] : best
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        let preset = pool[(day + year) % pool.count]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEEE, d MMMM · HH:mm"
        let dateText = formatter.string(from: date)
        let capitalizedDate = dateText.prefix(1).uppercased() + dateText.dropFirst()
        return Recommendation(preset: preset,
            context: "\(capitalizedDate) · \(season.rawValue.lowercased())",
            explanation: "\(period.rawValue) · \(weekend ? "неспешный выходной" : "рабочий ритм"). \(preset.subtitle).")
    }
}
