import SwiftUI

enum Layout {
    /// How big the cards hang, from Size in the menu bar. The clip and the
    /// rope keep their size; the cards and the room they take grow or shrink.
    /// Medium is the original size.
    enum Size: String, CaseIterable {
        case small, medium, large

        var scale: CGFloat {
            switch self {
            case .small:  return 0.8
            case .medium: return 1
            case .large:  return 1.35
            }
        }
    }

    static var size: Size {
        get { Size(rawValue: UserDefaults.standard.string(forKey: "lineSize") ?? "") ?? .medium }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "lineSize") }
    }

    static var cardWidth: CGFloat { (168 * size.scale).rounded() }
    static var cardHeight: CGFloat { (122 * size.scale).rounded() }
    static var spacing: CGFloat { cardWidth + 24 }
    static var panelHeight: CGFloat { cardHeight + 110 }
    static let ropeTop: CGFloat = 10
    static let pinAbove: CGFloat = 9.5

    /// How much of each end of the rope is faded away. A fixed 40 points, so
    /// it looks the same on a laptop screen and on an ultrawide one.
    static func ropeFade(width: CGFloat) -> CGFloat { min(0.08, 40 / max(width, 1)) }

    /// The rope hangs as a parabola from edge to edge of the screen.
    static func sag(width: CGFloat) -> CGFloat { min(30, width * 0.018) }

    static func ropeY(x: CGFloat, width: CGFloat) -> CGFloat {
        guard width > 0 else { return ropeTop }
        let f = x / width
        return ropeTop + 4 * sag(width: width) * f * (1 - f)
    }

    /// Cards hang `spacing` apart, centred. When there are more than the
    /// `visible` that fit: with Keep on line set, they keep their spacing,
    /// the newest stays where the last one would hang on a full line, and
    /// `scroll` brings older ones in from the left. Otherwise (a line hung
    /// on a wider screen) they move closer together so none is past the edge.
    static func x(index: Int, count: Int, width: CGFloat, visible: Int, scroll: CGFloat) -> CGFloat {
        if Line.keepOnLine != nil && count > visible {
            let newest = width / 2 + CGFloat(visible - 1) * spacing / 2
            return newest - CGFloat(count - 1 - index) * spacing + scroll
        }
        let gaps = CGFloat(max(count - 1, 0))
        let step = gaps > 0 ? min(spacing, max(0, width - 200) / gaps) : spacing
        return width / 2 - gaps * step / 2 + CGFloat(index) * step
    }
}

struct LineView: View {
    @ObservedObject var line: Line

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack(alignment: .topLeading) {
                Rope(width: width)

                if line.liveCount == 0 && line.falling.isEmpty {
                    Hint()
                        .position(x: width / 2, y: Layout.ropeY(x: width / 2, width: width) + 34)
                        .transition(.opacity)
                }

                ForEach(Array(line.memos.enumerated()), id: \.element.id) { index, memo in
                    let x = Layout.x(index: index, count: line.memos.count, width: width,
                                     visible: line.visibleCount, scroll: line.scroll)
                    let ropeY = Layout.ropeY(x: x, width: width)
                    MemoView(memo: memo, line: line)
                        .frame(width: Layout.cardWidth, height: Layout.panelHeight - ropeY, alignment: .top)
                        // Cards scrolled towards an edge fade out before they reach it.
                        .opacity(min(1, max(0, min(x, width - x) / 90)))
                        .position(x: x, y: ropeY - Layout.pinAbove + (Layout.panelHeight - ropeY) / 2)
                }

                LineControls(line: line, width: width)
                    .frame(width: width, height: Layout.panelHeight, alignment: .topLeading)
            }
            // Cards shuffle quickly while one is being dragged along the
            // line, and settle with a spring when the drag is over.
            .animation(line.reorderID == nil ? .spring(response: 0.55, dampingFraction: 0.78)
                                             : .interactiveSpring(response: 0.24, dampingFraction: 0.86),
                       value: line.memos.map(\.id))
            .animation(.easeInOut(duration: 0.3), value: line.liveCount == 0)
            // Tucked away, the whole line waits above the top edge and slides
            // out from under the menu bar, the way an auto-hiding Dock does.
            .offset(y: line.revealed ? 0 : -(Layout.panelHeight + 12))
            .animation(line.revealed ? .spring(response: 0.42, dampingFraction: 0.82)
                                     : .easeIn(duration: 0.22), value: line.revealed)
        }
        .onPreferenceChange(HitRectsKey.self) { rects in
            line.hitRects = rects
        }
        .onPreferenceChange(ControlRectsKey.self) { rects in
            line.controlRects = rects
        }
    }
}

private struct Hint: View {
    var body: some View {
        Text(L("No memos yet. Press ⌃⌥N to write one."))
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: Capsule())
    }
}

/// A thin, neutral line: a mid gray core with a faint highlight and a soft
/// shadow, so it reads on light and dark backgrounds alike. It fades out at
/// both ends so it seems to come from beyond the screen.
struct Rope: View {
    let width: CGFloat

    private var path: Path {
        Path { p in
            let top = Layout.ropeTop
            p.move(to: CGPoint(x: -20, y: top))
            p.addQuadCurve(
                to: CGPoint(x: width + 20, y: top),
                control: CGPoint(x: width / 2, y: top + 2 * Layout.sag(width: width)))
        }
    }

    var body: some View {
        ZStack {
            path.stroke(Color.black.opacity(0.22), lineWidth: 1.4).offset(y: 1.2).blur(radius: 1.2)
            path.stroke(Color(white: 0.55), lineWidth: 1.2)
            path.stroke(Color.white.opacity(0.45), lineWidth: 0.4).offset(y: -0.35)
        }
        // A short fade at each end, so the rope still reads where the buttons
        // hang: a long one would leave them hanging on nothing.
        .mask(
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: Layout.ropeFade(width: width)),
                .init(color: .black, location: 1 - Layout.ropeFade(width: width)),
                .init(color: .clear, location: 1),
            ], startPoint: .leading, endPoint: .trailing)
        )
        .allowsHitTesting(false)
    }
}

/// The two things you do to the whole line, hung at the end of the rope like
/// everything else: write a new memo, or tuck the line away.
struct LineControls: View {
    @ObservedObject var line: Line
    let width: CGFloat

    private var newX: CGFloat { width - 54 }
    private var hideX: CGFloat { width - 104 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RopeButton(symbol: "plus", help: L("New Memo")) { line.newMemo() }
                .position(x: newX, y: Layout.ropeY(x: newX, width: width) + 24)
            RopeButton(symbol: "chevron.up", help: L("Hide line")) { line.onHide?() }
                .position(x: hideX, y: Layout.ropeY(x: hideX, width: width) + 24)
        }
    }
}

private struct RopeButton: View {
    let symbol: String
    let help: String
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 26, height: 26)
                .glassFrame(circle: true)
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering ? 1.1 : 1)
        .shadow(color: .black.opacity(hovering ? 0.22 : 0.12), radius: hovering ? 6 : 4, y: 2)
        .animation(.easeOut(duration: 0.15), value: hovering)
        .onHover { hovering = $0 }
        .help(help)
        .background(
            GeometryReader { g in
                Color.clear.preference(key: ControlRectsKey.self, value: [g.frame(in: .global)])
            }
        )
    }
}

struct ControlRectsKey: PreferenceKey {
    static var defaultValue: [CGRect] = []
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value.append(contentsOf: nextValue())
    }
}

struct HitRectsKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}
