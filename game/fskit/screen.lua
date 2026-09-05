-- fskit/screen.lua
-- Fixed 640x480 virtual canvas, letterbox-scaled (never stretched) onto the
-- real framebuffer. Covers every RG35XX variant (all 640x480 internally),
-- HDMI-out (1280x720), and panel-variant edge crop (SAFE inset).
--
-- finish(shader) optionally applies a fragment shader on the final blit --
-- JarMu uses this to composite its CRT post-process in one pass.

local screen = {}

screen.W, screen.H = 640, 480
screen.SAFE        = 10

local canvas
local scale, ox, oy = 1, 0, 0

function screen.load()
    canvas = love.graphics.newCanvas(screen.W, screen.H)
    canvas:setFilter("linear", "linear")
    screen.resize(love.graphics.getDimensions())
end

function screen.resize(w, h)
    w = w or love.graphics.getWidth()
    h = h or love.graphics.getHeight()
    scale = math.min(w / screen.W, h / screen.H)
    ox = math.floor((w - screen.W * scale) / 2 + 0.5)
    oy = math.floor((h - screen.H * scale) / 2 + 0.5)
end

function screen.begin()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 1)
end

function screen.finish(shader)
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    if shader then love.graphics.setShader(shader) end
    love.graphics.draw(canvas, ox, oy, 0, scale, scale)
    if shader then love.graphics.setShader() end
end

function screen.canvasRef() return canvas end

function screen.safe()
    local s = screen.SAFE
    return s, s, screen.W - s * 2, screen.H - s * 2
end

return screen
