import SwiftUI

public struct CardView: View {
    public let card: Card
    public var deckStyle: CardDeckStyle = GameSettings.shared.cardDeckStyle
    public var isHighlighted: Bool = false
    public var isGhost: Bool = false // Dimmed when dragged from original spot
    public var cornerRadius: CGFloat = 8

    public static let cardWidth: CGFloat = 84
    public static let cardHeight: CGFloat = 118

    public init(
        card: Card,
        deckStyle: CardDeckStyle = GameSettings.shared.cardDeckStyle,
        isHighlighted: Bool = false,
        isGhost: Bool = false,
        cornerRadius: CGFloat = 8
    ) {
        self.card = card
        self.deckStyle = deckStyle
        self.isHighlighted = isHighlighted
        self.isGhost = isGhost
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        ZStack {
            if card.isFaceUp {
                faceUpView
            } else {
                CardBackView(cornerRadius: cornerRadius)
            }
        }
        .frame(width: Self.cardWidth, height: Self.cardHeight)
        .opacity(isGhost ? 0.35 : 1.0)
        .overlay {
            if isHighlighted {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange, Color.yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .shadow(color: Color.yellow.opacity(0.8), radius: 6)
            }
        }
        .shadow(color: Color.black.opacity(isGhost ? 0.05 : 0.22), radius: isHighlighted ? 6 : 3, x: 0, y: 2)
    }

    // MARK: - Face Up Presentation
    @ViewBuilder
    private var faceUpView: some View {
        ZStack {
            // Card Base Background
            switch deckStyle {
            case .glass:
                glassCardBackground
            case .classicLinen:
                linenCardBackground
            }

            // Card Face Content
            VStack(spacing: 0) {
                // Top-Left Index
                HStack {
                    cornerIndex
                    Spacer()
                }
                .padding(.top, 5)
                .padding(.leading, 6)

                Spacer(minLength: 0)

                // Center Artwork / Pips
                centerArt
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer(minLength: 0)

                // Bottom-Right Inverted Index
                HStack {
                    Spacer()
                    cornerIndex
                        .rotationEffect(.degrees(180))
                }
                .padding(.bottom, 5)
                .padding(.trailing, 6)
            }

            // Glass specular edge highlight
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.65), Color.white.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    // MARK: - Glassmorphic Frosted Background
    private var glassCardBackground: some View {
        ZStack {
            // Ultra-thin blurred material
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)

            // Frosted translucent glaze
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.72),
                            Color.white.opacity(0.48)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Subtle suit tint in background
            RadialGradient(
                colors: [
                    card.suit.color.swiftUIColor.opacity(0.06),
                    Color.clear
                ],
                center: .center,
                startRadius: 5,
                endRadius: 50
            )
        }
    }

    // MARK: - Modern Classic Linen Background
    private var linenCardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.99),
                            Color(white: 0.94)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
        }
    }

    // MARK: - Corner Index
    private var cornerIndex: some View {
        VStack(spacing: -1) {
            Text(card.rank.symbol)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(card.suit.color.swiftUIColor)

            Image(systemName: card.suit.sfSymbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(card.suit.color.swiftUIColor)
        }
    }

    // MARK: - Center Content
    @ViewBuilder
    private var centerArt: some View {
        switch card.rank {
        case .ace:
            Image(systemName: card.suit.sfSymbol)
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(card.suit.color.swiftUIColor)
                .shadow(color: card.suit.color.swiftUIColor.opacity(0.2), radius: 3)

        case .jack:
            courtBadge(letter: "J", icon: "shield.lefthalf.filled")

        case .queen:
            courtBadge(letter: "Q", icon: "crown")

        case .king:
            courtBadge(letter: "K", icon: "crown.fill")

        default:
            pipLayout(for: card.rank.rawValue)
        }
    }

    private func courtBadge(letter: String, icon: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(card.suit.color.swiftUIColor.opacity(0.85))

            HStack(spacing: 4) {
                Text(letter)
                    .font(.system(size: 18, weight: .heavy, design: .serif))
                    .foregroundStyle(card.suit.color.swiftUIColor)

                Image(systemName: card.suit.sfSymbol)
                    .font(.system(size: 14))
                    .foregroundStyle(card.suit.color.swiftUIColor)
            }
        }
    }

    @ViewBuilder
    private func pipLayout(for count: Int) -> some View {
        VStack(spacing: 3) {
            Image(systemName: card.suit.sfSymbol)
                .font(.system(size: count > 6 ? 16 : 22, weight: .medium))
                .foregroundStyle(card.suit.color.swiftUIColor)

            if count > 4 {
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(card.suit.color.swiftUIColor.opacity(0.75))
            }
        }
    }
}
