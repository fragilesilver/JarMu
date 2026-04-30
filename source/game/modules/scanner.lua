-- modules/scanner.lua
-- Scans muOS ROM directories. The standard muOS layout puts ROMs under
-- /mnt/mmc/ROMS/<system>/ with optional /mnt/sdcard/ROMS/ for SD2.
-- Each system folder contains files in the appropriate format(s).

local scanner = {}

-- muOS folder name -> friendly system label
-- Source: muOS supported folder names + Onion ROM folder reference.
local SYSTEM_LABELS = {
    arcade      = "Arcade",
    fbneo       = "FBNeo",
    mame        = "MAME",
    a2600       = "Atari 2600",
    a5200       = "Atari 5200",
    a7800       = "Atari 7800",
    lynx        = "Atari Lynx",
    jaguar      = "Atari Jaguar",
    nes         = "NES",
    snes        = "SNES",
    n64         = "Nintendo 64",
    nds         = "Nintendo DS",
    gb          = "Game Boy",
    gbc         = "Game Boy Color",
    gba         = "Game Boy Advance",
    md          = "Mega Drive",
    megadrive   = "Mega Drive",
    genesis     = "Genesis",
    ms          = "Master System",
    gg          = "Game Gear",
    sega32x     = "Sega 32X",
    segacd      = "Sega CD",
    saturn      = "Saturn",
    dreamcast   = "Dreamcast",
    ps         = "PlayStation",
    psx         = "PlayStation",
    psp         = "PSP",
    pce         = "PC Engine",
    tg16        = "TurboGrafx-16",
    ngp         = "Neo Geo Pocket",
    ngpc        = "Neo Geo Pocket Color",
    wsc         = "WonderSwan",
    msx         = "MSX",
    c64         = "Commodore 64",
    amiga       = "Amiga",
    dos         = "DOS",
    zx          = "ZX Spectrum",
    scummvm     = "ScummVM",
    pico8       = "PICO-8",
    ports       = "Ports",
}

-- File extensions per system - liberal whitelist, anything not matching skipped.
local ROM_EXTS = {
    [".nes"]=true, [".sfc"]=true, [".smc"]=true, [".gba"]=true, [".gb"]=true,
    [".gbc"]=true, [".n64"]=true, [".z64"]=true, [".v64"]=true, [".nds"]=true,
    [".md"]=true,  [".smd"]=true, [".bin"]=true, [".gen"]=true, [".sms"]=true,
    [".gg"]=true,  [".pce"]=true, [".lnx"]=true, [".a26"]=true, [".a52"]=true,
    [".a78"]=true, [".jag"]=true, [".ngp"]=true, [".ngc"]=true, [".ws"]=true,
    [".wsc"]=true, [".cue"]=true, [".chd"]=true, [".iso"]=true, [".pbp"]=true,
    [".cso"]=true, [".zip"]=true, [".7z"]=true,  [".rom"]=true, [".col"]=true,
    [".int"]=true, [".d64"]=true, [".adf"]=true, [".dsk"]=true, [".min"]=true,
    [".p8"]=true,  [".gbz"]=true, [".gba.zip"]=true,
}

-- Default search roots. We probe each and use whichever exist.
local SEARCH_ROOTS = {
    "/mnt/mmc/ROMS",
    "/mnt/sdcard/ROMS",
    "/mnt/mmc/roms",
    "/mnt/sdcard/roms",
}

local function fileExtension(name)
    local lower = name:lower()
    -- Handle .gba.zip etc.
    local double = lower:match("(%.%a+%.%a+)$")
    if double and ROM_EXTS[double] then return double end
    return lower:match("(%.[%w]+)$")
end

local function cleanGameName(filename)
    -- Strip extension
    local name = filename:gsub("%.[%w]+$", "")
    -- Strip common region/dump tags: (USA), [!], (Rev 1), etc.
    name = name:gsub("%b()", "")
    name = name:gsub("%b[]", "")
    -- Collapse whitespace
    name = name:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return name
end

-- Use io.popen to list directory contents - love.filesystem can't read
-- arbitrary paths outside the save directory.
local function listDir(path)
    local f = io.popen('ls -1 "' .. path .. '" 2>/dev/null')
    if not f then return {} end
    local entries = {}
    for line in f:lines() do
        if line and #line > 0 then
            table.insert(entries, line)
        end
    end
    f:close()
    return entries
end

local function isDir(path)
    local f = io.popen('test -d "' .. path .. '" && echo yes 2>/dev/null')
    if not f then return false end
    local result = f:read("*l")
    f:close()
    return result == "yes"
end

local function exists(path)
    local f = io.popen('test -e "' .. path .. '" && echo yes 2>/dev/null')
    if not f then return false end
    local result = f:read("*l")
    f:close()
    return result == "yes"
end

