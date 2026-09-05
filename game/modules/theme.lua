-- modules/theme.lua
-- 8-colour theme picker matching ClockMu, with retro arcade neon accents.

local theme = {}

-- Each theme defines a base accent colour. The arcade aesthetic uses
-- a dark background with neon-saturated accents regardless of the
-- chosen accent hue.
local THEMES = {
    mustard = {
        name   = "Mustard Yellow",
        accent = {1.00, 0.78, 0.20},
        glow   = {1.00, 0.85, 0.35},
    },
    orange = {
        name   = "Intense Orange",
        accent = {1.00, 0.45, 0.10},
        glow   = {1.00, 0.60, 0.25},
    },
    red = {
        name   = "Bloody Red",
        accent = {1.00, 0.20, 0.25},
        glow   = {1.00, 0.40, 0.45},
    },
    blue = {
        name   = "Ocean Blue",
        accent = {0.20, 0.65, 1.00},
        glow   = {0.40, 0.80, 1.00},
    },
    green = {
        name   = "Forest Green",
        accent = {0.30, 0.95, 0.50},
        glow   = {0.50, 1.00, 0.70},
    },
    purple = {
        name   = "Funky Purple",
        accent = {0.75, 0.30, 1.00},
        glow   = {0.90, 0.50, 1.00},
    },
    white = {
        name   = "Yoga White",
        accent = {0.95, 0.95, 0.95},
        glow   = {1.00, 1.00, 1.00},
    },
    black = {
        name   = "Midnight Black",
        accent = {0.45, 0.45, 0.50},
        glow   = {0.65, 0.65, 0.70},
    },
}

local THEME_ORDER = {
    "mustard", "orange", "red", "blue",
    "green", "purple", "white", "black",
}

local current = "mustard"

function theme.load(name)
    if THEMES[name] then current = name end
end

function theme.set(name)
    if THEMES[name] then current = name end
end

function theme.cycle()
    for i, k in ipairs(THEME_ORDER) do
        if k == current then
            current = THEME_ORDER[(i % #THEME_ORDER) + 1]
            return current
        end
    end
end

function theme.name()
    return current
end

function theme.list()
    return THEME_ORDER
end

function theme.color(role)
    local t = THEMES[current]
    if role == "bg"        then return 0.04, 0.04, 0.07, 1.00 end
    if role == "panel"     then return 0.08, 0.08, 0.12, 1.00 end
    if role == "panel_alt" then return 0.12, 0.12, 0.16, 1.00 end
    if role == "border"    then return t.accent[1], t.accent[2], t.accent[3], 1.0 end
    if role == "accent"    then return t.accent[1], t.accent[2], t.accent[3], 1.0 end
    if role == "glow"      then return t.glow[1],   t.glow[2],   t.glow[3],   1.0 end
    if role == "text"      then return 0.92, 0.92, 0.95, 1.0 end
    if role == "text_dim"  then return 0.55, 0.55, 0.60, 1.0 end
    if role == "text_accent" then return t.glow[1], t.glow[2], t.glow[3], 1.0 end
    if role == "danger"    then return 1.00, 0.30, 0.35, 1.0 end
    if role == "success"   then return 0.30, 1.00, 0.50, 1.0 end
    return 1, 1, 1, 1
end

return theme
