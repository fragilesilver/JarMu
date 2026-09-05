-- conf.lua -- LÖVE configuration for JarMu
-- muOS Andromeda 2606.0 (Jacaranda-compatible), whole RG35XX family
-- (Allwinner H700, 640x480). fskit.screen letterboxes a fixed 640x480 virtual
-- canvas onto whatever muOS drives (internal panel or HDMI), so nothing here
-- is device-specific.

function love.conf(t)
    t.identity              = "JarMu"
    t.version               = "11.4"   -- matches the bundled love/ binary
    t.console               = false
    t.appendidentity        = true

    t.window.title          = "JarMu"
    t.window.width          = 640
    t.window.height         = 480
    t.window.fullscreen     = true
    t.window.fullscreentype = "exclusive"
    t.window.vsync          = 1
    t.window.resizable      = false
    t.window.borderless     = true
    t.window.display        = 1
    t.window.highdpi        = false

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
    t.modules.physics = true   -- jar/token physics
    t.modules.sound   = true
    t.modules.system  = true
    t.modules.thread  = true
    t.modules.timer   = true
    t.modules.touch   = false
    t.modules.video   = false
    t.modules.window  = true
end
