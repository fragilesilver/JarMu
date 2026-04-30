-- scenes/result.lua

local picker  = require("modules.picker")
local library = require("modules.library")

local result = {}

local STATUS_CYCLE = { "backlog", "playing", "beaten", "favourite" }

local function nextStatus(s)
    for i, v in ipairs(STATUS_CYCLE) do
        if v == s then return STATUS_CYCLE[(i % #STATUS_CYCLE) + 1] end
    end
    return "backlog"
end

local game = nil
local perfect = false
local elapsed = 0

function result:enter(payload)
    game = payload.game
    perfect = payload.perfect or false
    elapsed = 0
    App.audio().play("reveal")
end

function result:update(dt)
    elapsed = elapsed + dt
    local input = App.input()

    if input.pressed("a") then
        if game and not game.virtual then
            -- On real muOS hardware we'd dispatch to the launcher.
            -- For the demo we simply mark it played and return.
            library.incrementPlayCount(game.rom_path)
            self._launching = true
            self._launch_timer = 0
            App.audio().play("button")
        else
            App.audio().play("button")
        end
    elseif input.pressed("b") then
        App.switch("jar")
    elseif input.pressed("y") then
        -- "Not feeling it" - skip for session and reshake
        if game then picker.skipForSession(game.rom_path) end
        App.switch("jar")
    elseif input.pressed("x") then
        -- Cycle status
        if game then
            game.status = nextStatus(game.status or "backlog")
            library.setStatus(game.rom_path, game.status)
        end
        App.audio().play("button")
    end

    if self._launching then
        self._launch_timer = self._launch_timer + dt
        if self._launch_timer > 1.5 then
            self._launching = false
            self._launch_timer = 0
            App.switch("jar")
        end
    end
end

local function drawCard(theme, x, y, w, h)
    -- Background panel with neon border
    love.graphics.setColor(theme.color("panel"))
    love.graphics.rectangle("fill", x, y, w, h, 8)
    love.graphics.setColor(theme.color("border"))
    love.graphics.setLineWidth(perfect and 3 or 2)
    love.graphics.rectangle("line", x, y, w, h, 8)

    if perfect then
        -- Extra outer glow ring for perfect shake
        love.graphics.setColor(theme.color("glow"))
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", x - 6, y - 6, w + 12, h + 12, 12)
        love.graphics.rectangle("line", x - 12, y - 12, w + 24, h + 24, 16)
    end
end

local function drawSparkles(theme)
    -- Decorative sparkle dots that pulse with elapsed time
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

function result:draw()
    local theme = App.theme()

    -- Subtle backdrop
    love.graphics.setColor(theme.color("text_dim"))
    local font = love.graphics.getFont()
    local hdr = "YOUR PICK"
    love.graphics.print(hdr, (640 - font:getWidth(hdr) * 1.2) / 2, 18, 0, 1.2, 1.2)

    if perfect then drawSparkles(theme) end

    -- Card
    local card_x, card_y = 60, 80
    local card_w, card_h = 520, 320
    drawCard(theme, card_x, card_y, card_w, card_h)

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

    -- Status badge (right side)
    local status_color = "text_dim"
    if game.status == "favourite" then status_color = "text_accent"
    elseif game.status == "playing" then status_color = "success"
    elseif game.status == "backlog" then status_color = "accent"
    end
    love.graphics.setColor(theme.color(status_color))
    love.graphics.printf(game.status:upper(), 350, 137, 200, "right")

    -- Name (large, wrapped). printf with scale uses pre-scale limit for wrap.
    love.graphics.setColor(theme.color("text"))
    love.graphics.printf(game.name, 90, 180, 460 / 1.6, "left", 0, 1.6, 1.6)

    -- Tags
    if game.tags and #game.tags > 0 then
        love.graphics.setColor(theme.color("text_dim"))
        love.graphics.print("TAGS: " .. table.concat(game.tags, ", "), 90, 290)
    end

    -- Path / virtual marker
    love.graphics.setColor(theme.color("text_dim"))
    if game.virtual then
        love.graphics.printf("(sample game - cannot launch)", 90, 360, 460, "left")
    else
        love.graphics.printf(game.rom_path, 90, 360, 460, "left")
    end

    -- Launching overlay
    if self._launching then
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(theme.color("text_accent"))
        local font2 = love.graphics.getFont()
        local m1 = "LAUNCH NOT YET WIRED IN DEMO"
        love.graphics.print(m1, (640 - font2:getWidth(m1) * 1.3) / 2, 220, 0, 1.3, 1.3)
        love.graphics.setColor(theme.color("text_dim"))
        love.graphics.printf("(In v1, A would hand off to muOS launcher)", 0, 260, 640, "center")
    end

    -- Footer
    local hints
    if game.virtual then
        hints = {
            { btn = "B", label = "RESHAKE" },
            { btn = "Y", label = "NOT THIS ONE" },
            { btn = "X", label = "STATUS" },
        }
    else
        hints = {
            { btn = "A", label = "LAUNCH" },
            { btn = "B", label = "RESHAKE" },
            { btn = "Y", label = "NOT THIS ONE" },
            { btn = "X", label = "STATUS" },
        }
    end
    local y = 458
    local x = 12
    for _, h in ipairs(hints) do
        love.graphics.setColor(theme.color("accent"))
        love.graphics.print("[" .. h.btn .. "]", x, y)
        local bw = love.graphics.getFont():getWidth("[" .. h.btn .. "] ")
        love.graphics.setColor(theme.color("text"))
        love.graphics.print(h.label, x + bw, y)
        x = x + bw + love.graphics.getFont():getWidth(h.label) + 16
    end
end

return result
