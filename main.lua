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
            text_alt = {200, 200, 200},
            background_global = {32, 32, 32},
            background_alt = {20, 20, 20},
            editor_cursor_color = {20, 126, 255},
            debug_text = {255, 0, 255},
            debug_background = {0, 0, 0, 100},
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
            
            toggle_command_box = "tab",
            select_mode = "s",
            grab_mode = "h",
            grab_mode_cut = "g",
            toggle_grid = "f1",
            toggle_fullscreen = "f2",
            select_palette_color = "cc",
            move_palette_cursor = "c",
            undo = "u",
            redo = "y"
        },
        settings = {
            max_undo_steps = 100,
            use_history = true,
            command_timeout = 0.3,
            show_grid = false,
            debug = true,
            max_palette_columns = 8,
            max_palette_rows = 32,
            window_width = 800,
            window_height = 600,
            window_fullscreen = false,
            window_resizable = true
        }
    }

    -- Loading config
    fs.setIdentity(NAME)
    config = defaultConfig
    if fs.getInfo("config.ini") then
        --config = ini.load("config.ini")
    else
        --ini.save(config, "config.ini")
    end

    updateWindow()
    -- Creating folders
    local folder_structure = {"export", "save", "palettes", "fonts"}
    for _, folder in ipairs(folder_structure) do
        if not fs.getInfo(folder) then
            fs.createDirectory(folder)
        end
    end

    -- Loading colors
    for k,v in pairs(config.color) do
        config.color[k] = color(unpack(v))
    end

    -- Löve setup
    lg.setBackgroundColor(config.color.background_global)
    lg.setLineStyle("rough")
    lk.setKeyRepeat(true)

    -- tt.lua setup
    tt:setInputFilter(function() return not command.visible end)
    tt:setBufferTimeout(config.settings.command_timeout)
    tt:setBufferLength(8)

    command:load()
    command:hide()

    -- Registering text triggers
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

    -- Select & grab mode
    tt:new(config.keys.select_mode, function() editor:setSelectMode() end)
    tt:new(config.keys.grab_mode, function() editor:setGrabMode() end)
    tt:new(config.keys.grab_mode_cut, function() editor:setGrabMode(nil, true) end)


    tt:new(config.keys.toggle_fullscreen, function()
        config.settings.window_fullscreen = not config.settings.window_fullscreen
        updateWindow()
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
    command:register("selectPaletteColor", function(index)
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
        local file = filenameFromTable({...}, "png")
        if #file < 1 then 
            editor:print("No file name provided")  
            return
        end
        editor:save(file)
    end)

    command:register("export", function(...)
        local args = {...}
        local scale = args[#args]
        if tonumber(scale) then remove(args, #args) else scale = 1 end
        local filename = filenameFromTable(args, "png")
        if #filename < 1 then
            editor:print("No file name provided")
        else
            editor:export(filename, scale)    
        end
    end)

    command:register("load", function(...)
        local file = filenameFromTable({...}, "png")
        file = "save/"..file
        if fs.getInfo(file) then
            editor:loadImage(file)
        else
            editor:print(f("Image '%s' does not exists", file))
        end 
    end)

    command:register("loadPalette", function(...)
        local file = filenameFromTable({...}, "png")
        if fs.getInfo("palettes/"..file) then
            editor:loadPalette("palettes/"..file)
        end
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
    editor:loadPalette(config.palette.default)
    editor:new(16, 16)
end

function updateWindow()
    -- Creating window
    love.window.setMode(config.settings.window_width, config.settings.window_height, {
        resizable = config.settings.window_resizable,
        fullscreen = config.settings.window_fullscreen
    })
    love.window.setTitle("KDP")

    -- Loading fonts
    config.font.large = lg.newFont(config.font.file, lg.getWidth() * 0.1)
    config.font.small = lg.newFont(config.font.file, lg.getWidth() * 0.04)
    config.font.tiny = lg.newFont(config.font.file, lg.getWidth() * 0.03)
end

function love.update(dt)
    smoof:update(dt)
    tt:updateTimer(dt)
    editor:update(dt)
end

function love.draw()
    editor:draw()
    command:draw()

    if config.settings.debug then
        local str = f("FPS: %d", love.timer.getFPS())
        lg.setColor(config.color.debug_text)
        lg.print(str, 12, command.height + command.y)
    end
end

function love.resize(w, h)
    config.settings.window_width = w
    config.settings.window_height = h
    config.font.large = lg.newFont(config.font.file, w * 0.1)
    config.font.small = lg.newFont(config.font.file, w * 0.04)
    config.font.tiny = lg.newFont(config.font.file, w * 0.03)
    command:resize(w, h)
end

function love.textinput(t)
    command:textinput(t)
end

function love.keypressed(key)
    tt:updateBuffer(key)
    if key == config.keys.toggle_command_box then command:toggle() end
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
            command.command = "selectPaletteColor "
        end

        if tonumber(key) then
            editor:selectPaletteColor(tonumber(key))
        end
    end
end

function love.filedropped(file)
    file:open("r")
    if get_file_type(file:getFilename()) == "png" then
        local data = love.image.newImageData(file)
        editor:loadImage(data)
    else
        editor:print("Usupported file")
    end
end