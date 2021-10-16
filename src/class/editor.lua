local editor = {}

local min, max = math.min, math.max

function editor:load()
    self.safeWidth = lg.getWidth() * 0.8
    self.safeHeight = lg.getHeight() * 0.95
    self.border = 1
    self.color = {1, 1, 1, 1} -- Selected color
    self.history = {}
    self.undoSteps = 0
    self.pixels = false

    -- Message in the bottom bar
    self.message = ""
    self.messageTimeout = 5
    self.messageTick = 0

    self.cursor = {
        x = 0,
        y = 0,
        pixel = config.settings.empty_pixel
    }

    self.selection = {
        x = 0, 
        y = 0, 
        originX = 0, 
        originY = 0, 
        width = 0, 
        height = 0, 
        pixels = {}
    }

    self.palette = {
        selected = 1,
        colors = {}
    }

    -- Loading modes
    self.modes = {}
    local modeFiles = fs.getDirectoryItems("src/class/editorModes")
    for _, file in ipairs(modeFiles) do
        local name = get_file_name(file)
        if get_file_type(file) == "lua" then
            self.modes[name] = fs.load(f("src/class/editorModes/%s", file))()
        end
    end

    self:setMode(config.settings.default_mode)
end

function editor:setMode(mode)
    assert(self.modes[mode], f("Mode '%s' does not exist", mode))
    self.mode = self.modes[mode]
    self.mode:enter(self)
end

function editor:updateCellSize()
    self.cellSize = min(floor(self.safeWidth / self.width), floor(self.safeHeight / self.height))
end

function editor:new(width, height)
    self.width, self.height = tonumber(width), tonumber(height)
    
    self.pixels = {}
    for y=1, height do
        self.pixels[y] = {}
        for x=1, width do
            self.pixels[y][x] = config.settings.empty_pixel
        end
    end

    self:updateCellSize()
    self:setCursor(width / 2, height / 2)
    self:print("Created new image")
end

function editor:loadImageFromPath(path)
    if not fs.getInfo(path) then
        self:print(f("Image '%s' does not exist", path))
        return 
    end
    local data = love.image.newImageData(path)
    self.width = data:getWidth()
    self.height = data:getHeight()
    self.pixels = {}
    for y=1, self.height do
        self.pixels[y] = {}
        for x=1, self.width do
            local r, g, b, a = data:getPixel(x - 1, y - 1)
            self.pixels[y][x] = {r, g, b, a}
        end
    end
    self:updateCellSize()
    self:setCursor(self.width / 2, self.height / 2)
    self:print(f("Loaded image '%s'", path))
end

function editor:loadImageFromData(data, path)
    local data = data
    self.width = data:getWidth()
    self.height = data:getHeight()
    self.pixels = {}
    for y=1, self.height do
        self.pixels[y] = {}
        for x=1, self.width do
            local r, g, b, a = data:getPixel(x - 1, y - 1)
            self.pixels[y][x] = {r, g, b, a}
        end
    end
    self:updateCellSize()
    self:setCursor(self.width / 2, self.height / 2)
    self:print(f("Loaded image '%s'", path))
end

function editor:draw()
    if self.pixels then
        self.safeWidth = lg.getWidth() * 0.8
        self.safeHeight = lg.getHeight() * 0.95
        self:updateCellSize()

        local drawWidth = self.width * self.cellSize
        local drawHeight = self.height * self.cellSize
        local xOffset = (self.safeWidth / 2) - (drawWidth / 2)
        local yOffset = (self.safeHeight / 2) - (drawHeight / 2)
        -- Border
        lg.setColor(config.color.background_alt)
        lg.setLineWidth(config.settings.editor_border_width)
        lg.rectangle("line", xOffset, yOffset, self.width * self.cellSize, self.height * self.cellSize)

        -- Image
        for y=1, self.height do
            for x=1, self.width do
                local pixel = self.pixels[y][x]
                lg.setColor(pixel)
                local border = 1
                if not config.settings.show_grid then
                    border = 0
                end
                lg.rectangle("fill", xOffset + (x - 1) * self.cellSize, yOffset + (y - 1) * self.cellSize, self.cellSize - border, self.cellSize - border)
            end
        end

        self.mode:draw(xOffset, yOffset)
    end

    -- Color palette
    local x = self.safeWidth 
    local y = 0
    local cellWidth = (lg.getWidth() - self.safeWidth) / config.settings.max_palette_columns
    local cellHeight = (self.safeHeight / config.settings.max_palette_rows)
    local column = 1
    for i,v in ipairs(self.palette.colors) do
        lg.setColor(v)
        lg.rectangle("fill", x, y, cellWidth, cellHeight)
        lg.setColor(invertColor(v))
        if i == self.palette.selected then
            lg.rectangle("line", x, y, cellWidth, cellHeight)
        end
        x = x + cellWidth
        column = column + 1
        if column > config.settings.max_palette_columns then
            x = self.safeWidth 
            y = y + cellHeight
            column = 1
        end
    end

    -- Info panel
    lg.setColor(self.color)
    lg.rectangle("fill", 0, self.safeHeight, lg.getWidth(), lg.getHeight() - self.safeHeight)
    
    lg.setColor(invertColor(self.color))
    lg.setFont(config.font.tiny)

    -- left
    lg.print(f("%dx%d", self.cursor.x, self.cursor.y), 12, self.safeHeight)

    -- Center
    lg.printf(f("%s", self.message), 0, self.safeHeight, lg.getWidth(), "center")

    -- Right
    lg.printf(f("cmd: %s | %dx%d", tt:getBuffer(), self.width, self.height), -12, self.safeHeight, lg.getWidth(), "right")
