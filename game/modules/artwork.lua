-- modules/artwork.lua
-- Resolve and load a game's artwork from muOS's info catalogue.
--
-- muOS creates  <root>/<CatalogueName>/<type>/  where <CatalogueName> is the
-- *assign* directory name (e.g. "Nintendo SNES"), NOT the ROM folder name.
-- Andromeda bind-mounts the catalogue to /run/muos/storage/info/catalogue from
-- whichever card holds it (SD2 wins if present, else SD1), so one path is
-- card-agnostic; the real per-card paths are tried as a fallback.
--
--   <root>/<CatalogueName>/<type>/<rom filename without ext>.<ext>
--     type : preview (screenshot) -> box -> splash
--     match: case-insensitive filename, .png first
--
-- Since we only ever resolve ONE picked game, if the obvious folder guesses
-- miss we brute-force every catalogue directory that exists on the device --
-- one cached `ls` per dir, always correct.

local artwork = {}

local TYPES = { "preview", "box", "splash" }
local EXTS  = { "png", "jpg", "jpeg", "bmp" }

local LOG = function(...) print("[artwork]", ...) end

-- Catalogue roots, in priority order.
local function catalogueRoots()
    local roots, seen = {}, {}
    local function add(p) if p and #p > 0 and not seen[p] then seen[p] = true; roots[#roots + 1] = p end end
    add(os.getenv("JARMU_CATALOGUE"))
    add("/run/muos/storage/info/catalogue")
    for _, k in ipairs({ "JARMU_ROM_SD1", "JARMU_ROM_SD2" }) do
        local m = os.getenv(k)
        if m and #m > 0 then add(m .. "/MUOS/info/catalogue") end
    end
    return roots
end

-- Cached directory listing:  dir -> { lowercase -> realname }
local dirCache = {}
local function listDir(dir)
    local c = dirCache[dir]
    if c ~= nil then return c end
    local map = {}
    local h = io.popen('ls -1 "' .. dir .. '" 2>/dev/null')
    if h then
        for line in h:lines() do
            if line and #line > 0 then map[line:lower()] = line end
        end
        h:close()
    end
    dirCache[dir] = map
    return map
end

local function findFile(dir, stem)
    local map = listDir(dir)
    for _, ext in ipairs(EXTS) do
        local want = (stem .. "." .. ext):lower()
        if map[want] then return dir .. "/" .. map[want] end
    end
    return nil
end

-- Image filename candidates: the ROM filename minus its extension, and the
-- cleaned display name.
local function stemsFor(game)
    local out, seen = {}, {}
    local function add(s) if s and #s > 0 and not seen[s] then seen[s] = true; out[#out + 1] = s end end
    if game.filename then add((game.filename:gsub("%.[%w]+$", ""))) end
    add(game.name)
    return out
end

-- Substrings that identify a platform inside an assign / catalogue dir name.
local SYS_KEYWORDS = {
    snes = { "snes", "super nintendo", "super famicom" },
    nes  = { "- nes", " nes", "famicom", "nintendo entertainment" },
    gb   = { "game boy" }, gbc = { "game boy color" }, gba = { "game boy advance" },
    n64  = { "nintendo 64", "n64" }, nds = { "nintendo ds" },
    md = { "mega drive", "megadrive", "genesis" }, megadrive = { "mega drive", "genesis" },
    genesis = { "genesis", "mega drive" },
    ms = { "master system" }, gg = { "game gear" },
    sega32x = { "32x" }, segacd = { "sega cd", "mega cd" }, saturn = { "saturn" },
    dreamcast = { "dreamcast" },
    ps = { "playstation" }, psx = { "playstation" }, psp = { "psp", "playstation portable" },
    pce = { "pc engine", "turbografx", "turbo grafx" }, tg16 = { "turbografx", "pc engine" },
    ngp = { "neo geo pocket" }, ngpc = { "neo geo pocket color" },
    arcade = { "arcade", "mame", "fbneo", "fb neo", "neo geo" },
    fbneo = { "fbneo", "fb neo", "arcade" }, mame = { "mame", "arcade" },
    dos = { "dos" }, scummvm = { "scummvm" }, pico8 = { "pico" },
    c64 = { "commodore 64" }, amiga = { "amiga" }, msx = { "msx" },
    a2600 = { "atari 2600", "2600" }, lynx = { "lynx" }, wsc = { "wonderswan" }, ws = { "wonderswan" },
    ports = { "port" },
}

