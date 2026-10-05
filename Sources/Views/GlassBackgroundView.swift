import SwiftUI
import AppKit

public struct GlassBackgroundView: View {
    public let theme: BackgroundTheme
    public let customImageData: Data?

    public init(
        theme: BackgroundTheme = GameSettings.shared.backgroundTheme,
        customImageData: Data? = GameSettings.shared.customBackgroundImageData
    ) {
        self.theme = theme
        self.customImageData = customImageData
    }

    public var body: some View {
        ZStack {
            if theme == .custom, let data = customImageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .overlay(Color.black.opacity(0.18))
            } else {
                themeGradient
            }

            // Vignette edge shading
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.38)],
                center: .center,
                startRadius: 280,
                endRadius: 750
            )

            // Ultra-subtle felt / noise mesh texture overlay
            ambientGlowOrbs
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var themeGradient: some View {
        switch theme {
        case .emeraldFelt:
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.35, blue: 0.22),
                    Color(red: 0.04, green: 0.22, blue: 0.14),
                    Color(red: 0.02, green: 0.14, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .midnightObsidian:
            LinearGradient(
                colors: [
                    Color(red: 0.14, green: 0.16, blue: 0.22),
                    Color(red: 0.08, green: 0.09, blue: 0.13),
                    Color(red: 0.04, green: 0.05, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .royalBlueFelt:
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.24, blue: 0.48),
                    Color(red: 0.05, green: 0.14, blue: 0.32),
                    Color(red: 0.02, green: 0.08, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .purpleVelvet:
            LinearGradient(
                colors: [
                    Color(red: 0.32, green: 0.12, blue: 0.40),
                    Color(red: 0.18, green: 0.06, blue: 0.26),
                    Color(red: 0.08, green: 0.02, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .auroraTeal:
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.28, blue: 0.32),
                    Color(red: 0.02, green: 0.16, blue: 0.24),
                    Color(red: 0.01, green: 0.08, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .custom:
            Color.black
        }
    }

    private var ambientGlowOrbs: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                // Top-left soft spotlight
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: w * 0.7, height: w * 0.7)
                    .blur(radius: 80)
                    .position(x: w * 0.25, y: h * 0.2)

                // Center subtle ambient warm accent
                Circle()
                    .fill(Color.cyan.opacity(0.03))
                    .frame(width: w * 0.5, height: w * 0.5)
                    .blur(radius: 90)
                    .position(x: w * 0.75, y: h * 0.7)
            }
        }
    }
}
