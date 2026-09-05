-- modules/input.lua
-- Maps physical inputs (keyboard + gamepad) to logical actions.
-- muOS RG35XX devices report standard SDL gamepad events.

local input = {}

local actions = {
    a       = false,  -- confirm / launch
    b       = false,  -- back / cancel
    x       = false,  -- secondary action (cycle status)
    y       = false,  -- skip / not feeling it
    up      = false,
    down    = false,
    left    = false,
    right   = false,
    l1      = false,  -- left bumper - prev tab
    r1      = false,  -- right bumper - next tab
    start   = false,  -- menu
    select  = false,  -- alt menu / settings
}

local pressed_this_frame = {}
local hold_durations = {}  -- key -> seconds held

-- Keyboard fallbacks (useful for desktop development)
local KEY_MAP = {
    ["return"]    = "a",
    ["space"]     = "a",
    ["escape"]    = "b",
    ["backspace"] = "b",
    ["x"]         = "x",
    ["y"]         = "y",
    ["up"]        = "up",
    ["down"]      = "down",
    ["left"]      = "left",
    ["right"]     = "right",
    ["q"]         = "l1",
    ["e"]         = "r1",
    ["tab"]       = "start",
    ["lshift"]    = "select",
}

-- Gamepad mapping (SDL standard layout)
-- Note: muOS / Anbernic devices use standard A/B swap relative to Xbox -
-- on these handhelds, the bottom face button is "B" (back) and right is "A" (confirm).
-- SDL reports them by their physical position so this mapping holds.
local PAD_MAP = {
    ["a"]             = "a",
    ["b"]             = "b",
    ["x"]             = "x",
    ["y"]             = "y",
    ["dpup"]          = "up",
    ["dpdown"]        = "down",
    ["dpleft"]        = "left",
    ["dpright"]       = "right",
    ["leftshoulder"]  = "l1",
    ["rightshoulder" ] = "r1",
    ["start"]         = "start",
    ["back"]          = "select",
}

-- input.update should be called at the END of each frame, after scenes have
-- read their input. We update hold durations here, then clear pressed_this_frame
-- so the next frame's keypressed events populate a fresh table.
function input.update(dt)
    for action, held in pairs(actions) do
        if held then
            hold_durations[action] = (hold_durations[action] or 0) + dt
        else
            hold_durations[action] = 0
        end
    end
end

-- Called by main.lua AFTER scene update to clear edge-triggered presses for
-- the next frame.
function input.endFrame()
    pressed_this_frame = {}
end

function input.keypressed(key)
    local action = KEY_MAP[key]
    if action and not actions[action] then
        actions[action] = true
        pressed_this_frame[action] = true
    end
end

function input.keyreleased(key)
    local action = KEY_MAP[key]
    if action then
        actions[action] = false
    end
end

function input.gamepadpressed(joystick, button)
    local action = PAD_MAP[button]
    if action and not actions[action] then
        actions[action] = true
        pressed_this_frame[action] = true
    end
end

function input.gamepadreleased(joystick, button)
    local action = PAD_MAP[button]
    if action then
        actions[action] = false
    end
end

function input.held(action)
    return actions[action] == true
end

function input.pressed(action)
    return pressed_this_frame[action] == true
end

function input.holdTime(action)
    return hold_durations[action] or 0
end

return input
