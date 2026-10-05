import SwiftUI
import Combine

@Observable
public final class SolitaireViewModel: @unchecked Sendable {
    // MARK: - Game State
    public var stock: [Card] = []
    public var waste: [Card] = []
    public var foundations: [[Card]] = [[], [], [], []]
    public var tableau: [[Card]] = [[], [], [], [], [], [], []]

    public var score: Int = 0
    public var movesCount: Int = 0
    public var elapsedSeconds: Int = 0
    public var isGameWon: Bool = false
    public var isGameActive: Bool = false
    public var isPaused: Bool = false
    public var wasteRecycleCount: Int = 0

    // MARK: - Undo / Redo
    public var undoStack: [GameMove] = []
    public var redoStack: [GameMove] = []

    // MARK: - Drag & Drop State
    public var draggedCards: [Card] = []
    public var dragSource: CardLocation?
    public var dragOffset: CGSize = .zero
    public var dragStartPoint: CGPoint = .zero
    public var dragCurrentLocation: CGPoint = .zero
    public var hoveredTarget: CardLocation?
    public var dropTargetFrames: [CardLocation: CGRect] = [:]

    public func registerDropTarget(location: CardLocation, frame: CGRect) {
        dropTargetFrames[location] = frame
    }

    public func dropTarget(at point: CGPoint) -> CardLocation? {
        // Find best target containing the point
        for (location, frame) in dropTargetFrames {
            if frame.contains(point) {
                return location
            }
        }
        return nil
    }

    // MARK: - Hint State
    public var activeHint: Hint?
    private var hintTimer: AnyCancellable?

    // MARK: - Timer & Win Animation
    private var gameTimer: AnyCancellable?
    public var isAutoCompleting: Bool = false

    // Initial board snapshot for restart
    private var initialStock: [Card] = []
    private var initialTableau: [[Card]] = []

    public init() {
        startNewGame()
    }

    // MARK: - Game Setup
    public func startNewGame() {
        cancelDrag()
        stopTimer()
        isAutoCompleting = false
        isGameWon = false
        isPaused = false
        movesCount = 0
        elapsedSeconds = 0
        wasteRecycleCount = 0
        undoStack.removeAll()
        redoStack.removeAll()
        activeHint = nil

        let settings = GameSettings.shared
        score = (settings.scoringMode == .vegas) ? -52 : 0

        var deck = Card.standardDeck().shuffled()

        // Deal 7 tableau columns
        var newTableau: [[Card]] = []
        for col in 0..<7 {
            var colCards: [Card] = []
            for i in 0...col {
                var card = deck.removeFirst()
                card.isFaceUp = (i == col)
                colCards.append(card)
            }
            newTableau.append(colCards)
        }
        tableau = newTableau

        stock = deck
        waste = []
        foundations = [[], [], [], []]

        // Preserve initial snapshot for restart
        initialStock = stock
        initialTableau = tableau

        isGameActive = true
        startTimer()
        AudioService.shared.playFlip()
    }

    public func restartGame() {
        cancelDrag()
        stopTimer()
        isAutoCompleting = false
        isGameWon = false
        isPaused = false
        movesCount = 0
        elapsedSeconds = 0
        wasteRecycleCount = 0
        undoStack.removeAll()
        redoStack.removeAll()
        activeHint = nil

        let settings = GameSettings.shared
        score = (settings.scoringMode == .vegas) ? -52 : 0

        stock = initialStock
        tableau = initialTableau
        waste = []
        foundations = [[], [], [], []]

        isGameActive = true
        startTimer()
        AudioService.shared.playFlip()
    }

    // MARK: - Pause & Resume
    public func togglePause() {
        guard isGameActive, !isGameWon, !isAutoCompleting else { return }
        if isPaused {
            resumeGame()
        } else {
            pauseGame()
        }
    }

    public func pauseGame() {
        guard isGameActive, !isGameWon, !isAutoCompleting, !isPaused else { return }
        cancelDrag()
        clearHint()
        isPaused = true
        stopTimer()
    }

    public func resumeGame() {
        guard isGameActive, !isGameWon, !isAutoCompleting, isPaused else { return }
        isPaused = false
        startTimer()
    }

