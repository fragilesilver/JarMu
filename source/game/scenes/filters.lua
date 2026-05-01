-- scenes/filters.lua
-- Filter screen: select systems, tags, status, plus toggles.
-- Layout: three columns (Systems / Tags / Status) navigated with L/R for column,
-- D-pad up/down to move within column, A to toggle, B to return to jar.

local picker  = require("modules.picker")
local library = require("modules.library")

local filters = {}

local columns = {}    -- list of {title, items, type} where items may be checkbox or toggle
local col_idx = 1     -- which column has focus
local row_idx = {1, 1, 1}  -- per-column cursor row

local function rebuildColumns()
    columns = {}

    -- Column 1: Systems
    local sys_items = {}
    for _, sys in ipairs(library.systems()) do
        table.insert(sys_items, {
            label = sys,
            kind  = "system",
            value = sys,
        })
    end
    table.insert(columns, { title = "SYSTEMS", items = sys_items })

    -- Column 2: Tags
    local tag_items = {}
    table.insert(tag_items, {
        label = "Match: " .. (picker.tagsMode() == "all" and "ALL TAGS" or "ANY TAG"),
        kind  = "tag_mode",
    })
    for _, tag in ipairs(library.tags()) do
        table.insert(tag_items, {
            label = tag,
            kind  = "tag",
            value = tag,
        })
    end
    if #tag_items == 1 then
        table.insert(tag_items, {
            label = "(no tags yet - edit overrides.lua)",
            kind  = "info",
        })
    end
    table.insert(columns, { title = "TAGS", items = tag_items })

    -- Column 3: Status + special
    local stat_items = {
        { label = "Backlog",    kind = "status", value = "backlog" },
        { label = "Playing",    kind = "status", value = "playing" },
        { label = "Beaten",     kind = "status", value = "beaten" },
        { label = "Favourite",  kind = "status", value = "favourite" },
        { label = "---",        kind = "spacer" },
        { label = "Surprise Me", kind = "surprise" },
        { label = "Weighted Random", kind = "weighted" },
    }
    table.insert(columns, { title = "STATUS", items = stat_items })

    for i = 1, 3 do
        if row_idx[i] > #columns[i].items then
            row_idx[i] = #columns[i].items
        end
        if row_idx[i] < 1 then row_idx[i] = 1 end
    end
end

function filters:enter()
    rebuildColumns()
end

local function isChecked(item)
    if item.kind == "system" then
        -- Inverted: checked means INCLUDED (not excluded)
        return not picker.isSystemExcluded(item.value)
    elseif item.kind == "tag" then
        return picker.isTagRequired(item.value)
    elseif item.kind == "status" then
        return not picker.isStatusExcluded(item.value)
    elseif item.kind == "surprise" then
        return picker.surpriseMe()
    elseif item.kind == "weighted" then
        return App.persistence().get("weighted", true)
    end
    return false
end

local function toggleItem(item)
    if item.kind == "system" then
        picker.setSystemExcluded(item.value, not picker.isSystemExcluded(item.value))
    elseif item.kind == "tag" then
        picker.setTagRequired(item.value, not picker.isTagRequired(item.value))
    elseif item.kind == "status" then
        picker.setStatusExcluded(item.value, not picker.isStatusExcluded(item.value))
    elseif item.kind == "tag_mode" then
        picker.toggleTagsMode()
        rebuildColumns()
    elseif item.kind == "surprise" then
        picker.setSurpriseMe(not picker.surpriseMe())
    elseif item.kind == "weighted" then
        local cur = App.persistence().get("weighted", true)
        App.persistence().set("weighted", not cur)
    end
end

