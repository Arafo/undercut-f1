# Swift Packaging Blueprint

This document tracks how the Swift port mirrors the .NET release workflow so distribution automation can stage
macOS and Linux archives alongside existing artefacts.

## Reference .NET Artefacts

The current .NET tooling produces four primary distribution shapes:

1. **Dotnet tool** – published to NuGet via `dotnet tool install -g undercutf1` and documented in the README.
2. **Homebrew formula** – installs the same executable and prerequisites with `brew install undercutf1`.
3. **Standalone archives** – platform-specific binaries uploaded to GitHub releases.
4. **Docker image** – built from the root `Dockerfile`, layering runtime dependencies (`libfontconfig`, `ffmpeg`, `libgdiplus`) and
   publishing `undercutf1.dll` with an entrypoint.

The Swift packaging flow aims to recreate these shapes with native binaries while reusing the same asset directory layout.

## Swift Package Layout

- The **root `Package.swift`** now exposes an `undercutf1` executable that depends on `UndercutF1Data` and the terminal library.
  Building from the repository root (`swift build --product undercutf1`) produces a CLI binary that matches the .NET naming scheme
  so downstream automation can substitute it directly.
- The **`swift/UndercutF1Terminal` manifest** exports both the reusable library and a `undercutf1-terminal-preview` executable.
  The preview target gives CI a way to smoke-test resource bundling without a full data stack.
- Both manifests declare SwiftPM resources that reserve space for SwiftTerm licenses, Whisper model artefacts, and the CZlib shim
  acknowledgements. These placeholders ensure the generated bundles have stable locations where packaging automation can drop the
  real files.

## Asset Bundling Strategy

Swift relies on three external artefacts today:

| Asset            | Source                                                      | Swift Treatment |
|------------------|-------------------------------------------------------------|-----------------|
| SwiftTerm        | Pulled via SwiftPM dependency. License copied into `Resources/ThirdParty/SwiftTerm`. |
| Whisper models   | Downloaded from `ggerganov/whisper.cpp`. Models should be staged next to `Resources/ThirdParty/Whisper/manifest.json` before packaging. |
| CZlib shim       | Links against system `libz`. Include the zlib license within `Resources/ThirdParty/CZlibShim`. |

The helper script `scripts/swift/stage-dist.sh` compiles the CLI in release mode and mirrors these resources into a staging
folder. Populate the resource directories with the actual licences/models before running the script to ensure the resulting
archive contains every third-party acknowledgement required by the .NET releases.

## Installer and Distribution Parity

| Distribution Shape | Swift Equivalent Plan |
|--------------------|-----------------------|
| Dotnet tool        | Package the release binary produced by `stage-dist.sh` as a zip/tar archive so the existing GitHub release workflow can upload it alongside the .NET build. |
| Homebrew formula   | Reuse the Homebrew tap but point the formula to the Swift tarball. The manifest already produces an `undercutf1` binary so the existing formula can reuse the same target paths. |
| Standalone archive | Use `stage-dist.sh` to emit `.dist/undercutf1` with `bin/undercutf1` and `assets/**`. Zip this directory per platform. |
| Docker image       | Base image can switch to Swift runtime images once the Swift server components are implemented. For now retain the .NET Dockerfile as a reference for required packages (`libfontconfig`, `ffmpeg`, `libgdiplus`). |

Future automation can extend the script to build universal macOS binaries (via `xcodebuild -scheme undercutf1 -configuration Release` once Xcode project integration lands) and to invoke Swift cross-compilers for Linux from macOS CI builders.

## Installation and Runtime Prerequisites

- **Swift 5.9 toolchain** with concurrency enabled (required by the package manifests).
- **libz development headers** (already present on macOS; install `zlib1g-dev` on Linux to compile the shim).
- **FFmpeg** and **mpg123/afplay** for audio playback, mirroring the .NET runtime expectations documented in the README.
- **Whisper model binaries** placed in `Sources/UndercutF1TerminalCLI/Resources/ThirdParty/Whisper` prior to packaging or downloaded lazily on first run.
- **SwiftTerm license** and **zlib license** copied into their respective resource folders before publishing artefacts.

These prerequisites should be captured in downstream CI (GitHub Actions, Azure Pipelines, etc.) so Swift builds can publish
artifacts in lockstep with the .NET release job.
