-- scenes/jar.lua
-- Main scene: the jar with shake mechanic.

local physics = require("modules.physics")
local picker  = require("modules.picker")

local jar = {}

local STATE_IDLE     = "idle"
local STATE_HOLDING  = "holding"
local STATE_TIPPING  = "tipping"

local state          = STATE_IDLE
local power          = 0     -- 0..1
local power_target   = 0
local tip_timer      = 0
local SWEET_LOW      = 0.85
local SWEET_HIGH     = 0.95
local last_tick_band = 0     -- tracks which power band has played its tick

function jar:enter()
    -- Recreate physics with tokens matching current eligible count
    local count = picker.eligibleCount()
    physics.load(math.min(count, 60), App.theme())
    state = STATE_IDLE
    power = 0
    power_target = 0
    tip_timer = 0
    picker.clearSessionSkips()
end

function jar:leave()
    physics.reset()
end

local function startTip(perfect)
    state = STATE_TIPPING
    tip_timer = 0
    physics.tipJar()
    App.audio().play("tip")
    if perfect then
        App.audio().play("sparkle")
    end
end

function jar:update(dt)
    local input = App.input()

    if state == STATE_IDLE then
        if input.held("a") then
            state = STATE_HOLDING
            power = 0
            power_target = 0
            last_tick_band = 0
            App.audio().play("button")
        elseif input.pressed("b") then
            -- B on main screen: quit the app (returns to muOS launcher)
            App.audio().play("button")
            App.persistence().save()
            love.event.quit()
        elseif input.pressed("l1") then
            App.switch("filters")
        elseif input.pressed("r1") then
            App.switch("filters")
        elseif input.pressed("y") then
            picker.setSurpriseMe(not picker.surpriseMe())
            App.audio().play("button")
        elseif input.pressed("x") then
            -- Cycle theme
            local newName = App.theme().cycle()
            App.persistence().set("theme", newName)
            App.audio().play("button")
        elseif input.pressed("select") then
            App.audio().setEnabled(not App.audio().isEnabled())
            App.persistence().set("sfx_enabled", App.audio().isEnabled())
            App.audio().play("button")
        end

    elseif state == STATE_HOLDING then
        local hold = input.holdTime("a")
        -- Power fills smoothly to ~1.0 over 1.5s, then oscillates
        if hold < 1.5 then
            power_target = hold / 1.5
        else
            -- Once full, oscillate between 0.4 and 1.0 so timing the release
            -- on the sweet spot is a real skill challenge.
            power_target = 0.7 + math.sin((hold - 1.5) * 4) * 0.3
        end
        power = power + (power_target - power) * math.min(dt * 12, 1)

        -- Tick sound when crossing power bands
        local band = math.floor(power * 5)
        if band > last_tick_band then
            if band <= 2 then
                App.audio().play("tick_lo")
            elseif band <= 3 then
                App.audio().play("tick_mid")
            else
                App.audio().play("tick_hi")
            end
            last_tick_band = band
        end

        if not input.held("a") then
            local perfect = power >= SWEET_LOW and power <= SWEET_HIGH
            startTip(perfect)
            if picker.eligibleCount() == 0 then
                -- Empty jar - go straight back to idle with no pick
                state = STATE_IDLE
                power = 0
            else
                local pick = picker.pick({
                    weighted    = App.persistence().get("weighted", true),
                    perfect     = perfect,
                    avoidRecent = true,
                })
                if pick then
                    self._pending_pick = pick
                    self._pending_perfect = perfect
                end
            end
        end
    end

    physics.update(dt, state == STATE_HOLDING and power or 0)

    if state == STATE_TIPPING then
        tip_timer = tip_timer + dt
        if tip_timer > 0.7 then
            if self._pending_pick then
                App.switch("result", {
                    game    = self._pending_pick,
                    perfect = self._pending_perfect,
                })
                self._pending_pick = nil
                self._pending_perfect = nil
            else
                state = STATE_IDLE
                power = 0
            end
        end
    end
end

local function drawHeader(theme)
    -- Title rendered with scale - need to account for scaled width
    love.graphics.setColor(theme.color("text_accent"))
    local font = love.graphics.getFont()
    local title = "JarMu"
    local title_w = font:getWidth(title) * 1.5
    love.graphics.print(title, (640 - title_w) / 2, 10, 0, 1.5, 1.5)

    love.graphics.setColor(theme.color("text_dim"))
    local count = picker.eligibleCount()
    local label = picker.surpriseMe() and "SURPRISE MODE" or "FILTERED"
    love.graphics.printf(("%s   %d GAMES IN JAR"):format(label, count), 0, 40, 640, "center")
end

local function drawPowerMeter(theme)
    local x, y = 60, 410
    local w, h = 520, 26

    love.graphics.setColor(theme.color("panel"))
    love.graphics.rectangle("fill", x, y, w, h, 4)
    love.graphics.setColor(theme.color("border"))
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 4)

    -- Sweet spot zone
    local sweet_x  = x + SWEET_LOW * w
    local sweet_w  = (SWEET_HIGH - SWEET_LOW) * w
    love.graphics.setColor(theme.color("success"))
    love.graphics.rectangle("fill", sweet_x, y + 2, sweet_w, h - 4, 2)

    -- Fill bar
    if state == STATE_HOLDING then
        love.graphics.setColor(theme.color("accent"))
        love.graphics.rectangle("fill", x + 2, y + 2, (w - 4) * power, h - 4, 2)
        -- Glow on top of fill
        love.graphics.setColor(theme.color("glow"))
        love.graphics.rectangle("fill", x + 2, y + 2, (w - 4) * power, 4, 2)
    end

    love.graphics.setColor(theme.color("text_dim"))
    love.graphics.printf("POWER", x, y + 32, w, "left")
    love.graphics.printf("PERFECT", x, y + 32, w, "center")
end

local function drawFooter(theme)
    local hints = {}
    if state == STATE_IDLE then
        hints = {
            { btn = "A",   label = "SHAKE" },
            { btn = "L/R", label = "FILTERS" },
            { btn = "Y",   label = "SURPRISE" },
            { btn = "X",   label = "THEME" },
            { btn = "B",   label = "QUIT" },
        }
    elseif state == STATE_HOLDING then
        hints = {
            { btn = "RELEASE A", label = "TIP THE JAR" },
        }
    end

    local y = 458
    local x = 12
    love.graphics.setColor(theme.color("text"))
    for _, h in ipairs(hints) do
        love.graphics.setColor(theme.color("accent"))
        love.graphics.print("[" .. h.btn .. "]", x, y)
        local btn_w = love.graphics.getFont():getWidth("[" .. h.btn .. "] ")
        love.graphics.setColor(theme.color("text"))
        love.graphics.print(h.label, x + btn_w, y)
        x = x + btn_w + love.graphics.getFont():getWidth(h.label) + 16
    end
end

function jar:draw()
    local theme = App.theme()
    drawHeader(theme)
    physics.draw(theme)

    if state == STATE_HOLDING then
        drawPowerMeter(theme)
    elseif state == STATE_IDLE then
        love.graphics.setColor(theme.color("text_dim"))
        love.graphics.printf("HOLD A TO SHAKE THE JAR", 0, 425, 640, "center")
    elseif state == STATE_TIPPING then
        love.graphics.setColor(theme.color("text_accent"))
        local font = love.graphics.getFont()
        local txt = "TIPPING..."
        love.graphics.print(txt, (640 - font:getWidth(txt) * 1.2) / 2, 425, 0, 1.2, 1.2)
    end

    drawFooter(theme)
end

return jar
