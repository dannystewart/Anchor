import AppKit
import SwiftUI

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem! = nil
    private var setTaskPopover: NSPopover? = nil
    private var menuBarLabel: NSHostingView<MenuBarLabel>? = nil
    private let appModel: AppModel = .shared

    func applicationWillFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_: Notification) {
        self.setupStatusItem()
        self.startObservingModel()
    }

    func updateStatusItemDisplay() {
        self.menuBarLabel?.rootView = MenuBarLabel(task: self.appModel.currentTask)
        self.statusItem.length = self.labelWidth(for: self.appModel.currentTask)
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
            await Task.yield() // one runloop pass — lets NSMenu finish closing, zero perceptible delay
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

        // Use a SwiftUI hosting view for perfectly centered layout
        button.title = ""
        button.image = nil

        let label = NSHostingView(rootView: MenuBarLabel(task: appModel.currentTask))
        label.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            label.topAnchor.constraint(equalTo: button.topAnchor),
            label.bottomAnchor.constraint(equalTo: button.bottomAnchor),
        ])
        self.menuBarLabel = label

        let menu = NSMenu()
        menu.delegate = self
        self.statusItem.menu = menu

        self.updateStatusItemDisplay()
    }

    private func labelWidth(for task: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 14)
        let iconWidth: CGFloat = 18
        let spacing: CGFloat = 5
        let sidePadding: CGFloat = 16
        guard !task.isEmpty else { return iconWidth + sidePadding }
        let textWidth = ceil((task as NSString).size(withAttributes: [.font: font]).width)
        return textWidth + spacing + iconWidth + sidePadding
    }
}

// MARK: NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let setTitle = "Set Task…"
        let setItem = NSMenuItem(title: setTitle, action: #selector(openSetTask), keyEquivalent: "")
        setItem.image = NSImage(systemSymbolName: "pencil.line", accessibilityDescription: nil)
        setItem.target = self
        menu.addItem(setItem)

        if !self.appModel.currentTask.isEmpty {
            let clearItem = NSMenuItem(title: "Clear Task", action: #selector(clearTask), keyEquivalent: "")
            clearItem.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
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
