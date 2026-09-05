-- modules/store.lua
-- Persistent read/write for JarMu's state, cache and overrides.
--
-- The launcher exports JARMU_DATA (an absolute, writable dir inside the app).
-- We write there with plain io so persistence never depends on LÖVE's save-dir
-- resolution, fused-mode source shadowing, or muOS bind-mount behaviour.
-- On desktop (no env var) we fall back to love.filesystem.

local store = {}

local DIR = os.getenv("JARMU_DATA")

local function path(name)
    return DIR and (DIR .. "/" .. name) or nil
end

function store.dir() return DIR end

-- read raw string, or nil
function store.read(name)
    local p = path(name)
    if p then
        local f = io.open(p, "rb")
        if f then local d = f:read("*a"); f:close(); if d and #d > 0 then return d end end
        -- one-time fallback: pick up anything an older build wrote via LÖVE
        if love.filesystem.getInfo(name) then return love.filesystem.read(name) end
        return nil
    end
    if love.filesystem.getInfo(name) then return love.filesystem.read(name) end
    return nil
end

-- write raw string; returns ok
function store.write(name, data)
    local p = path(name)
    if p then
        local f, err = io.open(p, "wb")
        if not f then print("[JarMu] store.write failed for " .. p .. ": " .. tostring(err)); return false end
        f:write(data); f:close(); return true
    end
    return love.filesystem.write(name, data)
end

-- load a "return { ... }" Lua chunk from the store; returns the value or nil
function store.readLua(name)
    local s = store.read(name)
    if not s then return nil end
    local chunk = loadstring and loadstring(s, "=" .. name) or load(s, "=" .. name)
    if not chunk then return nil end
    local ok, val = pcall(chunk)
    if ok then return val end
    return nil
end

return store
