import SwiftUI

public struct BoardView: View {
    @Bindable public var viewModel: SolitaireViewModel
    private let coordinateSpaceName = "GameBoard"

    public init(viewModel: SolitaireViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            // Ambient Glass & Felt Background
            GlassBackgroundView()

            VStack(spacing: 0) {
                // Top Control & Stats Toolbar
                ToolbarView(viewModel: viewModel)

                // Main Game Board
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    VStack(spacing: 36) {
                        // Top Row: Stock, Waste, and Foundations
                        HStack(alignment: .top) {
                            StockWasteView(viewModel: viewModel, coordinateSpaceName: coordinateSpaceName)

                            Spacer(minLength: 40)

                            FoundationView(viewModel: viewModel, coordinateSpaceName: coordinateSpaceName)
                        }
                        .padding(.horizontal, 36)
                        .padding(.top, 24)

                        // Bottom Row: 7 Tableau Columns
                        HStack(alignment: .top, spacing: 18) {
                            ForEach(0..<7, id: \.self) { colIndex in
                                TableauColumnView(
                                    viewModel: viewModel,
                                    columnIndex: colIndex,
                                    coordinateSpaceName: coordinateSpaceName
                                )
                            }
                        }
                        .padding(.horizontal, 36)
                        .padding(.bottom, 40)
                    }
                    .frame(minWidth: 860, minHeight: 640)
                }
            }

            // Hint Text Overlay
            if let hint = viewModel.activeHint {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text(hint.message)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(Capsule().strokeBorder(Color.yellow.opacity(0.6), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.3), radius: 10)
                    )
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // Floating Dragged Card(s) Overlay
            if !viewModel.draggedCards.isEmpty {
                floatingDraggedCards
            }

            // Winning Cascade Animation Overlay
            if viewModel.isGameWon {
                WinCascadeView(viewModel: viewModel)
                    .transition(.opacity)
            }

            // Pause Overlay
            if viewModel.isPaused {
                pauseOverlay
                    .transition(.opacity)
            }
        }
        .coordinateSpace(name: coordinateSpaceName)
        .onPreferenceChange(DropTargetPreferenceKey.self) { list in
            for item in list {
                viewModel.registerDropTarget(location: item.location, frame: item.frame)
            }
        }
    }

    // MARK: - Pause Overlay
    private var pauseOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.4))
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Game Paused")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Take a legit break. Your timer and cards are frozen.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))

                HStack(spacing: 16) {
                    VStack {
                        Text("TIME")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.55))
                        Text(formatTime(viewModel.elapsedSeconds))
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                    )

                    VStack {
                        Text("SCORE")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.55))
                        Text("\(viewModel.score)")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                    )
                }

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                        viewModel.resumeGame()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Resume Game")
                    }
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.yellow)
                            .shadow(color: Color.yellow.opacity(0.4), radius: 8)
                    )
                }
                .buttonStyle(.plain)
                .keyboardShortcut("p", modifiers: .command)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 24)
            )
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    // MARK: - Floating Dragged Cards
    private var floatingDraggedCards: some View {
        GeometryReader { _ in
            let pos = viewModel.dragCurrentLocation
            let cards = viewModel.draggedCards

            VStack(spacing: 0) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { idx, card in
                    CardView(card: card)
                        .offset(y: CGFloat(idx) * 28)
                }
            }
            .scaleEffect(1.04)
            .shadow(color: Color.black.opacity(0.4), radius: 14, x: 0, y: 8)
            .position(
                x: pos.x,
                y: pos.y + CGFloat(cards.count - 1) * 14
            )
            .allowsHitTesting(false)
        }
    }
}
