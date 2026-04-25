import AppKit

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let cpuItem = NSMenuItem(title: "CPU —", action: nil, keyEquivalent: "")
    private let gpuItem = NSMenuItem(title: "GPU —", action: nil, keyEquivalent: "")
    private let aneItem = NSMenuItem(title: "ANE —", action: nil, keyEquivalent: "")
    private let otherItem = NSMenuItem(title: "Other —", action: nil, keyEquivalent: "")
    private let totalItem = NSMenuItem(title: "Total —", action: nil, keyEquivalent: "")

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "… W"
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular)
        }

        for item in [cpuItem, gpuItem, aneItem, otherItem] { menu.addItem(item) }
        menu.addItem(.separator())
        menu.addItem(totalItem)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "退出 PendingPower", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
    }

    func showError(_ message: String) {
        statusItem.button?.title = "—"
        totalItem.title = message
    }

    func update(_ r: PowerReading) {
        statusItem.button?.title = Self.formatTotal(r.total)
        cpuItem.title = String(format: "CPU   %.2f W", r.cpu)
        gpuItem.title = String(format: "GPU   %.2f W", r.gpu)
        aneItem.title = String(format: "ANE   %.2f W", r.ane)
        otherItem.title = String(format: "Other %.2f W", r.other)
        totalItem.title = String(format: "Total %.2f W", r.total)
    }

    private static func formatTotal(_ watts: Double) -> String {
        // <10 W  → 2 decimals (e.g. "8.34 W")
        // 10–99  → 1 decimal  (e.g. "23.4 W")
        // ≥100   → integer    (e.g. "147 W")
        let abs = Swift.abs(watts)
        if abs < 10 {
            return String(format: "%.2f W", watts)
        } else if abs < 100 {
            return String(format: "%.1f W", watts)
        } else {
            return String(format: "%.0f W", watts)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
