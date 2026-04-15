import AppKit
import SwiftUI

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem! = nil
    private var setTaskPopover: NSPopover? = nil
    private var setTimerPopover: NSPopover? = nil
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
        let timerString = self.appModel.timerDisplayString
        self.menuBarLabel?.rootView = MenuBarLabel(task: self.appModel.currentTask, timerString: timerString)
        self.statusItem.length = self.labelWidth(for: self.appModel.currentTask, timerString: timerString)
    }

    // MARK: - Observation of AppModel

    func startObservingModel() {
        withObservationTracking {
            _ = self.appModel.currentTask
            _ = self.appModel.timeRemaining
        } onChange: {
            Task { @MainActor in
                self.updateStatusItemDisplay()
                self.startObservingModel()
            }
        }
    }

    // MARK: - Popovers

    func showSetTaskPopover() {
        guard let button = statusItem.button else { return }

        if let existing = setTaskPopover {
            if existing.isShown {
                existing.close()
                return
            }
            self.setTaskPopover = nil
        }

        // Close timer popover if open
        self.setTimerPopover?.close()

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

    func showSetTimerPopover() {
        guard let button = statusItem.button else { return }

        if let existing = setTimerPopover {
            if existing.isShown {
                existing.close()
                return
            }
            self.setTimerPopover = nil
        }

        // Close task popover if open
        self.setTaskPopover?.close()

        let popover = NSPopover()
        let rootView = SetTimerView()
            .environment(self.appModel)
        popover.contentViewController = NSHostingController(rootView: rootView)
        popover.contentSize = NSSize(width: 240, height: 130)
        popover.behavior = .transient
        popover.delegate = self
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        self.setTimerPopover = popover
    }

    // MARK: - Menu Actions

    @objc func openSetTask() {
        Task { @MainActor in
            await Task.yield()
            self.showSetTaskPopover()
        }
    }

    @objc func clearTask() {
        self.appModel.currentTask = ""
    }

    @objc func openSetTimer() {
        Task { @MainActor in
            await Task.yield()
            self.showSetTimerPopover()
        }
    }

    @objc func stopTimer() {
        self.appModel.stopTimer()
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }

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

    private func labelWidth(for task: String, timerString: String? = nil) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 14)
        let iconWidth: CGFloat = 18
        let spacing: CGFloat = 5
        let sidePadding: CGFloat = 16

        let displayText: String = switch (!task.isEmpty, timerString != nil) {
        case (true, true): "\(task) • \(timerString!)"
        case (true, false): task
        case (false, true): timerString!
        case (false, false): ""
        }

        guard !displayText.isEmpty else { return iconWidth + sidePadding }
        let textWidth = ceil((displayText as NSString).size(withAttributes: [.font: font]).width)
        return textWidth + spacing + iconWidth + sidePadding
    }
}

// MARK: NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let setTaskTitle = self.appModel.currentTask.isEmpty ? "Set Task…" : "Change Task…"
        let setTaskItem = NSMenuItem(title: setTaskTitle, action: #selector(openSetTask), keyEquivalent: "")
        setTaskItem.image = NSImage(systemSymbolName: "pencil.line", accessibilityDescription: nil)
        setTaskItem.target = self
        menu.addItem(setTaskItem)

        if !self.appModel.currentTask.isEmpty {
            let clearItem = NSMenuItem(title: "Clear Task", action: #selector(clearTask), keyEquivalent: "")
            clearItem.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
            clearItem.target = self
            menu.addItem(clearItem)
        }

        menu.addItem(.separator())

        if self.appModel.isTimerRunning {
            let changeTimerItem = NSMenuItem(title: "Change Timer…", action: #selector(openSetTimer), keyEquivalent: "")
            changeTimerItem.image = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)
            changeTimerItem.target = self
            menu.addItem(changeTimerItem)

            let stopTimerItem = NSMenuItem(title: "Reset Timer", action: #selector(stopTimer), keyEquivalent: "")
            stopTimerItem.image = NSImage(systemSymbolName: "stop.circle", accessibilityDescription: nil)
            stopTimerItem.target = self
            menu.addItem(stopTimerItem)
        } else {
            let setTimerItem = NSMenuItem(title: "Set Timer…", action: #selector(openSetTimer), keyEquivalent: "")
            setTimerItem.image = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)
            setTimerItem.target = self
            menu.addItem(setTimerItem)
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
    func popoverDidClose(_ notification: Notification) {
        guard let popover = notification.object as? NSPopover else { return }
        if popover === self.setTaskPopover {
            self.setTaskPopover = nil
        } else if popover === self.setTimerPopover {
            self.setTimerPopover = nil
        }
    }
}
