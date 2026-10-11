import AppKit
import Carbon
import Combine
import ServiceManagement
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let line = Line()
    private var panel: LinePanel!
    private var statusItem: NSStatusItem!
    private var toggleKey: HotKey?
    private var newMemoKey: HotKey?
    private var cancellables = Set<AnyCancellable>()
    private var mouseTimer: Timer?
    private var clickMonitors: [Any] = []

    /// Whether the panel is ordered in. It can be in and still tucked away
    /// above the top edge, like an auto-hiding Dock.
    private var isPresent = false
    /// Whether the line has slid down into view.
    private var isRevealed = false
    /// Opened on purpose with the shortcut or the menu: it stays down until
    /// the cursor has visited it and left, or the shortcut is pressed again.
    private var pinned = false
    /// A new memo shows itself for a moment, then tucks away.
    private var peekUntil = Date.distantPast
    private var hotZoneSince: Date?
    /// After a click in the menu bar the line stays up there hidden until the
    /// pointer leaves the menu bar, so it does not come back over a menu.
    private var menuBarSuppressed = false
    private var awaySince: Date?
    /// Whether the line should be up, if nothing prevents it. A full screen
    /// app on that screen does: the line waits until you leave full screen.
    private var wanted = false
    /// Set when you open the line on purpose, so it stays up while empty.
    private var keepOpen = false

    // What brings the line down, from the menu bar's "Bring the line down".
    // Out of the box, the first two are on and the third off.

    /// Resting the pointer in the menu bar. Off, only the shortcut and the
    /// menu open it.
    static var opensFromMenuBar: Bool {
        get { !UserDefaults.standard.bool(forKey: "menuBarRevealOff") }
        set { UserDefaults.standard.set(!newValue, forKey: "menuBarRevealOff") }
    }

    /// Something new hanging shows itself for a moment. Off, it hangs
    /// quietly and waits for you to bring the line down.
    static var peeksAtNew: Bool {
        get { !UserDefaults.standard.bool(forKey: "quietHang") }
        set { UserDefaults.standard.set(!newValue, forKey: "quietHang") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let host = NSHostingView(rootView: LineView(line: line))
        host.sizingOptions = []
        panel = LinePanel(content: host)
        panel.placeOnScreen()
        updateCapacity()

        registerShortcuts()
        setUpMenu()
        setUpStatusItem()
        watchMenuBarClicks()

        panel.onScroll = { [weak self] event in
            // Sideways on a trackpad, or the wheel of a mouse.
            let delta = abs(event.scrollingDeltaX) >= abs(event.scrollingDeltaY)
                ? event.scrollingDeltaX : event.scrollingDeltaY
            self?.line.scroll(by: event.hasPreciseScrollingDeltas ? delta : delta * 12)
        }
        line.onEdit = { [weak self] memo in self?.openEditor(for: memo) }
        line.onHide = { [weak self] in self?.hide() }

        line.$memos
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.memosChanged() }
            .store(in: &cancellables)
        // Memos kept from last time show themselves for a moment.
        if line.liveCount > 0 { comeDown(on: nil) }

        // Entering or leaving full screen switches Space. Check again once the
        // switch animation has settled.
        let workspace = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.activeSpaceDidChangeNotification, NSWorkspace.didActivateApplicationNotification] {
            workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.refresh()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self?.refresh() }
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.panel.placeOnScreen()
            self?.updateCapacity()
        }


        // First launch: the line comes down for a moment and says how to
        // start writing, then tucks itself away again.
        if !UserDefaults.standard.bool(forKey: "welcomed") {
            UserDefaults.standard.set(true, forKey: "welcomed")
            keepOpen = true
            wanted = true
            refresh()
            reveal(pinned: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
                guard let self, self.line.memos.isEmpty else { return }
                self.keepOpen = false
                self.wanted = false
                self.refresh()
            }
        }
    }

    // MARK: Writing

    /// A new note, hung at the right end of the line, with the editor open
    /// on it straight away.
    private func newMemo() {
        keepOpen = true
        wanted = true
        panel.placeOnScreen()
        updateCapacity()
        refresh()
        reveal(pinned: true)
        line.edit(line.add())
    }

    private func openEditor(for memo: Memo) {
        keepOpen = true
        wanted = true
        refresh()
        reveal(pinned: true)

        let visible = (panel.screen ?? LinePanel.screenUnderPointer())?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        MemoEditor.shared.edit(
            memo,
            top: panel.frame.minY,
            centerX: cardCenterX(for: memo.id) ?? visible.midX,
            screen: visible,
            commit: { [weak self] text in self?.line.setText(memo.id, text) },
            paper: { [weak self] paper in self?.line.setPaper(memo.id, paper) },
            close: { [weak self] in
                guard let self else { return }
                self.keepOpen = false
                self.line.finishEditing(memo.id)
                self.refresh()
            })
    }

    /// Where a card hangs across the screen, in screen coordinates, using the
    /// same layout as the line view.
    private func cardCenterX(for id: UUID) -> CGFloat? {
        guard let index = line.memos.firstIndex(where: { $0.id == id }), panel.frame.width > 0 else { return nil }
        let x = Layout.x(index: index, count: line.memos.count, width: panel.frame.width,
                         visible: line.visibleCount, scroll: line.scroll)
        return panel.frame.minX + x
    }

    private func clearAll() {
        guard line.liveCount > 0 else { return }
        let alert = NSAlert()
        alert.messageText = L("Take everything down?")
        alert.informativeText = L("Every memo on the line will be deleted.")
        alert.addButton(withTitle: L("Delete"))
        alert.addButton(withTitle: L("Cancel"))
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn { line.clear() }
    }

    // MARK: Showing and hiding

    /// An empty line goes away, unless it was opened on purpose.
    private func memosChanged() {
        guard line.liveCount == 0, !keepOpen else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self, self.line.liveCount == 0, !self.keepOpen else { return }
            self.wanted = false
            self.refresh()
        }
    }

    /// The line comes down on that screen for a moment, then tucks away.
    /// Without a screen, it uses the one under the pointer.
    private func comeDown(on screen: NSScreen?) {
        panel.placeOnScreen(screen)
        updateCapacity()
        wanted = true
        refresh()
        if Self.peeksAtNew { reveal(peekFor: 2.5) }
    }

    /// Decides whether the panel is ordered in at all: something to show,
    /// and no full screen app on that screen.
    private func refresh() {
        let blocked = panel.screen.map(FullScreen.blocksLine(on:))
            ?? LinePanel.screenUnderPointer().map(FullScreen.blocksLine(on:)) ?? false
        if wanted && !blocked {
            present()
        } else {
            dismiss()
        }
        // The cursor is watched even when nothing hangs on the line: resting
        // in the menu bar is how the line is brought down when empty, so the
        // hint can say how to start.
        startMouseTracking()
    }

    private func present() {
        guard !isPresent else { return }
        isPresent = true
        panel.alphaValue = 1
        // The window itself only comes in while the line is down; see setRevealed.
        if isRevealed { panel.orderFrontRegardless() }
    }

    private func dismiss() {
        guard isPresent else { return }
        isPresent = false
        setRevealed(false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, !self.isPresent else { return }
            self.panel.orderOut(nil)
        }
    }

    private func reveal(pinned: Bool = false, peekFor seconds: TimeInterval = 0) {
        guard isPresent else { return }
        if pinned { self.pinned = true }
        if seconds > 0 { peekUntil = Date().addingTimeInterval(seconds) }
        awaySince = nil
        setRevealed(true)
    }

    private func setRevealed(_ on: Bool) {
        guard on != isRevealed else { return }
        isRevealed = on
        line.revealed = on
        // It always comes down showing the newest.
        if on { line.scroll = 0 }
        // Tucked away, the line leaves no window behind: an invisible strip
        // over the top of the screen would still sit above other apps for
        // anything that checks what is on top, like screen automation.
        if on {
            if isPresent { panel.orderFrontRegardless() }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self, !self.isRevealed else { return }
                self.panel.orderOut(nil)
            }
        }
        if !on {
            pinned = false
            peekUntil = .distantPast
            panel.ignoresMouseEvents = true
        }
    }

    private func toggle() {
        if isRevealed {
            hide()
        } else {
            keepOpen = true
            wanted = true
            panel.placeOnScreen()
            updateCapacity()
            refresh()
            reveal(pinned: true)
        }
    }

    /// Tucks the line away. An empty one leaves nothing behind.
    private func hide() {
        setRevealed(false)
        if line.liveCount == 0 {
            keepOpen = false
            wanted = false
            refresh()
        }
    }

    private func startMouseTracking() {
        guard mouseTimer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 30.0, target: self, selector: #selector(tick),
                          userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        mouseTimer = timer
    }

    /// How long the cursor rests against the top edge before the line comes
    /// down. Short enough to feel instant, long enough that a quick trip to
    /// the menu bar does not trigger it.
    private static let revealDelay: TimeInterval = 0.25
    /// How long the cursor is away before the line tucks back up.
    private static let retractDelay: TimeInterval = 0.5

    /// The menu bar strip at the top of a screen. With an auto-hiding menu
    /// bar the visible frame reaches the top, so the system thickness is used.
    static func menuBarBand(of screen: NSScreen) -> NSRect {
        var h = screen.frame.maxY - screen.visibleFrame.maxY
        if h < 1 { h = max(NSStatusBar.system.thickness, screen.safeAreaInsets.top) }
        return NSRect(x: screen.frame.minX, y: screen.frame.maxY - h, width: screen.frame.width, height: h)
    }

    /// A click anywhere in the top bar of any screen, a menu or an icon, puts
    /// the line away.
    private func watchMenuBarClicks() {
        let handler: (NSEvent?) -> Void = { [weak self] _ in
            guard let self else { return }
            let p = NSEvent.mouseLocation
            guard NSScreen.screens.contains(where: { NSMouseInRect(p, Self.menuBarBand(of: $0), false) }) else { return }
            self.menuBarSuppressed = true
            self.hotZoneSince = nil
            if self.isRevealed {
                self.pinned = false
                self.setRevealed(false)
            }
        }
        if let global = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: handler) {
            clickMonitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { event in
            handler(event)
            return event
        }) {
            clickMonitors.append(local)
        }
    }

    @objc private func tick() {
        let mouse = NSEvent.mouseLocation
        let now = Date()

        let screenUnderPointer = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
        let inMenuBar = screenUnderPointer.map { NSMouseInRect(mouse, Self.menuBarBand(of: $0), false) } ?? false
        if !inMenuBar { menuBarSuppressed = false }

        guard isRevealed else {
            // Resting in the menu bar brings the line down on that screen.
            // Pushing against the top edge is part of it, and it also works
            // when another display sits above and the pointer never stops.
            if Self.opensFromMenuBar, let screen = screenUnderPointer, inMenuBar, !menuBarSuppressed,
               !FullScreen.blocksLine(on: screen) {
                let since = hotZoneSince ?? now
                hotZoneSince = since
                if now.timeIntervalSince(since) >= Self.revealDelay {
                    hotZoneSince = nil
                    if panel.screen != screen {
                        panel.placeOnScreen()
                        updateCapacity()
                    }
                    wanted = true
                    refresh()
                    reveal()
                }
            } else {
                hotZoneSince = nil
            }
            return
        }

        updateMousePassThrough(mouse)

        // The line's zone runs from its lowest point up to the top of the
        // screen, menu bar included, so moving up never hides it.
        var zone = panel.frame
        if let screen = panel.screen { zone.size.height = screen.frame.maxY - zone.minY }
        let inside = NSMouseInRect(mouse, zone, false)
        if inside && pinned { pinned = false }

        let busy = pinned || GrabView.isDragging || GrabView.isShowingMenu
            || line.pressedID != nil || line.editingID != nil || now < peekUntil
        if inside || busy {
            awaySince = nil
        } else {
            let since = awaySince ?? now
            awaySince = since
            if now.timeIntervalSince(since) >= Self.retractDelay {
                awaySince = nil
                setRevealed(false)
                // An empty line leaves nothing behind: it takes itself out
                // until the menu bar asks for it again.
                if line.liveCount == 0 && !keepOpen {
                    wanted = false
                    refresh()
                }
            }
        }
    }

    /// The panel spans the whole width of the screen, so it only accepts the
    /// mouse while the cursor is over a card. Everywhere else, clicks go to
    /// whatever is underneath.
    private func updateMousePassThrough(_ mouse: NSPoint) {
        // A card being dragged along the line, or out of it, keeps the whole
        // panel live: the pointer must not fall through mid-drag.
        guard !GrabView.isDragging, line.reorderID == nil else { return }
        let local = panel.convertPoint(fromScreen: mouse)
        let flipped = CGPoint(x: local.x, y: panel.frame.height - local.y)
        var overCard = line.hitRects.values.contains { $0.insetBy(dx: -4, dy: -4).contains(flipped) }
        // The two buttons at the end of the rope take clicks too.
        if !overCard {
            overCard = line.controlRects.contains { $0.insetBy(dx: -4, dy: -4).contains(flipped) }
        }
        // A line longer than the screen also takes the band the cards hang
        // in, gaps included, so a swipe anywhere along it moves it.
        if !overCard, line.memos.count > line.visibleCount, Line.keepOnLine != nil {
            let band = line.hitRects.values.reduce(CGRect.null) { $0.union($1) }
            overCard = !band.isNull && flipped.y >= band.minY - 4 && flipped.y <= band.maxY + 4
        }
        if panel.ignoresMouseEvents == overCard {
            panel.ignoresMouseEvents = !overCard
        }
    }

    // MARK: Shortcut

    private func registerShortcuts() {
        toggleKey = nil
        newMemoKey = nil
        if let shortcut = Shortcut.current {
            toggleKey = HotKey(shortcut) { [weak self] in self?.toggle() }
        }
        // ⌃⌥N always makes a new memo. It is not offered for changing: one
        // shortcut to remember is enough.
        newMemoKey = HotKey(Shortcut(keyCode: kVK_ANSI_N, modifiers: [.control, .option], key: "n")) { [weak self] in
            self?.newMemo()
        }
    }

    private func changeShortcut() {
        // Off while recording, so pressing the current one records it
        // instead of showing the line.
        toggleKey = nil
        ShortcutRecorder.shared.record { [weak self] result in
            guard let self else { return }
            if let result {
                let previous = Shortcut.current
                Shortcut.current = result
                self.registerShortcuts()
                // Taken by another app: keep the one that worked.
                if result != nil && self.toggleKey == nil {
                    NSSound.beep()
                    Shortcut.current = previous
                }
            }
            self.registerShortcuts()
        }
    }

    private func setKeep(_ n: Int?) {
        guard n != Line.keepOnLine else { return }
        Line.keepOnLine = n
        updateCapacity()
        line.trim()
    }

    private func setSize(_ size: Layout.Size) {
        guard size != Layout.size else { return }
        Layout.size = size
        panel.placeOnScreen(panel.screen)
        updateCapacity()
    }

    private func updateCapacity() {
        line.panelWidth = panel.frame.width
        let usable = panel.frame.width - 200
        let fits = max(3, min(12, Int(usable / Layout.spacing)))
        line.visibleCount = fits
        line.maxItems = max(fits, Line.keepOnLine ?? fits)
    }

    // MARK: Menu bar

    /// An accessory app never draws a menu bar, but ⌘C, ⌘V, ⌘X, ⌘A and ⌘Z are
    /// still delivered through it: with no Edit menu they do nothing at all,
    /// not even in the editor.
    private func setUpMenu() {
        let main = NSMenu()
        let editItem = NSMenuItem()
        let edit = NSMenu(title: L("Edit"))
        edit.addItem(withTitle: L("Undo"), action: Selector(("undo:")), keyEquivalent: "z")
        let redo = edit.addItem(withTitle: L("Redo"), action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        edit.addItem(.separator())
        edit.addItem(withTitle: L("Cut"), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: L("Copy"), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: L("Paste"), action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: L("Select All"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        main.addItem(editItem)

        // Quit works with ⌘Q while the app is the active one, the way it does
        // everywhere else on the Mac.
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "MemoLine")
        appMenu.addItem(withTitle: L("Quit MemoLine"), action: #selector(NSApplication.terminate(_:)),
                        keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)

        NSApp.mainMenu = main
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let description = L("MemoLine, memos on a clothesline")
        let image = NSImage(systemSymbolName: "note.text", accessibilityDescription: description)
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = description
        let menu = NSMenu()
        // Items say themselves whether they can be used, like Take everything
        // down on an empty line.
        menu.autoenablesItems = false
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let toggleItem = ClosureMenuItem(isRevealed ? L("Hide line") : L("Show line")) { [weak self] in
            self?.toggle()
        }
        if let shortcut = Shortcut.current, shortcut.key.count == 1 {
            toggleItem.keyEquivalent = shortcut.key
            toggleItem.keyEquivalentModifierMask = shortcut.modifiers
        }
        menu.addItem(toggleItem)

        menu.addItem(ClosureMenuItem(L("New Memo"), key: "n") { [weak self] in self?.newMemo() })

        let clearItem = ClosureMenuItem(L("Take everything down")) { [weak self] in self?.clearAll() }
        clearItem.isEnabled = line.liveCount > 0
        menu.addItem(clearItem)

        let bringDown = NSMenuItem(title: L("Bring the line down"), action: nil, keyEquivalent: "")
        let options = NSMenu()
        let hover = ClosureMenuItem(L("When the pointer rests in the menu bar")) {
            AppDelegate.opensFromMenuBar.toggle()
        }
        hover.state = Self.opensFromMenuBar ? .on : .off
        options.addItem(hover)
        let peek = ClosureMenuItem(L("When something new hangs")) {
            AppDelegate.peeksAtNew.toggle()
        }
        peek.state = Self.peeksAtNew ? .on : .off
        options.addItem(peek)
        let fullScreen = ClosureMenuItem(L("Over full screen apps")) { [weak self] in
            FullScreen.showLineOver.toggle()
            self?.refresh()
        }
        fullScreen.state = FullScreen.showLineOver ? .on : .off
        options.addItem(fullScreen)
        bringDown.submenu = options
        menu.addItem(bringDown)

        let keepItem = NSMenuItem(title: L("Keep on line"), action: nil, keyEquivalent: "")
        let keeps = NSMenu()
        let fit = ClosureMenuItem(L("As many as fit")) { [weak self] in self?.setKeep(nil) }
        fit.state = Line.keepOnLine == nil ? .on : .off
        keeps.addItem(fit)
        for n in Line.keepChoices {
            let item = ClosureMenuItem(String(format: L("%d memos"), n)) { [weak self] in self?.setKeep(n) }
            item.state = Line.keepOnLine == n ? .on : .off
            keeps.addItem(item)
        }
        keepItem.submenu = keeps
        menu.addItem(keepItem)

        let sizeItem = NSMenuItem(title: L("Size"), action: nil, keyEquivalent: "")
        let sizes = NSMenu()
        for (size, title) in [(Layout.Size.small, L("Small")), (.medium, L("Medium")), (.large, L("Large"))] {
            let item = ClosureMenuItem(title) { [weak self] in self?.setSize(size) }
            item.state = Layout.size == size ? .on : .off
            sizes.addItem(item)
        }
        sizeItem.submenu = sizes
        menu.addItem(sizeItem)

        let shortcutItem = NSMenuItem(title: L("Shortcut"), action: nil, keyEquivalent: "")
        let shortcuts = NSMenu()
        let current = NSMenuItem(title: String(format: L("%@ to show the line"), Shortcut.current?.display ?? L("None")),
                                 action: nil, keyEquivalent: "")
        current.isEnabled = false
        shortcuts.addItem(current)
        let newMemoShortcut = NSMenuItem(title: String(format: L("%@ for a new memo"), "⌃⌥N"),
                                         action: nil, keyEquivalent: "")
        newMemoShortcut.isEnabled = false
        shortcuts.addItem(newMemoShortcut)
        shortcuts.addItem(ClosureMenuItem(L("Change Shortcut…")) { [weak self] in self?.changeShortcut() })
        shortcutItem.submenu = shortcuts
        menu.addItem(shortcutItem)

        menu.addItem(.separator())

        let sound = ClosureMenuItem(L("Sounds")) { [weak self] in
            self?.line.soundOn.toggle()
        }
        sound.state = line.soundOn ? .on : .off
        menu.addItem(sound)

        let login = ClosureMenuItem(L("Open at login")) {
            AppDelegate.toggleLaunchAtLogin()
        }
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(L("Quit MemoLine"), key: "q") {
            NSApp.terminate(nil)
        })
    }

    private static func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = L("Could not change the login setting")
            alert.informativeText = L("Move MemoLine to the Applications folder and try again.")
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }
}
