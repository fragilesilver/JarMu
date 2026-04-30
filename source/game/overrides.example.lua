-- overrides.example.lua
-- Copy this file to /mnt/mmc/MUOS/application/JarMu/.local/share/love/JarMu/overrides.lua
-- Edit it to tag your games and set their backlog/favourite status.
--
-- The keys must be the EXACT rom_path as found by the scanner.
-- Run the app once with logging enabled to see your scanned paths in the cache.lua file.

return {
    ["/mnt/mmc/ROMS/SNES/Chrono Trigger (USA).sfc"] = {
        tags   = {"RPG", "long", "story"},
        status = "favourite",
    },
    ["/mnt/mmc/ROMS/GBA/Metroid Fusion (USA).gba"] = {
        tags   = {"metroidvania", "short"},
        status = "backlog",
    },
    ["/mnt/mmc/ROMS/PS1/Final Fantasy VII (Disc 1).cue"] = {
        tags   = {"RPG", "long", "story"},
        status = "playing",
    },

    -- Example of a manual entry not produced by the scanner.
    -- Set virtual = true and provide your own rom_path key.
    ["/mnt/mmc/ROMS/PCE/My Custom Game.pce"] = {
        virtual = true,
        name    = "My Custom Game",
        system  = "PC Engine",
        tags    = {"shmup", "short"},
        status  = "backlog",
    },
}
