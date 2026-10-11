import AppKit
import SwiftUI

/// The little window a memo is written in. It hangs just under the line, on
/// the card it belongs to, and saves on every keystroke: closing it any way
/// at all keeps the text.
final class MemoEditor: NSObject, NSWindowDelegate {
    static let shared = MemoEditor()

    private static let size = NSSize(width: 340, height: 250)

    private var window: NSWindow?
    private var commit: ((String) -> Void)?
    private var close: (() -> Void)?

    /// Opens the editor under the line. `top` is the bottom edge of the line
    /// panel, `centerX` the middle of the card, both in screen coordinates.
    func edit(_ memo: Memo, top: CGFloat, centerX: CGFloat, screen: NSRect,
              commit: @escaping (String) -> Void,
              paper: @escaping (Paper) -> Void,
              close: @escaping () -> Void) {
        self.commit = commit
        self.close = close

        let host = NSHostingView(rootView: EditorView(
            text: memo.text,
            paper: memo.paper,
            onCommit: { [weak self] text in self?.commit?(text) },
            onPaper: paper,
            onClose: { [weak self] in self?.closeFromInside() }))
        host.frame = NSRect(origin: .zero, size: Self.size)

        let window = self.window ?? makeWindow()
        window.setContentSize(Self.size)
        window.contentView = host
        self.window = window

        var x = centerX - Self.size.width / 2
        x = min(max(x, screen.minX + 12), screen.maxX - Self.size.width - 12)
        let y = max(top - 12 - Self.size.height, screen.minY + 12)
        window.setFrameOrigin(NSPoint(x: x, y: y))

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    /// The Done button and Escape both come here.
    func closeFromInside() {
        window?.close()
    }

    func windowWillClose(_ notification: Notification) {
        guard (notification.object as? NSWindow) === window else { return }
        let close = self.close
        self.close = nil
        commit = nil
        close?()
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: Self.size),
                              styleMask: [.titled, .closable, .fullSizeContentView],
                              backing: .buffered, defer: false)
        window.title = L("Memo")
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.delegate = self
        return window
    }
}

/// A sheet of paper with the text on it, and the palette along the bottom.
private struct EditorView: View {
    let text: String
    @State private var paper: Paper
    let onCommit: (String) -> Void
    let onPaper: (Paper) -> Void
    let onClose: () -> Void

    init(text: String, paper: Paper,
         onCommit: @escaping (String) -> Void,
         onPaper: @escaping (Paper) -> Void,
         onClose: @escaping () -> Void) {
        self.text = text
        _paper = State(initialValue: paper)
        self.onCommit = onCommit
        self.onPaper = onPaper
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            MemoTextView(text: text, onCommit: onCommit, onDone: onClose)
                .padding(.horizontal, 8)
                .padding(.top, 6)

            HStack(spacing: 8) {
                ForEach(Paper.allCases) { choice in
                    Button { paper = choice; onPaper(choice) } label: {
                        Circle()
                            .fill(choice.color)
                            .frame(width: 17, height: 17)
                            .overlay(Circle().strokeBorder(Color.black.opacity(0.18), lineWidth: 0.5))
                            .overlay {
                                if paper == choice {
                                    Circle().strokeBorder(Color.primary.opacity(0.65), lineWidth: 1.5)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .help(choice.name)
                }

                Spacer(minLength: 8)

                Text(L("Saved as you type"))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Button(L("Done")) { onClose() }
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.045))
        }
        .background(paper.color)
        .onExitCommand { onClose() }
    }
}

/// The text itself, hand-built. SwiftUI's `TextEditor` insists on the system
/// scroll bar with its light trough, which reads as a stray stripe down the
/// paper. Here the trough is transparent and only the thin knob is left.
private struct MemoTextView: NSViewRepresentable {
    let text: String
    let onCommit: (String) -> Void
    let onDone: () -> Void

    static let font = NSFont.systemFont(ofSize: 14)
    static let ink = NSColor(srgbRed: 0.16, green: 0.15, blue: 0.14, alpha: 1)

    func makeCoordinator() -> Coordinator {
        Coordinator(onCommit: onCommit, onDone: onDone)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 320, height: 190))
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        // The system default draws a light trough. Overlay leaves the thin
        // knob floating over the paper and nothing else.
        scrollView.scrollerStyle = .overlay

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4

        let textView = NSTextView(frame: scrollView.contentView.bounds)
        textView.drawsBackground = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = Self.font
        textView.textColor = Self.ink
        textView.textContainerInset = NSSize(width: 4, height: 8)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.defaultParagraphStyle = paragraph
        textView.typingAttributes = [.font: Self.font, .foregroundColor: Self.ink, .paragraphStyle: paragraph]
        textView.delegate = context.coordinator
        textView.string = text
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        context.coordinator.onCommit = onCommit
        context.coordinator.onDone = onDone
        if textView.string != text { textView.string = text }
        context.coordinator.focus(textView)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var onCommit: (String) -> Void
        var onDone: () -> Void
        private var focused = false

        init(onCommit: @escaping (String) -> Void, onDone: @escaping () -> Void) {
            self.onCommit = onCommit
            self.onDone = onDone
        }

        /// The caret is waiting in the memo the moment the window appears.
        func focus(_ textView: NSTextView) {
            guard !focused else { return }
            focused = true
            DispatchQueue.main.async { textView.window?.makeFirstResponder(textView) }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            onCommit(textView.string)
        }

        /// Escape closes the editor, as it does in any other small window.
        func textView(_ textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            guard selector == #selector(NSResponder.cancelOperation(_:)) else { return false }
            onDone()
            return true
        }
    }
}
