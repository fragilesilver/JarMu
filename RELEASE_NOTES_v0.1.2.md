# JarMu v0.1.2

Second demo build. Two major fixes that make the app actually usable.

**Download:** `JarMu-demo-0.1.2.muxapp` (attached below)

## Install

1. Download the `.muxapp` below and copy it to `/mnt/mmc/ARCHIVE/` on your device.
2. On the device: **Applications → Archive Manager → JarMu-demo-0.1.2.muxapp**.
3. Launch from **Applications → JarMu**.

## What's fixed

- **All non-shake buttons now work.** The previous build had an input-timing
  bug that wiped edge-triggered button presses before any scene could read
  them, which is why only "hold A to shake" worked and L/R/X/Y/B all silently
  did nothing.
- **B button quits from the main jar screen** back to the muOS launcher.
- **Splash screen actually waits for input** instead of auto-advancing after
  2 seconds. Includes a "release first" guard so the launch button doesn't
  immediately dismiss the splash.
- **Filter screen no longer crashes on L/R press** — fixed a `setColor`
  ternary that was only passing the first of theme.color's 4 return values.

## Known issues (not fixed in this build)

- Filter columns longer than the visible area don't scroll.
- Theme cycle (X on jar screen) doesn't repaint existing tokens until you
  visit Filters and come back.
- Result screen "A = Launch" is still a placeholder; muOS launcher hand-off
  is the main work for v0.2.

See [README → Known Issues](https://github.com/mdhaziqomar/jarmu#known-issues)
for the full list. **Please don't open new issues for these — comment on the
existing tracking issues instead.**

## Tested on

x86_64 Linux LÖVE 11.5 (sandbox testing only). **Not yet verified on real
RG35XX hardware.** First testers very welcome — gamepad button mapping is
the most likely thing to need adjustment.

## Reporting bugs

Use the [bug report template](https://github.com/mdhaziqomar/jarmu/issues/new?template=bug_report.yml).
Please attach `/mnt/mmc/MUOS/application/JarMu/jarmu.log` if it crashed.

## Full changelog

See [CHANGELOG.md](https://github.com/mdhaziqomar/jarmu/blob/main/CHANGELOG.md).
