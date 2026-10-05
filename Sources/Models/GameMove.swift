import Foundation

public enum CardLocation: Equatable, Hashable, Codable, Sendable {
    case stock
    case waste
    case foundation(index: Int)
    case tableau(column: Int, index: Int)

    public var isTableau: Bool {
        if case .tableau = self { return true }
        return false
    }

    public var isFoundation: Bool {
        if case .foundation = self { return true }
        return false
    }
}

public struct GameMove: Equatable, Codable, Sendable {
    public enum MoveType: Equatable, Codable, Sendable {
        /// Drawing 1 or 3 cards from stock to waste
        case drawFromStock(cards: [Card])
        /// Recycling the entire waste pile back into the stock
        case recycleWaste(cards: [Card])
        /// Moving one or more cards from one location to another
        case move(cards: [Card], from: CardLocation, to: CardLocation, flippedCardUnderneath: Bool)
    }

    public let id: UUID
    public let type: MoveType
    public let scoreDelta: Int
    public let timestamp: Date

    public init(id: UUID = UUID(), type: MoveType, scoreDelta: Int = 0, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.scoreDelta = scoreDelta
        self.timestamp = timestamp
    }
}
