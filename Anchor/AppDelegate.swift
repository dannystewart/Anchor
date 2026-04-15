import AppKit
import SwiftUI

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem! = nil
    private var setTaskPopover: NSPopover? = nil
    private let appModel: AppModel = .shared

    func applicationWillFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_: Notification) {
        self.setupStatusItem()
        self.startObservingModel()
    }

    func updateStatusItemDisplay() {
        guard let button = statusItem?.button else { return }
        let icon = NSImage(systemSymbolName: "sailboat.fill", accessibilityDescription: "Anchor")
        button.image = icon
        if self.appModel.currentTask.isEmpty {
            button.title = ""
            button.imagePosition = .imageOnly
        } else {
            button.title = "\(self.appModel.currentTask)  "
            button.imagePosition = .imageRight
            button.imageHugsTitle = true
        }
    }

    // MARK: - Observation of AppModel

    func startObservingModel() {
        withObservationTracking {
            _ = self.appModel.currentTask
        } onChange: {
            Task { @MainActor in
                self.updateStatusItemDisplay()
                self.startObservingModel()
            }
        }
    }

    // MARK: - Popover

    func showSetTaskPopover() {
        guard let button = statusItem.button else { return }

        if let existing = setTaskPopover {
            if existing.isShown {
                existing.close()
                return
            }
            self.setTaskPopover = nil
        }

        let popover = NSPopover()
        let rootView = SetTaskView()
            .environment(self.appModel)
        popover.contentViewController = NSHostingController(rootView: rootView)
        popover.contentSize = NSSize(width: 300, height: 148)
        popover.behavior = .transient
        popover.delegate = self
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        self.setTaskPopover = popover
    }

    // MARK: - Menu Actions

    @objc func openSetTask() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            self.showSetTaskPopover()
        }
    }

    @objc func clearTask() {
        self.appModel.currentTask = ""
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.font = .menuBarFont(ofSize: 14)
        let menu = NSMenu()
        menu.delegate = self
        self.statusItem.menu = menu
        self.updateStatusItemDisplay()
    }
}

// MARK: NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let setTitle = self.appModel.currentTask.isEmpty ? "Set Current Task…" : "Change Task…"
        let setItem = NSMenuItem(title: setTitle, action: #selector(openSetTask), keyEquivalent: "")
        setItem.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: nil)
        setItem.target = self
        menu.addItem(setItem)

        if !self.appModel.currentTask.isEmpty {
            let clearItem = NSMenuItem(title: "Clear Task", action: #selector(clearTask), keyEquivalent: "")
            clearItem.image = NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: nil)
            clearItem.target = self
            menu.addItem(clearItem)
        }

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Anchor", action: #selector(quitApp), keyEquivalent: "")
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        quitItem.target = self
        menu.addItem(quitItem)
    }
}

// MARK: NSPopoverDelegate

extension AppDelegate: NSPopoverDelegate {
    func popoverDidClose(_: Notification) {
        self.setTaskPopover = nil
    }
}
