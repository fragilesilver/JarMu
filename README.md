## JarMu

A "shake the jar" random game picker for **[muOS](https://muos.dev/) Andromeda**
on the **Anbernic RG35XX family** (all Allwinner H700 - Pro, Plus, H, SP, 2024).
Built with LÖVE2D on the shared **[fskit](#-built-on-fskit)** kit, with a retro
arcade look. Jacaranda-compatible.

<img width="640" height="480" alt="screenshot_splash" src="https://github.com/user-attachments/assets/ca257d31-2f3d-4dc3-8ac3-a17939961d8a" />
<br>
<img width="640" height="480" alt="screenshot_jar" src="https://github.com/user-attachments/assets/5f0d53ca-cf92-4fc7-9a57-c1a0640b4190" />

### 🚀 Features
- Scans **SD1 and SD2** - `ROMS/<system>/` on both cards, plus **PortMaster**
  ports (`ports/*.sh`). Falls back to a bundled sample set if nothing is found.
- Hold-and-release shake with a power meter - land in the sweet spot for a
  "perfect shake" (backlog and favourites get a weighting bonus)
- Filter by **system**, **genre** (any/all match), and **status**
  (backlog / playing / beaten / favourite)
- "Surprise Me" mode ignores every filter
- Weighted randomness (backlog ×3, favourite ×2, playing ×1.5, beaten ×0.5),
  with re-pick avoidance for the last few picks
- **Genres auto-populate from each system's `gamelist.xml`** and are
  canonicalised; ports are tagged `port`
- **In-app genre editing** on the result screen - writes only to the app's own
  `save/usergenres.lua`, never your `gamelist.xml` or metadata
- **Game artwork** on the result screen, pulled from the muOS info catalogue
  (`preview` → `box` → `splash`), resolved by the same catalogue name muOS assigns
- 8 colour themes shared with ClockMu and BatteryMu
- Retro visuals: CRT scanlines, chromatic aberration, neon glow
- **No launching** - JarMu decides *what* to play; you hand off to muOS yourself.
  This keeps it robust across every RG35XX variant and Andromeda's launch changes.
- Letterboxed 640×480 render - safe on every RG35XX panel variant, and on HDMI-out

### 📥 Installation
1. Download the latest `.muxapp` from [Releases](https://github.com/fragilesilver/JarMu/releases).
2. Copy it to `ARCHIVE/` on your SD card.
3. On the device: **Applications → Archive Manager**, select the file.
4. Launch from **Applications → JarMu**.

### 🎮 Controls

#### Splash
| Button | Action |
|--------|--------|
| Any button | Enter the jar (release any held button first - "RELEASE TO BEGIN") |

#### Jar (main)
| Button | Action |
|--------|--------|
| **Hold A** | Build shake power |
| **Release A** | Tip the jar (sweet spot = perfect shake) |
| **L1 / R1** | Open Filters |
| **Y** | Toggle Surprise Me |
| **X** | Cycle theme colour |
| **Select** | Toggle SFX |
| **B** | Quit to muOS |

#### Filters
| Button | Action |
|--------|--------|
| D-pad Up/Down | Move within column |
| **L1 / R1** | Switch column (Systems / Genre / Status) |
| **A** | Toggle item (or flip genre match mode any/all) |
| **Y** | Include all items in the current column |
| **B** | Back to jar |

#### Result (after a pick)
| Button | Action |
|--------|--------|
| **A** / **B** | Reshake (back to jar) |
| **Y** | "Not feeling it" - skip this game for the session |
| **X** | Cycle status (backlog → playing → beaten → favourite) |
| **L1** | Open the genre editor |

#### Genre editor
| Button | Action |
|--------|--------|
| Up/Down | Move through the preset genre list |
| **A** | Toggle the highlighted genre |
| **B** / **L1** | Done |

### 💾 Data & Overrides

JarMu writes only inside its own `save/` directory (via the `JARMU_DATA` path the
launcher exports): the scan cache, session state, and your genre/status edits.

Genre precedence, lowest to highest:

1. `gamelist.xml` (read-only, never modified)
2. `save/overrides.lua` - optional, hand-edited for bulk changes
   (see `game/overrides.example.lua` for the format)
3. `save/usergenres.lua` - written by the in-app genre editor

`overrides.lua` can also carry manual entries for games not on disk
(`virtual = true`).

### 📝 Notes

- Artwork needs the muOS catalogue populated for the system (Content → the
  system → download/scrape artwork). JarMu logs catalogue hits and misses to
  `jarmu.log`.
- SD2 wins when both cards hold a catalogue, matching muOS's bind-mount.
- SFX are procedurally synthesised - no audio assets.

### 🧩 Built on fskit

JarMu, [ClockMu](https://github.com/fragilesilver/ClockMu) and
[BatteryMu](https://github.com/fragilesilver/BatteryMu) share **fskit** - a small
LÖVE2D kit providing the letterboxed 640×480 screen, the theme palette, fonts,
glyphs, input abstraction and the header/footer chrome. JarMu keeps its own
theme, input and CRT modules and pulls `fskit.screen` for the letterbox and CRT
compositing, so the three apps stay consistent on every RG35XX variant.

### 🙏 Credits

- LÖVE2D aarch64 runtime by [Cebion/love2d_aarch64](https://github.com/Cebion/love2d_aarch64)
- Built for the muOS community

### 📄 Licence

GPL-3.0-or-later. See [LICENSE](LICENSE).

---

Part of the **fragilesilver** muOS app family - [ClockMu](https://github.com/fragilesilver/ClockMu) · [JarMu](https://github.com/fragilesilver/JarMu) · [BatteryMu](https://github.com/fragilesilver/BatteryMu).
