-- scenes/splash.lua
-- Wait for the user to press any button before entering the jar.
-- Guards against the case where launching the app from muOS leaves
-- a face button still held when the splash first appears.

local splash = {}

local elapsed = 0
local input_armed = false  -- true once all buttons have been observed released
local MIN_DISPLAY = 0.6    -- minimum time before we accept input even if armed

local WATCH = { "a", "b", "x", "y", "start", "select", "l1", "r1" }

local function anyHeld()
    local input = App.input()
    for _, action in ipairs(WATCH) do
        if input.held(action) then return true end
    end
    return false
end

local function anyPressed()
    local input = App.input()
    for _, action in ipairs(WATCH) do
        if input.pressed(action) then return true end
    end
    return false
end

function splash:enter()
    elapsed = 0
    input_armed = false
end

function splash:update(dt)
    elapsed = elapsed + dt

    -- Arm only after every button has been released, so the launch button
    -- doesn't immediately dismiss the splash on first frame.
    if not input_armed and not anyHeld() then
        input_armed = true
    end

    if input_armed and elapsed > MIN_DISPLAY and anyPressed() then
        App.audio().play("button")
        App.switch("jar")
    end
end

function splash:draw()
    local theme = App.theme()
    love.graphics.clear(theme.color("bg"))

    local title = "JarMu"
    local subtitle = "DEMO BUILD"
    local hint = input_armed and "PRESS ANY BUTTON" or "RELEASE TO BEGIN"

    local font = love.graphics.getFont()
    local title_w    = font:getWidth(title)    * 3
    local subtitle_w = font:getWidth(subtitle) * 1.5

    -- Title with shimmer
    love.graphics.setColor(theme.color("glow"))
    love.graphics.print(title, (640 - title_w) / 2, 170, 0, 3, 3)

    local pulse = math.abs(math.sin(elapsed * 4))
    local r, g, b = theme.color("accent")
    love.graphics.setColor(r, g, b, 0.4 + pulse * 0.4)
    love.graphics.print(title, (640 - title_w) / 2, 170, 0, 3, 3)

    love.graphics.setColor(theme.color("text_dim"))
    love.graphics.print(subtitle, (640 - subtitle_w) / 2, 250, 0, 1.5, 1.5)

    -- Blinking hint, only after MIN_DISPLAY so the splash holds for a beat
    if elapsed > MIN_DISPLAY then
        love.graphics.setColor(theme.color("text"))
        if math.floor(elapsed * 2) % 2 == 0 then
            love.graphics.printf(hint, 0, 360, 640, "center")
        end
    end

    -- Loaded library count footer
    love.graphics.setColor(theme.color("text_dim"))
    local count = App.library().count()
    local roots = App.library().roots()
    local msg
    if #roots == 0 then
        msg = ("Loaded %d games"):format(count)
    else
        msg = ("Loaded %d games from %d source(s)"):format(count, #roots)
    end
    love.graphics.printf(msg, 0, 440, 640, "center")
end

return splash
