-- overrides.example.lua  (OPTIONAL, power-user)
-- Copy to  <app dir>/save/overrides.lua  (the JARMU_DATA dir) to hand-set a
-- game's genres / status / friendly name. JarMu reads this file but NEVER
-- writes it.
--
-- Genres are normally filled in automatically from each system folder's
-- gamelist.xml, and you can add/remove them in-app on the result screen
-- (press L1). Those in-app edits are saved to  save/usergenres.lua  -- also
-- never touching gamelist.xml or this file. Precedence, lowest to highest:
--     gamelist.xml  <  overrides.lua  <  usergenres.lua
--
-- Keys must be the EXACT rom_path the scanner produced (see save/cache.lua).

return {
    ["/mnt/mmc/ROMS/SNES/Chrono Trigger (USA).sfc"] = {
        genres = { "rpg" },
        status = "favourite",
    },
    ["/mnt/mmc/ROMS/GBA/Metroid Fusion (USA).gba"] = {
        genres = { "metroidvania" },
        status = "backlog",
    },
    ["/mnt/sdcard/ROMS/PS1/Final Fantasy VII (Disc 1).cue"] = {
        genres = { "rpg" },
        status = "playing",
    },

    -- A manual entry the scanner did not produce: set virtual = true and
    -- provide your own rom_path key.
    ["/mnt/mmc/ROMS/PCE/My Custom Game.pce"] = {
        virtual = true,
        name    = "My Custom Game",
        system  = "PC Engine",
        genres  = { "shmup" },
        status  = "backlog",
    },
}
