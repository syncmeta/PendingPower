import AppKit
import Sparkle

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    private static let fixedWidth: CGFloat = 48

    init(updaterController: SPUStandardUpdaterController) {
        statusItem = NSStatusBar.system.statusItem(withLength: Self.fixedWidth)
        statusItem.autosaveName = "PendingPower-Watts"
        statusItem.isVisible = true
        if let button = statusItem.button {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular)
            button.alignment = .right
            button.wantsLayer = true
            button.attributedTitle = Self.attributed("… W")
        }

        let checkUpdates = NSMenuItem(title: NSLocalizedString("menu.checkUpdates", comment: "Check for updates menu item"), action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)), keyEquivalent: "")
        checkUpdates.target = updaterController
        menu.addItem(checkUpdates)
        let quit = NSMenuItem(title: NSLocalizedString("menu.quit", comment: "Quit menu item"), action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        let about = NSMenuItem(title: NSLocalizedString("menu.about", comment: "About menu item"), action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        statusItem.menu = menu
    }

    func update(_ watts: Double?) {
        setTitle(Self.attributed(watts.map(Self.formatTotal) ?? "— W"))
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

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }
}
