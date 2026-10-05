import SwiftUI
import AppKit

public struct CardBackView: View {
    public let theme: CardBackTheme
    public let customImageData: Data?
    public var cornerRadius: CGFloat = 8

    public init(theme: CardBackTheme = GameSettings.shared.cardBackTheme,
                customImageData: Data? = GameSettings.shared.customCardBackImageData,
                cornerRadius: CGFloat = 8) {
        self.theme = theme
        self.customImageData = customImageData
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        ZStack {
            if theme == .custom, let data = customImageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
            } else {
                switch theme {
                case .geometricGlass:
                    geometricGlassPattern
                case .royalSapphire:
                    royalSapphirePattern
                case .crimsonVelvet:
                    crimsonVelvetPattern
                case .obsidianMinimal:
                    obsidianMinimalPattern
                case .custom:
                    geometricGlassPattern
                }
            }

            // Glassmorphic specular border & inner shine
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    // MARK: - Geometric Glass
    private var geometricGlassPattern: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.22, blue: 0.38), Color(red: 0.05, green: 0.12, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Geometric diamond grid
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: 6))
                    p.addLine(to: CGPoint(x: w - 6, y: h * 0.5))
                    p.addLine(to: CGPoint(x: w * 0.5, y: h - 6))
                    p.addLine(to: CGPoint(x: 6, y: h * 0.5))
                    p.closeSubpath()
                }
                .stroke(Color.cyan.opacity(0.35), lineWidth: 1.5)

                Path { p in
                    p.move(to: CGPoint(x: w * 0.5, y: 14))
                    p.addLine(to: CGPoint(x: w - 14, y: h * 0.5))
                    p.addLine(to: CGPoint(x: w * 0.5, y: h - 14))
                    p.addLine(to: CGPoint(x: 14, y: h * 0.5))
                    p.closeSubpath()
                }
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
            }

            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Color.cyan.opacity(0.8))
        }
    }

    // MARK: - Royal Sapphire
    private var royalSapphirePattern: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.18, blue: 0.45), Color(red: 0.04, green: 0.08, blue: 0.25)],
                startPoint: .top,
                endPoint: .bottom
            )

            RoundedRectangle(cornerRadius: cornerRadius - 2)
                .inset(by: 4)
                .stroke(Color(red: 0.85, green: 0.72, blue: 0.42).opacity(0.6), lineWidth: 1.5)

            Image(systemName: "crown.fill")
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.88, blue: 0.5), Color(red: 0.8, green: 0.6, blue: 0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    // MARK: - Crimson Velvet
    private var crimsonVelvetPattern: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.48, green: 0.08, blue: 0.14), Color(red: 0.22, green: 0.03, blue: 0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: cornerRadius - 2)
                .inset(by: 5)
                .stroke(Color(red: 0.95, green: 0.80, blue: 0.45).opacity(0.5), lineWidth: 1.5)

            Image(systemName: "suit.diamond.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color(red: 0.95, green: 0.85, blue: 0.55).opacity(0.85))
        }
    }

    // MARK: - Obsidian Minimal
    private var obsidianMinimalPattern: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.18), Color(white: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: cornerRadius - 2)
                .inset(by: 5)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)

            Image(systemName: "circle.grid.cross")
                .font(.system(size: 18, weight: .ultraLight))
                .foregroundStyle(Color.white.opacity(0.35))
        }
    }
}