-- Read the muOS-canonical catalogue name for a ROM folder, if muOS has an
-- auto-assign core.cfg for it. Line 4 = catalogue (see content.h content_field).
local function coreCfgCatalogue(folder)
    if not folder then return nil end
    local share = os.getenv("MUOS_SHARE_DIR") or "/opt/muos/share"
    local f = io.open(share .. "/info/content/" .. folder .. "/core.cfg", "r")
    if not f then return nil end
    local n = 0
    for line in f:lines() do
        n = n + 1
        if n == 4 then f:close(); line = line:gsub("%s+$", ""); return #line > 0 and line or nil end
    end
    f:close()
    return nil
end

-- Ordered list of catalogue dir names to try for a game, within one root.
local function catNamesFor(game, root)
    local out, seen = {}, {}
    local function add(s) if s and #s > 0 and not seen[s:lower()] then seen[s:lower()] = true; out[#out + 1] = s end end

    if game.port then add("Application"); add("Ports") end

    add(coreCfgCatalogue(game.folder))          -- authoritative when present
    add(game.folder)                            -- "snes"
    if game.folder then add(game.folder:upper()) end
    add(game.system)                            -- "SNES" / "PlayStation"

    -- keyword match against the dirs that actually exist under this root
    local real = listDir(root)                  -- lower -> realname
    local kws  = SYS_KEYWORDS[(game.folder or ""):lower()]
    if kws then
        for lname, realname in pairs(real) do
            for _, kw in ipairs(kws) do
                if lname:find(kw, 1, true) then add(realname); break end
            end
        end
    end

    -- last resort: every catalogue dir on the device
    for _, realname in pairs(real) do add(realname) end

    return out
end

-- Absolute path to a usable artwork file, or nil.
function artwork.pathFor(game)
    if not game or game.virtual then return nil end
    local stems = stemsFor(game)
    for _, root in ipairs(catalogueRoots()) do
        if next(listDir(root)) then
            for _, cat in ipairs(catNamesFor(game, root)) do
                for _, t in ipairs(TYPES) do
                    local dir = root .. "/" .. cat .. "/" .. t
                    for _, stem in ipairs(stems) do
                        local hit = findFile(dir, stem)
                        if hit then return hit end
                    end
                end
            end
        end
    end
    return nil
end

-- Load the artwork for `game` as a LÖVE Image, or nil. Caches the last hit.
local last = { path = nil, image = nil }
function artwork.load(game)
    local path = artwork.pathFor(game)
    if not path then
        LOG("no catalogue image for", game and game.name or "?")
        last = { path = nil, image = nil }
        return nil
    end
    if last.path == path then return last.image end

    local f = io.open(path, "rb")
    if not f then last = { path = nil, image = nil }; return nil end
    local bytes = f:read("*a"); f:close()
    if not bytes or #bytes == 0 then return nil end

    local function decode()
        local idata
        if love.data and love.data.newByteData then
            idata = love.image.newImageData(love.data.newByteData(bytes))
        else
            idata = love.image.newImageData(love.filesystem.newFileData(bytes, "art"))
        end
        return love.graphics.newImage(idata)
    end

    local ok, img = pcall(decode)
    if ok and img then
        LOG("loaded", path)
        last = { path = path, image = img }
        return img
    end
    LOG("decode failed for", path, tostring(img))
    last = { path = nil, image = nil }
    return nil
end

-- Drop the per-session dir cache (call after a library rescan).
function artwork.clearCache()
    dirCache = {}
    last = { path = nil, image = nil }
end

return artwork
