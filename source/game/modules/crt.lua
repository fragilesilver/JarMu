-- modules/crt.lua
-- CRT post-processing: scanlines + subtle chromatic aberration + vignette.
-- Drawn on top of the off-screen canvas in main.draw().

local crt = {}

local shader_source = [[
extern number scanline_strength;
extern number aberration;
extern number vignette;
extern vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    // Chromatic aberration - sample R and B with slight offset
    vec2 offset = vec2(aberration / resolution.x, 0.0);
    float r = Texel(tex, tc + offset).r;
    float g = Texel(tex, tc).g;
    float b = Texel(tex, tc - offset).b;
    vec3 col = vec3(r, g, b);

    // Scanlines - dark horizontal bands
    float scan = sin(tc.y * resolution.y * 3.14159) * 0.5 + 0.5;
    col *= 1.0 - (scanline_strength * (1.0 - scan));

    // Subtle vignette
    vec2 v = tc - 0.5;
    float vd = dot(v, v);
    col *= 1.0 - (vignette * vd);

    return vec4(col, 1.0) * color;
}
]]

local shader = nil

function crt.load()
    shader = love.graphics.newShader(shader_source)
    shader:send("scanline_strength", 0.18)
    shader:send("aberration",        0.7)
    shader:send("vignette",          0.55)
    shader:send("resolution",        {640, 480})
end

function crt.draw(canvas)
    love.graphics.setShader(shader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, 0, 0)
    love.graphics.setShader()
end

return crt
