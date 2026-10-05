import Foundation

public struct Card: Identifiable, Equatable, Hashable, Codable, Sendable {
    public let id: UUID
    public let suit: Suit
    public let rank: Rank
    public var isFaceUp: Bool

    public init(id: UUID = UUID(), suit: Suit, rank: Rank, isFaceUp: Bool = false) {
        self.id = id
        self.suit = suit
        self.rank = rank
        self.isFaceUp = isFaceUp
    }

    public var isRed: Bool {
        suit.color == .red
    }

    public var isBlack: Bool {
        suit.color == .black
    }

    public var displayName: String {
        "\(rank.symbol)\(suit.symbol)"
    }

    public var fullDescription: String {
        "\(rank.name) of \(suit.displayName)"
    }

    public static func standardDeck() -> [Card] {
        var deck: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.append(Card(suit: suit, rank: rank, isFaceUp: false))
            }
        }
        return deck
    }
}
