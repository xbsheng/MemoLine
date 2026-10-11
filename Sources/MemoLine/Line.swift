import AppKit
import Combine
import Foundation
import os
import SwiftUI

let log = Logger(subsystem: "app.memoline.MemoLine", category: "line")

/// The paper a memo is written on.
enum Paper: String, Codable, CaseIterable, Identifiable {
    case cream, butter, blush, sky, mint

    var id: String { rawValue }

    var nsColor: NSColor {
        switch self {
        case .cream:  return NSColor(srgbRed: 0.99, green: 0.97, blue: 0.90, alpha: 1)
        case .butter: return NSColor(srgbRed: 1.00, green: 0.93, blue: 0.70, alpha: 1)
        case .blush:  return NSColor(srgbRed: 0.99, green: 0.87, blue: 0.87, alpha: 1)
        case .sky:    return NSColor(srgbRed: 0.84, green: 0.92, blue: 0.99, alpha: 1)
        case .mint:   return NSColor(srgbRed: 0.86, green: 0.95, blue: 0.87, alpha: 1)
        }
    }

    var color: Color { Color(nsColor: nsColor) }
    /// Ink that reads on every paper in the palette.
    var ink: Color { Color(nsColor: NSColor(srgbRed: 0.16, green: 0.15, blue: 0.14, alpha: 1)) }

    var name: String {
        switch self {
        case .cream:  return L("Cream")
        case .butter: return L("Butter")
        case .blush:  return L("Blush")
        case .sky:    return L("Sky")
        case .mint:   return L("Mint")
        }
    }
}

/// One memo hanging on the line.
struct Memo: Identifiable, Codable, Equatable {
    var id = UUID()
    var text = ""
    var paper: Paper = .cream
    var createdAt = Date()

    /// Every note hangs a little crooked, and always by the same amount: the
    /// angle comes from the id, so it survives a relaunch without being stored.
    var tilt: Double { Double(id.uuid.0) / 255 * 5 - 2.5 }
}

/// The line itself: what hangs on it and what you can do with each memo.
final class Line: ObservableObject {
    @Published private(set) var memos: [Memo] = []
    /// Cards on their way down. They stay in `memos` until the fall is drawn.
    @Published private(set) var falling: Set<UUID> = []
    @Published private(set) var gust = 0
    @Published var copiedID: UUID?
    /// Being dragged out of the line as text.
    @Published var draggingID: UUID?
    /// Being dragged along the line: it takes the slot it is dropped on.
    @Published var reorderID: UUID?
    @Published var pressedID: UUID?
    /// The memo the editor is open on, if any. The line stays down meanwhile.
    @Published var editingID: UUID?
    /// Whether the line has slid down into view.
    @Published var revealed = false
    /// How far the line is scrolled towards older memos, in points; 0 shows
    /// the newest.
    @Published var scroll: CGFloat = 0

    /// Card frames in window coordinates, reported by the views. The panel
    /// uses them to only catch clicks over cards and let the rest through.
    var hitRects: [UUID: CGRect] = [:]
    /// The same for the two buttons hanging at the end of the rope.
    var controlRects: [CGRect] = []

    var maxItems = 8
    /// How many cards fit across the screen. With Keep on line set, the line
    /// can hold more, and the rest are reached by scrolling.
    var visibleCount = 8
    /// The width the cards are laid out across, kept by the app delegate.
    var panelWidth: CGFloat = 0

    /// Double click or the corner pencil: write the memo.
    var onEdit: ((Memo) -> Void)?
    /// The button at the end of the rope: tuck the line away.
    var onHide: (() -> Void)?

    /// The other button at the end of the rope: a new memo, written straight
    /// away. It goes through `edit` so the line stays down while you type.
    func newMemo() {
        edit(add())
    }

    /// Keep on line, from the menu bar: how many memos the line keeps, or nil
    /// for as many as fit across the screen.
    static let keepChoices = [25, 50, 100]
    static var keepOnLine: Int? {
        get {
            let n = UserDefaults.standard.integer(forKey: "keepOnLine")
            return keepChoices.contains(n) ? n : nil
        }
        set { UserDefaults.standard.set(newValue ?? 0, forKey: "keepOnLine") }
    }

    var soundOn: Bool {
        get { !UserDefaults.standard.bool(forKey: "soundOff") }
        set { UserDefaults.standard.set(!newValue, forKey: "soundOff") }
    }

