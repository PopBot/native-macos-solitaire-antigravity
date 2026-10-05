import SwiftUI

public struct ToolbarView: View {
    @Bindable public var viewModel: SolitaireViewModel
    @State private var settings = GameSettings.shared

    public var body: some View {
        HStack(spacing: 16) {
            // Left Action Buttons
            HStack(spacing: 8) {
                Button {
                    withAnimation {
                        viewModel.startNewGame()
                    }
                } label: {
                    Label("New Game", systemImage: "plus.circle")
                }
                .keyboardShortcut("n", modifiers: .command)

                Button {
                    withAnimation {
                        viewModel.restartGame()
                    }
                } label: {
                    Label("Restart", systemImage: "arrow.counterclockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
            }
            .buttonStyle(GlassToolbarButtonStyle())

            Spacer()

            // Center HUD Stats Badges
            HStack(spacing: 14) {
                // Score
                hudBadge(
                    title: "SCORE",
                    value: formattedScore
                )

                // Moves
                hudBadge(
                    title: "MOVES",
                    value: "\(viewModel.movesCount)"
                )

                // Timer
                if settings.timerEnabled {
                    hudBadge(
                        title: "TIME",
                        value: formatTime(viewModel.elapsedSeconds)
                    )
                }
            }

            Spacer()

            // Right Action Buttons
            HStack(spacing: 8) {
                // Auto Complete Button
                if viewModel.isAutoCompletable {
                    Button {
                        viewModel.startAutoComplete()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "wand.and.stars")
                            Text("Auto Finish")
                        }
                        .foregroundStyle(.yellow)
                    }
                    .buttonStyle(GlassToolbarButtonStyle(accentGlow: true))
                    .transition(.scale.combined(with: .opacity))
                }

                // Hint Button
                Button {
                    viewModel.requestHint()
                } label: {
                    Label("Hint", systemImage: "lightbulb")
                }
                .keyboardShortcut("h", modifiers: .command)
                .buttonStyle(GlassToolbarButtonStyle())

                // Undo Button
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        viewModel.undo()
                    }
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!viewModel.canUndo)
                .keyboardShortcut("z", modifiers: .command)
                .buttonStyle(GlassToolbarButtonStyle())

                // Redo Button
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        viewModel.redo()
                    }
                } label: {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .disabled(!viewModel.canRedo)
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .buttonStyle(GlassToolbarButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Rectangle()
                    .fill(Color.white.opacity(0.04))
                VStack {
                    Spacer()
                    Divider()
                        .background(Color.white.opacity(0.12))
                }
            }
        )
    }

    private var formattedScore: String {
        if settings.scoringMode == .vegas {
            return viewModel.score < 0 ? "-$\(abs(viewModel.score))" : "$\(viewModel.score)"
        }
        return "\(viewModel.score)"
    }

    private func hudBadge(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.55))

            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

public struct GlassToolbarButtonStyle: ButtonStyle {
    public var accentGlow: Bool = false

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(accentGlow ? Color.yellow : Color.white.opacity(configuration.isPressed ? 0.7 : 0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.2 : (accentGlow ? 0.16 : 0.08)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(
                                accentGlow ? Color.yellow.opacity(0.6) : Color.white.opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}
