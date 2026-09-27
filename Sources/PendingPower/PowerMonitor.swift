import Foundation

final class PowerMonitor {
    private let reader: SMCPowerReader
    private var timer: Timer?

    var onUpdate: ((Double?) -> Void)?

    init?() {
        guard let reader = SMCPowerReader() else { return nil }
        self.reader = reader
    }

    func start(interval: TimeInterval = 1.0) {
        stop()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.onUpdate?(self.reader.readWatts())
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