    var liveCount: Int { memos.filter { !falling.contains($0.id) }.count }

    init() {
        restore()
        scheduleGust()
    }

    // MARK: Hanging and taking down

    /// A new memo, hung at the right end of the line with the next paper in
    /// the palette.
    @discardableResult
    func add(text: String = "") -> UUID {
        let memo = Memo(text: text, paper: Paper.allCases[memos.count % Paper.allCases.count])
        memos.append(memo)
        scroll = 0
        // A full line lets the oldest memo fall off the far end. Only one: a
        // line hung on a wider screen keeps its length here instead of losing
        // several memos at once.
        if liveCount > maxItems, let oldest = memos.first(where: { !falling.contains($0.id) }) {
            takeDown(oldest.id, quietly: true)
        }
        save()
        play("Tink", volume: 0.3)
        return memo.id
    }

    func setText(_ id: UUID, _ text: String) {
        guard let i = memos.firstIndex(where: { $0.id == id }) else { return }
        memos[i].text = text
        save()
    }

    func setPaper(_ id: UUID, _ paper: Paper) {
        guard let i = memos.firstIndex(where: { $0.id == id }) else { return }
        memos[i].paper = paper
        save()
    }

    func edit(_ id: UUID) {
        guard let memo = memos.first(where: { $0.id == id }) else { return }
        editingID = id
        onEdit?(memo)
    }

    /// The editor closed. A memo left empty was never written, so it goes
    /// the way of the corner cross.
    func finishEditing(_ id: UUID) {
        editingID = nil
        guard let memo = memos.first(where: { $0.id == id }),
              memo.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        takeDown(id)
    }

    /// Off the line, and out of the file.
    func takeDown(_ id: UUID, quietly: Bool = false) {
        guard memos.contains(where: { $0.id == id }), !falling.contains(id) else { return }
        falling.insert(id)
        hitRects[id] = nil
        save()
        if !quietly { play("Pop", volume: 0.25) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
            guard let self else { return }
            self.memos.removeAll { $0.id == id }
            self.falling.remove(id)
        }
    }

    /// "Take everything down": every memo goes the way of its corner cross.
    func clear() {
        takeDown(memos.filter { !falling.contains($0.id) }, reversed: false)
    }

    /// The memos hung before (left) or after (right) this one.
    func neighbours(of id: UUID, toTheLeft: Bool) -> [Memo] {
        let live = memos.filter { !falling.contains($0.id) }
        guard let i = live.firstIndex(where: { $0.id == id }) else { return [] }
        return toTheLeft ? Array(live[..<i]) : Array(live[(i + 1)...])
    }

    /// Takes down everything on one side of a memo.
    func takeDown(_ id: UUID, toTheLeft: Bool) {
        takeDown(neighbours(of: id, toTheLeft: toTheLeft), reversed: false)
    }

