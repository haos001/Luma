import Foundation

public struct SavedState: Codable, Equatable, Sendable {
    public var color: RGB
    public var brightness: Int
    public var favorites: [Preset]
    public var lastApplied: Date?
    public var lastCommandWasOff: Bool
    public var language: AppLanguage

    public init(color: RGB = RGB(201, 135, 88), brightness: Int = 100, favorites: [Preset] = [],
                lastApplied: Date? = nil, lastCommandWasOff: Bool = false, language: AppLanguage = .system) {
        self.color = color; self.brightness = min(100, max(0, brightness)); self.favorites = favorites
        self.lastApplied = lastApplied; self.lastCommandWasOff = lastCommandWasOff
        self.language = language
    }

    private enum CodingKeys: String, CodingKey { case color, brightness, favorites, lastApplied, lastCommandWasOff, language }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        color = try values.decode(RGB.self, forKey: .color)
        brightness = try values.decode(Int.self, forKey: .brightness)
        favorites = try values.decode([Preset].self, forKey: .favorites)
        lastApplied = try values.decodeIfPresent(Date.self, forKey: .lastApplied)
        lastCommandWasOff = try values.decodeIfPresent(Bool.self, forKey: .lastCommandWasOff) ?? false
        language = try values.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .system
    }

    public func validated() -> SavedState {
        var copy = self
        copy.brightness = min(100, max(0, brightness))
        var ids = Set<String>()
        copy.favorites = favorites.filter { ids.insert($0.id).inserted }.prefix(100).map { preset in
            var p = preset
            p.brightness = min(100, max(0, p.brightness))
            p.name = String(p.name.prefix(60))
            return p
        }
        return copy
    }
}

public struct StateStore {
    public let url: URL
    public init(url: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/Luma/state.json")) { self.url = url }

    public func load() -> SavedState {
        if let data = try? Data(contentsOf: url), let state = try? JSONDecoder().decode(SavedState.self, from: data) {
            return state.validated()
        }
        return SavedState()
    }

    public func save(_ state: SavedState) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(state.validated()).write(to: url, options: .atomic)
    }
}
