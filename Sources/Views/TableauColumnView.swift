import SwiftUI

public struct TableauColumnView: View {
    @Bindable public var viewModel: SolitaireViewModel
    public let columnIndex: Int
    public var coordinateSpaceName: String = "GameBoard"

    private let faceDownOffset: CGFloat = 16
    private let faceUpOffset: CGFloat = 28

    public var body: some View {
        let column = viewModel.tableau[columnIndex]
        let isHovered = (viewModel.hoveredTarget == .tableau(column: columnIndex, index: max(0, column.count - 1)))
            || (column.isEmpty && viewModel.hoveredTarget == .tableau(column: columnIndex, index: 0))
        let isHintTarget = isColumnHintTarget

        ZStack(alignment: .top) {
            // Base slot placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isHovered
                                ? Color.green.opacity(0.85)
                                : (isHintTarget ? Color.yellow : Color.white.opacity(0.18)),
                            lineWidth: isHovered || isHintTarget ? 2.5 : 1
                        )
                )
                .frame(width: CardView.cardWidth, height: CardView.cardHeight)

            if column.isEmpty {
                // Faint King watermark for empty slot
                Text("K")
                    .font(.system(size: 28, weight: .thin, design: .serif))
                    .foregroundStyle(Color.white.opacity(0.12))
                    .frame(width: CardView.cardWidth, height: CardView.cardHeight)
            } else {
                // Stack of cards
                ForEach(Array(column.enumerated()), id: \.element.id) { index, card in
                    let yOffset = calculateYOffset(upTo: index, column: column)
                    let isGhost = isCardGhost(cardIndex: index)
                    let isHinted = isCardHintSource(cardIndex: index)

                    CardView(
                        card: card,
                        isHighlighted: isHinted,
                        isGhost: isGhost
                    )
                    .offset(y: yOffset)
                    .gesture(
                        card.isFaceUp ? dragGesture(for: card, at: index) : nil
                    )
                }
            }
        }
        .frame(width: CardView.cardWidth, height: max(CardView.cardHeight, totalColumnHeight(column: column)), alignment: .top)
        .dropTargetLocation(
            .tableau(column: columnIndex, index: max(0, column.count - 1)),
            in: coordinateSpaceName
        )
        .shadow(
            color: isHovered ? Color.green.opacity(0.4) : (isHintTarget ? Color.yellow.opacity(0.4) : Color.clear),
            radius: 8
        )
    }

    private func calculateYOffset(upTo targetIndex: Int, column: [Card]) -> CGFloat {
        var offset: CGFloat = 0
        for i in 0..<targetIndex {
            offset += column[i].isFaceUp ? faceUpOffset : faceDownOffset
        }
        return offset
    }

    private func totalColumnHeight(column: [Card]) -> CGFloat {
        guard !column.isEmpty else { return CardView.cardHeight }
        return calculateYOffset(upTo: column.count - 1, column: column) + CardView.cardHeight
    }

    private func isCardGhost(cardIndex: Int) -> Bool {
        if case .tableau(let col, let startIdx) = viewModel.dragSource, col == columnIndex {
            return cardIndex >= startIdx
        }
        return false
    }

    private func isCardHintSource(cardIndex: Int) -> Bool {
        if case .tableau(let col, let startIdx) = viewModel.activeHint?.from, col == columnIndex {
            return cardIndex >= startIdx
        }
        return false
    }

    private var isColumnHintTarget: Bool {
        if case .tableau(let col, _) = viewModel.activeHint?.to {
            return col == columnIndex
        }
        return false
    }

    private func dragGesture(for card: Card, at cardIndex: Int) -> some Gesture {
        DragGesture(coordinateSpace: .named(coordinateSpaceName))
            .onChanged { value in
                if viewModel.dragSource == nil {
                    viewModel.beginDrag(
                        location: .tableau(column: columnIndex, index: cardIndex),
                        startPoint: value.startLocation
                    )
                }
                let target = viewModel.dropTarget(at: value.location)
                viewModel.updateDrag(
                    translation: value.translation,
                    currentPoint: value.location,
                    targetCandidate: target
                )
            }
            .onEnded { value in
                let target = viewModel.dropTarget(at: value.location)
                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                    viewModel.endDrag(targetLocation: target)
                }
            }
    }
}