local function scanSystemFolder(root, folder)
    local games = {}
    local full = root .. "/" .. folder
    if not isDir(full) then return games end

    for _, entry in ipairs(listDir(full)) do
        local rom_path = full .. "/" .. entry
        local ext = fileExtension(entry)
        if ext and ROM_EXTS[ext] then
            local system = SYSTEM_LABELS[folder:lower()] or folder:upper()
            table.insert(games, {
                name      = cleanGameName(entry),
                rom_path  = rom_path,
                system    = system,
                folder    = folder:lower(),
                filename  = entry,
                tags      = {},
                status    = "backlog",
                play_count = 0,
            })
        end
    end
    return games
end

function scanner.scan()
    local all = {}
    local roots_used = {}

    for _, root in ipairs(SEARCH_ROOTS) do
        if exists(root) then
            table.insert(roots_used, root)
            for _, sub in ipairs(listDir(root)) do
                if isDir(root .. "/" .. sub) then
                    local games = scanSystemFolder(root, sub)
                    for _, g in ipairs(games) do
                        table.insert(all, g)
                    end
                end
            end
        end
    end

    return all, roots_used
end

-- Bundled sample list used when no ROMs are found, so the demo is still
-- exercisable on a desktop or fresh device. Marked virtual so the launch
-- button can communicate that they cannot actually be launched.
function scanner.sampleGames()
    local sample = {
        {name="Chrono Trigger",        system="SNES",          tags={"RPG","long","story"},     status="backlog"},
        {name="Super Mario World",     system="SNES",          tags={"platformer","short"},     status="favourite"},
        {name="Castlevania: SOTN",     system="PlayStation",   tags={"metroidvania","long"},    status="backlog"},
        {name="Final Fantasy VI",      system="SNES",          tags={"RPG","long","story"},     status="backlog"},
        {name="Sonic the Hedgehog 2",  system="Mega Drive",    tags={"platformer","short"},     status="beaten"},
        {name="The Legend of Zelda: Link's Awakening", system="Game Boy", tags={"adventure","long"}, status="backlog"},
        {name="Pokemon Crystal",       system="Game Boy Color",tags={"RPG","long"},             status="favourite"},
        {name="Metroid Fusion",        system="Game Boy Advance", tags={"metroidvania","short"},status="backlog"},
        {name="Advance Wars",          system="Game Boy Advance", tags={"strategy","short"},    status="backlog"},
        {name="Super Metroid",         system="SNES",          tags={"metroidvania","long"},    status="favourite"},
        {name="Earthbound",            system="SNES",          tags={"RPG","long","story"},     status="backlog"},
        {name="Doom",                  system="DOS",           tags={"FPS","short"},            status="beaten"},
        {name="Street Fighter II",     system="Arcade",        tags={"fighting","short"},       status="playing"},
        {name="Contra: Hard Corps",    system="Mega Drive",    tags={"action","short"},         status="backlog"},
        {name="Mega Man X",            system="SNES",          tags={"action","short"},         status="favourite"},
        {name="Symphony of the Night", system="PlayStation",   tags={"metroidvania","long"},    status="playing"},
        {name="Final Fantasy VII",     system="PlayStation",   tags={"RPG","long","story"},     status="backlog"},
        {name="Crash Bandicoot",       system="PlayStation",   tags={"platformer","short"},     status="beaten"},
        {name="Tony Hawk's Pro Skater 2", system="PlayStation",tags={"sports","short"},         status="backlog"},
        {name="Resident Evil 2",       system="PlayStation",   tags={"horror","long"},          status="backlog"},
        {name="Mario Kart: Super Circuit", system="Game Boy Advance", tags={"racing","short"},  status="playing"},
        {name="Wario Land 4",          system="Game Boy Advance", tags={"platformer","short"},  status="backlog"},
        {name="Golden Sun",            system="Game Boy Advance", tags={"RPG","long","story"},  status="backlog"},
        {name="Tetris",                system="Game Boy",      tags={"puzzle","short"},         status="favourite"},
        {name="Donkey Kong Country",   system="SNES",          tags={"platformer","short"},     status="beaten"},
        {name="Streets of Rage 2",     system="Mega Drive",    tags={"beat-em-up","short"},     status="favourite"},
        {name="Phantasy Star IV",      system="Mega Drive",    tags={"RPG","long","story"},     status="backlog"},
        {name="Shining Force",         system="Mega Drive",    tags={"strategy","long"},        status="backlog"},
        {name="Toejam & Earl",         system="Mega Drive",    tags={"adventure","short","co-op"}, status="backlog"},
        {name="Klonoa: Empire of Dreams", system="Game Boy Advance", tags={"platformer","short"}, status="backlog"},
    }
    -- Decorate with virtual paths and metadata
    for i, g in ipairs(sample) do
        g.rom_path  = "(sample)/" .. g.system .. "/" .. g.name
        g.folder    = g.system:lower():gsub(" ", "_")
        g.filename  = g.name
        g.virtual   = true
        g.play_count = 0
    end
    return sample
end

return scanner
