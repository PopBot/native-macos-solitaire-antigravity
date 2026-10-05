import SwiftUI

@main
struct SolitaireApp: App {
    @State private var viewModel = SolitaireViewModel()
    @State private var settings = GameSettings.shared

    var body: some Scene {
        Window("Solitaire Glass", id: "main-solitaire-window") {
            BoardView(viewModel: viewModel)
                .frame(minWidth: 920, minHeight: 680)
                .preferredColorScheme(settings.appearance.colorScheme)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Game") {
                    viewModel.startNewGame()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Restart Game") {
                    viewModel.restartGame()
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            CommandGroup(replacing: .undoRedo) {
                if settings.allowUndoRedo {
                    Button("Undo") {
                        viewModel.undo()
                    }
                    .keyboardShortcut("z", modifiers: .command)
                    .disabled(!viewModel.canUndo)

                    Button("Redo") {
                        viewModel.redo()
                    }
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                    .disabled(!viewModel.canRedo)
                }
            }

            CommandMenu("Game") {
                Button(viewModel.isPaused ? "Resume Game" : "Pause Game") {
                    viewModel.togglePause()
                }
                .keyboardShortcut("p", modifiers: .command)

                Divider()

                Button("Draw Card") {
                    viewModel.drawFromStock()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("Show Hint") {
                    viewModel.requestHint()
                }
                .keyboardShortcut("h", modifiers: .command)

                if viewModel.isAutoCompletable {
                    Button("Auto Finish Game") {
                        viewModel.startAutoComplete()
                    }
                    .keyboardShortcut("a", modifiers: [.command, .shift])
                }
            }
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .preferredColorScheme(settings.appearance.colorScheme)
        }
        #endif
    }
}
