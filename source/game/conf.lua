-- conf.lua
-- LÖVE2D configuration for JarMu
-- Targets: muOS Funky Jacaranda + Canada Goose on RG35XX family (640x480)

function love.conf(t)
    t.identity        = "JarMu"
    t.version         = "11.4"
    t.console         = false

    t.window.title    = "JarMu"
    t.window.width    = 640
    t.window.height   = 480
    t.window.fullscreen = true
    t.window.fullscreentype = "exclusive"
    t.window.vsync    = 1
    t.window.resizable = false
    t.window.borderless = true
    t.window.display  = 1

    t.modules.audio   = true
    t.modules.data    = true
    t.modules.event   = true
    t.modules.font    = true
    t.modules.graphics = true
    t.modules.image   = true
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.math    = true
    t.modules.mouse   = false
    t.modules.physics = true   -- needed for jar/token physics
    t.modules.sound   = true
    t.modules.system  = true
    t.modules.thread  = true
    t.modules.timer   = true
    t.modules.touch   = false
    t.modules.video   = false
    t.modules.window  = true
end
