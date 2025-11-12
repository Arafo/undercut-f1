import Foundation
import SwiftTerm

public protocol RenderNode {
    func render(into buffer: inout String)
}

public final class ConsoleLoop {
    private enum LoopState {
        case running
        case stopping
    }

    public static let targetFrameTime: TimeInterval = 0.150

    private let terminal: TerminalProtocol
    private let displayRegistry: DisplayRegistry
    private let inputRouter: InputRouter
    private let footerRenderer: FooterRenderer
    private let terminalManager: TerminalManager
    private let clock: () -> Date
    private var previousFrame: String = ""
    private var loopState: LoopState = .running
    private var slowFrameReports = 0

    public init(
        terminal: TerminalProtocol,
        displayRegistry: DisplayRegistry,
        inputRouter: InputRouter,
        footerRenderer: FooterRenderer,
        terminalManager: TerminalManager,
        clock: @escaping () -> Date = Date.init
    ) {
        self.terminal = terminal
        self.displayRegistry = displayRegistry
        self.inputRouter = inputRouter
        self.footerRenderer = footerRenderer
        self.terminalManager = terminalManager
        self.clock = clock
    }

    public func run(until cancellation: CancellationToken) async {
        await terminalManager.configure()
        var lastTimestamp = clock()

        while !cancellation.isCancelled {
            let frameStart = clock()
            await terminal.moveCursor(to: .zero)
            await inputRouter.pollInput(terminal: terminal, cancellation: cancellation)

            if cancellation.isCancelled {
                break
            }

            do {
                let activeDisplay = displayRegistry.activeDisplay()
                let frame = try await renderFrame(using: activeDisplay)
                if frame != previousFrame {
                    if terminal.capabilities.supportsSynchronizedUpdates {
                        await terminal.beginSynchronizedUpdate()
                    }

                    await terminal.write(frame)
                    previousFrame = frame

                    if terminal.capabilities.supportsSynchronizedUpdates {
                        await terminal.endSynchronizedUpdate()
                    }
                }

                try await activeDisplay.postRender(force: frame != previousFrame, terminal: terminal)
            } catch {
                await render(error: error)
            }

            let frameEnd = clock()
            let elapsed = frameEnd.timeIntervalSince(frameStart)
            if elapsed < Self.targetFrameTime {
                let delay = Self.targetFrameTime - elapsed
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } else if slowFrameReports < 10 {
                print("⚠️ Frame time exceeded 100ms: \(elapsed * 1000)ms")
                slowFrameReports += 1
            }

            lastTimestamp = frameEnd
        }

        await shutdownTerminal()
    }

    public func stop() {
        loopState = .stopping
    }

    private func renderFrame(using display: Display) async throws -> String {
        var buffer = String()
        let layout = RootLayout(content: try await display.render(), footer: footerRenderer.renderFooter())
        layout.render(into: &buffer)
        return buffer.replacingOccurrences(of: "\n", with: "\r\n")
    }

    private func shutdownTerminal() async {
        guard loopState != .stopping else { return }
        loopState = .stopping
        await terminal.write("Exiting undercutf1...\r\n")
        await terminalManager.restore()
    }

    private func render(error: Error) async {
        var buffer = ""
        let panel = ErrorPanel(error: error, footerHeight: footerRenderer.footerHeight)
        panel.render(into: &buffer)
        await terminal.write(buffer)
    }
}
