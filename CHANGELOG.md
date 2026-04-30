# Changelog

All notable changes to JarMu will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Known issues
- Filter columns longer than visible area don't scroll (cursor moves but items
  past bottom are cut off).
- Theme cycle on jar screen doesn't repaint existing tokens until next scene
  change.
- Result screen "A = Launch" still shows placeholder; muOS hand-off not wired.
- `setColor` crash possible if the codebase still has any
  `setColor(cond and theme.color(...) or theme.color(...))` patterns hiding
  in scenes; first one was fixed in v0.1.2 (filters.lua line 151) but a full
  audit is pending.

## [0.1.2] - 2026-05-01

### Added
- B button on main jar screen now quits the app cleanly back to muOS launcher.
- Splash screen "release first" guard: if a button is still held when splash
  loads (because launching the app required holding A), splash shows
  "RELEASE TO BEGIN" until all buttons are released, then accepts any press.
- Footer hint on jar scene now displays `[B] QUIT`.

### Fixed
- **Major input bug:** `pressed_this_frame` was being cleared in
  `input.update()` BEFORE scenes ran their update functions, meaning every
  edge-triggered button check (`input.pressed(...)`) was guaranteed to return
  false. Only `input.held("a")` worked, which is why the hold-to-shake
  mechanic functioned but L/R/Y/X/B did nothing. Fixed by introducing
  `input.endFrame()` called by main.lua AFTER scene updates have run.
- Splash screen no longer auto-advances after 2s — was masking the input bug
  and preventing a real "press any button" flow.
- `setColor` ternary crash in `scenes/filters.lua` (line 151) — the pattern
  `setColor(cond and theme.color(...) or theme.color(...))` only kept the
  first of theme.color's 4 returned values. Replaced with explicit if/else.

## [0.1.1] - 2026-04-30

### Fixed
- Box2D contact callback API used the wrong signature; `getNormalImpulses`
  was being called on `Contact` (which doesn't have it). Switched to the
  `postSolve` callback's impulse argument.
- Library cache schema mismatch could crash on startup if a previous build
  had written a cache with different field names. Now validated and
  re-scanned silently.
- `printf` with scale uses the unscaled width for centring then renders
  scaled, pushing titles off-screen. Replaced with manual width-aware
  `print` calls.

## [0.1.0] - 2026-04-30

### Added
- Initial demo build.
- Hold-and-release shake mechanic with power meter and "perfect shake" sweet
  spot detection.
- Auto-scan ROM folders under `/mnt/mmc/ROMS` and `/mnt/sdcard/ROMS`.
- Bundled 30 sample games as fallback when no ROMs detected.
- Filter UI: systems, tags (any/all), status (backlog/playing/beaten/favourite).
- Surprise Me mode bypassing all filters.
- Weighted random pick (toggleable): backlog ×3, favourite ×2, playing ×1.5,
  beaten ×0.5, with re-pick avoidance for last 5 picks.
- 8 colour theme palette matching ClockMu.
- Retro arcade visual style: CRT scanlines, chromatic aberration, neon glow.
- Procedurally generated SFX (no binary asset dependencies).
- Box2D-backed jar physics with bouncing tokens.
- File-based override system (`overrides.lua`) for manual tagging.
- muOS launcher integration via `mux_launch.sh` and `mux_launch.ini`.
- LÖVE2D 11.4 aarch64 binary bundled via Cebion/love2d_aarch64.

[Unreleased]: https://github.com/mdhaziqomar/jarmu/compare/v0.1.2...HEAD
[0.1.2]: https://github.com/mdhaziqomar/jarmu/releases/tag/v0.1.2
[0.1.1]: https://github.com/mdhaziqomar/jarmu/releases/tag/v0.1.1
[0.1.0]: https://github.com/mdhaziqomar/jarmu/releases/tag/v0.1.0
