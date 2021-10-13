NAME = "KDP"
VERSION = 0.1

-- GLOBALS
lg = love.graphics
fs = love.filesystem
lk = love.keyboard
lm = love.mouse
random = math.random
noise = love.math.noise
floor = math.floor
sin = math.sin
cos = math.cos
f = string.format
insert = table.insert
remove = table.remove

function love.load()
    -- Loading classes
    require "src.class.util"
    requireFolder("src/class")
    exString.import()

    local defaultConfig = {
        palette = {
            default = "src/palette/duel-1x.png"
        },
        color = {
            text_default = {255, 255, 255},
            text_alt = {30, 30, 30},
            background_global = {64, 64, 64},
            background_alt = {30, 30, 30},
            editor_cursor_color = {20, 126, 255},
            debug = {255, 0, 255},
            selection = {255, 0, 255}
        },
        font = {
            file = "src/font/monogram.ttf"
        },
        keys = {
            cursor_left = "left",
            cursor_right = "right",
            cursor_up = "up",
            cursor_down = "down",
            cursor_draw = "d",
            cursor_erase = "x",
            cursor_fill = "f",
            cursor_pick = "t",

            cursor_line_left = "ddleft",
            cursor_line_right = "ddright",
            cursor_line_up = "ddup",
            cursor_line_down = "dddown",
            
            cursor_line_color_left = "dcleft",
            cursor_line_color_right = "dcright",
            cursor_line_color_up = "dcup",
            cursor_line_color_down = "dcdown",

            cursor_warp_left = "wwleft",
            cursor_warp_down = "wwdown",
            cursor_warp_up = "wwup",
            cursor_warp_right = "wwright",

            cursor_warp_color_left = "wcleft",
            cursor_warp_color_right = "wcright",
            cursor_warp_color_up = "wcup",
            cursor_warp_color_down = "wcdown",
            
            cursor_change = "_",
            toggle_command = "tab",
            select_mode = "s",
            grab_mode = "g",
            toggle_grid = "",
            select_palette_color = "cc",
            move_palette_cursor = "c",
            --next_palette_color = "l",
            --previous_palette_color = "h",
            --next_palette_row = "j",
            --previous_palette_row = "k",
            undo = "u",
            redo = "y"
        },
        settings = {
            max_undo_steps = 100,
            use_history = true,
            show_grid = false,
            debug = true,
            max_palette_columns = 8,
            max_palette_rows = 32,
            window_width = 800,
            window_height = 600
        }
    }

    -- Loading config
    fs.setIdentity(NAME)
    config = defaultConfig
    if fs.getInfo("config.ini") then
        --config = ini.load("config.ini")
    else
        --ttf.save(config, "config.lua")
        ini.save(config, "config.ini")
    end

    -- Creating window
    love.window.setMode(config.settings.window_width, config.settings.window_height, {resizable = true})
    love.window.setTitle("KDP")

    -- Loading fonts
    config.font.large = lg.newFont(config.font.file, lg.getWidth() * 0.1)
    config.font.small = lg.newFont(config.font.file, lg.getWidth() * 0.04)
    config.font.tiny = lg.newFont(config.font.file, lg.getWidth() * 0.03)

    -- Loading colors
    for k,v in pairs(config.color) do
        config.color[k] = color(unpack(v))
    end

    -- Löve setup
    lg.setBackgroundColor(config.color.background_global)
    lg.setLineStyle("rough")
    lk.setKeyRepeat(true)

    command:load()
    command:hide()

    -- Registering text triggers
    tt:setInputFilter(function() return not command.visible end)
    -- Line fill
    tt:new(config.keys.cursor_line_left, function() editor:fillLine(-1, 0) end)
    tt:new(config.keys.cursor_line_right, function() editor:fillLine(1, 0) end)
    tt:new(config.keys.cursor_line_up, function() editor:fillLine(0, -1) end)
    tt:new(config.keys.cursor_line_down, function() editor:fillLine(0, 1) end)

    --Cursor warp
    tt:new(config.keys.cursor_warp_left, function() editor:setCursor(1) end)
    tt:new(config.keys.cursor_warp_right, function() editor:setCursor(editor.width) end)
    tt:new(config.keys.cursor_warp_up, function() editor:setCursor(nil, 1) end)
    tt:new(config.keys.cursor_warp_down, function() editor:setCursor(nil, editor.height) end)

    --Cursor color warp
    tt:new(config.keys.cursor_warp_color_left, function() editor:warpCursor(-1, 0) end)
    tt:new(config.keys.cursor_warp_color_right, function() editor:warpCursor(1, 0) end)
    tt:new(config.keys.cursor_warp_color_up, function() editor:warpCursor(0, -1) end)
    tt:new(config.keys.cursor_warp_color_down, function() editor:warpCursor(0, 1) end)

    -- Cursor warp line
    tt:new(config.keys.cursor_line_color_left, function() editor:warpLine(-1, 0) end)
    tt:new(config.keys.cursor_line_color_right, function() editor:warpLine(1, 0) end)
    tt:new(config.keys.cursor_line_color_up, function() editor:warpLine(0, -1) end)
    tt:new(config.keys.cursor_line_color_down, function() editor:warpLine(0, 1) end)

    tt:new(config.keys.select_mode, function() editor:setSelectMode() end)
    tt:new(config.keys.grab_mode, function() editor:setGrabMode() end)

    -- Palette movement
    --tt:new(config.keys.next_palette_color, function() editor:selectPaletteColor(editor.selectedColor + 1) end)
    --tt:new(config.keys.previous_palette_color, function() editor:selectPaletteColor(editor.selectedColor - 1) end)
    --tt:new(config.keys.next_palette_row, function() editor:selectPaletteColor(editor.selectedColor + config.settings.max_palette_columns) end)
    --tt:new(config.keys.previous_palette_row, function() editor:selectPaletteColor(editor.selectedColor - config.settings.max_palette_columns) end)

    tt:new(config.keys.select_palette_color, function()
        command:show()
        command.command = "p "     
    end)
    
    -- Registering commands
    command:register("q", function() love.event.push("quit") end)
    command:register("os", function() love.system.openURL("file://"..love.filesystem.getSaveDirectory()) end)
    command:register("color", function(r, g, b, a)
        if r and not g and not b and not a then
            g = r
            b = r
        end
        a = a or 255
        editor.color = {r / 255, g / 255, b / 255, a / 255}
    end)
    command:register("p", function(index)
        editor:selectPaletteColor(tonumber(index))
    end)
    command:register("ap", function(index)
        editor:addToPalette(nil, index)
    end)

    command:register("shade", function(factor)
        factor = factor or 1.1
        local new = copyColor(editor.color)
        for i=1, 3 do
            new[i] = editor.color[i] / factor
        end
        editor.color = new
    end)

    command:register("light", function(factor)
        factor = factor or 0.1
        local new = copyColor(editor.color)
        for i=1, 3 do
            new[i] = editor.color[i] + factor
        end
        editor.color = new
    end)

    command:register("new", function(w, h)
        if w and not h then
            h = w
        end
        editor:new(w or 16, h or 16)
    end)

    command:register("save", function(...)
        local file = ""
        for i,v in ipairs({...}) do 
            file = file..v
            if i < #{...} then
                file = file.." "
            end
        end
        if #file < 1 then file = "untitled" end
        file = file..".png"
        editor:save(file)
    end)

    command:register("export", function(filename, scale)
        if tonumber(scale) then
            editor:export(filename, scale)    
        end
    end)

    command:register("load", function(...)
        local file = ""
        for i,v in ipairs({...}) do 
            file = file..v
            if i < #{...} then
                file = file.." "
            end
        end
        file = file..".png"
        editor:loadImage(file)
    end)

    -- "shaders"
    command:register("invert", function()
        editor:map(function(pixel)
            return {1 - pixel[1], 1 - pixel[2], 1 - pixel[3], pixel[4]}
        end)
    end)
    command:register("grayscale", function()
        editor:map(function(pixel)
            local avg = pixel[1] + pixel[2] + pixel[3] / 3
            return {avg, avg, avg, pixel[4]}
        end)
    end)

    command:register("noise", function(strength)
        editor:map(function(pixel)
            strength = strength or 0.01
            local off = random() * strength
            return {pixel[1] + off, pixel[2] + off, pixel[3] + off, pixel[4]} 
        end)
    end)
    editor:load()
    editor:new(16, 16)
    editor:loadPalette(config.palette.default)
    --editor:load("all_sprites.png")

