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

        guard let m = PowerMonitor() else {
            NSLog("PendingPower: AppleSMC unavailable")
            statusBar.update(nil)
            return
        }
        m.onUpdate = { [weak self] watts in
            self?.statusBar.update(watts)
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
