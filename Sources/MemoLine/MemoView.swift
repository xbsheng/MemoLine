import SwiftUI

/// One memo with its clothespin. All the charm lives here: it drops onto the
/// line, swings, sways with the breeze and slips off when you take it down.
struct MemoView: View {
    let memo: Memo
    @ObservedObject var line: Line

    @State private var swing: Double = 0
    @State private var arrived = false
    @State private var hovering = false

    private var copied: Bool { line.copiedID == memo.id }
    private var dragging: Bool { line.draggingID == memo.id }
    private var reordering: Bool { line.reorderID == memo.id }
    private var pressed: Bool { line.pressedID == memo.id }
    private var falling: Bool { line.falling.contains(memo.id) }

    var body: some View {
        VStack(spacing: -12) {
            Clothespin()
                .zIndex(1)
            card
        }
        .rotationEffect(.degrees(swing + memo.tilt + (falling ? 18 : 0)), anchor: .top)
        .offset(y: falling ? 40 : (arrived ? 0 : -46))
        // The card does not fall far: it slips out of the clip and is gone.
        .opacity(falling ? 0 : (arrived ? 1 : 0))
        .animation(.easeIn(duration: 0.5), value: falling)
        .onAppear(perform: arrive)
        .onChange(of: line.gust) { _ in breeze() }
        .onChange(of: copied) { isCopied in if isCopied { nudge(3) } }
    }

    private var display: String {
        memo.text.isEmpty ? L("New memo") : memo.text
    }

    private var card: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Frame.radius, style: .continuous)
                .fill(memo.paper.color)

            Text(display)
                .font(.system(size: 12.5 * Layout.size.scale, weight: .medium))
                .foregroundStyle(memo.paper.ink.opacity(memo.text.isEmpty ? 0.35 : 0.82))
                .lineSpacing(3.5)
                .multilineTextAlignment(.leading)
                .frame(width: Layout.cardWidth - 30, height: Layout.cardHeight - 28, alignment: .topLeading)
                .padding(15)
        }
        .frame(width: Layout.cardWidth, height: Layout.cardHeight)
        // A sheet of paper: a hairline edge and a soft shadow, nothing more.
        .overlay(
            RoundedRectangle(cornerRadius: Frame.radius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.09), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(hovering ? 0.24 : 0.16),
                radius: hovering ? 12 : 8, y: hovering ? 7 : 4)
        // Holding presses the card in slowly, so a long press feels like it
        // is building up to something. A card being dragged along the line
        // lifts instead, so it is clear which one is moving.
        .scaleEffect(pressed ? 0.95 : (reordering ? 1.05 : (hovering ? 1.03 : 1)), anchor: .top)
        .animation(pressed ? .easeInOut(duration: 0.45) : .spring(response: 0.3, dampingFraction: 0.6), value: pressed)
        .opacity(dragging ? 0.45 : 1)
        // Drawn here, clicked through GrabView, which sits on top: the
        // copy button copies, the cross takes the memo down.
        .overlay(alignment: .topLeading) { CornerButton(symbol: "square.on.square", visible: hovering && !dragging && !reordering) }
        .overlay(alignment: .topTrailing) { CornerButton(symbol: "xmark", visible: hovering && !dragging && !reordering) }
        .overlay(GrabArea(memo: memo, line: line))
        .overlay(alignment: .bottom) {
            if copied {
                Label(L("Copied"), systemImage: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .glassFrame(capsule: true)
                    .offset(y: 16)
                    .transition(.opacity.combined(with: .offset(y: -4)))
            }
        }
        .animation(.easeOut(duration: 0.18), value: hovering)
        .animation(.easeOut(duration: 0.2), value: copied)
        .onHover { hovering = $0 }
        .background(
            GeometryReader { g in
                Color.clear.preference(key: HitRectsKey.self,
                                       value: falling ? [:] : [memo.id: g.frame(in: .global)])
            }
        )
    }

    private func arrive() {
        swing = 16
        withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) { arrived = true }
        withAnimation(.interpolatingSpring(stiffness: 46, damping: 2.6)) { swing = 0 }
    }

    private func breeze() {
        let delay = Double.random(in: 0...0.35)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            nudge(Double.random(in: 1.6...3.4))
        }
    }

    private func nudge(_ degrees: Double) {
        withAnimation(.easeOut(duration: 0.3)) { swing = degrees }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.interpolatingSpring(stiffness: 38, damping: 2.4)) { swing = 0 }
        }
    }
}

/// The little glass button in a corner of the card. GrabView handles the
/// clicks; this only draws.
private struct CornerButton: View {
    let symbol: String
    let visible: Bool

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.primary)
            .frame(width: 20, height: 20)
            .glassFrame(circle: true)
            .padding(3)
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible ? 1 : 0.6)
            .allowsHitTesting(false)
    }
}

enum Frame {
    static let radius: CGFloat = 14
}

extension View {
    /// A crisp glass: the system's blurred material with a thin specular
    /// edge, lit from above. No refraction, so the background stays sharp
    /// around the frame instead of bending like gel.
    func glassFrame(cornerRadius: CGFloat = 0, circle: Bool = false, capsule: Bool = false) -> some View {
        let shape: AnyShape = circle ? AnyShape(Circle())
            : capsule ? AnyShape(Capsule())
            : AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        return background(.ultraThinMaterial, in: shape)
            .overlay(
                shape.stroke(
                    LinearGradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0.12)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 0.75)
            )
            .overlay(shape.stroke(Color.black.opacity(0.10), lineWidth: 0.5).padding(-0.5))
    }
}

/// A minimal aluminium clip: a brushed metal pill with a slot where it
/// grips the line, and a soft shadow so it reads on any background.
struct Clothespin: View {
    private let metal = LinearGradient(
        stops: [
            .init(color: Color(white: 0.70), location: 0),
            .init(color: Color(white: 0.93), location: 0.35),
            .init(color: Color(white: 0.82), location: 0.65),
            .init(color: Color(white: 0.62), location: 1),
        ],
        startPoint: .leading, endPoint: .trailing)

    var body: some View {
        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
            .fill(metal)
            .frame(width: 9, height: 26)
            .overlay(
                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.9), Color.black.opacity(0.18)],
                                           startPoint: .top, endPoint: .bottom),
                            lineWidth: 0.6)
            )
            .overlay(alignment: .top) {
                // The slot the line passes through.
                Capsule()
                    .fill(Color.black.opacity(0.32))
                    .frame(width: 5, height: 1.4)
                    .padding(.top, 8.5)
            }
            .shadow(color: .black.opacity(0.30), radius: 2, y: 1.5)
            .allowsHitTesting(false)
    }
}
