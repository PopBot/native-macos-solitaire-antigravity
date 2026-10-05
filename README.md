# Solitaire Glass (macOS SwiftUI)

A native macOS Solitaire (Klondike) game built with Swift 6 and SwiftUI, styled with Apple's modern glassmorphic aesthetic (frosted acrylic materials, specular rim lighting, ambient dynamic felt/mesh gradients, and fluid physics).

![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange)
![Xcode 16+](https://img.shields.io/badge/Xcode-16.0%2B-blue)
![License-MIT](https://img.shields.io/badge/License-MIT-green)

---

## ✨ Features

- **Apple Glassmorphic Design**:
  - Translucent frosted glass cards with specular edge gradients and inner glow.
  - Modern Classic Linen deck option for high-contrast traditional paper feel.
  - Dynamic ambient backgrounds: Emerald Felt, Midnight Obsidian, Royal Blue, Velvet Nebula, and Aurora Glass.
  - Support for **Custom Background** and **Custom Card Back** images imported directly from Finder.
  - Native **Dark Mode** and **Light Mode** support (System, Dark, Light).
- **Physical Drag-and-Drop**:
  - Drag-and-drop interaction with physical card lifting, elevation shadows, and target glow.
  - Multi-card stack dragging down tableau columns.
- **Classic Klondike Rules & Flexibility**:
  - Toggle between **Draw 1** and **Draw 3** modes in Settings.
  - **Standard** and **Vegas** scoring modes.
  - Optional timer display.
- **Polish & Assists**:
  - **Unlimited Undo and Redo** (`Cmd+Z`, `Cmd+Shift+Z`).
  - **Smart Hint System** (`Cmd+H`) analyzing board state for legal and strategic moves.
  - **Auto Finish Button** (`Cmd+Shift+A`) when all cards are face up.
  - **Celebratory Bouncing Card Cascade**: 60/120fps physics simulation with card trails upon winning.
  - **Procedural Sound Engine**: Crisp low-latency synthesized sounds for flips, slides, taps, foundation chimes, and win fanfare (volume adjustable, toggleable).
- **Statistics & Persistence**:
  - Persisted tracking of games played, games won, win rate, winning streaks, best time, and high scores.
- **macOS System Integration**:
  - Standard Preferences / Settings window (`Cmd+,`).
  - Native Menu Bar shortcuts (`Cmd+N`, `Cmd+R`, `Cmd+Z`, `Cmd+Shift+Z`, `Cmd+H`, `Space`).

---

## 🛠 Project Structure

```
native-macos-solitaire/
├── project.yml                     # XcodeGen declarative project configuration
├── SolitaireGlass.xcodeproj        # Native Xcode project file
├── Sources/
│   ├── App/
│   │   └── SolitaireApp.swift      # Main @main App, window, commands & menu bar
│   ├── Models/
│   │   ├── Suit.swift              # Suit definitions (Clubs, Diamonds, Hearts, Spades)
│   │   ├── Rank.swift              # Card rank definitions (Ace through King)
│   │   ├── Card.swift              # Card struct & standard 52-card deck generator
│   │   ├── GameMove.swift          # Move models & location tracking for undo/redo
│   │   ├── GameSettings.swift      # Observable user preferences (themes, rules, audio)
│   │   └── GameStats.swift         # Observable stats (win rate, streaks, best scores)
│   ├── Services/
│   │   └── AudioService.swift      # Procedural sound effect synthesizer
│   ├── ViewModels/
│   │   ├── SolitaireViewModel.swift # Game state, drag-and-drop controller, auto-complete
│   │   └── HintEngine.swift        # Safe move analysis & strategic hint solver
│   └── Views/
│       ├── BoardView.swift         # Top-level game board layout & drop coordinates
│       ├── CardView.swift          # Card face view (Glass vs Linen, custom court art)
│       ├── CardBackView.swift      # Card back patterns & custom user image rendering
│       ├── TableauColumnView.swift # Cascading tableau columns with multi-card drag
│       ├── FoundationView.swift    # 4 foundation piles with suit watermark slots
│       ├── StockWasteView.swift    # Draw pile and fanned waste pile
│       ├── ToolbarView.swift       # Glassmorphic HUD with score, moves, time & controls
│       ├── GlassBackgroundView.swift # Ambient felt & obsidian mesh gradients
│       ├── WinCascadeView.swift    # Celebratory bouncing card physics animation
│       ├── DropTargetModifier.swift # PreferenceKey spatial drop target detector
│       └── SettingsView.swift      # Native macOS Preferences window (Cmd+,)
├── Tests/
│   └── SolitaireGameTests.swift    # Unit tests for rules, dealing, moves, and undo/redo
└── Resources/
    └── Assets.xcassets             # App icon and asset catalog
```

---

## 🚀 Building & Running

### Option 1: Xcode
1. Double-click `SolitaireGlass.xcodeproj` to open in Xcode.
2. Select the `SolitaireGlass` scheme and click **Run** (`Cmd+R`).

### Option 2: Command Line (`xcodebuild`)
To build the application bundle:
```bash
xcodebuild -project SolitaireGlass.xcodeproj -scheme SolitaireGlass build
```

To run all unit tests:
```bash
xcodebuild -project SolitaireGlass.xcodeproj -scheme SolitaireGlassTests test
```

### Regenerating Project Files (`xcodegen`)
If you modify `project.yml`:
```bash
xcodegen generate
```

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| `Cmd + N` | New Game |
| `Cmd + R` | Restart Current Game |
| `Space` | Draw Card from Stock |
| `Cmd + Z` | Undo Move |
| `Cmd + Shift + Z` | Redo Move |
| `Cmd + H` | Request Hint |
| `Cmd + Shift + A` | Auto Finish (when available) |
| `Cmd + ,` | Open Settings & Appearance |
