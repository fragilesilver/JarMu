-- modules/library.lua
-- The in-memory game library. Loads cache from disk, applies user overrides,
-- exposes a unified games list to filters and picker.

local scanner = require("modules.scanner")

local library = {}

local CACHE_FILE     = "cache.lua"
local OVERRIDES_FILE = "overrides.lua"

local games = {}              -- flat array of game tables
local by_path = {}            -- rom_path -> game (fast lookup for overrides)
local roots_used = {}         -- list of /mnt paths actually scanned

local function serialize(t, indent)
    indent = indent or ""
    local lines = {"{"}
    for k, v in pairs(t) do
        local key
        if type(k) == "number" then
            key = ""
        else
            key = string.format("[%q] = ", k)
        end
        local val
        if type(v) == "table" then
            val = serialize(v, indent .. "  ")
        elseif type(v) == "string" then
            val = string.format("%q", v)
        elseif type(v) == "number" or type(v) == "boolean" then
            val = tostring(v)
        else
            val = "nil"
        end
        table.insert(lines, indent .. "  " .. key .. val .. ",")
    end
    table.insert(lines, indent .. "}")
    return table.concat(lines, "\n")
end

local function loadFile(filename)
    if not love.filesystem.getInfo(filename) then return nil end
    local chunk, err = love.filesystem.load(filename)
    if not chunk then return nil end
    local ok, data = pcall(chunk)
    if ok then return data end
    return nil
end

local function rebuildIndex()
    by_path = {}
    for _, g in ipairs(games) do
        by_path[g.rom_path] = g
    end
end

local function applyOverrides(overrides)
    if type(overrides) ~= "table" then return end
    for path, override in pairs(overrides) do
        local g = by_path[path]
        if g then
            if override.tags   then g.tags   = override.tags end
            if override.status then g.status = override.status end
            if override.name   then g.name   = override.name end
        elseif override.virtual then
            -- Manual entry not present in scan
            override.rom_path = path
            table.insert(games, override)
        end
    end
    rebuildIndex()
end

function library.load()
    local cached = loadFile(CACHE_FILE)
    -- Validate cache schema: must have games array with rom_path strings.
    -- Older builds used different field names; reject and re-scan if so.
    local valid = false
    if cached and type(cached.games) == "table" and #cached.games > 0 then
        local first = cached.games[1]
        if type(first) == "table" and type(first.rom_path) == "string" then
            valid = true
        end
    end

    if valid then
        games = cached.games
        roots_used = cached.roots_used or {}
    else
        if cached then
            print("[library] cache schema mismatch, re-scanning")
        end
        library.refresh(true)
    end
    rebuildIndex()

    local overrides = loadFile(OVERRIDES_FILE)
    if overrides then applyOverrides(overrides) end
end

-- Scan ROM folders. If `useSampleFallback` is true and no ROMs found, populate
-- with bundled samples so the demo is exercisable.
function library.refresh(useSampleFallback)
    local scanned, roots = scanner.scan()
    if #scanned == 0 and useSampleFallback then
        games = scanner.sampleGames()
        roots_used = {"(no ROMs detected - using bundled samples)"}
    else
        games = scanned
        roots_used = roots
    end
    rebuildIndex()

    local cache_payload = { games = games, roots_used = roots_used }
    love.filesystem.write(CACHE_FILE, "return " .. serialize(cache_payload))
end

function library.all()
    return games
end

function library.count()
    return #games
end

function library.roots()
    return roots_used
end

function library.systems()
    local seen = {}
    local list = {}
    for _, g in ipairs(games) do
        if not seen[g.system] then
            seen[g.system] = true
            table.insert(list, g.system)
        end
    end
    table.sort(list)
    return list
end

function library.tags()
    local seen = {}
    local list = {}
    for _, g in ipairs(games) do
        for _, t in ipairs(g.tags or {}) do
            if not seen[t] then
                seen[t] = true
                table.insert(list, t)
            end
        end
    end
    table.sort(list)
    return list
end

function library.setStatus(rom_path, status)
    local g = by_path[rom_path]
    if g then g.status = status end
end

function library.incrementPlayCount(rom_path)
    local g = by_path[rom_path]
    if g then g.play_count = (g.play_count or 0) + 1 end
end

return library
