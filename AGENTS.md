# Swift Port Migration Plan

## Architectural Snapshot
- **Console loop expectations** – The Swift `ConsoleLoop` already mirrors the C# cadence (150 ms frames), frame diffing, synchronized updates, and per-frame error handling captured in `docs/swift-port/console-loop-audit.md`. Terminal startup and shutdown rely on `TerminalManager` to switch buffers, toggle raw mode, clear the screen, and restore cursor state as described in `docs/swift-port/raw-terminal-management.md`.
- **Terminal lifecycle & toolkit** – SwiftTerm is the chosen foundation for terminal I/O. It supplies alternate-buffer control, synchronized output, raw key events, and sixel hooks, matching the evaluation recorded in `docs/swift-port/toolkit-selection.md`.
- **Display coverage** – Timing Tower and Log displays are live in Swift. All other Spectre screens remain pending, with the authoritative status table in `docs/swift-port/display-porting-notes.md` describing data requirements and layout expectations.

## Migration Tasks
1. **Data parity**
   - Extend the Swift data layer to match `UndercutF1.Data`, including models, caching, decompression, and helper utilities.
   - Audit the Swift `LiveTimingClient` against the C# SignalR client for identical handshake topics, subscription acknowledgements, reconnection, and retry strategies.
   - Align the Swift `TimingService` queuing, delay compensation, decompression, and race-control handling with the C# channel-driven processor loop, including `.z` payload logic.
   - Port the DataImporter (meeting/session discovery, topic fetch, JSONL export) so offline replays do not require .NET.
2. **Processor translation**
   - Recreate each processor (timing, gaps, race control, tyre, team radio, etc.) so Swift exposes the same computed state currently produced through AutoMapper projections in C#.
   - Mirror option binding, notification routing, and HTTP client wiring defined in `ServiceCollectionExtensions` so Swift offers matching toggle defaults and directory layout.
   - Replace the temporary Swift transcription provider with a Whisper-based implementation that mirrors the C# download, cache, and conversion workflow to keep team-radio processors functional.
3. **Terminal client completion**
   - Finish the Swift terminal loop so frame pacing, diffing, alternate-buffer use, and graceful shutdown exactly match the documented Spectre semantics.
   - Expand `TerminalManager` / `TerminalProtocol` to emit any remaining control sequences surfaced by Spectre helpers (screen clears, raw mode, cursor movement, synchronized updates).
   - Port the full input-handler catalogue, reusing the Swift router’s escape-sequence parsing and footer rendering so every C# command (screen switching, delay controls, cursor jumps, playback, etc.) is wired through.
   - Re-implement every Spectre display using the Swift layout primitives; Timing Tower is done, port the pending screens listed in the display notes while preserving `Screen` enum semantics.
4. **CLI and host parity**
   - Recreate the CLI surface in Swift (root/import/info/image/login/logout commands) with equivalent options and defaults.
   - Rebuild the root command pipeline that wires services, logging, clipboard integration, and the optional web host (Swift Argument Parser + async main recommended).
   - Port app-specific options (FFmpeg preference, forced graphics protocol, external sync) and replicate config-file discovery across platforms.
5. **Web service port**
   - Replace the ASP.NET minimal API with a Swift web service (e.g., Vapor) that exposes the same control/timing endpoints (pause/resume clock, latest timing snapshots, lap history).
   - Ensure the Swift host shares session state with the terminal client just as the .NET host currently does via dependency injection.
6. **Packaging & distribution**
   - Update SwiftPM manifests so `UndercutF1Swift` (data) and `UndercutF1Terminal` (UI) build together, producing executables or bundles aligned with today’s .NET distribution (Swift CLI, Homebrew, etc.).
   - Decide how to ship third-party assets (SwiftTerm, Whisper models, CZlib shim) and update build scripts for macOS/Linux parity.
7. **Testing & coverage**
   - Restore XCTest coverage that mirrors existing Swift unit tests (timing queue, compression, layout) and port relevant .NET tests to Swift.
   - Add integration tests (CLI, API, terminal rendering) once the Swift stack stabilises, using snapshot or golden-file comparisons where possible.

## Swift Contribution Conventions
- Target **Swift 5.9** and prefer async/await over callback-based concurrency. Keep indentation at four spaces to match the existing Swift sources.
- Group related types with extensions and internal access control where possible; default to `struct` for immutable data models and `actor`/`class` for long-lived services mirroring the C# singletons.
- Maintain Spectre-style naming to ease code search (e.g., `TimingHistoryDisplay`, `RaceControlProcessor`). Keep protocol names aligned with their C# interfaces when translating features.

## Running the Swift Targets
- Build the shared data library from the repo root: `swift build` (uses `Package.swift` for `UndercutF1Data`).
- Run data-layer tests: `swift test`.
- Work on the terminal client inside `swift/UndercutF1Terminal`:
  - Build: `swift build --package-path swift/UndercutF1Terminal`.
  - Test: `swift test --package-path swift/UndercutF1Terminal`.
  - Execute ad-hoc tools via `swift run --package-path swift/UndercutF1Terminal <target>` once executable targets land.

Keep this plan updated as milestones complete so new contributors can immediately see the remaining parity work and how to exercise the Swift targets.
