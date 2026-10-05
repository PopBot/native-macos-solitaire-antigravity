import SwiftUI

public struct FoundationView: View {
    @Bindable public var viewModel: SolitaireViewModel
    public var coordinateSpaceName: String = "GameBoard"

    private let suits: [Suit] = [.spades, .hearts, .clubs, .diamonds]

    public var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<4, id: \.self) { fIndex in
                foundationSlot(for: fIndex)
            }
        }
    }

    private func foundationSlot(for index: Int) -> some View {
        let pile = viewModel.foundations[index]
        let isHovered = (viewModel.hoveredTarget == .foundation(index: index))
        let isHintTarget = (viewModel.activeHint?.to == .foundation(index: index))
        let defaultSuit = suits[index]

        return ZStack {
            // Base Frosted Slot Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isHovered
                                ? Color.green.opacity(0.85)
                                : (isHintTarget ? Color.yellow : Color.white.opacity(0.2)),
                            lineWidth: isHovered || isHintTarget ? 2.5 : 1
                        )
                )
                .frame(width: CardView.cardWidth, height: CardView.cardHeight)

            if pile.isEmpty {
                // Etched suit watermark
                Image(systemName: defaultSuit.sfSymbol)
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.25))
            } else if let topCard = pile.last {
                let isBeingDragged = (viewModel.dragSource == .foundation(index: index))

                CardView(
                    card: topCard,
                    isGhost: isBeingDragged
                )
                .gesture(
                    dragGesture(for: topCard, foundationIndex: index)
                )
            }
        }
        .frame(width: CardView.cardWidth, height: CardView.cardHeight)
        .dropTargetLocation(.foundation(index: index), in: coordinateSpaceName)
        .shadow(
            color: isHovered ? Color.green.opacity(0.5) : (isHintTarget ? Color.yellow.opacity(0.5) : Color.clear),
            radius: 8
        )
    }

    private func dragGesture(for card: Card, foundationIndex: Int) -> some Gesture {
        DragGesture(coordinateSpace: .named(coordinateSpaceName))
            .onChanged { value in
                if viewModel.dragSource == nil {
                    viewModel.beginDrag(location: .foundation(index: foundationIndex), startPoint: value.startLocation)
                }
                let target = viewModel.dropTarget(at: value.location)
                viewModel.updateDrag(translation: value.translation, currentPoint: value.location, targetCandidate: target)
            }
            .onEnded { value in
                let target = viewModel.dropTarget(at: value.location)
                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                    viewModel.endDrag(targetLocation: target)
                }
            }
    }
}