end

function love.update(dt)
    smoof:update(dt)
end

function love.draw()
    editor:draw()
    command:draw()

    lg.setColor(config.color.debug)
    lg.setFont(config.font.tiny)
    lg.printf(love.timer.getFPS(), 12, lg.getHeight() - config.font.tiny:getHeight() * 2, lg.getWidth(), "center")
end

function love.resize(w, h)
    config.settings.window_width = w
    config.settings.window_height = h
    config.font.large = lg.newFont(config.font.file, w * 0.1)
    config.font.small = lg.newFont(config.font.file, w * 0.04)
    config.font.tiny = lg.newFont(config.font.file, w * 0.03)
end

function love.textinput(t)
    command:textinput(t)
end

function love.keypressed(key)
    tt:updateBuffer(key)
    --if key == "escape" then love.event.push("quit") end 
    if key == config.keys.toggle_command then command:toggle() end
    if key == "backspace" then command:backspace() end
    if key == "return" then command:run() end
    

    if not command.visible then
        if key == config.keys.cursor_left then
            local xStep, yStep = -1, 0
            if lk.isDown(config.keys.move_palette_cursor) then
                editor:movePaletteCursor(xStep, yStep)
            else
                editor:moveCursor(xStep, yStep)
            end
        elseif key == config.keys.cursor_right then
            local xStep, yStep = 1, 0
            if lk.isDown(config.keys.move_palette_cursor) then
                editor:movePaletteCursor(xStep, yStep)
            else
                editor:moveCursor(xStep, yStep)
            end
        elseif key == config.keys.cursor_up then
            local xStep, yStep = 0, -1
            if lk.isDown(config.keys.move_palette_cursor) then
                editor:movePaletteCursor(xStep, yStep)
            else
                editor:moveCursor(xStep, yStep)
            end
        elseif key == config.keys.cursor_down then
            local xStep, yStep = 0, 1
            if lk.isDown(config.keys.move_palette_cursor) then
                editor:movePaletteCursor(xStep, yStep)
            else
                editor:moveCursor(xStep, yStep)
            end
        end

        if key == config.keys.cursor_draw then
            editor:drawPixel()
        elseif key == config.keys.cursor_erase then
            editor:erasePixel()
        elseif key == config.keys.cursor_fill then
            editor:fill()
        elseif key == config.keys.cursor_pick then
            editor:pickPixel()
        elseif key == config.keys.undo then
            editor:undo()
        elseif key == config.keys.redo then
            editor:redo()
        elseif key == config.keys.toggle_grid then 
            config.settings.show_grid = not config.settings.show_grid
        elseif key == config.keys.cursor_change then
            local r, g, b, a = unpack(editor:getPixel())
            command:show()
            command.command = "color "..r.." "..g.." "..b.." "..a
        elseif key == config.keys.select_palette_color then
            command:show()
            command.command = "p "
        end

        if tonumber(key) then
            editor:selectPaletteColor(tonumber(key))
        end
    end
end

function love.filedropped(file)
    file:open("r")
    local data = love.image.newImageData(file)
    editor:loadImage(data)
end