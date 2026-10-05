import SwiftUI
import AppKit

public struct SettingsView: View {
    @State private var settings = GameSettings.shared
    @State private var stats = GameStats.shared

    public init() {}

    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            appearanceTab
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }

            statsTab
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar")
                }
        }
        .frame(width: 520, height: 420)
        .padding()
    }

    // MARK: - General Tab
    private var generalTab: some View {
        Form {
            Section("Gameplay Rules") {
                Picker("Card Draw Mode:", selection: $settings.drawMode) {
                    ForEach(DrawMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Scoring System:", selection: $settings.scoringMode) {
                    ForEach(ScoringMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Enable Game Timer", isOn: $settings.timerEnabled)

                Toggle("Enable Undo & Redo", isOn: $settings.allowUndoRedo)
            }

            Section("Audio & Feedback") {
                Toggle("Sound Effects", isOn: $settings.soundEnabled)

                if settings.soundEnabled {
                    Slider(value: $settings.soundVolume, in: 0.1...1.0) {
                        Text("Volume:")
                    } minimumValueLabel: {
                        Image(systemName: "speaker.wave.1")
                    } maximumValueLabel: {
                        Image(systemName: "speaker.wave.3")
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Appearance Tab
    private var appearanceTab: some View {
        Form {
            Section("Theme & Style") {
                Picker("Interface Mode:", selection: $settings.appearance) {
                    ForEach(AppAppearance.allCases) { app in
                        Text(app.title).tag(app)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Card Deck Style:", selection: $settings.cardDeckStyle) {
                    ForEach(CardDeckStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Game Table Background") {
                Picker("Background Theme:", selection: $settings.backgroundTheme) {
                    ForEach(BackgroundTheme.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }

                if settings.backgroundTheme == .custom {
                    HStack {
                        if let data = settings.customBackgroundImageData, let img = NSImage(data: data) {
                            Image(nsImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }

                        Button("Choose Background Image…") {
                            chooseImage { data in
                                settings.customBackgroundImageData = data
                            }
                        }
                    }
                }
            }

            Section("Card Back Artwork") {
                Picker("Card Back Theme:", selection: $settings.cardBackTheme) {
                    ForEach(CardBackTheme.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }

                if settings.cardBackTheme == .custom {
                    HStack {
                        if let data = settings.customCardBackImageData, let img = NSImage(data: data) {
                            Image(nsImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 46)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Button("Choose Card Back Image…") {
                            chooseImage { data in
                                settings.customCardBackImageData = data
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Statistics Tab
    private var statsTab: some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                statCard(title: "Games Played", value: "\(stats.gamesPlayed)")
                statCard(title: "Games Won", value: "\(stats.gamesWon)")
                statCard(title: "Win Rate", value: String(format: "%.1f%%", stats.winPercentage))
                statCard(title: "Current Streak", value: "\(stats.currentStreak)")
                statCard(title: "Best Standard Score", value: "\(stats.bestScoreStandard)")
                statCard(title: "Best Vegas Score", value: "$\(stats.bestScoreVegas)")
                statCard(title: "Best Time", value: stats.bestTimeSeconds != nil ? formatTime(stats.bestTimeSeconds!) : "--:--")
                statCard(title: "Best Streak", value: "\(stats.bestStreak)")
            }

            Spacer()

            Button("Reset All Statistics", role: .destructive) {
                stats.reset()
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func chooseImage(completion: @escaping (Data) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? Data(contentsOf: url) {
                completion(data)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
