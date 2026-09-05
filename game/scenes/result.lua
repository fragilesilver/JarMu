-- scenes/result.lua
-- Shows the picked game. JarMu decides *what* to play; muOS launches it.
-- L1 opens a genre editor: toggle genres on/off for this game. Edits persist
-- to usergenres.lua in the app's own store (gamelist.xml is never touched) and
-- immediately feed the GENRE column in the Filters screen.

local picker  = require("modules.picker")
local library = require("modules.library")
local scanner = require("modules.scanner")
local artwork = require("modules.artwork")

local result = {}

local STATUS_CYCLE = { "backlog", "playing", "beaten", "favourite" }

local function nextStatus(s)
    for i, v in ipairs(STATUS_CYCLE) do
        if v == s then return STATUS_CYCLE[(i % #STATUS_CYCLE) + 1] end
    end
    return "backlog"
end

local game    = nil
local perfect = false
local elapsed = 0
local mode    = "view"      -- "view" | "genres"
local cands   = {}          -- candidate genre list for the editor
local gCur    = 1
local art     = nil         -- LÖVE Image from muOS's info catalogue, or nil

local function hasGenre(g)
    for _, t in ipairs(game and game.genres or {}) do
        if t == g then return true end
    end
    return false
end

local function rebuildCandidates()
    local seen, list = {}, {}
    local function add(t)
        t = tostring(t):lower()
        if #t > 0 and not seen[t] then seen[t] = true; list[#list + 1] = t end
    end
    for _, t in ipairs(scanner.GENRE_PRESETS or {}) do add(t) end
    for _, t in ipairs(library.genres()) do add(t) end
    for _, t in ipairs(game and game.genres or {}) do add(t) end
    table.sort(list)
    cands = list
end

local function toggleGenre(g)
    local list, removed = {}, false
    for _, t in ipairs(game.genres or {}) do
        if t == g then removed = true else list[#list + 1] = t end
    end
    if not removed then list[#list + 1] = g end
    library.setGenres(game.rom_path, list)   -- mutates game.genres, persists
    rebuildCandidates()
end

function result:enter(payload)
    game    = payload.game
    perfect = payload.perfect or false
    elapsed = 0
    mode    = "view"
    gCur    = 1
    art     = artwork.load(game)   -- preview / box art from MUOS/info/catalogue
    App.audio().play("reveal")
end

function result:update(dt)
    elapsed = elapsed + dt
    local input = App.input()

    if mode == "genres" then
        if input.pressed("b") or input.pressed("l1") then
            mode = "view"
            App.audio().play("button")
        elseif input.pressed("up") then
            gCur = gCur > 1 and gCur - 1 or #cands
        elseif input.pressed("down") then
            gCur = gCur < #cands and gCur + 1 or 1
        elseif input.pressed("a") then
            local sel = cands[gCur]
            if sel then toggleGenre(sel) end
            App.audio().play("button")
        end
        return
    end

    -- view mode -- JarMu decides *what* to play; muOS launches it.
    if input.pressed("b") or input.pressed("a") then
        App.switch("jar")
    elseif input.pressed("y") then
        if game then picker.skipForSession(game.rom_path) end
        App.switch("jar")
    elseif input.pressed("x") then
        if game then
            game.status = nextStatus(game.status or "backlog")
            library.setStatus(game.rom_path, game.status)
        end
        App.audio().play("button")
    elseif input.pressed("l1") then
        if game then
            rebuildCandidates()
            gCur = 1
            mode = "genres"
            App.audio().play("button")
        end
    end
end

local function drawCard(theme, x, y, w, h)
    love.graphics.setColor(theme.color("panel"))
    love.graphics.rectangle("fill", x, y, w, h, 8)
    love.graphics.setColor(theme.color("border"))
    love.graphics.setLineWidth(perfect and 3 or 2)
    love.graphics.rectangle("line", x, y, w, h, 8)
    if perfect then
        love.graphics.setColor(theme.color("glow"))
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", x - 6, y - 6, w + 12, h + 12, 12)
        love.graphics.rectangle("line", x - 12, y - 12, w + 24, h + 24, 16)
    end
end

local function drawSparkles(theme)
    for i = 1, 12 do
        local seed = i * 173.7
        local angle = elapsed * 1.5 + seed
        local r = 200 + math.sin(elapsed * 2 + seed) * 30
        local cx = 320 + math.cos(angle) * r
        local cy = 240 + math.sin(angle) * r * 0.7
        local size = 2 + math.abs(math.sin(elapsed * 3 + seed)) * 3
        love.graphics.setColor(theme.color("glow"))
        love.graphics.circle("fill", cx, cy, size)
    end
end

local function drawHints(theme, hints)
    local y, x = 458, 12
    for _, h in ipairs(hints) do
        love.graphics.setColor(theme.color("accent"))
        love.graphics.print("[" .. h.btn .. "]", x, y)
        local bw = love.graphics.getFont():getWidth("[" .. h.btn .. "] ")
        love.graphics.setColor(theme.color("text"))
        love.graphics.print(h.label, x + bw, y)
        x = x + bw + love.graphics.getFont():getWidth(h.label) + 16
    end
end

local function drawGenreEditor(theme)
    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 0, 0, 640, 480)

    local px, py, pw, ph = 100, 40, 440, 400
    love.graphics.setColor(theme.color("panel"))
    love.graphics.rectangle("fill", px, py, pw, ph, 8)
    love.graphics.setColor(theme.color("border"))
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px, py, pw, ph, 8)

    love.graphics.setColor(theme.color("text_accent"))
    love.graphics.print("EDIT GENRES", px + 16, py + 12, 0, 1.3, 1.3)
    love.graphics.setColor(theme.color("text_dim"))
    love.graphics.printf(game.name, px + 16, py + 40, pw - 32, "left")
    love.graphics.setColor(theme.color("text"))
    local cur = (game.genres and #game.genres > 0) and table.concat(game.genres, ", ") or "(none)"
    love.graphics.printf("ON: " .. cur, px + 16, py + 62, pw - 32, "left")

    local rowH, visible = 22, 12
    local first = math.max(1, math.min(gCur - math.floor(visible / 2), #cands - visible + 1))
    if first < 1 then first = 1 end
    local ly = py + 96
    for i = first, math.min(first + visible - 1, #cands) do
        local g = cands[i]
        local sel = (i == gCur)
        local on  = hasGenre(g)
        if sel then
            love.graphics.setColor(theme.color("panel_alt"))
            love.graphics.rectangle("fill", px + 8, ly - 2, pw - 16, rowH, 2)
        end
        love.graphics.setColor(theme.color(on and "accent" or "text_dim"))
        love.graphics.print(on and "[X]" or "[ ]", px + 16, ly + 2)
        love.graphics.setColor(theme.color((sel or on) and "text" or "text_dim"))
        love.graphics.print(g, px + 48, ly + 2)
        ly = ly + rowH
    end

    if #cands > visible then
        love.graphics.setColor(theme.color("text_dim"))
        love.graphics.printf(("%d/%d"):format(gCur, #cands), px, py + ph - 46, pw - 16, "right")
    end

    drawHints(theme, {
        { btn = "A", label = "TOGGLE" },
        { btn = "B", label = "DONE" },
    })
end

function result:draw()
    local theme = App.theme()

    love.graphics.setColor(theme.color("text_dim"))
    local font = love.graphics.getFont()
    local hdr = "YOUR PICK"
    love.graphics.print(hdr, (640 - font:getWidth(hdr) * 1.2) / 2, 18, 0, 1.2, 1.2)

    if perfect then drawSparkles(theme) end

    drawCard(theme, 60, 80, 520, 320)

    if perfect then
        love.graphics.setColor(theme.color("glow"))
        love.graphics.printf("** PERFECT SHAKE **", 0, 90, 640, "center")
    end

    if not game then
        love.graphics.setColor(theme.color("text_dim"))
        love.graphics.printf("(no game selected)", 0, 220, 640, "center")
        return
    end

    -- System pill
    love.graphics.setColor(theme.color("accent"))
    love.graphics.rectangle("fill", 90, 130, 200, 30, 4)
    love.graphics.setColor(theme.color("bg"))
    love.graphics.printf(game.system, 90, 137, 200, "center")

    -- Status badge. Sits top-right of the card normally, but moves clear of the
    -- artwork box (into the strip above it) when a preview is shown.
    local status_color = "text_dim"
    if game.status == "favourite" then status_color = "text_accent"
    elseif game.status == "playing" then status_color = "success"
    elseif game.status == "backlog" then status_color = "accent"
    end
    love.graphics.setColor(theme.color(status_color))
    local st = (game.status or "backlog"):upper()
    if art then
        love.graphics.printf(st, 300, 100, 268, "right")
    else
        love.graphics.printf(st, 350, 137, 200, "right")
    end

    -- Artwork (preview / box) from muOS's catalogue, if we found one
    local nameW = 460 / 1.6
    if art then
        local bx, by, bw, bh = 366, 126, 200, 150
        love.graphics.setColor(theme.color("panel_alt"))
        love.graphics.rectangle("fill", bx, by, bw, bh, 4)
        local iw, ih = art:getDimensions()
        local s = math.min(bw / iw, bh / ih)
        local dw, dh = iw * s, ih * s
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(art, bx + (bw - dw) / 2, by + (bh - dh) / 2, 0, s, s)
        love.graphics.setColor(theme.color("border"))
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", bx, by, bw, bh, 4)
        nameW = (bx - 90 - 12) / 1.6   -- keep the name clear of the artwork
    end

    -- Name
    love.graphics.setColor(theme.color("text"))
    love.graphics.printf(game.name, 90, 180, nameW, "left", 0, 1.6, 1.6)

    -- Genres
    love.graphics.setColor(theme.color("text_dim"))
    if game.genres and #game.genres > 0 then
        love.graphics.printf("GENRE: " .. table.concat(game.genres, ", "), 90, 288, 460, "left")
    else
        love.graphics.print("GENRE: (none - press L1 to add)", 90, 290)
    end

    -- Location
    love.graphics.setColor(theme.color("text_dim"))
    if game.virtual then
        love.graphics.printf("(bundled sample - no ROMs detected)", 90, 360, 460, "left")
    elseif game.port then
        love.graphics.printf("PortMaster:  " .. game.rom_path, 90, 360, 460, "left")
    else
        love.graphics.printf(game.rom_path, 90, 360, 460, "left")
    end

    drawHints(theme, {
        { btn = "B",  label = "RESHAKE" },
        { btn = "Y",  label = "NOT THIS ONE" },
        { btn = "X",  label = "STATUS" },
        { btn = "L1", label = "GENRE" },
    })

    if mode == "genres" then drawGenreEditor(theme) end
end

return result
