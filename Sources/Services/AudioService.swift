import AppKit
import AVFoundation

public final class AudioService: @unchecked Sendable {
    public static let shared = AudioService()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var isEngineRunning = false
    private let audioQueue = DispatchQueue(label: "com.jarodwong.solitaire.audio", qos: .userInteractive)

    private init() {
        setupEngine()
    }

    private func setupEngine() {
        engine.attach(playerNode)
        let mainMixer = engine.mainMixerNode
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(playerNode, to: mainMixer, format: format)

        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            print("Failed to start AVAudioEngine: \(error)")
        }
    }

    private func generateBuffer(duration: Double, sampleRate: Double = 44100, generator: (Double) -> Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount
        let channelData = buffer.floatChannelData![0]

        for i in 0..<Int(frameCount) {
            let time = Double(i) / sampleRate
            channelData[i] = generator(time)
        }
        return buffer
    }

    private func playProcedural(duration: Double, generator: @escaping (Double) -> Float) {
        guard GameSettings.shared.soundEnabled else { return }
        let volume = Float(GameSettings.shared.soundVolume)
        guard volume > 0 else { return }

        audioQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.isEngineRunning {
                self.setupEngine()
            }
            guard let buffer = self.generateBuffer(duration: duration, generator: generator) else { return }
            self.playerNode.volume = volume
            self.playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            if !self.playerNode.isPlaying {
                self.playerNode.play()
            }
        }
    }

    /// Card pickup / drag start: subtle light tactile tick
    public func playPickup() {
        playProcedural(duration: 0.04) { t in
            let progress = t / 0.04
            let env = Float(1.0 - progress)
            let freq = 600.0 - 200.0 * progress
            return sin(Float(2.0 * .pi * freq * t)) * env * 0.25
        }
    }

    /// Card flip sound: crisp paper snap
    public func playFlip() {
        playProcedural(duration: 0.06) { t in
            let progress = t / 0.06
            let env = Float(1.0 - progress * progress)
            let noise = Float.random(in: -0.3...0.3)
            let freq = 1200.0 - 800.0 * progress
            let tone = sin(Float(2.0 * .pi * freq * t))
            return (tone * 0.5 + noise * 0.5) * env * 0.35
        }
    }

    /// Card placed on tableau: gentle felt tap
    public func playPlace() {
        playProcedural(duration: 0.08) { t in
            let progress = t / 0.08
            let env = Float(exp(-progress * 15.0))
            let freq = 320.0 - 120.0 * progress
            return sin(Float(2.0 * .pi * freq * t)) * env * 0.4
        }
    }

    /// Card placed on foundation: rewarding crystal chime
    public func playFoundationSnap() {
        playProcedural(duration: 0.16) { t in
            let progress = t / 0.16
            let env = Float(exp(-progress * 8.0))
            let tone1 = sin(Float(2.0 * .pi * 880.0 * t)) // A5
            let tone2 = sin(Float(2.0 * .pi * 1320.0 * t)) // E6 harmonic
            return (tone1 * 0.6 + tone2 * 0.4) * env * 0.45
        }
    }

    /// Invalid move bounce back: low soft woodblock thud
    public func playInvalidMove() {
        playProcedural(duration: 0.09) { t in
            let progress = t / 0.09
            let env = Float(exp(-progress * 18.0))
            let freq = 160.0 - 60.0 * progress
            return sin(Float(2.0 * .pi * freq * t)) * env * 0.3
        }
    }

    /// Win fanfare: harmonic arpeggio
    public func playWinFanfare() {
        guard GameSettings.shared.soundEnabled else { return }
        let notes: [Double] = [523.25, 659.25, 783.99, 1046.50] // C5, E5, G5, C6
        for (index, freq) in notes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.12) { [weak self] in
                self?.playProcedural(duration: 0.35) { t in
                    let progress = t / 0.35
                    let env = Float(exp(-progress * 5.0))
                    let s1 = sin(Float(2.0 * .pi * freq * t))
                    let s2 = sin(Float(2.0 * .pi * (freq * 2.0) * t)) * 0.3
                    return (s1 + s2) * env * 0.4
                }
            }
        }
    }
}
