import AppKit
import Sparkle
import ServiceManagement

final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let launchAtLogin = NSMenuItem(title: NSLocalizedString("menu.launchAtLogin", comment: "Launch at login"), action: #selector(toggleLaunchAtLogin), keyEquivalent: "")

    private static let fixedWidth: CGFloat = 48

    init(updaterController: SPUStandardUpdaterController) {
        statusItem = NSStatusBar.system.statusItem(withLength: Self.fixedWidth)
        super.init()
        statusItem.autosaveName = "PendingPower-Watts"
        statusItem.isVisible = true
        if let button = statusItem.button {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular)
            button.alignment = .right
            button.wantsLayer = true
            button.attributedTitle = Self.attributed("… W")
        }

        launchAtLogin.target = self
        menu.addItem(launchAtLogin)
        menu.addItem(.separator())
        menu.delegate = self
        refreshLaunchAtLogin()
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
        setTitle(Self.attributed(watts.map(PowerDisplay.format) ?? "— W"))
    }

    func menuWillOpen(_ menu: NSMenu) {
        refreshLaunchAtLogin()
    }

    private func refreshLaunchAtLogin() {
        switch SMAppService.mainApp.status {
        case .enabled: launchAtLogin.state = .on
        case .requiresApproval: launchAtLogin.state = .mixed
        default: launchAtLogin.state = .off
        }
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled || service.status == .requiresApproval {
                try service.unregister()
            } else {
                try service.register()
                if service.status == .requiresApproval {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("login.approvalTitle", comment: "Login approval required")
                    alert.informativeText = NSLocalizedString("login.approvalMessage", comment: "Login approval instructions")
                    alert.addButton(withTitle: NSLocalizedString("login.openSettings", comment: "Open System Settings"))
                    alert.addButton(withTitle: NSLocalizedString("login.cancel", comment: "Cancel"))
                    NSApp.activate(ignoringOtherApps: true)
                    if alert.runModal() == .alertFirstButtonReturn {
                        SMAppService.openSystemSettingsLoginItems()
                    }
                }
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("login.errorTitle", comment: "Login setting error")
            alert.informativeText = error.localizedDescription
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
        refreshLaunchAtLogin()
    }

    private func setTitle(_ s: NSAttributedString) {
        guard let button = statusItem.button else { return }
        if button.attributedTitle.string == s.string { return }
        statusItem.length = max(Self.fixedWidth, ceil(s.size().width) + 12)
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
        let url = URL(string: "https://github.com/syncmeta/PendingPower")!
        let link = NSAttributedString(string: "GitHub", attributes: [
            .link: url,
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ])
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [.credits: link])
    }
}
