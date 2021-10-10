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
    cmd = require "src.class.command"
    editor = require "src.class.editor"
    smoof = require "src.class.smoof"
    exString = require "src.class.exString"
    exString.import()

    config = {
        palette = {
            default = "src/palette/resurrect-32-1x.png"
        },
        color = {
            text_default = color(255, 255, 255),
            text_alt = color(30, 30, 30),
            background_global = color(100, 100, 100),
            background_alt = color(30, 30, 30),
            editor_cursor_color = color(20, 126, 255),
            debug = color(255, 0, 255)
        },
        font = {
            large = lg.newFont("src/font/monogram.ttf", lg.getWidth() * 0.1),
            small = lg.newFont("src/font/monogram.ttf", lg.getWidth() * 0.04),
            tiny = lg.newFont("src/font/monogram.ttf", lg.getWidth() * 0.03),
        },
        keys = {
            cursor_left = "left",
            cursor_right = "right",
            cursor_up = "up",
            cursor_down = "down",
            cursor_draw = "d",
            cursor_erase = "x",
            cursor_fill = "f",
            cursor_pick = "s",
            cursor_change = "c",
            toggle_command = "tab",
            toggle_grid = "g",
            select_palette_color = "p",
            undo = "u",
            redo = "y"
        },
        settings = {
            max_undo_steps = 100,
            use_history = true,
            debug = true
        }
    }

    -- Löve setup
    lg.setBackgroundColor(config.color.background_global)
    lg.setLineStyle("rough")
    lk.setKeyRepeat(true)

    cmd:load()
    cmd:hide()

    -- Registering commands
    cmd:register("q", function() love.event.push("quit") end)
    cmd:register("color", function(r, g, b, a)
        a = a or 255
        editor.color = {r / 255, g / 255, b / 255, a / 255}
    end)
    cmd:register("p", function(index)
        editor:selectPaletteColor(tonumber(index))
    end)
    cmd:register("ap", function(index)
        editor:addToPalette(nil, index)
    end)

    cmd:register("shade", function(factor)
        factor = factor or 1.1
        local new = copyColor(editor.color)
        for i=1, 3 do
            new[i] = editor.color[i] / factor
        end
        editor.color = new
    end)

    cmd:register("light", function(factor)
        factor = factor or 0.1
        local new = copyColor(editor.color)
        for i=1, 3 do
            new[i] = editor.color[i] + factor
        end
        editor.color = new
    end)


    cmd:register("new", function(w, h)
        editor:new(w, h)
    end)

    -- "shaders"
    cmd:register("invert", function()
        editor:map(function(pixel)
            return {1 - pixel[1], 1 - pixel[2], 1 - pixel[3], pixel[4]}
        end)
    end)
    cmd:register("grayscale", function()
        editor:map(function(pixel)
            local avg = pixel[1] + pixel[2] + pixel[3] / 3
            return {avg, avg, avg, pixel[4]}
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
    cmd:draw()

    lg.setColor(config.color.debug)
    lg.setFont(config.font.tiny)
    lg.print(love.timer.getFPS(), 12, lg.getHeight() - config.font.tiny:getHeight())
end

function love.textinput(t)
    cmd:textinput(t)
end

function love.keypressed(key)
    if key == "escape" then love.event.push("quit") end 
    if key == config.keys.toggle_command then cmd:toggle() end
    if key == "backspace" then cmd:backspace() end
    if key == "return" then cmd:run() end
    

    if not cmd.visible then
        if key == config.keys.cursor_left then
            editor:moveCursor(-1, 0)
        elseif key == config.keys.cursor_right then
            editor:moveCursor(1, 0)
        elseif key == config.keys.cursor_up then
            editor:moveCursor(0, -1)
        elseif key == config.keys.cursor_down then
            editor:moveCursor(0, 1)
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
            editor:toggleBorder()
        elseif key == config.keys.cursor_change then
            local r, g, b, a = unpack(editor:getPixel())
            cmd:show()
            cmd.command = "color "..r.." "..g.." "..b.." "..a
        elseif key == config.keys.select_palette_color then
            cmd:show()
            cmd.command = "p "
        end

        if tonumber(key) then
            editor:selectPaletteColor(tonumber(key))
        end
    end
end