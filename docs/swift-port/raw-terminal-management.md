# Raw Terminal Management

The Swift port introduces `TerminalManager`, a cross-platform utility that mirrors the lifecycle logic currently implemented in C#:

- **Alternate buffer activation** – `useAlternateBuffer()` is called during `configure()` to match the Spectre Console behaviour. `restore()` switches back to the main buffer when the loop ends or an error occurs.
- **Raw mode enablement** – `enableRawMode()` is invoked prior to frame rendering. `restore()` disables raw mode to ensure the user's terminal is returned to canonical mode.
- **Cursor visibility** – The cursor is hidden when the UI starts and restored on shutdown.
- **Cursor positioning** – The cursor is moved to the origin before each frame, allowing the renderer to overwrite the prior frame.
- **Screen clearing** – A full clear is performed when entering and leaving the alternate buffer, mirroring the Spectre `ControlSequences.ClearScreen` calls.

`ConsoleLoop` now depends on `TerminalManager`, ensuring cleanup occurs exactly once and the shutdown message is flushed before restoring the terminal state.
