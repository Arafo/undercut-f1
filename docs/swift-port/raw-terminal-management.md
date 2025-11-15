# Raw Terminal Management

The Swift port introduces `TerminalManager`, a cross-platform utility that mirrors the lifecycle logic currently implemented in C#:

- **Alternate buffer activation** – `useAlternateBuffer()` is called during `configure()` to match the Spectre Console behaviour. `restore()` switches back to the main buffer when the loop ends or an error occurs.
- **Raw mode enablement** – `enableRawMode()` is invoked prior to frame rendering. `restore()` disables raw mode to ensure the user's terminal is returned to canonical mode.
- **Cursor visibility** – The cursor is hidden when the UI starts and restored on shutdown.
- **Cursor positioning** – The cursor is moved to the origin before each frame, allowing the renderer to overwrite the prior frame.
- **Screen clearing** – A full clear is performed when entering and leaving the alternate buffer, mirroring the Spectre `ControlSequences.ClearScreen` calls.

`ConsoleLoop` now depends on `TerminalManager`, ensuring cleanup occurs exactly once and the shutdown message is flushed before restoring the terminal state.

## Swift Terminal Bootstrap Baseline

The current Swift baseline wires the control flow described above through `TerminalProtocol` and `SwiftTermAdapter`:

- `TerminalManager.configure()` guards against duplicate activation and then issues the full bootstrap sequence (`setScreenBuffer(.alternate)`, `enableRawMode()`, `setCursorVisible(false)`, `moveCursor(to: .zero)`, `clearScreen(.full)`) before the first frame renders (`swift/UndercutF1Terminal/Sources/UndercutF1Terminal/Graphics/TerminalManager.swift`).
- `prepareForNextFrame()` rewrites the cursor position every 150 ms frame so diffed output can overwrite the previous buffer without any redundant clears.
- `restore()` performs the inverse of the bootstrap (cursor visible, disable raw mode, clear, swap back to the main buffer) and flips the `isConfigured` flag so repeated shutdown attempts are safely ignored.
- `SwiftTermAdapter` translates every `TerminalProtocol` call into the precise control sequences required by SwiftTerm (`swift/UndercutF1Terminal/Sources/UndercutF1Terminal/TerminalProtocol.swift`), guaranteeing the same alternate-buffer, synchronized-output, and raw-mode toggles documented in the console-loop audit.

This wiring is now the reference configuration for the Swift terminal bootstrap; any additional startup/shutdown behaviour (for example, resizing hooks or bell notifications) should be layered through `TerminalManager` so the lifecycle stays centralised.
