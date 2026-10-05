import SwiftUI

public struct StockWasteView: View {
    @Bindable public var viewModel: SolitaireViewModel
    public var coordinateSpaceName: String = "GameBoard"

    public var body: some View {
        HStack(spacing: 20) {
            // MARK: - Stock Pile
            stockPileView

            // MARK: - Waste Pile
            wastePileView
        }
    }

    // MARK: - Stock Pile View
    private var stockPileView: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.drawFromStock()
            }
        } label: {
            ZStack {
                // Base placeholder slot
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    )
                    .frame(width: CardView.cardWidth, height: CardView.cardHeight)

                if viewModel.stock.isEmpty {
                    // Empty stock recycle icon
                    if !viewModel.waste.isEmpty {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.75))

                            Text("Recycle")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.6))
                        }
                    }
                } else {
                    // Depth effect for remaining cards
                    if viewModel.stock.count > 10 {
                        CardBackView()
                            .offset(x: -2, y: -2)
                    }
                    if viewModel.stock.count > 20 {
                        CardBackView()
                            .offset(x: -4, y: -4)
                    }

                    // Top Card Back
                    CardBackView()
                        .overlay(alignment: .bottomTrailing) {
                            Text("\(viewModel.stock.count)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.black.opacity(0.55)))
                                .padding(4)
                        }
                }
            }
            .frame(width: CardView.cardWidth, height: CardView.cardHeight)
        }
        .buttonStyle(.plain)
        .overlay {
            if viewModel.activeHint?.from == .stock {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.yellow, lineWidth: 2.5)
                    .shadow(color: Color.yellow.opacity(0.8), radius: 6)
            }
        }
    }

    // MARK: - Waste Pile View
    private var wastePileView: some View {
        ZStack {
            // Empty placeholder slot
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
                .frame(width: CardView.cardWidth, height: CardView.cardHeight)

            if !viewModel.waste.isEmpty {
                let cardsToShow = GameSettings.shared.drawMode == .drawThree
                    ? Array(viewModel.waste.suffix(3))
                    : [viewModel.waste.last!]

                HStack(spacing: -50) {
                    ForEach(Array(cardsToShow.enumerated()), id: \.element.id) { index, card in
                        let isTop = (index == cardsToShow.count - 1)
                        let isBeingDragged = (viewModel.dragSource == .waste && isTop)
                        let isHinted = (viewModel.activeHint?.from == .waste && isTop)

                        CardView(
                            card: card,
                            isHighlighted: isHinted,
                            isGhost: isBeingDragged
                        )
                        .offset(x: CGFloat(index) * 16)
                        .gesture(
                            isTop ? dragGesture(for: card) : nil
                        )
                    }
                }
            }
        }
        .frame(width: CardView.cardWidth + 32, height: CardView.cardHeight, alignment: .leading)
    }

    private func dragGesture(for card: Card) -> some Gesture {
        DragGesture(coordinateSpace: .named(coordinateSpaceName))
            .onChanged { value in
                if viewModel.dragSource == nil {
                    viewModel.beginDrag(location: .waste, startPoint: value.startLocation)
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
