-- modules/physics.lua
-- Box2D-backed jar with bouncing tokens.
-- The jar is rendered separately - this module just owns physics state.

local audio = require("modules.audio")

local physics = {}

local world = nil
local jar_body = nil
local jar_shapes = {}
local tokens = {}      -- list of {body, fixture, color, radius}

local SCALE = 1  -- Box2D uses meters; we work in pixels directly
local JAR_X, JAR_Y = 320, 280     -- jar centre
local JAR_WIDTH    = 220
local JAR_HEIGHT   = 280
local JAR_NECK     = 90           -- narrow opening at top
local TOKEN_RADIUS = 8
local MAX_VISIBLE  = 60           -- visual cap; logical pool size is independent

-- Sound throttling so a flurry of contacts doesn't overwhelm the speaker
local last_clink = 0
local CLINK_COOLDOWN = 0.07

local function makeJarBody()
    -- Static body with multiple edges forming a flask-shaped container
    -- with a narrow neck at the top so tokens visibly tumble out.
    jar_body = love.physics.newBody(world, JAR_X, JAR_Y, "static")

    local hw = JAR_WIDTH / 2
    local hh = JAR_HEIGHT / 2
    local neck = JAR_NECK / 2

    -- Bottom (slight curve approximated as 3 segments)
    local segments = {
        -- Left wall (vertical, lower portion)
        { -hw,  hh,  -hw, -hh + 30 },
        -- Left shoulder (curve to neck)
        { -hw, -hh + 30, -neck, -hh },
        -- Right shoulder
        {  neck, -hh,  hw, -hh + 30 },
        -- Right wall
        {  hw, -hh + 30,  hw,  hh },
        -- Bottom
        { -hw,  hh,  hw,  hh },
    }

    jar_shapes = {}
    for _, s in ipairs(segments) do
        local shape   = love.physics.newEdgeShape(s[1], s[2], s[3], s[4])
        local fixture = love.physics.newFixture(jar_body, shape)
        fixture:setRestitution(0.4)
        fixture:setUserData("wall")
        table.insert(jar_shapes, { shape = shape, fixture = fixture, points = s })
    end
end

local function makeToken(mix)
    local x = JAR_X + (math.random() - 0.5) * (JAR_WIDTH - TOKEN_RADIUS * 4)
    local y = JAR_Y + (math.random() - 0.5) * (JAR_HEIGHT - TOKEN_RADIUS * 4)
    local body  = love.physics.newBody(world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(TOKEN_RADIUS)
    local fix   = love.physics.newFixture(body, shape, 1)
    fix:setRestitution(0.55)
    fix:setFriction(0.2)
    fix:setUserData("token")
    body:setLinearDamping(0.3)
    body:setAngularDamping(0.5)
    -- Store only the accent<->glow blend weight; the actual colour is resolved
    -- live in physics.draw() so a theme change recolours existing tokens.
    return { body = body, fixture = fix, mix = mix, radius = TOKEN_RADIUS }
end

-- LÖVE Box2D postSolve callback: (a, b, contact, normalImpulse, tangentImpulse)
local function onPostSolve(a, b, contact, normalImpulse, tangentImpulse)
    local ua = a:getUserData()
    local ub = b:getUserData()
    if ua == "token" or ub == "token" then
        local now = love.timer.getTime()
        if (now - last_clink) > CLINK_COOLDOWN and normalImpulse and normalImpulse > 0.5 then
            audio.clink()
            last_clink = now
        end
    end
end

function physics.load(token_count, theme)
    love.physics.setMeter(64)
    world = love.physics.newWorld(0, 800, true)
    -- setCallbacks(beginContact, endContact, preSolve, postSolve)
    world:setCallbacks(nil, nil, nil, onPostSolve)
    makeJarBody()

    tokens = {}
    local n = math.min(token_count, MAX_VISIBLE)
    for i = 1, n do
        -- accent<->glow blend weight, for per-token variety
        table.insert(tokens, makeToken(math.random() * 0.4 + 0.3))
    end
end

function physics.update(dt, shake_intensity)
    if not world then return end
    world:update(dt)

    -- shake_intensity in 0..1 - apply random jitter forces to tokens
    if shake_intensity and shake_intensity > 0 then
        local force = shake_intensity * 800
        for _, t in ipairs(tokens) do
            local fx = (math.random() - 0.5) * force
            local fy = (math.random() - 0.5) * force - shake_intensity * 100
            t.body:applyLinearImpulse(fx * dt, fy * dt)
        end
    end
end

function physics.draw(theme)
    if not world then return end

    -- Jar outline
    love.graphics.setColor(theme.color("border"))
    love.graphics.setLineWidth(2)
    for _, s in ipairs(jar_shapes) do
        local p = s.points
        love.graphics.line(
            JAR_X + p[1], JAR_Y + p[2],
            JAR_X + p[3], JAR_Y + p[4]
        )
    end

    -- Subtle inner glow line
    love.graphics.setColor(theme.color("glow"))
    love.graphics.setLineWidth(1)
    for _, s in ipairs(jar_shapes) do
        local p = s.points
        love.graphics.line(
            JAR_X + p[1] + 2, JAR_Y + p[2],
            JAR_X + p[3] - 2, JAR_Y + p[4]
        )
    end

    -- Tokens with neon glow halo. Colour is resolved from the *current* theme
    -- each frame, so cycling the theme recolours tokens already in the jar.
    local ar, ag, ab = theme.color("accent")
    local gr, gg, gb = theme.color("glow")
    for _, t in ipairs(tokens) do
        local x, y = t.body:getPosition()
        local m = t.mix
        local cr = ar * (1 - m) + gr * m
        local cg = ag * (1 - m) + gg * m
        local cb = ab * (1 - m) + gb * m
        love.graphics.setColor(cr, cg, cb, 0.25)
        love.graphics.circle("fill", x, y, t.radius * 1.8)
        love.graphics.setColor(cr, cg, cb, 0.5)
        love.graphics.circle("fill", x, y, t.radius * 1.3)
        love.graphics.setColor(cr, cg, cb, 1)
        love.graphics.circle("fill", x, y, t.radius)
        -- Highlight dot
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.circle("fill", x - t.radius * 0.3, y - t.radius * 0.3, t.radius * 0.25)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function physics.tipJar()
    -- Strong upward + sideways impulse to "pour" tokens out of the neck
    if not world then return end
    for _, t in ipairs(tokens) do
        local fx = (math.random() - 0.5) * 200
        local fy = -800 - math.random() * 400
        t.body:applyLinearImpulse(fx, fy)
    end
end

function physics.reset()
    if world then
        world:destroy()
        world = nil
    end
    tokens = {}
end

return physics
