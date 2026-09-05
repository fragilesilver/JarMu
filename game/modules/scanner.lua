-- modules/scanner.lua
-- Scans muOS ROM storage on BOTH cards plus PortMaster ports.
--   SD1 (rom mount)    : GET_VAR device storage/rom/mount     -> /mnt/mmc
--   SD2 (sdcard mount) : GET_VAR device storage/sdcard/mount  -> /mnt/sdcard
-- The launcher resolves these and exports JARMU_ROM_SD1 / JARMU_ROM_SD2 so
-- this works on every RG35XX variant (and any other muOS device). On each
-- card muOS creates <mount>/ROMS/<system>/ for emulator content and
-- <mount>/ports/ for PortMaster games.

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

-- Card mount points: prefer what the launcher resolved from muOS, else the
-- RG35XX-family defaults. SD2 is only included if the user actually has one.
local function cardMounts()
    local mounts = {}
    local sd1 = os.getenv("JARMU_ROM_SD1")
    local sd2 = os.getenv("JARMU_ROM_SD2")
    if sd1 and #sd1 > 0 then mounts[#mounts+1] = sd1 end
    if sd2 and #sd2 > 0 then mounts[#mounts+1] = sd2 end
    if #mounts == 0 then
        mounts = { "/mnt/mmc", "/mnt/sdcard" }
    end
    return mounts
end

