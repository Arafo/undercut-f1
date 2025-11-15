# Swift Distribution & Workspace Plan

## Shared Swift workspace
- The repository root `Package.swift` now declares the Swift data library, CLI, and terminal targets in one manifest.
- `swift build` and `swift test` resolve every dependency (ArgumentParser, swift-log, SwiftTerm, and CZlib) in a single resolution graph so the CLI and terminal stay in lockstep.
- Terminal sources remain under `swift/UndercutF1Terminal`, but the root manifest exposes them as the `UndercutF1Terminal` product, letting Xcode or `swift package generate-xcodeproj` open the entire Swift surface at once.
- Use `swift build --product undercutf1` for the CLI and `swift test --filter UndercutF1TerminalTests` (or `swift test` for all) to validate both stacks together.

## Distribution strategy for external assets
### Whisper
- Team-radio transcription is handled by `WhisperTranscriptionProvider` which downloads `ggml-large-v3-turbo-q5.bin` on demand into `<data-directory>/models`. No model files are committed to the repo or bundled in releases to avoid shipping a ~550 MB asset.
- The provider honors `UNDERCUTF1_FFMPEG` and `UNDERCUTF1_WHISPER` environment variables so downstream packagers can point to custom binaries without patching the source.
- Because the download flow already verifies file existence and size before replacing the cached model, no additional installer logic is required beyond ensuring FFmpeg/whisper binaries are present on the user PATH.

### SwiftTerm
- SwiftTerm is consumed as a Swift Package Manager dependency (via `https://github.com/migueldeicaza/SwiftTerm.git`), so the latest compatible source is fetched at build time for macOS or Linux.
- The dependency lives in the shared workspace manifest, which keeps the terminal renderer versioned alongside the CLI and makes `swift build` sufficient for development, CI, and Homebrew-style formula builds.
- Release archives simply embed the compiled binary; source distributions rely on SPM to re-fetch SwiftTerm, avoiding submodules or manual vendoring.

### CZlib
- Compression uses a small `CZlibShim` target that links against the platform `libz`. Package maintainers only need to ensure the OS development headers are available (e.g., `zlib1g-dev` on Debian/Ubuntu or the default SDK on macOS).
- Because the shim is part of the shared workspace, the same compiled artifact is reused by both the CLI and any future Swift terminal executables without extra packaging steps.

## Release guidance
- Binary releases should be produced with `swift build -c release --product undercutf1` (and future terminal executables once they exist). The resulting artifacts can be zipped without bundling Whisper models.
- Documented prerequisites (FFmpeg, Whisper CLI, libz) remain the responsibility of downstream installers; the workspace manifest ensures the Swift sources and third-party libraries resolve consistently across macOS and Linux.
