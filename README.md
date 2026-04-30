# JarMu

A "shake the jar" random ROM picker for muOS. Built with LÖVE2D.

JarMu watches your ROM folders, lets you filter what's eligible, then picks
one when you shake the jar. Hold A to charge a power meter; release in the
sweet spot for a "perfect shake" that biases the pick toward your backlog.

> **Demo build (v0.1.2)** — full v1 feature set minus polish. Looking for
> testers across the RG35XX family. See **Known Issues** below before reporting
> bugs that are already on the list.

## Compatibility

- **muOS:** 2601.1 Funky Jacaranda
- **Devices:** RG35XX+ / 2024 / SP / H / Pro (any 640×480 H700 device)
- **Resolution:** Designed for 640×480

## Features

- Auto-scans `/mnt/mmc/ROMS` and `/mnt/sdcard/ROMS`; falls back to 30 bundled
  sample games if no ROMs are detected, so the demo is exercisable before
  you copy any ROMs over.
- Hold-and-release shake mechanic with a power meter. Land in the sweet spot
  for a "perfect shake" — backlog and favourite games get a weighting bonus,
  and the result reveal gets a sparkle treatment.
- Filter by system, by tag (any/all match), and by status
  (backlog / playing / beaten / favourite). Hidden games are always excluded.
- Surprise Me mode ignores all filters.
- Weighted randomness by default (backlog ×3, favourite ×2, playing ×1.5,
  beaten ×0.5). Toggleable in the filters screen.
- Last 5 picks excluded from re-pick to avoid repeats.
- "Not feeling it" button skips a game for the current session.
- 8 colour themes matching ClockMu (Mustard, Orange, Red, Blue, Green,
  Purple, White, Black). Press X on the jar screen to cycle.
- Retro arcade visual style: CRT scanlines, chromatic aberration, neon glow on
  tokens.
- Manual tag and status overrides via an editable Lua file (see below).

## Install

1. Download `JarMu-demo-0.1.2.muxapp` from the
   [Releases page](https://github.com/mdhaziqomar/jarmu/releases).
2. Copy it to `/mnt/mmc/ARCHIVE/` on your device (via SD card reader or SFTP).
3. On the device, open **Applications → Archive Manager** and select
   `JarMu-demo-0.1.2.muxapp`.
4. Once installed, launch from **Applications → JarMu**.

## Controls

### Splash screen

Press any button to enter the jar. If a button was still held when the splash
appeared (e.g. you held A to launch), release it first — the hint will say
"RELEASE TO BEGIN" until everything's released.

### Jar screen (main)

| Button | Action |
|--------|--------|
| **Hold A** | Build shake power |
| **Release A** | Tip the jar (in sweet spot = perfect shake) |
| **L / R** | Open Filters screen |
| **Y** | Toggle Surprise Me mode |
| **X** | Cycle theme colour |
| **B** | Quit JarMu (returns to muOS) |
| **Select** | Toggle SFX on/off |

### Filters screen

| Button | Action |
|--------|--------|
| **D-pad up/down** | Move within column |
| **L / R** | Switch column (Systems / Tags / Status) |
| **A** | Toggle item |
| **Y** | Include all items in current column |
| **B** | Back to jar |

### Result screen (after a pick)

| Button | Action |
|--------|--------|
| **A** | Launch ROM (not yet wired in demo — shows placeholder) |
| **B** | Reshake (return to jar) |
| **Y** | "Not feeling it" — skip this game for the session |
| **X** | Cycle status (backlog → playing → beaten → favourite) |

## Manual tags and overrides

Tags and status changes you make in-app are saved automatically. You can also
edit a Lua file directly to apply overrides in bulk.

1. Run JarMu once on the device. This produces a save file at:
   `/mnt/mmc/MUOS/application/JarMu/.local/share/love/JarMu/cache.lua`
2. Open `cache.lua` to find the exact `rom_path` strings the scanner produced.
3. Create a sibling file `overrides.lua` next to `cache.lua` using the
   structure shown in `source/game/overrides.example.lua`. Map each ROM path
   to the tags and status you want.
4. Restart JarMu — overrides are applied on top of the cache.

You can also add **manual entries** for games not present on disk by setting
`virtual = true` in the override (useful for tracking physical carts you
haven't ripped, or games you plan to grab soon).

## Known Issues

These are bugs already known and tracked. Please don't open new issues for
them — comment on the existing one if you have additional reproduction info.

- **Filter list scrolling.** Console / handheld lists longer than the visible
  column don't scroll. The cursor moves but items past the bottom edge are
  cut off.
- **Theme change doesn't update jar tokens immediately.** When cycling theme
  with X on the jar screen, the existing tokens keep their old colour until
  you visit Filters and come back. (Tokens are recreated on scene re-entry.)
- **Launch button is a placeholder.** On the result screen, A shows a
  "not yet wired" overlay rather than handing off to the muOS launcher.
- **Gamepad button mapping unverified on hardware.** Tested on x86_64 LÖVE
  only. RG35XX face button assignments may need adjustment.

## Coming soon

- Fix scrolling in long filter lists.
- Live theme update on the jar without scene change.
- Real ROM launching via muOS launcher hand-off.
- History screen showing the last N picks.
- In-app on-screen keyboard for tagging without editing files.
- Recorded SFX samples (current SFX are procedurally synthesised).
- System icon images instead of text labels.
- Box art display on the result card (where available).
- Multi-jar profiles (e.g. "kids", "solo", "co-op").

## Reporting bugs

Open an issue at
[github.com/mdhaziqomar/jarmu/issues](https://github.com/mdhaziqomar/jarmu/issues)
using the bug report template. Include:

- Your device (e.g. RG35XX H, RG35XX SP)
- muOS version (Settings → Information)
- What you were doing when the bug happened
- The contents of `/mnt/mmc/MUOS/application/JarMu/jarmu.log` if it crashed

Please check **Known Issues** above before opening a new ticket.

## Building from source

```bash
# On a desktop with LÖVE 11.4 or 11.5 installed:
cd source/game
love .
```

To rebuild the `.muxapp`:

```bash
cd source
mkdir -p build/mnt/mmc/MUOS/application/JarMu
cp -r love game glyph mux_launch.ini mux_launch.sh \
    build/mnt/mmc/MUOS/application/JarMu/
cd build
zip -r ../../JarMu-demo-0.1.2.muxapp .
```

## Credits

- LÖVE2D 11.4 aarch64 binary by
  [Cebion/love2d_aarch64](https://github.com/Cebion/love2d_aarch64)
- Inspired by [ClockMu](https://community.muos.dev/t/clockmu-an-alarm-clock-for-funky-jacaranda/1496)
- Built for the muOS community

## Licence

GPL-3.0-or-later. See [LICENSE](LICENSE).

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.
