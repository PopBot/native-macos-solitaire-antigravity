import XCTest
@testable import SolitaireGlass

final class SolitaireGameTests: XCTestCase {

    func testStandardDeckCreation() {
        let deck = Card.standardDeck()
        XCTAssertEqual(deck.count, 52)

        let suits = Set(deck.map { $0.suit })
        XCTAssertEqual(suits.count, 4)

        for suit in Suit.allCases {
            let ranksForSuit = deck.filter { $0.suit == suit }.map { $0.rank }
            XCTAssertEqual(ranksForSuit.count, 13)
            XCTAssertEqual(Set(ranksForSuit).count, 13)
        }
    }

    func testInitialGameSetup() {
        let vm = SolitaireViewModel()
        vm.startNewGame()

        // 7 tableau columns
        XCTAssertEqual(vm.tableau.count, 7)
        for col in 0..<7 {
            XCTAssertEqual(vm.tableau[col].count, col + 1)
            // Top card is face up
            XCTAssertTrue(vm.tableau[col].last!.isFaceUp)
            // Cards underneath are face down
            for i in 0..<col {
                XCTAssertFalse(vm.tableau[col][i].isFaceUp)
            }
        }

        // Remaining 24 cards in stock
        XCTAssertEqual(vm.stock.count, 24)
        XCTAssertEqual(vm.waste.count, 0)
        XCTAssertEqual(vm.foundations.count, 4)
        for f in vm.foundations {
            XCTAssertEqual(f.count, 0)
        }
    }

    func testTableauPlacementRules() {
        // Red 9 onto Black 10: Valid
        let black10 = Card(suit: .spades, rank: .ten, isFaceUp: true)
        let red9 = Card(suit: .hearts, rank: .nine, isFaceUp: true)
        XCTAssertTrue(HintEngine.canPlaceOnTableau(movingCard: red9, destination: [black10]))

        // Red 9 onto Red 10: Invalid (same color)
        let red10 = Card(suit: .diamonds, rank: .ten, isFaceUp: true)
        XCTAssertFalse(HintEngine.canPlaceOnTableau(movingCard: red9, destination: [red10]))

        // Red 8 onto Black 10: Invalid (rank skip)
        let red8 = Card(suit: .hearts, rank: .eight, isFaceUp: true)
        XCTAssertFalse(HintEngine.canPlaceOnTableau(movingCard: red8, destination: [black10]))

        // King onto empty tableau: Valid
        let king = Card(suit: .clubs, rank: .king, isFaceUp: true)
        XCTAssertTrue(HintEngine.canPlaceOnTableau(movingCard: king, destination: []))

        // Non-King onto empty tableau: Invalid
        let queen = Card(suit: .spades, rank: .queen, isFaceUp: true)
        XCTAssertFalse(HintEngine.canPlaceOnTableau(movingCard: queen, destination: []))
    }

    func testFoundationPlacementRules() {
        // Ace of Spades onto empty foundation: Valid
        let aceSpades = Card(suit: .spades, rank: .ace, isFaceUp: true)
        XCTAssertTrue(HintEngine.canPlaceOnFoundation(card: aceSpades, foundation: []))

        // 2 of Spades onto empty foundation: Invalid
        let twoSpades = Card(suit: .spades, rank: .two, isFaceUp: true)
        XCTAssertFalse(HintEngine.canPlaceOnFoundation(card: twoSpades, foundation: []))

        // 2 of Spades onto Ace of Spades: Valid
        XCTAssertTrue(HintEngine.canPlaceOnFoundation(card: twoSpades, foundation: [aceSpades]))

        // 2 of Hearts onto Ace of Spades: Invalid (mismatched suit)
        let twoHearts = Card(suit: .hearts, rank: .two, isFaceUp: true)
        XCTAssertFalse(HintEngine.canPlaceOnFoundation(card: twoHearts, foundation: [aceSpades]))
    }

    func testDrawFromStockAndRecycle() {
        let vm = SolitaireViewModel()
        GameSettings.shared.drawMode = .drawOne
        vm.startNewGame()

        let initialStockCount = vm.stock.count
        XCTAssertEqual(initialStockCount, 24)

        // Draw 1 card
        vm.drawFromStock()
        XCTAssertEqual(vm.stock.count, initialStockCount - 1)
        XCTAssertEqual(vm.waste.count, 1)
        XCTAssertTrue(vm.waste.last!.isFaceUp)

        // Draw all remaining cards
        while !vm.stock.isEmpty {
            vm.drawFromStock()
        }
        XCTAssertEqual(vm.waste.count, initialStockCount)

        // Recycle waste back to stock
        vm.drawFromStock()
        XCTAssertEqual(vm.stock.count, initialStockCount)
        XCTAssertEqual(vm.waste.count, 0)
        XCTAssertFalse(vm.stock.first!.isFaceUp)
    }

