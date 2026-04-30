-- modules/picker.lua
-- Filter state management and weighted random picking.

local library     = require("modules.library")
local persistence = require("modules.persistence")

local picker = {}

local state = {
    systems_excluded = {},   -- set: system_name -> true means excluded
    tags_required    = {},   -- set: tag -> true (AND/OR controlled by tags_mode)
    tags_mode        = "any",-- "any" or "all"
    status_excluded  = { hidden = true },  -- "hidden" always excluded by default
    session_skips    = {},   -- set: rom_path -> true (skipped via "not feeling it")
    surprise_me      = false,
}

-- Status weighting (when weighted mode on)
local STATUS_WEIGHT = {
    backlog   = 3.0,
    favourite = 2.0,
    playing   = 1.5,
    beaten    = 0.5,
}

local function copySet(s)
    local out = {}
    for k, v in pairs(s) do out[k] = v end
    return out
end

function picker.setSystemExcluded(system, excluded)
    state.systems_excluded[system] = excluded and true or nil
end

function picker.isSystemExcluded(system)
    return state.systems_excluded[system] == true
end

function picker.setTagRequired(tag, required)
    state.tags_required[tag] = required and true or nil
end

function picker.isTagRequired(tag)
    return state.tags_required[tag] == true
end

function picker.toggleTagsMode()
    state.tags_mode = (state.tags_mode == "any") and "all" or "any"
end

function picker.tagsMode()
    return state.tags_mode
end

function picker.setStatusExcluded(status, excluded)
    state.status_excluded[status] = excluded and true or nil
end

function picker.isStatusExcluded(status)
    return state.status_excluded[status] == true
end

function picker.skipForSession(rom_path)
    state.session_skips[rom_path] = true
end

function picker.clearSessionSkips()
    state.session_skips = {}
end

function picker.setSurpriseMe(v)
    state.surprise_me = v and true or false
end

function picker.surpriseMe()
    return state.surprise_me
end

-- Returns the list of games that pass the active filters.
function picker.eligible()
    local games = library.all()
    local out = {}

    for _, g in ipairs(games) do
        local include = true

        -- Session skip always wins
        if state.session_skips[g.rom_path] then include = false end

        -- Hidden always excluded
        if include and g.status == "hidden" then include = false end

        if include and not state.surprise_me then
            -- Status filter
            if state.status_excluded[g.status] then include = false end

            -- System filter
            if include and state.systems_excluded[g.system] then include = false end

            -- Tag filter
            if include and next(state.tags_required) then
                local game_tags = {}
                for _, t in ipairs(g.tags or {}) do game_tags[t] = true end
                if state.tags_mode == "all" then
                    for tag, _ in pairs(state.tags_required) do
                        if not game_tags[tag] then include = false; break end
                    end
                else
                    local match = false
                    for tag, _ in pairs(state.tags_required) do
                        if game_tags[tag] then match = true; break end
                    end
                    if not match then include = false end
                end
            end
        end

        if include then table.insert(out, g) end
    end

    return out
end

function picker.eligibleCount()
    return #picker.eligible()
end

-- Pick a game.
-- options.weighted    - apply backlog/favourite weighting
-- options.perfect     - perfect-shake bonus: triple weight on backlog/favourite
-- options.avoidRecent - exclude recent picks if pool is large enough
function picker.pick(options)
    options = options or {}
    local pool = picker.eligible()
    if #pool == 0 then return nil end

    -- Re-pick avoidance: exclude recent picks if pool > history size
    if options.avoidRecent ~= false then
        local filtered = {}
        for _, g in ipairs(pool) do
            if not persistence.wasRecent(g.rom_path) then
                table.insert(filtered, g)
            end
        end
        if #filtered > 0 then pool = filtered end
    end

    -- Build weights
    local total = 0
    local weights = {}
    for i, g in ipairs(pool) do
        local w = 1.0
        if options.weighted ~= false then
            w = STATUS_WEIGHT[g.status] or 1.0
            if options.perfect and (g.status == "backlog" or g.status == "favourite") then
                w = w * 2.5
            end
        end
        weights[i] = w
        total = total + w
    end

    local r = math.random() * total
    local accum = 0
    for i, w in ipairs(weights) do
        accum = accum + w
        if r <= accum then
            local pick = pool[i]
            persistence.recordPick(pick.rom_path)
            return pick
        end
    end
    return pool[#pool]  -- fallback
end

return picker
