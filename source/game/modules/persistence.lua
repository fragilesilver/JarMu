-- modules/persistence.lua
-- Saves and loads settings + silent history to LÖVE's save directory.
-- Cache and overrides are stored separately by scanner / library modules.

local persistence = {}

local STATE_FILE = "state.lua"

local state = {
    theme        = "mustard",
    sfx_enabled  = true,
    weighted     = true,
    history      = {},   -- list of rom_paths recently picked (silent re-pick avoidance)
    history_size = 5,
}

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

function persistence.load()
    if love.filesystem.getInfo(STATE_FILE) then
        local chunk, err = love.filesystem.load(STATE_FILE)
        if chunk then
            local ok, loaded = pcall(chunk)
            if ok and type(loaded) == "table" then
                for k, v in pairs(loaded) do
                    state[k] = v
                end
            end
        end
    end
end

function persistence.save()
    local content = "return " .. serialize(state)
    love.filesystem.write(STATE_FILE, content)
end

function persistence.get(key, default)
    if state[key] == nil then return default end
    return state[key]
end

function persistence.set(key, value)
    state[key] = value
end

function persistence.recordPick(rom_path)
    table.insert(state.history, 1, rom_path)
    while #state.history > state.history_size do
        table.remove(state.history)
    end
end

function persistence.history()
    return state.history
end

function persistence.wasRecent(rom_path)
    for _, p in ipairs(state.history) do
        if p == rom_path then return true end
    end
    return false
end

return persistence
