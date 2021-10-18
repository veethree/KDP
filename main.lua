NAME = "KDP"
VERSION = "0.1.1"

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

    local defaultConfig = require("defaultConfig")
    -- Loading config
    fs.setIdentity(NAME)
    config = defaultConfig
    if fs.getInfo("config.ini") then
        --config = ini.load("config.ini")
    else
        ini.save(config, "config.ini")
    end

    updateWindow()
    
    require "src.commands.textTriggers"
    require "src.commands.consoleCommands"

    -- Creating folders
    local folder_structure = {"export", "save", "palettes", "fonts", "commands"}
    for _, folder in ipairs(folder_structure) do
        if not fs.getInfo(folder) then
            fs.createDirectory(folder)
        end
    end

    -- Loading colors
    rawColors = {} -- Storing raw color data
    for k,v in pairs(config.color) do
        config.color[k] = color(unpack(v))
        rawColors[k] = copyColor(v)
    end

    -- Löve setup
    lg.setBackgroundColor(config.color.background_global)
    lg.setLineStyle("rough")
    lk.setKeyRepeat(true)

    prompt:init()
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

-- Clears some unwanted values from the config table before saving it
function purgeConfig()

    config.font.large = nil
    config.font.small = nil
    config.font.tiny = nil
    config.color = rawColors
end

function love.update(dt)
    smoof:update(dt)
    tt:updateTimer(dt)
    editor:update(dt)
end

function love.draw()
    editor:draw()
    console:draw()
    prompt:draw()

    if config.settings.debug then
        local str = f("FPS: %d", love.timer.getFPS())
        lg.setColor(config.color.debug_text)
        lg.print(str, 12, console.height + console.y)
    end
end

function love.resize(w, h)
    config.settings.window_width = w
    config.settings.window_height = h
    config.font.large = lg.newFont(config.font.file, w * 0.1)
    config.font.small = lg.newFont(config.font.file, w * 0.04)
    config.font.tiny = lg.newFont(config.font.file, w * 0.03)
    console:resize(w, h)
end

function love.textinput(t)
    console:textinput(t)
end

function love.keypressed(key)
    tt:updateBuffer(key)
    prompt:keypressed(key)
    if key == config.keys.toggle_command_box then console:toggle() end
    if key == "backspace" then console:backspace() end
    if key == "return" then console:run() end
    
    if not console.visible and not prompt.visible then
        editor:keypressed(key)

        if key == config.keys.toggle_grid then 
            config.settings.show_grid = not config.settings.show_grid
        elseif key == config.keys.cursor_change then
            local r, g, b, a = unpack(editor:getPixel())
            console:show()
            console.command = "color "..r.." "..g.." "..b.." "..a
        elseif key == config.keys.select_palette_color then
            console:show()
            console.command = "selectPaletteColor "
        end

        if tonumber(key) then
            editor:selectPaletteColor(tonumber(key))
        end
    end
end

function love.filedropped(file)
    prompt:new("Load as", {"Image", "Palette"}, function(res)
        if res == "Image" then
            file:open("r")
            if get_file_type(file:getFilename()) == "png" then
                local data = love.image.newImageData(file)
                editor:loadImageFromData(data, file:getFilename())
            else
                editor:print("Unsupported file")
            end
        else
            file:open("r")
            if get_file_type(file:getFilename()) == "png" then
                local data = love.image.newImageData(file)
                editor:loadPaletteFromData(data, file:getFilename())
            else
                editor:print("Unsupported file")
            end
        end
    end)
end

function love.quit()
    purgeConfig()
    ini.save(config, "config.ini")
end
