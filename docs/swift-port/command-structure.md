# .NET Console Command Structure

This document captures the structure and behaviour of the .NET command handlers so the Swift CLI can mirror them accurately.

## Root command (`undercutf1`)
- **Options**
  - `--with-api` (`bool?`): enables the HTTP API on port 61937 when `true`.
  - `--data-directory` (`DirectoryInfo?`): overrides the data cache directory.
  - `--log-directory` (`DirectoryInfo?`): overrides the log directory.
  - `--verbose` (`bool?`): toggles verbose logging.
  - `--notify` (`bool?`): toggles BEL notifications for race control updates.
  - `--prefer-ffmpeg` (`bool?`): prefers FFmpeg for Team Radio playback.
  - `--force-graphics-protocol` (`GraphicsProtocol?`): forces a terminal graphics protocol.
- **Service wiring**
  - Builds an `IHost` via `WebApplication.CreateEmptyBuilder` and merges config from `config.json`, environment variables, and command line overrides.
  - Configures Serilog + in-memory logging, clipboard access, SignalR live timing, WebSocket sync, displays, Spectre console components, and hosted services for `ConsoleLoop` & `WebSocketSynchroniser`.
  - When the API is enabled, enables Kestrel, Swagger, and minimal API endpoints for control/timing.
  - Ensures the config file exists with the JSON schema reference and logs resolved options.

## `import`
- **Arguments/Options**
  - `year` (`int` argument)
  - `--meeting-key` (`int?` option)
  - `--session-key` (`int?` option)
  - Shares `--data-directory`, `--log-directory`, and `--verbose` with the root command.
- **Behaviour**
  - Bootstraps services with console logging.
  - Lists meetings when no `meeting-key`, lists sessions when a meeting is selected without `session-key`, or imports the selected session via `IDataImporter`.
  - Uses Spectre tables for tabular output.

## `info`
- **Options**: shares all root options except API toggle.
- **Behaviour**
  - Builds services, resolves displays, and renders the `InfoDisplay` content in raw terminal mode.

## `image`
- **Arguments/Options**
  - `file` (`FileInfo` argument)
  - `graphics-protocol` (`GraphicsProtocol` argument)
  - `--verbose` option
- **Behaviour**
  - Enters raw terminal mode, queries terminal dimensions, and emits the correct control sequences for Sixel, iTerm2, or Kitty graphics.

## `login`
- **Options**: `--verbose` only.
- **Behaviour**
  - Boots services (with console logging when verbose).
  - Prevents duplicate logins if the config already has a valid token.
  - Opens a SharpWebView browser, captures the `login-session` cookie, validates it with `Formula1Account`, and persists it to the config file.

## `logout`
- **Options**: none beyond shared verbose flag.
- **Behaviour**
  - Reads the config file, removes the stored access token, and writes the updated JSON to disk.

## Shared infrastructure
- `CommandHandler.GetBuilder` centralises configuration loading, logging set-up, clipboard injection, and HTTP client defaults for every command.
- `Options.ConfigFilePath` resolves to `%APPDATA%/undercut-f1/config.json` on Windows or `$XDG_CONFIG_HOME`/`~/.config/undercut-f1/config.json` on Linux/macOS.
