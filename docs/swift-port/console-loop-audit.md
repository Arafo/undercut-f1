# Console Loop Capabilities Audit

This document catalogues the terminal capabilities expected by the existing C# console front-end. It consolidates the behaviour observed in `ConsoleLoop` and the cooperating `Display`, `Input`, and `Graphics` implementations.

## Frame and Buffer Management
- Target refresh cadence of **150 ms** (`TargetFrameTimeMs`).
- Frame timer uses a `Stopwatch` to measure elapsed time, delaying the next iteration to keep cadence stable.
- Double buffering achieved by comparing the newly rendered ANSI frame with `_previousDraw`; frames are only written when the content changes.
- Synchronized terminal writes are used when supported (`TerminalGraphics.BeginSynchronizedUpdate` / `EndSynchronizedUpdate`).
- Each frame begins with `SetupBufferAsync`, issuing `CSI H` to move the cursor to the upper-left corner so the entire buffer redraw replaces the previous frame.

## Terminal Session Lifecycle
- On start (`SetupTerminalAsync`):
  - Switch to the **alternate screen buffer** (`CSI ? 1049 h`).
  - Enter **raw mode** to receive unprocessed key events.
  - Hide the cursor (`CSI ? 25 l`).
  - Clear the entire screen (`CSI 2 J`).
- On stop (`StopAsync`):
  - Print shutdown notice and clear the screen.
  - Restore cursor visibility and main screen buffer.
  - Disable raw mode.
  - Ensure cleanup runs only once (`_stopped` guard) even if `StopAsync` is called multiple times.

## Error Handling
- Errors during display rendering are caught per-frame.
- When a render failure occurs, the loop:
  - Logs the exception.
  - Renders a dedicated error panel using `DisplayErrorScreenAsync`.
  - The error panel uses Spectre.Console `Panel` + `Rows`, sized to leave room for footer (height = `Terminal.Size.Height - 1`).

## Layout Composition
- Uses Spectre.Console `Layout` to arrange:
  - A top **content panel** that changes based on the active screen.
  - A bottom **footer** row of height 1 that displays command hints.
- `UpdateInputFooter` builds `Columns` containing hotkey descriptions for enabled input handlers applicable to the current screen.

## Input Handling
- Raw bytes read using `Terminal.ReadAsync` into a pooled buffer (8 bytes) to handle multi-byte escape sequences.
- Uses `System.Console.KeyAvailable` to avoid blocking reads (workaround for cathode bug on Windows).
- `TryParseRawInput` interprets:
  - ANSI CSI sequences for arrow keys and modifier variations.
  - FE sequences for cursor control.
  - ESC key.
  - Repeated keypresses detected by duplicated trailing bytes (used for held keys).
- Input dispatch:
  - Filters handlers by `IsEnabled`, matching `ConsoleKey`, and applicability to current screen.
  - Executes handlers asynchronously, repeating when `times > 1` (key held down).
  - Exceptions during handler execution are logged but do not break the loop.

## Display Contract (`IDisplay`)
- Each display advertises its `Screen` enum value.
- `GetContentAsync` returns a Spectre `IRenderable` tree representing the current frame.
- Optional `PostContentDrawAsync` hook for terminal graphics (e.g., inline images / sixel) to write after the main buffer flush.
- Display implementations rely heavily on shared helpers in `CommonDisplayComponents` and `DisplayUtils`.

## Graphics Integration
- `TerminalGraphics` provides:
  - Detection of terminal synchronized output support.
  - Helpers to emit begin/end synchronization sequences.
- `Sixel` / `SKImageExtensions` support inline bitmap rendering for timing charts.
- Displays such as `DriverTrackerDisplay` use `PostContentDrawAsync` to paint graphics overlay (sixel data) after the textual frame renders.

## Footer Requirements
- Footer row lists enabled actions in sorted order using `DisplayKeys.ToDisplayCharacters()`.
- Layout collapses columns so hints wrap naturally within available width.
- Footer is refreshed every frame (even when frame content unchanged) because the footer is part of the layout diffed for `_previousDraw`.

## Summary of Required Terminal Capabilities
1. Alternate / main buffer switching.
2. Raw mode toggling and cursor visibility control.
3. Synchronized buffered output (when available).
4. Efficient frame diffing to avoid redundant writes.
5. Proper handling of ANSI CSI + FE escape sequences for keyboard input.
6. Ability to flush binary graphics payloads (sixel) post frame.
7. Layout primitives supporting rows, columns, panels, tables, charts, log views, and status panels.
