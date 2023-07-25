import SwiftUI
import LaunchAtLogin

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!

    var timer: Timer?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        let menuBarIcon = NSImage(named: "MenuBarIcon")
        menuBarIcon?.isTemplate = true
        self.statusBarItem.button?.image = menuBarIcon

        let statusBarMenu = NSMenu()

        let titleFont = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        let title = NSAttributedString(string: "Menu Mic", attributes: [.font: titleFont])
        statusBarMenu.addItem(withTitle: "", action: nil, keyEquivalent: "").attributedTitle = title

        statusBarMenu.addItem(NSMenuItem.separator())

        let inputDeviceTitle = NSAttributedString(string: "Input Device", attributes: [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)])
        statusBarMenu.addItem(withTitle: "", action: nil, keyEquivalent: "").attributedTitle = inputDeviceTitle

        statusBarMenu.addItem(NSMenuItem.separator())

        let keepInputActive = NSMenuItem(title: "Keep Input Active", action: #selector(AppDelegate.toggleKeepInputActive(_:)), keyEquivalent: "")
        keepInputActive.state = UserDefaults.standard.bool(forKey: "keepInputActive") ? NSControl.StateValue.on : NSControl.StateValue.off
        statusBarMenu.addItem(keepInputActive)

        let keepOutputBalanced = NSMenuItem(title: "Keep Output Balanced", action: #selector(AppDelegate.toggleKeepOutputBalanced(_:)), keyEquivalent: "")
        keepOutputBalanced.state = UserDefaults.standard.bool(forKey: "keepOutputBalanced") ? NSControl.StateValue.on : NSControl.StateValue.off
        statusBarMenu.addItem(keepOutputBalanced)

        let openAtLoginItem = NSMenuItem(title: "Open at Login", action: #selector(AppDelegate.toggleOpenAtLogin(_:)), keyEquivalent: "")
        openAtLoginItem.state = LaunchAtLogin.isEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
        statusBarMenu.addItem(openAtLoginItem)

        statusBarMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusBarMenu.addItem(quitItem)

        statusBarItem.menu = statusBarMenu

        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(AppDelegate.update), userInfo: nil, repeats: true)
        self.timer?.fire()

        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func toggleKeepInputActive(_ sender: AnyObject?) {
        UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: "keepInputActive"), forKey: "keepInputActive")

        let item = sender as! NSMenuItem
        item.state = UserDefaults.standard.bool(forKey: "keepInputActive") ? NSControl.StateValue.on : NSControl.StateValue.off
    }

    @objc func toggleKeepOutputBalanced(_ sender: AnyObject?) {
        UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: "keepOutputBalanced"), forKey: "keepOutputBalanced")

        let item = sender as! NSMenuItem
        item.state = UserDefaults.standard.bool(forKey: "keepOutputBalanced") ? NSControl.StateValue.on : NSControl.StateValue.off
    }

    @objc func toggleOpenAtLogin(_ sender: AnyObject?) {
        LaunchAtLogin.isEnabled.toggle()

        let item = sender as! NSMenuItem
        item.state = LaunchAtLogin.isEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
    }

    @objc func update() {
        self.updateInputDeviceItems()
        self.updateKeepInputActive()
        self.updateKeepOutputBalanced()
    }

    func updateInputDeviceItems() {
        let devices = AudioDevices.getInputDevices()
        let activeDevice = AudioDevices.getActiveInputDevice()

        // Remove all tagged items.
        for item in statusBarItem.menu!.items {
            if item.tag == 1 {
                statusBarItem.menu!.removeItem(item)
            }
        }

        // Add a menu item for each device.
        for device in devices {
            let item = NSMenuItem(title: device.getName(), action: #selector(AppDelegate.selectInputDevice(_:)), keyEquivalent: "")
            item.tag = 1
            item.target = self
            item.representedObject = device
            item.state = device.deviceID == activeDevice?.deviceID ? NSControl.StateValue.on : NSControl.StateValue.off
            statusBarItem.menu!.insertItem(item, at: 3)
        }
    }

    @objc func selectInputDevice(_ sender: AnyObject?) {
        let device = sender!.representedObject as! AudioDevice
        AudioDevices.setActiveInputDevice(device)
        UserDefaults.standard.set(device.deviceID, forKey: "inputDeviceID")
    }

    func updateKeepInputActive() {
        let keepInputActive = UserDefaults.standard.bool(forKey: "keepInputActive")
        let deviceId = UserDefaults.standard.integer(forKey: "inputDeviceID")
        let device = AudioDevices.getInputDevices().first(where: { $0.deviceID == deviceId })

        if keepInputActive && device != nil {
            AudioDevices.setActiveInputDevice(device!)
        }
    }

    func updateKeepOutputBalanced() {
        let keepOutputBalanced = UserDefaults.standard.bool(forKey: "keepOutputBalanced")

        if keepOutputBalanced {
            AudioDevices.balanceCenter()
        }
    }
}

