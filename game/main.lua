-- main.lua
-- JarMu entry point

local fskit       = require("fskit")
local theme       = require("modules.theme")
local input       = require("modules.input")
local audio       = require("modules.audio")
local crt         = require("modules.crt")
local persistence = require("modules.persistence")
local library     = require("modules.library")
local scanner     = require("modules.scanner")

-- Scenes
local scenes = {
    splash  = require("scenes.splash"),
    jar     = require("scenes.jar"),
    filters = require("scenes.filters"),
    result  = require("scenes.result"),
}

local current = nil
local nextScene = nil

local app = {}
_G.App = app  -- shared global so scenes/modules can switch screens

function app.switch(name, payload)
    nextScene = { name = name, payload = payload }
end

function app.theme()      return theme end
function app.input()      return input end
function app.audio()      return audio end
function app.library()    return library end
function app.persistence() return persistence end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    math.randomseed(os.time())

    fskit.load()   -- 640x480 virtual canvas, letterboxed to the real framebuffer

    persistence.load()
    theme.load(persistence.get("theme", "mustard"))
    audio.load(persistence.get("sfx_enabled", true))
    crt.load()
    library.load()

    -- Boot straight into splash; splash kicks scanner if cache empty
    current = scenes.splash
    if current.enter then current:enter() end
end

function love.resize(w, h)
    fskit.screen.resize(w, h)
end

function love.update(dt)
    -- Handle pending scene switch from previous frame
    if nextScene then
        if current and current.leave then current:leave() end
        current = scenes[nextScene.name]
        if current.enter then current:enter(nextScene.payload) end
        nextScene = nil
    end

    input.update(dt)
    if current and current.update then current:update(dt) end
    -- Clear edge-triggered "pressed" flags AFTER scenes have observed them.
    input.endFrame()
end

function love.draw()
    -- Render the scene into the 640x480 virtual canvas...
    fskit.screen.begin()
    love.graphics.clear(theme.color("bg"))
    if current and current.draw then current:draw() end
    -- ...then blit it letterboxed onto the real framebuffer, CRT shader applied
    -- in the same pass.
    fskit.screen.finish(crt.shader())
end

-- Centralised input handling: forward to active scene
function love.keypressed(key, scancode, isrepeat)
    input.keypressed(key, scancode, isrepeat)
    if current and current.keypressed then current:keypressed(key, scancode, isrepeat) end
end

function love.keyreleased(key, scancode)
    input.keyreleased(key, scancode)
    if current and current.keyreleased then current:keyreleased(key, scancode) end
end

function love.gamepadpressed(joystick, button)
    input.gamepadpressed(joystick, button)
    if current and current.gamepadpressed then current:gamepadpressed(joystick, button) end
end

function love.gamepadreleased(joystick, button)
    input.gamepadreleased(joystick, button)
    if current and current.gamepadreleased then current:gamepadreleased(joystick, button) end
end

function love.quit()
    persistence.save()
    return false
end
