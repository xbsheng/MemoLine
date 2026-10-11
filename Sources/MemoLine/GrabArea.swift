import AppKit
import SwiftUI

/// Bridges each card to AppKit's drag and drop, so its text can be pulled
/// into any app. Dropped inside MemoLine nothing happens and the card slides
/// back; dropped anywhere that takes text, the text lands there and the memo
/// stays on the line.
///
/// Click writes the memo. The corner copy button copies, the cross takes it
/// down, right click opens the menu.
struct GrabArea: NSViewRepresentable {
    let memo: Memo
    let line: Line

    func makeNSView(context: Context) -> GrabView {
        let view = GrabView()
        configure(view)
        return view
    }

    func updateNSView(_ view: GrabView, context: Context) {
        configure(view)
    }

    private func configure(_ view: GrabView) {
        let id = memo.id
        let line = line
        view.text = memo.text
        view.makeDragImage = { line.cardImage(for: memo) }
        view.onClick = { line.edit(id) }
        view.onCopy = { line.copy(id) }
        view.onDoubleClick = { line.edit(id) }
        view.onDragStart = { line.draggingID = id }
        view.onDragEnd = { line.draggingID = nil }
        view.onReorderStart = { line.startReorder(id) }
        view.onReorderMove = { x in line.reorder(id, toX: x) }
        view.onReorderEnd = { line.endReorder(id) }
        view.onReorderCancel = { line.cancelReorder(id) }
        view.onTakeDown = { line.takeDown(id) }
        view.onPressChange = { pressed in line.pressedID = pressed ? id : nil }
        view.menuProvider = {
            let menu = NSMenu()
            // Items say themselves whether they can be used.
            menu.autoenablesItems = false
            menu.addItem(ClosureMenuItem(L("Edit")) { line.edit(id) })
            menu.addItem(ClosureMenuItem(L("Copy")) { line.copy(id) })
            menu.addItem(ClosureMenuItem(L("New Memo")) { [weak line] in
                guard let line else { return }
                line.edit(line.add())
            })

            let paperItem = NSMenuItem(title: L("Paper"), action: nil, keyEquivalent: "")
            let papers = NSMenu()
            for paper in Paper.allCases {
                let item = ClosureMenuItem(paper.name) { line.setPaper(id, paper) }
                item.state = memo.paper == paper ? .on : .off
                papers.addItem(item)
            }
            paperItem.submenu = papers
            menu.addItem(paperItem)

            let left = ClosureMenuItem(L("Move Left")) { line.move(id, by: -1) }
            left.isEnabled = !line.neighbours(of: id, toTheLeft: true).isEmpty
            menu.addItem(left)
            let right = ClosureMenuItem(L("Move Right")) { line.move(id, by: 1) }
            right.isEnabled = !line.neighbours(of: id, toTheLeft: false).isEmpty
            menu.addItem(right)

            menu.addItem(.separator())
            menu.addItem(ClosureMenuItem(L("Take Down")) { line.takeDown(id) })
            let allLeft = ClosureMenuItem(L("Take down everything to the left")) { line.takeDown(id, toTheLeft: true) }
            allLeft.isEnabled = !line.neighbours(of: id, toTheLeft: true).isEmpty
            menu.addItem(allLeft)
            let allRight = ClosureMenuItem(L("Take down everything to the right")) { line.takeDown(id, toTheLeft: false) }
            allRight.isEnabled = !line.neighbours(of: id, toTheLeft: false).isEmpty
            menu.addItem(allRight)
            return menu
        }
    }
}

final class GrabView: NSView, NSDraggingSource {
    static var isDragging = false
    /// A card's menu is open. It reaches past the line, so the line waits.
    static var isShowingMenu = false

    /// What the pointer is over, in the corners of the card.
    private enum Corner { case copy, cross }

    var text = ""
    var makeDragImage: () -> NSImage? = { nil }
    var onClick: () -> Void = {}
    var onCopy: () -> Void = {}
    var onDoubleClick: () -> Void = {}
    var onDragStart: () -> Void = {}
    var onDragEnd: () -> Void = {}
    var onReorderStart: () -> Void = {}
    var onReorderMove: (CGFloat) -> Void = { _ in }
    var onReorderEnd: () -> Void = {}
    var onReorderCancel: () -> Void = {}
    var onTakeDown: () -> Void = {}
    var onPressChange: (Bool) -> Void = { _ in }
    var menuProvider: () -> NSMenu = { NSMenu() }

    private var downPoint: NSPoint?
    private var startedDrag = false
    private var reordering = false
    private var holdTimer: Timer?
    private var didLongPress = false

    /// How long you hold before the editor opens. Long enough not to fire on
    /// a slow click, short enough to feel deliberate.
    private static let holdDuration: TimeInterval = 0.45

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    /// Where the corner buttons are drawn; the same 26 points as in the card.
    static let cornerSize: CGFloat = 26