    func testUndoRedoMove() {
        let vm = SolitaireViewModel()
        vm.startNewGame()

        let ace = Card(suit: .hearts, rank: .ace, isFaceUp: true)
        vm.tableau[0] = [ace]
        let initialScore = vm.score

        // Move Ace to foundation
        vm.executeMove(cards: [ace], from: .tableau(column: 0, index: 0), to: .foundation(index: 0))

        XCTAssertEqual(vm.foundations[0].count, 1)
        XCTAssertEqual(vm.tableau[0].count, 0)
        XCTAssertTrue(vm.score > initialScore)
        XCTAssertTrue(vm.canUndo)

        // Undo move
        vm.undo()
        XCTAssertEqual(vm.foundations[0].count, 0)
        XCTAssertEqual(vm.tableau[0].count, 1)
        XCTAssertEqual(vm.score, initialScore)
        XCTAssertTrue(vm.canRedo)

        // Redo move
        vm.redo()
        XCTAssertEqual(vm.foundations[0].count, 1)
        XCTAssertEqual(vm.tableau[0].count, 0)
        XCTAssertTrue(vm.score > initialScore)
    }

    func testGameStatsRecording() {
        let stats = GameStats.shared
        stats.reset()

        XCTAssertEqual(stats.gamesPlayed, 0)
        XCTAssertEqual(stats.gamesWon, 0)
        XCTAssertEqual(stats.currentStreak, 0)

        stats.recordGameFinished(won: true, score: 500, timeElapsed: 120, scoringMode: .standard)
        XCTAssertEqual(stats.gamesPlayed, 1)
        XCTAssertEqual(stats.gamesWon, 1)
        XCTAssertEqual(stats.currentStreak, 1)
        XCTAssertEqual(stats.bestStreak, 1)
        XCTAssertEqual(stats.bestScoreStandard, 500)
        XCTAssertEqual(stats.bestTimeSeconds, 120)

        stats.recordGameFinished(won: false, score: 50, timeElapsed: 40, scoringMode: .standard)
        XCTAssertEqual(stats.gamesPlayed, 2)
        XCTAssertEqual(stats.gamesWon, 1)
        XCTAssertEqual(stats.currentStreak, 0)
        XCTAssertEqual(stats.bestStreak, 1)
    }

    func testPauseAndResumeGame() {
        let vm = SolitaireViewModel()
        vm.startNewGame()

        XCTAssertFalse(vm.isPaused)
        XCTAssertTrue(vm.canDrag(location: .tableau(column: 0, index: 0)))

        // Pause
        vm.pauseGame()
        XCTAssertTrue(vm.isPaused)
        // Board interactions should be blocked while paused
        XCTAssertFalse(vm.canDrag(location: .tableau(column: 0, index: 0)))

        let stockBefore = vm.stock.count
        vm.drawFromStock()
        XCTAssertEqual(vm.stock.count, stockBefore, "Should not draw cards while paused")

        // Resume
        vm.resumeGame()
        XCTAssertFalse(vm.isPaused)
        XCTAssertTrue(vm.canDrag(location: .tableau(column: 0, index: 0)))
    }

    func testAllowUndoRedoSetting() {
        let vm = SolitaireViewModel()
        vm.startNewGame()

        let ace = Card(suit: .hearts, rank: .ace, isFaceUp: true)
        vm.tableau[0] = [ace]
        vm.executeMove(cards: [ace], from: .tableau(column: 0, index: 0), to: .foundation(index: 0))

        GameSettings.shared.allowUndoRedo = true
        XCTAssertTrue(vm.canUndo)

        // Disable Undo/Redo in settings
        GameSettings.shared.allowUndoRedo = false
        XCTAssertFalse(vm.canUndo)
        XCTAssertFalse(vm.canRedo)

        // Re-enable
        GameSettings.shared.allowUndoRedo = true
        XCTAssertTrue(vm.canUndo)
    }
}