    /// One after another, and only the first makes a sound.
    private func takeDown(_ live: [Memo], reversed: Bool) {
        for (n, memo) in live.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06 * Double(n)) { [weak self] in
                self?.takeDown(memo.id, quietly: n > 0)
            }
        }
    }

    /// Moves a memo one place along the line.
    func move(_ id: UUID, by offset: Int) {
        guard let i = memos.firstIndex(where: { $0.id == id }) else { return }
        let j = i + offset
        guard memos.indices.contains(j) else { return }
        memos.swapAt(i, j)
        save()
    }

    // MARK: Dragging a card along the line

    /// The order as it was before the drag, in case it is pulled off the line
    /// into another app instead.
    private var orderBeforeDrag: [UUID]?

    func startReorder(_ id: UUID) {
        guard memos.contains(where: { $0.id == id }) else { return }
        orderBeforeDrag = memos.map(\.id)
        reorderID = id
    }

    /// The card follows the pointer: whichever slot it is over takes it, and
    /// the cards in between make room.
    func reorder(_ id: UUID, toX x: CGFloat) {
        guard reorderID == id, panelWidth > 0,
              let from = memos.firstIndex(where: { $0.id == id }) else { return }
        let to = nearestSlot(toX: x)
        guard to != from else { return }
        let memo = memos.remove(at: from)
        memos.insert(memo, at: min(to, memos.count))
    }

    /// Let go of the card: the new order stays.
    func endReorder(_ id: UUID) {
        guard reorderID == id else { return }
        reorderID = nil
        orderBeforeDrag = nil
        save()
    }

    /// Pulled off the line instead: the order goes back the way it was.
    func cancelReorder(_ id: UUID) {
        guard reorderID == id else { return }
        reorderID = nil
        if let order = orderBeforeDrag {
            let byID = Dictionary(uniqueKeysWithValues: memos.map { ($0.id, $0) })
            memos = order.compactMap { byID[$0] }
        }
        orderBeforeDrag = nil
    }

    private func nearestSlot(toX x: CGFloat) -> Int {
        var best = 0
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for index in memos.indices {
            let slot = Layout.x(index: index, count: memos.count, width: panelWidth,
                                visible: visibleCount, scroll: scroll)
            let distance = abs(slot - x)
            if distance < bestDistance {
                bestDistance = distance
                best = index
            }
        }
        return best
    }

    /// Moves along a line that holds more than fits, from a scroll gesture.
    func scroll(by delta: CGFloat) {
        let most = CGFloat(max(0, memos.count - visibleCount)) * Layout.spacing
        let next = min(most, max(0, scroll + delta))
        if next != scroll { scroll = next }
    }

    /// After Keep on line is lowered, the oldest memos past it come down.
    func trim() {
        while liveCount > maxItems, let oldest = memos.first(where: { !falling.contains($0.id) }) {
            takeDown(oldest.id, quietly: true)
        }
        scroll = 0
    }

    // MARK: Actions on one memo

    /// Click: the text goes to the clipboard, ready to paste anywhere.
    func copy(_ id: UUID) {
        guard let memo = memos.first(where: { $0.id == id }) else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(memo.text, forType: .string)

        copiedID = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            if self?.copiedID == id { self?.copiedID = nil }
        }
    }

    // MARK: Breeze

    /// Every so often a little wind moves the line. It is the detail that
    /// makes it feel like an object and not a widget.
    private func scheduleGust() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 7...16)) { [weak self] in
            guard let self else { return }
            if !self.memos.isEmpty && self.draggingID == nil { self.gust += 1 }
            self.scheduleGust()
        }
    }

    // MARK: Drawing and persistence

    /// The card as a bitmap, for the drag preview when the text is pulled
    /// into another app.
    func cardImage(for memo: Memo) -> NSImage {
        let size = NSSize(width: Layout.cardWidth, height: Layout.cardHeight)
        let image = NSImage(size: size)
        image.lockFocus()
        memo.paper.nsColor.setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size),
                     xRadius: Frame.radius, yRadius: Frame.radius).fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        paragraph.lineSpacing = 3
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12.5 * Layout.size.scale, weight: .medium),
            .foregroundColor: NSColor(srgbRed: 0.16, green: 0.15, blue: 0.14, alpha: 0.82),
            .paragraphStyle: paragraph,
        ]
        (memo.text as NSString).draw(in: NSRect(x: 15, y: 15,
                                                width: size.width - 30, height: size.height - 30),
                                     withAttributes: attributes)
        image.unlockFocus()
        return image
    }

    private static let storeURL: URL = {
        // The self-check points this at a scratch file so it never touches
        // the memos someone is actually using.
        if let path = ProcessInfo.processInfo.environment["MEMOLINE_STORE"] {
            return URL(fileURLWithPath: path)
        }
        let manager = FileManager.default
        let folder = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MemoLine", isDirectory: true)
        try? manager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("memos.json")
    }()

    /// Every change goes straight to disk, which means a write per keystroke
    /// while the editor is open.
    // ponytail: whole file per edit. Fine for the handful of notes a line
    // holds; debounce it if a line ever carries hundreds.
    private func save() {
        let alive = memos.filter { !falling.contains($0.id) }
        do {
            try JSONEncoder().encode(alive).write(to: Self.storeURL, options: .atomic)
        } catch {
            log.error("Could not save the memos: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func restore() {
        guard let data = try? Data(contentsOf: Self.storeURL),
              let saved = try? JSONDecoder().decode([Memo].self, from: data) else { return }
        memos = saved
    }

    private func play(_ name: String, volume: Float) {
        guard soundOn, let sound = NSSound(named: name)?.copy() as? NSSound else { return }
        sound.volume = volume
        sound.play()
    }
}