    private func corner(_ event: NSEvent) -> Corner? {
        let p = convert(event.locationInWindow, from: nil)
        let y = isFlipped ? 0 : bounds.height - Self.cornerSize
        let left = NSRect(x: 0, y: y, width: Self.cornerSize, height: Self.cornerSize)
        let right = NSRect(x: bounds.width - Self.cornerSize, y: y,
                           width: Self.cornerSize, height: Self.cornerSize)
        if left.contains(p) { return .copy }
        if right.contains(p) { return .cross }
        return nil
    }

    override func mouseDown(with event: NSEvent) {
        switch corner(event) {
        case .copy:
            downPoint = nil
            onCopy()
            return
        case .cross:
            downPoint = nil
            onTakeDown()
            return
        case nil:
            break
        }
        if event.clickCount == 2 {
            downPoint = nil
            onDoubleClick()
            return
        }
        downPoint = event.locationInWindow
        startedDrag = false
        reordering = false
        didLongPress = false
        onPressChange(true)
        holdTimer?.invalidate()
        holdTimer = Timer.scheduledTimer(withTimeInterval: Self.holdDuration, repeats: false) { [weak self] _ in
            guard let self, self.downPoint != nil, !self.startedDrag else { return }
            self.didLongPress = true
            self.onPressChange(false)
            self.onClick()
        }
    }

    /// A force click on a trackpad opens the editor, as it does in Finder.
    /// It counts instead of the click and of a long press.
    override func pressureChange(with event: NSEvent) {
        guard event.stage == 2, downPoint != nil, !startedDrag, !didLongPress else { return }
        didLongPress = true
        endPress()
        onClick()
    }

    private func endPress() {
        holdTimer?.invalidate()
        holdTimer = nil
        onPressChange(false)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = downPoint, !didLongPress else { return }
        let p = event.locationInWindow
        let onLine = window?.contentView.map { $0.bounds.contains(p) } ?? false

        if reordering {
            if onLine {
                onReorderMove(p.x)
                return
            }
            // Slid off the bottom: the order it was dragged away from comes
            // back and the text leaves as a real drag instead.
            cancelReorderIfNeeded()
        }
        guard !startedDrag, hypot(p.x - start.x, p.y - start.y) > 4 else { return }

        if onLine {
            reordering = true
            endPress()
            onReorderStart()
            onReorderMove(p.x)
            return
        }

        guard !text.isEmpty, let image = makeDragImage() else { return }
        startedDrag = true
        endPress()

        let item = NSDraggingItem(pasteboardWriter: text as NSString)
        item.setDraggingFrame(imageFrame(for: image, at: p), contents: image)
        let session = beginDraggingSession(with: [item], event: event, source: self)
        // Released where nothing accepts it: it flies back to the line.
        session.animatesToStartingPositionsOnCancelOrFail = true
        GrabView.isDragging = true
        onDragStart()
    }

    override func mouseUp(with event: NSEvent) {
        endPress()
        defer {
            downPoint = nil
            didLongPress = false
        }
        if reordering {
            reordering = false
            onReorderEnd()
            return
        }
        if downPoint != nil && !startedDrag && !didLongPress && event.clickCount == 1 { onClick() }
    }

    override func rightMouseDown(with event: NSEvent) {
        // The menu runs until it closes, and the line stays down meanwhile.
        GrabView.isShowingMenu = true
        NSMenu.popUpContextMenu(menuProvider(), with: event, for: self)
        GrabView.isShowingMenu = false
    }

    // MARK: NSDraggingSource

    func draggingSession(_ session: NSDraggingSession,
                         sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        context == .outsideApplication ? [.copy] : []
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        GrabView.isDragging = false
        startedDrag = false
        downPoint = nil
        onDragEnd()
    }

    /// The drag preview, centred on the pointer: by the time the text leaves
    /// the card the pointer is already off the line, and the preview should
    /// be where the pointer is, not where the card was.
    private func imageFrame(for image: NSImage, at point: NSPoint) -> NSRect {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return bounds }
        let scale = min(bounds.width / size.width, bounds.height / size.height)
        let w = size.width * scale, h = size.height * scale
        return NSRect(x: point.x - w / 2, y: point.y - h / 2, width: w, height: h)
    }

    /// A card that was already moving along the line before the pointer slid
    /// off it: the order it was dragged away from comes back.
    private func cancelReorderIfNeeded() {
        guard reordering else { return }
        reordering = false
        onReorderCancel()
    }
}

final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, key: String = "", handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(fire), keyEquivalent: key)
        target = self
    }

    required init(coder: NSCoder) { fatalError() }

    @objc private func fire() { handler() }
}