end

function editor:update(dt)
    if self.tick > 0 then
        self.tick = self.tick - dt
        if self.tick < 0 then
            self:print()
            self.tick = 0
        end
    end
end

function editor:print(message)
    self.message = message or ""
    if message then
        self.tick = self.messageTimeout
    end
end

function editor:inBounds(x, y)
    return x > 0 and x <= self.width and y > 0 and y <= self.height
end

function editor:setCursor(x, y)
    x = x or self.cursor.x
    y = y or self.cursor.y
    self.cursor.x, self.cursor.y = floor(x), floor(y)
    self.cursor.pixel = self.pixels[self.cursor.y][self.cursor.x]
end

function editor:moveCursor(x, y)
    -- Basic cursor movement
    self.cursor.x = self.cursor.x + x
    if self.cursor.x < 1 then self.cursor.x = 1 elseif self.cursor.x > self.width then self.cursor.x = self.width end

    self.cursor.y = self.cursor.y + y
    if self.cursor.y < 1 then self.cursor.y = 1 elseif self.cursor.y > self.width then self.cursor.y = self.width end

    self.cursorPixel = self.pixels[self.cursor.y][self.cursor.x]

    -- updating mode
    self.mode:moveCursor(self.cursor.x, self.cursor.y)
end
--<<[[ PALETTE ]]>>--

function editor:selectPaletteColor(index)
    if index < 1 then index = 1 elseif index > #self.palette.colors then index = #self.palette.colors end
    self.color = self.palette.colors[index]
    self.palette.selected = index
end

function editor:movePaletteCursor(x, y)
    self:selectPaletteColor(self.palette.selected + x)
    if y > 0 then
        self:selectPaletteColor(self.palette.selected + config.settings.max_palette_columns)
    elseif y < 0 then
        self:selectPaletteColor(self.palette.selected - config.settings.max_palette_columns)
    end
end

function editor:loadPalette(path)
    self.palette.colors = {}
    local data = love.image.newImageData(path)
    for y=0, data:getHeight() - 1 do
        for x=0, data:getWidth() - 1 do
            local i = (y * (data:getHeight() - 1)) + x + 1
            local r, g, b, a = data:getPixel(x, y)
            self.palette.colors[i] = {r, g, b, a}
        end
    end
    self:selectPaletteColor(1)
    self:print(f("Loaded palette '%s'", path))
end

--<<[[ EDITING ]]>>--

function editor:drawPixel(history)
    history = history or true
    if history then self:writeHistory() end
    self.pixels[self.cursor.y][self.cursor.x] = copyColor(self.color)
end

function editor:erasePixel()
    self:writeHistory()
    self.pixels[self.cursor.y][self.cursor.x] = {0, 0, 0, 0}
end

function editor:pickPixel()
    self.color = self.pixels[self.cursor.y][self.cursor.x]
    for i,v in ipairs(self.palette.colors) do 
        if compareColor(self.color, v) then 
            self:selectPaletteColor(i)
            break
        end
    end
end

function editor:getPixel()
    return self.pixels[self.cursor.y][self.cursor.x]
end

function editor:fill(x, y, target)
    if not target then self:writeHistory() end
    
    x = x or self.cursor.x
    y = y or self.cursor.y
    target = target or self.pixels[y][x]

    if not self:inBounds(x, y) or not compareColor(self.pixels[y][x], target) or compareColor(self.pixels[y][x], self.color) then
        return
    end

    self.pixels[y][x] = copyColor(self.color)

    self:fill(x-1, y, target)
    self:fill(x+1, y, target)
    self:fill(x, y-1, target)
    self:fill(x, y+1, target)
end

function editor:fillLine(xStep, yStep)
    local x, y = self.cursor.x, self.cursor.y
    while self:inBounds(x, y) do
        self:drawPixel()
        x = x + xStep
        y = y + yStep
        self:moveCursor(xStep, yStep)
    end
end