function filters:update(dt)
    local input = App.input()
    if input.pressed("b") then
        App.switch("jar")
    elseif input.pressed("l1") then
        col_idx = col_idx - 1
        if col_idx < 1 then col_idx = #columns end
        App.audio().play("button")
    elseif input.pressed("r1") then
        col_idx = col_idx + 1
        if col_idx > #columns then col_idx = 1 end
        App.audio().play("button")
    elseif input.pressed("up") then
        row_idx[col_idx] = row_idx[col_idx] - 1
        if row_idx[col_idx] < 1 then row_idx[col_idx] = #columns[col_idx].items end
        App.audio().play("button")
    elseif input.pressed("down") then
        row_idx[col_idx] = row_idx[col_idx] + 1
        if row_idx[col_idx] > #columns[col_idx].items then row_idx[col_idx] = 1 end
        App.audio().play("button")
    elseif input.pressed("a") then
        local item = columns[col_idx].items[row_idx[col_idx]]
        if item and item.kind ~= "info" and item.kind ~= "spacer" then
            toggleItem(item)
            App.audio().play("button")
        end
    elseif input.pressed("y") then
        -- Quick "include all" within active column
        for _, item in ipairs(columns[col_idx].items) do
            if item.kind == "system" then
                picker.setSystemExcluded(item.value, false)
            elseif item.kind == "tag" then
                picker.setTagRequired(item.value, false)
            elseif item.kind == "status" then
                picker.setStatusExcluded(item.value, false)
            end
        end
        App.audio().play("button")
    end
end

local function drawColumn(theme, col, x, w, focused)
    -- Header
    if focused then
		love.graphics.setColor(theme.color("text_accent"))
	else
		love.graphics.setColor(theme.color("text_dim"))
	end
    love.graphics.printf(col.title, x, 50, w, "center")

    -- Border
    if focused then
        love.graphics.setColor(theme.color("border"))
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x - 4, 70, w + 8, 360, 4)
    end

    local y = 80
    local cursor_row = row_idx[col_idx]
    for i, item in ipairs(col.items) do
        if y > 410 then break end

        local is_focused_row = focused and (i == cursor_row)

        if is_focused_row then
            love.graphics.setColor(theme.color("panel_alt"))
            love.graphics.rectangle("fill", x - 2, y - 2, w + 4, 22, 2)
        end

        if item.kind == "spacer" then
            love.graphics.setColor(theme.color("text_dim"))
            love.graphics.line(x + 8, y + 10, x + w - 8, y + 10)
        elseif item.kind == "info" then
            love.graphics.setColor(theme.color("text_dim"))
            love.graphics.print(item.label, x + 4, y + 4)
        elseif item.kind == "tag_mode" then
            love.graphics.setColor(theme.color("text_accent"))
            love.graphics.print(item.label, x + 4, y + 4)
        else
            local checked = isChecked(item)
            local box = checked and "[X]" or "[ ]"
			if checked then
				love.graphics.setColor(theme.color("accent"))
			else
				love.graphics.setColor(theme.color("text_dim"))
			end
            love.graphics.print(box, x + 4, y + 4)
			
			if is_focused_row then
				love.graphics.setColor(theme.color("text"))
			else
				if checked then
					love.graphics.setColor(theme.color("text"))
				else
					love.graphics.setColor(theme.color("text_dim"))
				end
			end
            love.graphics.print(item.label, x + 36, y + 4)
        end

        y = y + 22
    end
end

function filters:draw()
    local theme = App.theme()

    -- Title bar
    love.graphics.setColor(theme.color("text_accent"))
    local font = love.graphics.getFont()
    local title = "FILTERS"
    love.graphics.print(title, (640 - font:getWidth(title) * 1.5) / 2, 10, 0, 1.5, 1.5)
    love.graphics.setColor(theme.color("text_dim"))
    local count = picker.eligibleCount()
    love.graphics.printf(("%d GAMES IN JAR"):format(count), 0, 40, 640, "center")

    -- Three columns
    drawColumn(theme, columns[1],  20, 200, col_idx == 1)
    drawColumn(theme, columns[2], 220, 200, col_idx == 2)
    drawColumn(theme, columns[3], 420, 200, col_idx == 3)

    -- Footer
    local hints = {
        { btn = "A",   label = "TOGGLE" },
        { btn = "Y",   label = "INCLUDE ALL" },
        { btn = "L/R", label = "COLUMN" },
        { btn = "B",   label = "BACK" },
    }
    local y = 458
    local x = 12
    for _, h in ipairs(hints) do
        love.graphics.setColor(theme.color("accent"))
        love.graphics.print("[" .. h.btn .. "]", x, y)
        local bw = love.graphics.getFont():getWidth("[" .. h.btn .. "] ")
        love.graphics.setColor(theme.color("text"))
        love.graphics.print(h.label, x + bw, y)
        x = x + bw + love.graphics.getFont():getWidth(h.label) + 16
    end
end

return filters
