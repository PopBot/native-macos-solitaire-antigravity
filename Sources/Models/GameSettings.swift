import SwiftUI

public enum DrawMode: Int, Codable, CaseIterable, Identifiable, Sendable {
    case drawOne = 1
    case drawThree = 3

    public var id: Int { rawValue }
    public var title: String {
        switch self {
        case .drawOne: return "Draw 1"
        case .drawThree: return "Draw 3"
        }
    }
}

public enum ScoringMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case standard = "standard"
    case vegas = "vegas"

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .standard: return "Standard"
        case .vegas: return "Vegas"
        }
    }
}

public enum CardDeckStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case glass = "glass"
    case classicLinen = "classicLinen"

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .glass: return "Translucent Glass"
        case .classicLinen: return "Classic Linen"
        }
    }
}

public enum AppAppearance: String, Codable, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case dark = "dark"
    case light = "light"

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .system: return "System"
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

public enum BackgroundTheme: String, Codable, CaseIterable, Identifiable, Sendable {
    case emeraldFelt = "emeraldFelt"
    case midnightObsidian = "midnightObsidian"
    case royalBlueFelt = "royalBlueFelt"
    case purpleVelvet = "purpleVelvet"
    case auroraTeal = "auroraTeal"
    case custom = "custom"

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .emeraldFelt: return "Emerald Felt"
        case .midnightObsidian: return "Midnight Obsidian"
        case .royalBlueFelt: return "Royal Blue Felt"
        case .purpleVelvet: return "Velvet Nebula"
        case .auroraTeal: return "Aurora Glass"
        case .custom: return "Custom Image…"
        }
    }
}

public enum CardBackTheme: String, Codable, CaseIterable, Identifiable, Sendable {
    case geometricGlass = "geometricGlass"
    case royalSapphire = "royalSapphire"
    case crimsonVelvet = "crimsonVelvet"
    case obsidianMinimal = "obsidianMinimal"
    case custom = "custom"

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .geometricGlass: return "Geometric Glass"
        case .royalSapphire: return "Royal Sapphire"
        case .crimsonVelvet: return "Crimson Velvet"
        case .obsidianMinimal: return "Obsidian Minimal"
        case .custom: return "Custom Image…"
        }
    }
}

@Observable
public final class GameSettings: @unchecked Sendable {
    public static let shared = GameSettings()

    private let defaults = UserDefaults.standard

    public var drawMode: DrawMode {
        didSet { defaults.set(drawMode.rawValue, forKey: "drawMode") }
    }

    public var scoringMode: ScoringMode {
        didSet { defaults.set(scoringMode.rawValue, forKey: "scoringMode") }
    }

    public var timerEnabled: Bool {
        didSet { defaults.set(timerEnabled, forKey: "timerEnabled") }
    }

    public var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: "soundEnabled") }
    }

    public var soundVolume: Double {
        didSet { defaults.set(soundVolume, forKey: "soundVolume") }
    }

    public var cardDeckStyle: CardDeckStyle {
        didSet { defaults.set(cardDeckStyle.rawValue, forKey: "cardDeckStyle") }
    }

    public var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: "appearance") }
    }

    public var backgroundTheme: BackgroundTheme {
        didSet { defaults.set(backgroundTheme.rawValue, forKey: "backgroundTheme") }
    }

    public var cardBackTheme: CardBackTheme {
        didSet { defaults.set(cardBackTheme.rawValue, forKey: "cardBackTheme") }
    }

    public var customBackgroundImageData: Data? {
        didSet { defaults.set(customBackgroundImageData, forKey: "customBackgroundImageData") }
    }

    public var customCardBackImageData: Data? {
        didSet { defaults.set(customCardBackImageData, forKey: "customCardBackImageData") }
    }

    public init() {
        let drawVal = defaults.integer(forKey: "drawMode")
        self.drawMode = (drawVal == 3) ? .drawThree : .drawOne

        let scoreStr = defaults.string(forKey: "scoringMode") ?? ScoringMode.standard.rawValue
        self.scoringMode = ScoringMode(rawValue: scoreStr) ?? .standard

        self.timerEnabled = defaults.object(forKey: "timerEnabled") != nil ? defaults.bool(forKey: "timerEnabled") : true
        self.soundEnabled = defaults.object(forKey: "soundEnabled") != nil ? defaults.bool(forKey: "soundEnabled") : true

        let vol = defaults.double(forKey: "soundVolume")
        self.soundVolume = defaults.object(forKey: "soundVolume") != nil ? vol : 0.8

        let styleStr = defaults.string(forKey: "cardDeckStyle") ?? CardDeckStyle.glass.rawValue
        self.cardDeckStyle = CardDeckStyle(rawValue: styleStr) ?? .glass

        let appStr = defaults.string(forKey: "appearance") ?? AppAppearance.system.rawValue
        self.appearance = AppAppearance(rawValue: appStr) ?? .system

        let bgStr = defaults.string(forKey: "backgroundTheme") ?? BackgroundTheme.emeraldFelt.rawValue
        self.backgroundTheme = BackgroundTheme(rawValue: bgStr) ?? .emeraldFelt

        let backStr = defaults.string(forKey: "cardBackTheme") ?? CardBackTheme.geometricGlass.rawValue
        self.cardBackTheme = CardBackTheme(rawValue: backStr) ?? .geometricGlass

        self.customBackgroundImageData = defaults.data(forKey: "customBackgroundImageData")
        self.customCardBackImageData = defaults.data(forKey: "customCardBackImageData")
    }
}
