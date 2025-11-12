# Display Port Mapping

The Swift target introduces dedicated renderers for the highest-traffic screens and records the mapping for the remaining displays that still require translation work.

| Screen | Swift Display | Status | Notes |
| --- | --- | --- | --- |
| Timing Tower | `TimingTowerDisplay` | ✅ Ported | Produces race/non-race tables, status, and race control panels using `TimingTowerDataProvider`. |
| Logs | `LogDisplay` | ✅ Ported | Mirrors pagination, log level filtering, and cursor offset behaviour. |
| Timing History | `TimingHistoryDisplay` | ⏳ Pending | Requires charting primitives mirroring Spectre sparkline output. |
| Driver Tracker | `DriverTrackerDisplay` | ⏳ Pending | Needs graphics pipeline for sixel overlays after textual draw. |
| Info | `InfoDisplay` | ⏳ Pending | Multi-panel layout for weather, track, driver metadata. |
| Session Stats | `SessionStatsDisplay` | ⏳ Pending | Table aggregation for best/average lap metrics. |
| Tyre Stint | `TyreStintDisplay` | ⏳ Pending | Horizontal stint chart and tyre compound colouring. |
| Race Control | `RaceControlDisplay` | ⏳ Pending | Message timeline and incident detail panel. |
| Team Radio | `TeamRadioDisplay` | ⏳ Pending | Transcript queue with playback state. |
| Debug | `DebugDataDisplay` | ⏳ Pending | JSON dump with truncation controls. |
| Select Driver | `SelectDriverDisplay` | ⏳ Pending | Scrollable driver selection list. |
| Start Simulated Session | `StartSimulatedSessionDisplay` | ⏳ Pending | Multi-step wizard with validation hints. |
| Manage Session | `ManageSessionDisplay` | ⏳ Pending | Session timeline plus manual overrides. |
| Download Transcription | `DownloadTranscriptionModelDisplay` | ⏳ Pending | Progress bar and error summary. |

The ported displays rely on the rendering primitives defined in `swift/UndercutF1Terminal/Sources/UndercutF1Terminal/Layout.swift` and data-provider protocols that map directly to the C# processors. Pending displays have detailed notes pointing to their Spectre counterparts to support ongoing translation.