    // MARK: - Timer Management
    private func startTimer() {
        stopTimer()
        gameTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isGameActive, !self.isGameWon, !self.isPaused else { return }
                self.elapsedSeconds += 1
            }
    }

    private func stopTimer() {
        gameTimer?.cancel()
        gameTimer = nil
    }

    // MARK: - Stock & Waste Actions
    public func drawFromStock() {
        guard !isGameWon, !isAutoCompleting, !isPaused else { return }
        clearHint()

        if stock.isEmpty {
            guard !waste.isEmpty else { return }
            // Recycle waste into stock
            let recycled = waste.reversed().map { card -> Card in
                var c = card
                c.isFaceUp = false
                return c
            }
            stock = recycled
            waste.removeAll()
            wasteRecycleCount += 1

            var scoreDelta = 0
            if GameSettings.shared.scoringMode == .standard {
                if GameSettings.shared.drawMode == .drawOne {
                    scoreDelta = -100
                } else if wasteRecycleCount > 3 {
                    scoreDelta = -20
                }
            }
            score = max(0, score + scoreDelta)
            movesCount += 1

            let move = GameMove(type: .recycleWaste(cards: recycled), scoreDelta: scoreDelta)
            undoStack.append(move)
            redoStack.removeAll()

            AudioService.shared.playFlip()
            return
        }

        let count = min(GameSettings.shared.drawMode.rawValue, stock.count)
        var drawn: [Card] = []
        for _ in 0..<count {
            var card = stock.removeLast()
            card.isFaceUp = true
            drawn.append(card)
        }
        waste.append(contentsOf: drawn)
        movesCount += 1

        let move = GameMove(type: .drawFromStock(cards: drawn), scoreDelta: 0)
        undoStack.append(move)
        redoStack.removeAll()

        AudioService.shared.playFlip()
    }

    // MARK: - Drag and Drop Handling
    public func canDrag(location: CardLocation) -> Bool {
        guard !isGameWon, !isAutoCompleting, !isPaused else { return false }
        switch location {
        case .waste:
            return !waste.isEmpty
        case .foundation(let index):
            return !foundations[index].isEmpty
        case .tableau(let column, let index):
            guard column < tableau.count, index < tableau[column].count else { return false }
            return tableau[column][index].isFaceUp
        case .stock:
            return false
        }
    }

    public func beginDrag(location: CardLocation, startPoint: CGPoint) {
        guard canDrag(location: location) else { return }
        clearHint()

        dragSource = location
        dragCurrentLocation = startPoint
        dragOffset = .zero

        switch location {
        case .waste:
            if let card = waste.last {
                draggedCards = [card]
            }
        case .foundation(let index):
            if let card = foundations[index].last {
                draggedCards = [card]
            }
        case .tableau(let column, let index):
            let cards = Array(tableau[column][index...])
            draggedCards = cards
        case .stock:
            break
        }

        if !draggedCards.isEmpty {
            AudioService.shared.playPickup()
        }
    }

    public func updateDrag(translation: CGSize, currentPoint: CGPoint, targetCandidate: CardLocation?) {
        dragOffset = translation
        dragCurrentLocation = currentPoint
        if let target = targetCandidate, canDrop(cards: draggedCards, on: target) {
            hoveredTarget = target
        } else {
            hoveredTarget = nil
        }
    }

    public func endDrag(targetLocation: CardLocation?) {
        guard let source = dragSource, !draggedCards.isEmpty else {
            cancelDrag()
            return
        }

        if let target = targetLocation, canDrop(cards: draggedCards, on: target) {
            executeMove(cards: draggedCards, from: source, to: target)
        } else {
            AudioService.shared.playInvalidMove()
        }

        cancelDrag()
    }

    public func cancelDrag() {
        draggedCards.removeAll()
        dragSource = nil
        dragOffset = .zero
        dragCurrentLocation = .zero
        hoveredTarget = nil
    }

    // MARK: - Validation
    public func canDrop(cards: [Card], on target: CardLocation) -> Bool {
        guard let leadCard = cards.first else { return false }

        // Cannot drop on the same location
        if let source = dragSource, source == target { return false }

        switch target {
        case .foundation(let fIndex):
            guard cards.count == 1, fIndex < foundations.count else { return false }
            return HintEngine.canPlaceOnFoundation(card: leadCard, foundation: foundations[fIndex])

        case .tableau(let colIndex, _):
            guard colIndex < tableau.count else { return false }
            return HintEngine.canPlaceOnTableau(movingCard: leadCard, destination: tableau[colIndex])

        case .stock, .waste:
            return false
        }
    }

    // MARK: - Move Execution
    public func executeMove(cards: [Card], from source: CardLocation, to target: CardLocation) {
        var scoreDelta = 0
        var revealedCardInSource = false
        let isStandard = GameSettings.shared.scoringMode == .standard
        let isVegas = GameSettings.shared.scoringMode == .vegas

        // Remove cards from source
        switch source {
        case .waste:
            waste.removeLast(cards.count)
        case .foundation(let index):
            foundations[index].removeLast(cards.count)
        case .tableau(let col, let startIdx):
            tableau[col].removeSubrange(startIdx..<tableau[col].count)
            // Flip new top card if face down
            if let lastIdx = tableau[col].indices.last, !tableau[col][lastIdx].isFaceUp {
                tableau[col][lastIdx].isFaceUp = true
                revealedCardInSource = true
                if isStandard { scoreDelta += 5 }
            }
        case .stock:
            break
        }

        // Add cards to target & calculate score
        switch target {
        case .foundation(let index):
            foundations[index].append(contentsOf: cards)
            AudioService.shared.playFoundationSnap()
            if isStandard { scoreDelta += 10 }
            if isVegas { scoreDelta += 5 }

        case .tableau(let col, _):
            tableau[col].append(contentsOf: cards)
            AudioService.shared.playPlace()
            if source == .waste && isStandard {
                scoreDelta += 5
            } else if source.isFoundation {
                if isStandard { scoreDelta -= 15 }
                if isVegas { scoreDelta -= 5 }
            }

        case .stock, .waste:
            break
        }

        score = isStandard ? max(0, score + scoreDelta) : (score + scoreDelta)
        movesCount += 1

        let move = GameMove(
            type: .move(cards: cards, from: source, to: target, flippedCardUnderneath: revealedCardInSource),
            scoreDelta: scoreDelta
        )
        undoStack.append(move)
        redoStack.removeAll()

        checkWinCondition()
    }

    // MARK: - Undo & Redo
    public var canUndo: Bool {
        GameSettings.shared.allowUndoRedo && !undoStack.isEmpty && !isGameWon && !isAutoCompleting && !isPaused
    }

    public var canRedo: Bool {
        GameSettings.shared.allowUndoRedo && !redoStack.isEmpty && !isGameWon && !isAutoCompleting && !isPaused
    }

    public func undo() {
        guard canUndo, let move = undoStack.popLast() else { return }
        clearHint()

        switch move.type {
        case .drawFromStock(let cards):
            // Pop cards from waste back to stock face down
            waste.removeLast(cards.count)
            let reversedCards = cards.reversed().map { c -> Card in
                var card = c
                card.isFaceUp = false
                return card
            }
            stock.append(contentsOf: reversedCards)

        case .recycleWaste(let cards):
            // Stock back to waste
            stock.removeAll()
            let faceUpCards = cards.reversed().map { c -> Card in
                var card = c
                card.isFaceUp = true
                return card
            }
            waste = faceUpCards
            wasteRecycleCount = max(0, wasteRecycleCount - 1)

        case .move(let cards, let source, let target, let flippedUnderneath):
            // Reverse the placement from target back to source
            switch target {
            case .foundation(let index):
                foundations[index].removeLast(cards.count)
            case .tableau(let col, _):
                tableau[col].removeLast(cards.count)
            default:
                break
            }

            // Restore source
            switch source {
            case .waste:
                waste.append(contentsOf: cards)
            case .foundation(let index):
                foundations[index].append(contentsOf: cards)
            case .tableau(let col, _):
                if flippedUnderneath, let lastIdx = tableau[col].indices.last {
                    tableau[col][lastIdx].isFaceUp = false
                }
                tableau[col].append(contentsOf: cards)
            default:
                break
            }
        }

        score = max(0, score - move.scoreDelta)
        redoStack.append(move)
        AudioService.shared.playFlip()
    }

    public func redo() {
        guard canRedo, let move = redoStack.popLast() else { return }
        clearHint()

        switch move.type {
        case .drawFromStock(let cards):
            stock.removeLast(cards.count)
            waste.append(contentsOf: cards)

        case .recycleWaste(let cards):
            waste.removeAll()
            stock = cards.reversed().map { c -> Card in
                var card = c
                card.isFaceUp = false
                return card
            }
            wasteRecycleCount += 1

        case .move(let cards, let source, let target, let flippedUnderneath):
            // Remove from source
            switch source {
            case .waste:
                waste.removeLast(cards.count)
            case .foundation(let index):
                foundations[index].removeLast(cards.count)
            case .tableau(let col, let startIdx):
                tableau[col].removeSubrange(startIdx..<tableau[col].count)
                if flippedUnderneath, let lastIdx = tableau[col].indices.last {
                    tableau[col][lastIdx].isFaceUp = true
                }
            default:
                break
            }

            // Put into target
            switch target {
            case .foundation(let index):
                foundations[index].append(contentsOf: cards)
            case .tableau(let col, _):
                tableau[col].append(contentsOf: cards)
            default:
                break
            }
        }

        score += move.scoreDelta
        undoStack.append(move)
        AudioService.shared.playPlace()
        checkWinCondition()
    }

    // MARK: - Win Detection & Auto-Complete
    public func checkWinCondition() {
        let totalFoundationCards = foundations.reduce(0) { $0 + $1.count }
        if totalFoundationCards == 52 {
            triggerWin()
        }
    }

    private func triggerWin() {
        guard !isGameWon else { return }
        isGameWon = true
        stopTimer()

        // Time bonus in standard scoring
        if GameSettings.shared.scoringMode == .standard && elapsedSeconds > 0 {
            let bonus = max(0, 700_000 / elapsedSeconds)
            score += bonus
        }

        GameStats.shared.recordGameFinished(
            won: true,
            score: score,
            timeElapsed: elapsedSeconds,
            scoringMode: GameSettings.shared.scoringMode
        )

        AudioService.shared.playWinFanfare()
    }

    public var isAutoCompletable: Bool {
        guard !isGameWon, !isAutoCompleting else { return false }
        guard stock.isEmpty && waste.isEmpty else { return false }
        for column in tableau {
            for card in column {
                if !card.isFaceUp { return false }
            }
        }
        return true
    }

    public func startAutoComplete() {
        guard isAutoCompletable else { return }
        isAutoCompleting = true
        runAutoCompleteStep()
    }

    private func runAutoCompleteStep() {
        guard isAutoCompleting, !isGameWon else { return }

        // Find lowest rank card in tableau that can be placed on foundation
        for (colIndex, column) in tableau.enumerated() {
            guard let topCard = column.last else { continue }
            for (fIndex, foundation) in foundations.enumerated() {
                if HintEngine.canPlaceOnFoundation(card: topCard, foundation: foundation) {
                    executeMove(
                        cards: [topCard],
                        from: .tableau(column: colIndex, index: column.count - 1),
                        to: .foundation(index: fIndex)
                    )

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                        self?.runAutoCompleteStep()
                    }
                    return
                }
            }
        }

        isAutoCompleting = false
    }

    // MARK: - Hint System
    public func requestHint() {
        guard !isGameWon, !isAutoCompleting, !isPaused else { return }
        if let hint = HintEngine.findBestHint(stock: stock, waste: waste, foundations: foundations, tableau: tableau) {
            activeHint = hint
            hintTimer?.cancel()
            hintTimer = Just(())
                .delay(for: .seconds(4), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    self?.activeHint = nil
                }
        }
    }

    public func clearHint() {
        activeHint = nil
        hintTimer?.cancel()
    }
}
