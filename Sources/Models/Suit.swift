import SwiftUI

public enum SuitColor: String, Codable, Sendable {
    case red
    case black

    public var swiftUIColor: Color {
        switch self {
        case .red:
            return Color(red: 0.92, green: 0.22, blue: 0.24)
        case .black:
            return Color(red: 0.12, green: 0.14, blue: 0.18)
        }
    }
}

public enum Suit: String, CaseIterable, Codable, Identifiable, Sendable {
    case clubs = "clubs"
    case diamonds = "diamonds"
    case hearts = "hearts"
    case spades = "spades"

    public var id: String { rawValue }

    public var color: SuitColor {
        switch self {
        case .hearts, .diamonds:
            return .red
        case .spades, .clubs:
            return .black
        }
    }

    public var symbol: String {
        switch self {
        case .spades: return "♠"
        case .hearts: return "♥"
        case .diamonds: return "♦"
        case .clubs: return "♣"
        }
    }

    public var sfSymbol: String {
        switch self {
        case .spades: return "suit.spade.fill"
        case .hearts: return "suit.heart.fill"
        case .diamonds: return "suit.diamond.fill"
        case .clubs: return "suit.club.fill"
        }
    }

    public var displayName: String {
        switch self {
        case .spades: return "Spades"
        case .hearts: return "Hearts"
        case .diamonds: return "Diamonds"
        case .clubs: return "Clubs"
        }
    }
}
