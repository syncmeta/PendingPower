import AppKit

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let cpuItem = NSMenuItem(title: "CPU —", action: nil, keyEquivalent: "")
    private let gpuItem = NSMenuItem(title: "GPU —", action: nil, keyEquivalent: "")
    private let aneItem = NSMenuItem(title: "ANE —", action: nil, keyEquivalent: "")
    private let otherItem = NSMenuItem(title: "Other —", action: nil, keyEquivalent: "")
    private let totalItem = NSMenuItem(title: "Total —", action: nil, keyEquivalent: "")

    private static let fixedWidth: CGFloat = 48

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: Self.fixedWidth)
        if let button = statusItem.button {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular)
            button.alignment = .right
            button.wantsLayer = true
            button.attributedTitle = Self.attributed("… W")
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
        setTitle(Self.attributed("—"))
        totalItem.title = message
    }

    func update(_ r: PowerReading) {
        setTitle(Self.attributed(Self.formatTotal(r.total)))
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

    private func setTitle(_ s: NSAttributedString) {
        guard let button = statusItem.button else { return }
        if button.attributedTitle.string == s.string { return }
        let fade = CATransition()
        fade.type = .fade
        fade.duration = 0.25
        button.layer?.add(fade, forKey: "fade")
        button.attributedTitle = s
    }

    private static func attributed(_ s: String) -> NSAttributedString {
        let p = NSMutableParagraphStyle()
        p.alignment = .right
        return NSAttributedString(string: s, attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular),
            .paragraphStyle: p,
        ])
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
