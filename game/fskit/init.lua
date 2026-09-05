-- fskit (JarMu subset)
-- JarMu keeps its own theme / input / crt modules, so it only pulls in
-- fskit.screen -- the 640x480 virtual-canvas letterbox shared with
-- ClockMu / BatteryMu. Reconciled into the full fskit at extraction time.

local fskit = {
    _VERSION = "0.1.0",
    screen   = require("fskit.screen"),
}

function fskit.load()
    fskit.screen.load()
end

return fskit