-- ROM system-folder roots (both cards, upper- and lower-case ROMS).
local function romRoots()
    local roots = {}
    for _, m in ipairs(cardMounts()) do
        roots[#roots+1] = m .. "/ROMS"
        roots[#roots+1] = m .. "/roms"
    end
    return roots
end

-- PortMaster port roots (both cards). muOS creates <mount>/ports.
local function portRoots()
    local roots = {}
    for _, m in ipairs(cardMounts()) do
        roots[#roots+1] = m .. "/ports"
        roots[#roots+1] = m .. "/PORTS"
        roots[#roots+1] = m .. "/ROMS/PORTS"
    end
    return roots
end

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

-- ============================================================
-- GENRE (auto-populated from gamelist.xml; never written back)
-- ============================================================
-- Raw scraper genre string -> JarMu's canonical lower-case genre.
local GENRE_ALIAS = {
    ["role-playing"]="rpg", ["role playing"]="rpg", ["rpg"]="rpg",
    ["jrpg"]="rpg", ["action rpg"]="rpg", ["action role-playing"]="rpg",
    ["shoot 'em up"]="shmup", ["shoot-'em-up"]="shmup", ["shoot em up"]="shmup",
    ["shmup"]="shmup", ["shooter"]="shmup", ["run and gun"]="shmup",
    ["beat 'em up"]="beat-em-up", ["beat-'em-up"]="beat-em-up", ["beat em up"]="beat-em-up",
    ["platform"]="platformer", ["platformer"]="platformer",
    ["fighting"]="fighting", ["fighter"]="fighting", ["versus fighting"]="fighting",
    ["puzzle"]="puzzle", ["puzzle-solving"]="puzzle",
    ["racing"]="racing", ["driving"]="racing", ["racing / driving"]="racing",
    ["sports"]="sports", ["sport"]="sports",
    ["strategy"]="strategy", ["real-time strategy"]="strategy",
    ["turn-based strategy"]="strategy", ["tactics"]="strategy", ["strategy / tactics"]="strategy",
    ["adventure"]="adventure", ["action-adventure"]="adventure",
    ["point-and-click"]="adventure", ["graphic adventure"]="adventure",
    ["action"]="action", ["arcade"]="arcade", ["compilation"]="arcade",
    ["horror"]="horror", ["survival horror"]="horror",
    ["simulation"]="simulation", ["sim"]="simulation", ["life simulation"]="simulation",
    ["metroidvania"]="metroidvania", ["visual novel"]="visual-novel",
    ["pinball"]="pinball", ["rhythm"]="rhythm", ["music"]="rhythm", ["educational"]="educational",
}

-- Everything JarMu will offer in the in-app genre editor, plus whatever
-- gamelist.xml turns up.
local GENRE_PRESETS = {
    "action","adventure","arcade","beat-em-up","fighting","horror","metroidvania",
    "platformer","puzzle","racing","rhythm","rpg","shmup","simulation","sports",
    "strategy","visual-novel","port",
}
scanner.GENRE_PRESETS = GENRE_PRESETS

local function canonGenre(raw)
    raw = tostring(raw or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
    if #raw == 0 then return nil end
    return GENRE_ALIAS[raw] or raw
end

-- "Action / Adventure, RPG & Strategy" -> {"action","adventure","rpg","strategy"}
local function splitGenres(s)
    s = tostring(s or ""):gsub("%s+[Aa][Nn][Dd]%s+", "/")   -- "X and Y" -> split
    local out, seen = {}, {}
    for part in s:gmatch("[^/,;|&]+") do
        local g = canonGenre(part)
        if g and not seen[g] then seen[g] = true; out[#out + 1] = g end
    end
    table.sort(out)
    return out
end
scanner.splitGenres = splitGenres

-- Parse <folder>/gamelist.xml -> { basename(lower) -> {genre,...} }
local function readGamelist(folder)
    local map = {}
    local f = io.open(folder .. "/gamelist.xml", "r")
    if not f then return map end
    local xml = f:read("*a"); f:close()
    if not xml then return map end
    for block in xml:gmatch("<game[%s>].-</game>") do
        local rel   = block:match("<path>%s*(.-)%s*</path>")
        local genre = block:match("<genre>%s*(.-)%s*</genre>")
        if rel and genre and #genre > 0 then
            local base = rel:gsub("^%./", ""):match("([^/]+)$")
            if base then
                genre = genre:gsub("&amp;", "&"):gsub("&apos;", "'")
                             :gsub("&quot;", '"'):gsub("&lt;", "<"):gsub("&gt;", ">")
                map[base:lower()] = splitGenres(genre)
            end
        end
    end
    return map
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

    local genreMap = readGamelist(full)   -- basename -> {genre,...}

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
                genres    = genreMap[entry:lower()] or {},
                status    = "backlog",
                play_count = 0,
            })
        end
    end
    return games
end

-- PortMaster ports: each port is a launcher <name>.sh in a ports/ folder.
-- We list the .sh files and present them as games under system "Ports".
local PM_SKIP = {
    ["portmaster.sh"] = true, ["harbourmaster"] = true,
    ["pmsplash.sh"] = true, ["mod_"] = true, ["gamelist.xml"] = true,
}

local function scanPortsFolder(root, seen)
    local out = {}
    if not isDir(root) then return out end
    for _, entry in ipairs(listDir(root)) do
        local lower = entry:lower()
        if lower:match("%.sh$") and not PM_SKIP[lower] and not lower:match("^mod_") then
            local rom_path = root .. "/" .. entry
            if not seen[rom_path] then
                seen[rom_path] = true
                local name = entry:gsub("%.sh$", ""):gsub("[_%.]+", " ")
                name = name:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
                out[#out+1] = {
                    name       = name,
                    rom_path   = rom_path,
                    system     = "Ports",
                    folder     = "ports",
                    filename   = entry,
                    genres     = { "port" },
                    status     = "backlog",
                    play_count = 0,
                    port       = true,
                }
            end
        end
    end
    return out
end

function scanner.scan()
    local all = {}
    local roots_used = {}
    local seen_paths = {}

    -- Emulator ROMs on both cards
    for _, root in ipairs(romRoots()) do
        if exists(root) then
            table.insert(roots_used, root)
            for _, sub in ipairs(listDir(root)) do
                if isDir(root .. "/" .. sub) and sub:lower() ~= "ports" then
                    for _, g in ipairs(scanSystemFolder(root, sub)) do
                        if not seen_paths[g.rom_path] then
                            seen_paths[g.rom_path] = true
                            table.insert(all, g)
                        end
                    end
                end
            end
        end
    end

    -- PortMaster ports on both cards
    for _, root in ipairs(portRoots()) do
        if exists(root) then
            local ports = scanPortsFolder(root, seen_paths)
            if #ports > 0 then table.insert(roots_used, root) end
            for _, g in ipairs(ports) do table.insert(all, g) end
        end
    end

    return all, roots_used
end

-- Bundled sample list used when no ROMs are found, so the demo is still
-- exercisable on a desktop or fresh device. Marked virtual so the launch
-- button can communicate that they cannot actually be launched.
function scanner.sampleGames()
    local sample = {
        {name="Chrono Trigger",        system="SNES",          genres={"rpg"},          status="backlog"},
        {name="Super Mario World",     system="SNES",          genres={"platformer"},   status="favourite"},
        {name="Castlevania: SOTN",     system="PlayStation",   genres={"metroidvania"}, status="backlog"},
        {name="Final Fantasy VI",      system="SNES",          genres={"rpg"},          status="backlog"},
        {name="Sonic the Hedgehog 2",  system="Mega Drive",    genres={"platformer"},   status="beaten"},
        {name="The Legend of Zelda: Link's Awakening", system="Game Boy", genres={"adventure"}, status="backlog"},
        {name="Pokemon Crystal",       system="Game Boy Color",genres={"rpg"},          status="favourite"},
        {name="Metroid Fusion",        system="Game Boy Advance", genres={"metroidvania"}, status="backlog"},
        {name="Advance Wars",          system="Game Boy Advance", genres={"strategy"},  status="backlog"},
        {name="Super Metroid",         system="SNES",          genres={"metroidvania"}, status="favourite"},
        {name="Earthbound",            system="SNES",          genres={"rpg"},          status="backlog"},
        {name="Doom",                  system="DOS",           genres={"shmup"},        status="beaten"},
        {name="Street Fighter II",     system="Arcade",        genres={"fighting"},     status="playing"},
        {name="Contra: Hard Corps",    system="Mega Drive",    genres={"action","shmup"}, status="backlog"},
        {name="Mega Man X",            system="SNES",          genres={"action","platformer"}, status="favourite"},
        {name="Symphony of the Night", system="PlayStation",   genres={"metroidvania"}, status="playing"},
        {name="Final Fantasy VII",     system="PlayStation",   genres={"rpg"},          status="backlog"},
        {name="Crash Bandicoot",       system="PlayStation",   genres={"platformer"},   status="beaten"},
        {name="Tony Hawk's Pro Skater 2", system="PlayStation",genres={"sports"},       status="backlog"},
        {name="Resident Evil 2",       system="PlayStation",   genres={"horror"},       status="backlog"},
        {name="Mario Kart: Super Circuit", system="Game Boy Advance", genres={"racing"}, status="playing"},
        {name="Wario Land 4",          system="Game Boy Advance", genres={"platformer"}, status="backlog"},
        {name="Golden Sun",            system="Game Boy Advance", genres={"rpg"},       status="backlog"},
        {name="Tetris",                system="Game Boy",      genres={"puzzle"},       status="favourite"},
        {name="Donkey Kong Country",   system="SNES",          genres={"platformer"},   status="beaten"},
        {name="Streets of Rage 2",     system="Mega Drive",    genres={"beat-em-up"},   status="favourite"},
        {name="Phantasy Star IV",      system="Mega Drive",    genres={"rpg"},          status="backlog"},
        {name="Shining Force",         system="Mega Drive",    genres={"strategy"},     status="backlog"},
        {name="Toejam & Earl",         system="Mega Drive",    genres={"adventure"},    status="backlog"},
        {name="Klonoa: Empire of Dreams", system="Game Boy Advance", genres={"platformer","puzzle"}, status="backlog"},
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
