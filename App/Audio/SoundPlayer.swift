import AVFoundation

final class SoundPlayer: @unchecked Sendable {
    static let shared = SoundPlayer()

    private var players: [String: AVAudioPlayer] = [:]
    private let soundNames = [
        "tap1", "tap2", "tap3", "tap4", "tap5",
        "operator", "equals", "clear", "error", "success",
        "modeswitch", "easteregg", "startup"
    ]
    private var sessionConfigured = false

    private init() {
        configureSession()
        preload()
    }

    private func configureSession() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            sessionConfigured = false
        }
    }

    private func preload() {
        for name in soundNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { continue }
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[name] = player
            }
        }
    }

    func play(_ name: String, gain: Float) {
        guard let player = players[name] else { return }
        player.currentTime = 0
        player.volume = gain
        player.play()
    }
}