-- Warps cursor in a direction until the color changes
function editor:warpCursor(xStep, yStep, fill)
    fill = fill or false
    local color = self.cursorPixel
    local x, y = self.cursor.x, self.cursor.y
    while true do
        x = x + xStep
        y = y + yStep
        if not self:inBounds(x, y) or not compareColor(color, self.pixels[y][x]) then
            self:moveCursor(-xStep, -yStep)
            break
        else
            self:moveCursor(xStep, yStep)
            if fill then self:drawPixel() end
        end
    end
end

function editor:setSelectMode(set)
    set = set or not self.selectMode
    self.selectMode = set
    if self.selectMode then
        self.selection.originX, self.selection.originY = self.cursor.x, self.cursor.y
        self.selection.x, self.selection.y = self.cursor.x, self.cursor.y
        self.selection.width, self.selection.height = 1, 1
        self.grabMode = false
        self:updateSelection()
    end
end

function editor:updateSelection()
    self.selection.pixels = {}
    for y=self.selection.y - 1, self.selection.y + self.selection.height - 1 do
        self.selection.pixels[y - self.selection.y + 1] = {}
        for x=self.selection.x, self.selection.x + self.selection.width do
            self.selection.pixels[y - self.selection.y + 1][x - self.selection.x + 1] = self:clonePixel(x, y)
        end
    end
end

function editor:setGrabMode(set, cut)
    set = set or not self.grabMode
    cut = cut or false
    
    if self.selectMode and not self.grabMode then
        self.grabMode = set
        self.grabModeCut = cut
        if self.selection.originX > self.cursor.x then
            self.cursor.x = self.selection.originX
        end
        if self.selection.originY > self.cursor.y then
            self.cursor.y = self.selection.originY
        end
    end
end

function editor:map(func)
    self:writeHistory()
    for y=1, self.height do
        for x=1, self.width do
            self.pixels[y][x] = func(self.pixels[y][x])
        end
    end
end

function editor:writeHistory()
    if config.settings.use_history then
        if self.undoSteps > 0 then
            for i=#self.history, #self.history - (self.undoSteps - 1), -1 do
                remove(self.history, i)
            end
            self.undoSteps = 0
        end
        insert(self.history, self:clone())
        if #self.history > config.settings.max_undo_steps then
            remove(self.history, 1)
        end
    end
end

function editor:undo()
    if #self.history - self.undoSteps > 0  and not self.selectMode then
        self.pixels = self.history[#self.history - self.undoSteps]
        self.undoSteps = self.undoSteps + 1
    end
end

function editor:redo()
    if #self.history - self.undoSteps > 0 and not self.selectMode then
        self.undoSteps = self.undoSteps - 1
        if self.undoSteps < 0 then self.undoSteps = 0 end
        self.pixels = self.history[#self.history - self.undoSteps]
    end
end

function editor:clone()
    local copy = {}
    for y=1, self.height do
        copy[y] = {}
        for x=1, self.width do
            copy[y][x] = self:clonePixel(x, y)
        end
    end
    return copy
end

function editor:clonePixel(x, y)
    local copy = {}
    if self:inBounds(x, y) then
        for i,v in ipairs(self.pixels[y][x]) do
            copy[i] = v
        end
    end
    return copy
end

function editor:save(file)
    local data = love.image.newImageData(self.width, self.height)
    for y=1, self.height do
        for x=1, self.width do
            data:setPixel(x - 1, y - 1, unpack(self.pixels[y][x]))
        end
    end
    local ok = saveImage(data, "save/"..file)
    if ok then
        self:print(f("Saved as '%s'", "save/"..file))
    else
        self:print(f("'%s' already exists", "save/"..file))
    end
end

function editor:export(filename, scale)
    scale = scale or 1
    local canvas = lg.newCanvas(self.width * scale, self.height * scale)
    lg.setCanvas(canvas)
    for y=1, self.height do
        for x=1, self.width do
            lg.setColor(self.pixels[y][x])
            lg.rectangle("fill", (x - 1) * scale, (y - 1) * scale, scale, scale)
        end
    end
    lg.setCanvas()
    local ok = saveImage(canvas:newImageData(), "export/"..filename)
    if ok then
        self:print(f("Exported image as '%s' at %dx%d", filename, canvas:getWidth(), canvas:getHeight()))
    else
        self:print(f("'%s' already exists", "export/"..filename))
    end
end 
--<<[[ SETTINGS ]]>>--

function editor:toggleBorder()
    if self.border == 1 then self.border = 0 else self.border = 1 end
end

function editor:keypressed(key)
    if not lk.isDown(config.keys.move_palette_cursor) then
        if key == config.keys.cursor_left then
           self:moveCursor(-1, 0)
        elseif key == config.keys.cursor_right then
           self:moveCursor(1, 0)
        elseif key == config.keys.cursor_up then
           self:moveCursor(0, -1)
        elseif key == config.keys.cursor_down then
           self:moveCursor(0, 1)
        end
    end
    self.mode:keypressed(key)

end

return editor