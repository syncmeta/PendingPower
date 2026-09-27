import AppKit
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController!
    private var monitor: PowerMonitor?
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBar = StatusBarController(updaterController: updaterController)
        updaterController.startUpdater()

        guard let m = PowerMonitor.make() else {
            statusBar.showError("无法读取功耗(IOReport 不可用)")
            return
        }
        m.onUpdate = { [weak self] reading in
            self?.statusBar.update(reading)
        }
        m.start(interval: 1.0)
        monitor = m
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // no Dock icon, menu-bar only
app.run()
