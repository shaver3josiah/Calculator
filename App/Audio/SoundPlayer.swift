import AVFoundation
import os

final class SoundPlayer: @unchecked Sendable {
    static let shared = SoundPlayer()

    private var players: [String: AVAudioPlayer] = [:]
    private let soundNames = [
        "tap1", "tap2", "tap3", "tap4", "tap5",
        "operator", "equals", "clear", "error", "success",
        "modeswitch", "easteregg", "startup"
    ]
    private var sessionConfigured = false
    private let logger = Logger(subsystem: "com.shaver.bloomcalculator", category: "SoundPlayer")

    private init() {
        configureSession()
        preload()
    }

    private func configureSession() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            sessionConfigured = false
        }
    }

    private func preload() {
        var missing: [String] = []
        for name in soundNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
                missing.append(name)
                continue
            }
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[name] = player
            }
        }
        if !missing.isEmpty {
            logger.error("Missing bundled sounds: \(missing.joined(separator: ", "), privacy: .public)")
            #if DEBUG
            assertionFailure("Missing bundled sounds: \(missing.joined(separator: ", "))")
            #endif
        }
    }

    func play(_ name: String, gain: Float) {
        guard let player = players[name] else {
            logger.error("No preloaded player for sound: \(name, privacy: .public)")
            return
        }
        player.currentTime = 0
        player.volume = gain
        player.play()
    }
}
