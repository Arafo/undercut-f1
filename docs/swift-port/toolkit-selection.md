# Terminal Toolkit Selection

To support a Swift-native replacement for the Spectre.Console-based terminal client we evaluated three approaches:

| Option | Strengths | Limitations |
| --- | --- | --- |
| **SwiftTerm** | - Actively maintained by the Swift community.<br>- Provides full-screen terminal emulator with synchronized output support.<br>- Exposes raw key events (including escape sequences) and terminal state helpers.<br>- Includes cross-platform support for macOS and Linux with Swift Package Manager integration.<br>- Provides APIs for alternate screen buffer, cursor control, and terminal graphics (Sixel / iTerm2 inline images). | - Requires adding an event loop integration (run loop or GCD) for timely frame updates. |
| **swift-ncurses** | - Thin wrapper over `ncurses` with portable raw terminal handling.<br>- Efficient for grid-based UIs. | - Lacks high-level layout primitives; would require re-implementing tables/panels/log rendering.<br>- Limited support for synchronized output and inline graphics.<br>- Windows support is indirect (via curses ports). |
| **Manual termios** | - Maximum control and zero external dependencies. | - Re-implementing buffer management, layout engine, and Unicode handling would be time-consuming.<br>- Requires custom escape-sequence parsing and double buffering implementation.<br>- Harder to share across macOS and Linux without duplicate effort. |

## Selection
We will build on **SwiftTerm** because it matches the C# client capabilities with minimal reinvention:

- Provides a raw-mode terminal interface with proper cleanup hooks.
- Supports synchronized output through `TerminalView`'s batch updates.
- Offers access to alternate screen buffers and cursor visibility toggling.
- Sixel and iTerm2 inline image support allows us to reproduce the timing charts and driver tracker graphics.
- Delivered as a SwiftPM dependency so it can compile alongside the new `UndercutF1Terminal` package.

SwiftTerm will be complemented with a lightweight layout and rendering layer implemented in Swift to mirror the Spectre.Console constructs used by the existing displays (panels, tables, columns, rows).
