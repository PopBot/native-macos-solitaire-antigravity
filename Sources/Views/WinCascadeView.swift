import SwiftUI

private struct BouncingCard: Identifiable {
    let id: UUID = UUID()
    let card: Card
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var hasStarted: Bool = false
    var delay: Double
}

private struct StampedCard: Identifiable {
    let id: UUID = UUID()
    let card: Card
    let x: Double
    let y: Double
}

public struct WinCascadeView: View {
    @Bindable public var viewModel: SolitaireViewModel

    @State private var bouncingCards: [BouncingCard] = []
    @State private var stampedCards: [StampedCard] = []
    @State private var isInitialized: Bool = false

    private let gravity: Double = 0.65
    private let bounceDamping: Double = 0.82

    public init(viewModel: SolitaireViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let cardW = CardView.cardWidth
                    let cardH = CardView.cardHeight

                    // Render stamped trail cards
                    for stamp in stampedCards {
                        let rect = CGRect(x: stamp.x, y: stamp.y, width: cardW, height: cardH)
                        context.draw(
                            Text("\(stamp.card.rank.symbol)\(stamp.card.suit.symbol)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(stamp.card.isRed ? .red : .black),
                            in: rect
                        )
                        let path = RoundedRectangle(cornerRadius: 8).path(in: rect)
                        context.fill(path, with: .color(Color.white.opacity(0.92)))
                        context.stroke(path, with: .color(Color.black.opacity(0.15)), lineWidth: 1)
                    }

                    // Render active bouncing cards
                    for bCard in bouncingCards where bCard.hasStarted {
                        let rect = CGRect(x: bCard.x, y: bCard.y, width: cardW, height: cardH)
                        let path = RoundedRectangle(cornerRadius: 8).path(in: rect)
                        context.fill(path, with: .color(Color.white))
                        context.stroke(path, with: .color(Color.black.opacity(0.3)), lineWidth: 1.5)

                        context.draw(
                            Text("\(bCard.card.rank.symbol)\(bCard.card.suit.symbol)")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundColor(bCard.card.isRed ? .red : .black),
                            in: rect.insetBy(dx: 6, dy: 6)
                        )
                    }
                }
                .onChange(of: timeline.date) { _, _ in
                    updatePhysics(width: width, height: height)
                }
            }
            .onAppear {
                if !isInitialized {
                    setupCascade(width: width)
                    isInitialized = true
                }
            }

            // Win celebration overlay banner
            VStack(spacing: 16) {
                Spacer()

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        Text("Victory!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    HStack(spacing: 24) {
                        VStack {
                            Text("Score")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.7))
                            Text("\(viewModel.score)")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }

                        VStack {
                            Text("Moves")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.7))
                            Text("\(viewModel.movesCount)")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }

                        VStack {
                            Text("Time")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.7))
                            Text(formatTime(viewModel.elapsedSeconds))
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.top, 4)

                    Button {
                        viewModel.startNewGame()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Play Again")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 12)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 20)
                )

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
    }

    private func setupCascade(width: CGFloat) {
        // Collect all 52 cards ordered from Kings down to Aces across 4 foundations
        var cardsToCascade: [Card] = []
        for foundation in viewModel.foundations {
            cardsToCascade.append(contentsOf: foundation.reversed())
        }
        if cardsToCascade.isEmpty {
            cardsToCascade = Card.standardDeck()
        }

        var list: [BouncingCard] = []
        for (idx, card) in cardsToCascade.enumerated() {
            let startX = width * 0.45 + Double((idx % 4) * 100 - 150)
            let vx = Double.random(in: -4.5...4.5)
            let vy = Double.random(in: -7.0 ... -2.0)
            let delay = Double(idx) * 0.35

            list.append(
                BouncingCard(
                    card: card,
                    x: startX,
                    y: 70,
                    vx: vx == 0 ? 3.0 : vx,
                    vy: vy,
                    delay: delay
                )
            )
        }

        bouncingCards = list
    }

    private func updatePhysics(width: CGFloat, height: CGFloat) {
        let bottomLimit = height - CardView.cardHeight
        guard bottomLimit > 0 else { return }

        for i in 0..<bouncingCards.count {
            if bouncingCards[i].delay > 0 {
                bouncingCards[i].delay -= 1.0 / 60.0
                if bouncingCards[i].delay <= 0 {
                    bouncingCards[i].hasStarted = true
                }
                continue
            }

            guard bouncingCards[i].hasStarted else { continue }

            // Stamp every 4th frame for retro trail
            if Int.random(in: 0...2) == 0 && stampedCards.count < 350 {
                stampedCards.append(
                    StampedCard(
                        card: bouncingCards[i].card,
                        x: bouncingCards[i].x,
                        y: bouncingCards[i].y
                    )
                )
            }

            // Apply gravity
            bouncingCards[i].vy += gravity
            bouncingCards[i].x += bouncingCards[i].vx
            bouncingCards[i].y += bouncingCards[i].vy

            // Bounce off bottom
            if bouncingCards[i].y >= bottomLimit {
                bouncingCards[i].y = bottomLimit
                bouncingCards[i].vy = -abs(bouncingCards[i].vy) * bounceDamping
                if abs(bouncingCards[i].vy) < 1.0 {
                    bouncingCards[i].vy = -Double.random(in: 8.0...14.0)
                }
            }

            // Bounce off side walls
            if bouncingCards[i].x <= 0 {
                bouncingCards[i].x = 0
                bouncingCards[i].vx = abs(bouncingCards[i].vx)
            } else if bouncingCards[i].x >= width - CardView.cardWidth {
                bouncingCards[i].x = width - CardView.cardWidth
                bouncingCards[i].vx = -abs(bouncingCards[i].vx)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
