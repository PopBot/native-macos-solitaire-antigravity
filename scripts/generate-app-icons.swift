import AppKit
import CoreGraphics

let sourcePath = "/Users/jarodwong/.gemini/antigravity-cli/brain/11bf0256-26c4-4e24-aeee-394c4ba984da/solitaire_glass_app_icon_1791161231875.jpg"
let outputDir = "/Users/jarodwong/Documents/Projects/native-macos-solitaire-antigravity/Resources/Assets.xcassets/AppIcon.appiconset"

guard let sourceImage = NSImage(contentsOfFile: sourcePath),
      let cgSource = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fatalError("Failed to load source image at \(sourcePath)")
}

// 1. Create a 1024x1024 master icon with transparent background and squircle mask + shadow
let masterSize = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: masterSize,
    height: masterSize,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Failed to create CGContext")
}

// The squircle rect in the source image is centered around:
// x: 126, y: 126, width: 772, height: 772
// Let's scale and center it nicely into a standard macOS 824x824 icon bounds centered in 1024x1024
let targetIconRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 184.0

// First draw drop shadow
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -18), blur: 32, color: CGColor(gray: 0, alpha: 0.35))
let shadowPath = CGPath(roundedRect: targetIconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
context.addPath(shadowPath)
context.setFillColor(gray: 0, alpha: 0.6)
context.fillPath()
context.restoreGState()

// Now clip to squircle and draw source image cropped to the icon body
context.saveGState()
let clipPath = CGPath(roundedRect: targetIconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
context.addPath(clipPath)
context.clip()

// Source squircle is at (126, 126, 772, 772) in 1024x1024 coordinates
// Scale it so that source (126, 126, 772, 772) maps to targetIconRect (100, 100, 824, 824)
let scaleFactor: CGFloat = 824.0 / 772.0
let sourceOriginInTarget = CGPoint(
    x: targetIconRect.origin.x - 126.0 * scaleFactor,
    y: targetIconRect.origin.y - 126.0 * scaleFactor
)
let drawnSourceSize = CGSize(
    width: 1024.0 * scaleFactor,
    height: 1024.0 * scaleFactor
)

context.draw(cgSource, in: CGRect(origin: sourceOriginInTarget, size: drawnSourceSize))

// Subtle inner stroke border
context.setStrokeColor(CGColor(red: 1.0, green: 0.88, blue: 0.5, alpha: 0.45))
context.setLineWidth(3.0)
context.addPath(clipPath)
context.strokePath()

context.restoreGState()

guard let masterCGImage = context.makeImage() else {
    fatalError("Failed to render master CGImage")
}

// 2. Export all standard macOS sizes
let iconSpecs: [(size: Int, filename: String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

for spec in iconSpecs {
    guard let resizeCtx = CGContext(
        data: nil,
        width: spec.size,
        height: spec.size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { continue }

    resizeCtx.interpolationQuality = .high
    resizeCtx.draw(masterCGImage, in: CGRect(x: 0, y: 0, width: spec.size, height: spec.size))

    if let resizedImage = resizeCtx.makeImage() {
        let nsImage = NSImage(cgImage: resizedImage, size: NSSize(width: spec.size, height: spec.size))
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            continue
        }
        let destURL = URL(fileURLWithPath: "\(outputDir)/\(spec.filename)")
        try? pngData.write(to: destURL)
        print("Generated \(spec.filename) (\(spec.size)x\(spec.size))")
    }
}

print("AppIcon generation finished successfully!")
