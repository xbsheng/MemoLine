import Foundation

/// `MemoLine --self-check` runs this instead of the app: the parts that are
/// easy to get quietly wrong, checked with no screen and no framework.
func runSelfCheck() {
    let store = FileManager.default.temporaryDirectory.appendingPathComponent("memoline-self-check.json")
    try? FileManager.default.removeItem(at: store)
    setenv("MEMOLINE_STORE", store.path, 1)

    // The rope: flat where it leaves the screen, sagging in the middle.
    check(Layout.ropeY(x: 0, width: 1000) == Layout.ropeTop, "rope starts at the top")
    check(Layout.ropeY(x: 1000, width: 1000) == Layout.ropeTop, "rope ends at the top")
    check(Layout.ropeY(x: 500, width: 1000) > Layout.ropeTop, "rope sags in the middle")

    // Cards: left to right, all on screen.
    let xs = (0..<4).map { Layout.x(index: $0, count: 4, width: 1200, visible: 4, scroll: 0) }
    check(xs == xs.sorted(), "cards are laid out in order")
    check(xs.allSatisfy { $0 > 0 && $0 < 1200 }, "cards stay on screen")
    check(Layout.x(index: 0, count: 1, width: 1200, visible: 4, scroll: 0) == 600, "one card is centred")

    // Every card hangs a little crooked, and never more than a little.
    for _ in 0..<50 {
        check(abs(Memo(text: "x").tilt) <= 2.5, "the tilt stays small")
    }

    // Memos survive the trip through the file.
    let memos = [Memo(text: "one", paper: .mint), Memo(text: "two", paper: .sky)]
    let data = try! JSONEncoder().encode(memos)
    let read = try! JSONDecoder().decode([Memo].self, from: data)
    check(read.count == 2 && read[0].text == "one" && read[1].paper == .sky && read[0].id == memos[0].id,
          "memos round-trip through JSON")

    // The line: new memos at the end, moves, take downs, a file that holds
    // what is left.
    let line = Line()
    line.soundOn = false
    line.maxItems = 3
    let a = line.add(text: "a"), b = line.add(text: "b"), c = line.add(text: "c")
    check(line.memos.map(\.text) == ["a", "b", "c"], "memos hang oldest first")
    check(line.memos.map(\.paper) != [.cream, .cream, .cream], "papers move through the palette")
    line.move(a, by: 1)
    check(line.memos.map(\.text) == ["b", "a", "c"], "a memo moves one place")

    // Dragging a card along the line: it takes the slot it is let go on, and
    // a drag that turns into pulling the text out leaves the order alone.
    line.panelWidth = 1200
    line.visibleCount = 4
    line.startReorder(b)
    line.reorder(b, toX: Layout.x(index: 2, count: 3, width: 1200, visible: 4, scroll: 0))
    check(line.memos.map(\.text) == ["a", "c", "b"], "a dragged card takes the slot it is dropped on")
    line.startReorder(b)
    line.reorder(b, toX: Layout.x(index: 0, count: 3, width: 1200, visible: 4, scroll: 0))
    line.cancelReorder(b)
    check(line.memos.map(\.text) == ["a", "c", "b"], "a drag that leaves the line puts the order back")
    line.takeDown(b)
    check(line.liveCount == 2 && line.falling.contains(b), "a taken down memo is on its way out")
    check(line.neighbours(of: c, toTheLeft: true).map(\.text) == ["a"], "neighbours are to one side")
    line.maxItems = 1
    _ = line.add(text: "d")
    check(line.liveCount == 2, "a full line drops the oldest")

    // Writing an empty memo and closing the editor takes it down again.
    line.maxItems = 3
    let empty = line.add()
    line.finishEditing(empty)
    check(line.falling.contains(empty), "an unwritten memo goes away")

    let saved = try! JSONDecoder().decode([Memo].self, from: Data(contentsOf: store))
    check(saved.allSatisfy { !line.falling.contains($0.id) }, "the file keeps no fallen memos")
    check(saved.contains { $0.text == "c" }, "the file keeps the memos still up")

    try? FileManager.default.removeItem(at: store)
    print("self-check ok")
}

private func check(_ condition: Bool, _ message: String) {
    guard condition else {
        print("self-check failed: \(message)")
        exit(1)
    }
}
