-- modules/audio.lua
-- Procedurally generated SFX so the demo has zero binary asset dependencies.
-- Each SFX is synthesised at load time into a SoundData buffer.

local audio = {}

local enabled = true
local sources = {}

local function makeSource(generator, duration, sample_rate)
    sample_rate = sample_rate or 22050
    local samples = math.floor(duration * sample_rate)
    local data = love.sound.newSoundData(samples, sample_rate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sample_rate
        local s = generator(t, i, samples)
        if s >  1 then s =  1 end
        if s < -1 then s = -1 end
        data:setSample(i, s)
    end
    return love.audio.newSource(data, "static")
end

-- Glass clink: short pitched ping with quick decay
local function genClink(base_freq)
    return function(t)
        local env = math.exp(-t * 18)
        local sine = math.sin(2 * math.pi * base_freq * t)
        local harm = 0.4 * math.sin(2 * math.pi * base_freq * 2.7 * t)
        return (sine + harm) * env * 0.6
    end
end

-- Tip / pour: descending sweep
local function genTip(t)
    local env = math.exp(-t * 4)
    local freq = 600 - t * 400
    return math.sin(2 * math.pi * freq * t) * env * 0.5
end

-- Reveal jingle: short ascending chord
local function genReveal(t)
    local env = math.exp(-t * 3)
    local f1 = 440  -- A4
    local f2 = 554  -- C#5
    local f3 = 659  -- E5
    local s = math.sin(2 * math.pi * f1 * t)
        + math.sin(2 * math.pi * f2 * t)
        + math.sin(2 * math.pi * f3 * t)
    return (s / 3) * env * 0.6
end

-- Perfect shake sparkle: bright high-freq shimmer
local function genSparkle(t)
    local env = math.exp(-t * 5)
    local s = math.sin(2 * math.pi * 1320 * t)
        + 0.7 * math.sin(2 * math.pi * 1760 * t)
        + 0.5 * math.sin(2 * math.pi * 2640 * t * (1 + 0.3 * math.sin(t * 30)))
    return (s / 2.2) * env * 0.5
end

-- Button tick: short low click
local function genButton(t)
    local env = math.exp(-t * 60)
    return math.sin(2 * math.pi * 220 * t) * env * 0.4
end

-- Power meter tick: rising as meter fills (caller picks pitch)
local function genTick(freq)
    return function(t)
        local env = math.exp(-t * 50)
        return math.sin(2 * math.pi * freq * t) * env * 0.3
    end
end

function audio.load(initially_enabled)
    enabled = initially_enabled ~= false
    -- Defensive: if audio device failed to init, source creation will throw.
    -- We catch it once and disable audio rather than crash the app.
    local ok, err = pcall(function()
        sources.clink1   = makeSource(genClink(880),  0.25)
        sources.clink2   = makeSource(genClink(987),  0.22)
        sources.clink3   = makeSource(genClink(740),  0.28)
        sources.clink4   = makeSource(genClink(1100), 0.20)
        sources.tip      = makeSource(genTip,         0.6)
        sources.reveal   = makeSource(genReveal,      0.8)
        sources.sparkle  = makeSource(genSparkle,     0.7)
        sources.button   = makeSource(genButton,      0.08)
        sources.tick_lo  = makeSource(genTick(330),   0.06)
        sources.tick_mid = makeSource(genTick(550),   0.06)
        sources.tick_hi  = makeSource(genTick(880),   0.06)
    end)
    if not ok then
        print("[audio] init failed, disabling SFX: " .. tostring(err))
        enabled = false
        sources = {}
    end
end

function audio.setEnabled(v)
    enabled = v and true or false
end

function audio.isEnabled()
    return enabled
end

function audio.play(name)
    if not enabled then return end
    local src = sources[name]
    if src then
        local clone = src:clone()
        clone:setVolume(0.8)
        clone:play()
    end
end

function audio.clink()
    if not enabled then return end
    local pick = math.random(1, 4)
    audio.play("clink" .. pick)
end

return audio
