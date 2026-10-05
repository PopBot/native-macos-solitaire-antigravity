import Foundation

public struct Hint: Equatable, Sendable {
    public let from: CardLocation
    public let to: CardLocation
    public let message: String
    public let cards: [Card]

    public init(from: CardLocation, to: CardLocation, message: String, cards: [Card]) {
        self.from = from
        self.to = to
        self.message = message
        self.cards = cards
    }
}

public struct HintEngine {
    /// Determines whether moving a card to the foundation is safe (i.e. won't trap lower-rank cards needed on the tableau).
    public static func isSafeFoundationMove(card: Card, foundations: [[Card]]) -> Bool {
        // Aces and 2s are always safe
        if card.rank.rawValue <= 2 { return true }

        // Find the lowest rank of the opposite color currently in foundation
        let oppositeColor = (card.suit.color == .red) ? SuitColor.black : SuitColor.red
        var minOppositeRank = 13

        for f in foundations {
            if let top = f.last {
                if top.suit.color == oppositeColor {
                    minOppositeRank = min(minOppositeRank, top.rank.rawValue)
                }
            } else {
                // If an opposite color foundation is empty, rank is 0
                minOppositeRank = 0
            }
        }

        // Safe if moving card is at most opposite color foundation rank + 1
        return card.rank.rawValue <= (minOppositeRank + 1)
    }

    /// Finds the best available hint given current game state
    public static func findBestHint(
        stock: [Card],
        waste: [Card],
        foundations: [[Card]],
        tableau: [[Card]]
    ) -> Hint? {
        // 1. Check Waste to Foundation (safe)
        if let wasteCard = waste.last {
            for (fIndex, foundation) in foundations.enumerated() {
                if canPlaceOnFoundation(card: wasteCard, foundation: foundation) {
                    if isSafeFoundationMove(card: wasteCard, foundations: foundations) {
                        return Hint(
                            from: .waste,
                            to: .foundation(index: fIndex),
                            message: "Move \(wasteCard.displayName) to Foundation",
                            cards: [wasteCard]
                        )
                    }
                }
            }
        }

        // 2. Check Tableau to Foundation (safe)
        for (colIndex, column) in tableau.enumerated() {
            if let topCard = column.last, topCard.isFaceUp {
                for (fIndex, foundation) in foundations.enumerated() {
                    if canPlaceOnFoundation(card: topCard, foundation: foundation) {
                        if isSafeFoundationMove(card: topCard, foundations: foundations) {
                            return Hint(
                                from: .tableau(column: colIndex, index: column.count - 1),
                                to: .foundation(index: fIndex),
                                message: "Move \(topCard.displayName) from Column \(colIndex + 1) to Foundation",
                                cards: [topCard]
                            )
                        }
                    }
                }
            }
        }

        // 3. Tableau to Tableau moves that uncover face-down cards
        for (sourceCol, column) in tableau.enumerated() {
            let firstFaceUpIndex = column.firstIndex(where: { $0.isFaceUp }) ?? column.count
            guard firstFaceUpIndex < column.count else { continue }

            // If moving this card would uncover a face-down card
            let wouldUncover = firstFaceUpIndex > 0

            for cardIdx in firstFaceUpIndex..<column.count {
                let movingCard = column[cardIdx]
                let movingStack = Array(column[cardIdx...])

                // Don't move a King that's already at the base of a column with no face-down cards
                if movingCard.rank == .king && cardIdx == 0 {
                    continue
                }

                for (destCol, destColumn) in tableau.enumerated() where destCol != sourceCol {
                    if canPlaceOnTableau(movingCard: movingCard, destination: destColumn) {
                        if wouldUncover && cardIdx == firstFaceUpIndex {
                            return Hint(
                                from: .tableau(column: sourceCol, index: cardIdx),
                                to: .tableau(column: destCol, index: max(0, destColumn.count - 1)),
                                message: "Move \(movingCard.displayName) to Column \(destCol + 1) to reveal a hidden card",
                                cards: movingStack
                            )
                        }
                    }
                }
            }
        }

        // 4. Waste to Tableau
        if let wasteCard = waste.last {
            for (destCol, destColumn) in tableau.enumerated() {
                if canPlaceOnTableau(movingCard: wasteCard, destination: destColumn) {
                    // Avoid putting a King into an empty column unless it helps
                    if wasteCard.rank == .king && destColumn.isEmpty {
                        return Hint(
                            from: .waste,
                            to: .tableau(column: destCol, index: 0),
                            message: "Move King \(wasteCard.displayName) to empty Column \(destCol + 1)",
                            cards: [wasteCard]
                        )
                    } else if !destColumn.isEmpty {
                        return Hint(
                            from: .waste,
                            to: .tableau(column: destCol, index: destColumn.count - 1),
                            message: "Move \(wasteCard.displayName) from Waste to Column \(destCol + 1)",
                            cards: [wasteCard]
                        )
                    }
                }
            }
        }

        // 5. Any other Tableau to Tableau move
        for (sourceCol, column) in tableau.enumerated() {
            let firstFaceUpIndex = column.firstIndex(where: { $0.isFaceUp }) ?? column.count
            guard firstFaceUpIndex < column.count else { continue }

            for cardIdx in firstFaceUpIndex..<column.count {
                let movingCard = column[cardIdx]
                let movingStack = Array(column[cardIdx...])

                if movingCard.rank == .king && cardIdx == 0 {
                    continue
                }

                for (destCol, destColumn) in tableau.enumerated() where destCol != sourceCol {
                    if canPlaceOnTableau(movingCard: movingCard, destination: destColumn) {
                        return Hint(
                            from: .tableau(column: sourceCol, index: cardIdx),
                            to: .tableau(column: destCol, index: max(0, destColumn.count - 1)),
                            message: "Move \(movingCard.displayName) to Column \(destCol + 1)",
                            cards: movingStack
                        )
                    }
                }
            }
        }

        // 6. Draw from Stock
        if !stock.isEmpty || !waste.isEmpty {
            return Hint(
                from: .stock,
                to: .waste,
                message: stock.isEmpty ? "Recycle waste pile into stock" : "Draw new cards from stock",
                cards: []
            )
        }

        return nil
    }

    public static func canPlaceOnFoundation(card: Card, foundation: [Card]) -> Bool {
        if foundation.isEmpty {
            return card.rank == .ace
        }
        guard let topCard = foundation.last else { return false }
        return card.suit == topCard.suit && card.rank.rawValue == (topCard.rank.rawValue + 1)
    }

    public static func canPlaceOnTableau(movingCard: Card, destination: [Card]) -> Bool {
        if destination.isEmpty {
            return movingCard.rank == .king
        }
        guard let topCard = destination.last, topCard.isFaceUp else { return false }
        return movingCard.suit.color != topCard.suit.color && movingCard.rank.rawValue == (topCard.rank.rawValue - 1)
    }
}
