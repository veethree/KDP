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

    self.horizontalMirror = false
    self.verticalMirror = false

    -- Message in the bottom bar
    self.message = ""
    self.messageTimeout = 5
    self.messageTick = 0

    self.cursor = {
        x = 0,
        y = 0,
        pixel = config.settings.empty_pixel
    }
    self.palette = {
        selected = 1,
        colors = {}
    }

    self.zoom = 1

    -- Loading modes
    self.modes = {}
    local modeFiles = fs.getDirectoryItems("src/editorModes")
    for _, file in ipairs(modeFiles) do
        local name = get_file_name(file)
        if get_file_type(file) == "lua" then
            self.modes[name] = fs.load(f("src/editorModes/%s", file))()
            self.modes[name]:init(self)
        end
    end
    self.activeMode = "none" -- Used to check which mode is active within editor.lua.

    self:setMode(config.settings.default_mode)
end

function editor:setMode(mode)
    assert(self.modes[mode], f("Mode '%s' does not exist", mode))
    local passData -- Data to pass between the previous & new mode
    if self.mode then 
        passData = self.mode:leave() 
    end
    self.mode = self.modes[mode]
    self.mode:enter(passData)
    self.activeMode = mode
end

function editor:updateCellSize()
    self.cellSize = min(floor(self.safeWidth / (self.width / self.zoom + 2)), floor(self.safeHeight / (self.height / self.zoom + 2)))

end

function editor:clamp(x, y)
    if x < 1 then x = 1 elseif x > self.width then x = self.width end
    if y < 1 then y = 1 elseif y > self.height then y = self.height end
    return x, y
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

function editor:resizeImage(width, height)
    local previousWidth, previousHeight = self.width, self.height
    self.width = tonumber(width)
    self.height = tonumber(height)
    if self.cursor.x > self.width then self:setCursor(self.width) end
    if self.cursor.y > self.height then self:setCursor(nil, self.height) end
    -- Adding new pixels if larger
    if self.height >= previousHeight then
       for y=previousHeight + 1, self.height do
           self.pixels[y] = {}
           for x=1, self.width do
               self.pixels[y][x] = copyColor(config.settings.empty_pixel)
           end
       end 
    end
    if self.width >= previousWidth then
        for y=1, self.height do
            for x=previousWidth + 1, self.width do
                self.pixels[y][x] = copyColor(config.settings.empty_pixel)
            end
        end
    end
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

function editor:setZoom(amount)
    self.zoom = self.zoom + amount
    if self.zoom < 1 then self.zoom = 1 end
end

function editor:scale()
    if self.zoom > 1 then
        local xOffset, yOffset = self:getOffset()
        local curX = xOffset + (self.cursor.x - 1) * self.cellSize
        local curY = yOffset + (self.cursor.y - 1) * self.cellSize
        local cx = self.safeWidth / 2
        local cy = self.safeHeight / 2
        lg.translate((cx - curX), (cy - curY))
    end
end

function editor:getOffset()
    local drawWidth = self.width * self.cellSize
    local drawHeight = self.height * self.cellSize
    local xOffset = (self.safeWidth / 2) - (drawWidth / 2)
    local yOffset = (self.safeHeight / 2) - (drawHeight / 2)
    return xOffset, yOffset
end

function editor:drawColorPalette()
    local x = self.safeWidth 
    local y = 0
    local cellWidth = (lg.getWidth() - self.safeWidth) / config.settings.max_palette_columns
    local cellHeight = (self.safeHeight / config.settings.max_palette_rows)
    local column = 1
    lg.setLineWidth(1)
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
end

function editor:drawInfoPanel()
    -- Background
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

function editor:drawMirror()
    local xOffset, yOffset = self:getOffset()
    if self.horizontalMirror then
        lg.setColor(config.color.mirror)
        local x = xOffset + (self.horizontalMirror - 1) * self.cellSize
        lg.rectangle("line", x, yOffset, self.cellSize, yOffset + self.height * self.cellSize)
    end

    if self.verticalMirror then
        lg.setColor(config.color.mirror)
        local y = yOffset + (self.verticalMirror - 1) * self.cellSize
        lg.rectangle("line", xOffset, y, yOffset + self.width * self.cellSize, self.cellSize)
    end
end

function editor:drawImage()
    if self.pixels then
        local xOffset, yOffset = self:getOffset()
        
        lg.push()
        self:scale()
        -- Border
        lg.setColor(config.color.background_alt)
        lg.setLineWidth(config.settings.editor_border_width)
        lg.rectangle("line", xOffset, yOffset, self.width * self.cellSize, self.height * self.cellSize)

        -- Grid
        local gridWidth = floor(self.width / config.settings.grid_width)
        local gridHeight = floor(self.height / config.settings.grid_height)
        local cellHeight = (self.height * self.cellSize) / gridHeight
        local cellWidth = (self.width * self.cellSize) / gridWidth
        lg.setColor(config.color.grid_color)
        lg.setLineWidth(config.settings.grid_thickness)
        for y=1, gridHeight do
            local ly = yOffset + cellHeight * y 
            lg.line(xOffset, ly, xOffset + (self.width * self.cellSize), ly)
        end
        for x=1, gridWidth do
            local lx = xOffset + cellWidth * x
            lg.line(lx, yOffset, lx, yOffset + (self.height * self.cellSize))
        end
        -- Image
        for y=1, self.height do
            for x=1, self.width do
                local pixel = self.pixels[y][x]
                lg.setColor(pixel)
                local border = 1
                if not config.settings.show_pixel_border then
                    border = 0
                end
                --local fx = self.cursor.x * self.zoom + x - self.cursor.x * self.zoom
                lg.rectangle("fill", xOffset + (x - 1) * self.cellSize, yOffset + (y - 1) * self.cellSize, self.cellSize - border, self.cellSize - border)
            end
        end
        lg.pop()
    end
end

function editor:drawCursor()
    local xOffset, yOffset = self:getOffset()
    lg.push()
    lg.setColor(self.color)
    lg.setLineWidth(1)
    local x = xOffset + (self.cursor.x - 1) * self.cellSize
    local y = yOffset + (self.cursor.y - 1) * self.cellSize
    self:scale()
    -- Cursor
    lg.rectangle("fill", x, y, self.cellSize - self.border, self.cellSize - self.border)
    lg.setColor(invertColor(self.color))
    lg.rectangle("line", x, y, self.cellSize - self.border, self.cellSize - self.border)
    
    -- Horizontal Mirror
    if self.horizontalMirror then
        local mirrorX = self.horizontalMirror - self.cursor.x + self.horizontalMirror
        lg.setColor(config.color.mirror)
        lg.rectangle("fill", xOffset + (mirrorX - 1) * self.cellSize, yOffset + (self.cursor.y - 1) * self.cellSize, self.cellSize - self.border, self.cellSize - self.border)
    end
    -- Vertical Mirror
    if self.verticalMirror then
        local mirrorY = self.verticalMirror - self.cursor.y + self.verticalMirror
        lg.setColor(config.color.mirror)
        lg.rectangle("fill", xOffset + (self.cursor.x - 1) * self.cellSize, yOffset + (mirrorY - 1) * self.cellSize, self.cellSize - self.border, self.cellSize - self.border)
    end

    lg.pop()
end

function editor:draw()
    self.safeWidth = lg.getWidth() * 0.8
    self.safeHeight = lg.getHeight() * 0.95
    self:updateCellSize()

    self:drawImage()
    self:drawColorPalette()
    self:drawInfoPanel()
    local xOffset, yOffset = self:getOffset()
    self.mode:draw(xOffset, yOffset)


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

function editor:setHorizontalMirror()
    if self.horizontalMirror then
        self.horizontalMirror = false
    else
        self.horizontalMirror = self.cursor.x
    end
end

function editor:setVerticalMirror()
    if self.verticalMirror then
        self.verticalMirror = false
    else
        self.verticalMirror = self.cursor.y
    end
end

function editor:setCursor(x, y)
    x = x or self.cursor.x
    y = y or self.cursor.y
    self.cursor.x, self.cursor.y = floor(x), floor(y)
    if self.cursor.x == 0 then self.cursor.x = 1 end
    if self.cursor.y == 0 then self.cursor.y = 1 end
    self.cursor.pixel = self.pixels[self.cursor.y][self.cursor.x]
end

function editor:moveCursor(x, y)
    -- Basic cursor movement
    if lk.isDown(config.keys.cursor_jump) then
        x = x * config.settings.jump_length
        y = y * config.settings.jump_length
    end
    self.cursor.x = self.cursor.x + x
    if self.cursor.x < 1 then self.cursor.x = 1 elseif self.cursor.x > self.width then self.cursor.x = self.width end

    self.cursor.y = self.cursor.y + y
    if self.cursor.y < 1 then self.cursor.y = 1 elseif self.cursor.y > self.height then self.cursor.y = self.height end

    self.cursorPixel = self.pixels[self.cursor.y][self.cursor.x]

    -- updating mode
    self.mode:cursorMoved(self.cursor.x, self.cursor.y)
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

function editor:loadPaletteFromData(data, path)
    self.palette.colors = {}
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

function editor:drawPixel(history, color)
    color = color or self.color
    if self.activeMode == "drawMode" then
        if history == nil then history = true end
        if history then self:writeHistory() end
        self.pixels[self.cursor.y][self.cursor.x] = copyColor(color)
        if self.horizontalMirror then
            local mirrorX = self.horizontalMirror - self.cursor.x + self.horizontalMirror
            if self:inBounds(mirrorX, self.cursor.y) then
                self.pixels[self.cursor.y][mirrorX] = copyColor(color)
            end
        end
        if self.verticalMirror then
            local mirrorY = self.verticalMirror - self.cursor.y + self.verticalMirror
            if self:inBounds(self.cursor.x, mirrorY) then
                self.pixels[mirrorY][self.cursor.x] = copyColor(color)
            end
        end
    end
end

function editor:placePixels(pixels, xOffset, yOffset)
    self:writeHistory()
    for y=1, #pixels do
        for x=1, #pixels[y] do
           if self:inBounds(x + xOffset, y + yOffset) then
               self.pixels[y + yOffset][x + xOffset] = copyColor(pixels[y][x])
           end 
        end
    end
end

function editor:erasePixel()
    self:writeHistory()
    self:drawPixel(false, config.settings.empty_pixel)
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

function editor:getPixel(x, y)
    x = x or self.cursor.x
    y = y or self.cursor.y
    return self.pixels[y][x]
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
    self:writeHistory()
    local x, y = self.cursor.x, self.cursor.y
    while self:inBounds(x, y) do
        self:drawPixel(false)
        x = x + xStep
        y = y + yStep
        self:moveCursor(xStep, yStep)
    end
end

-- Warps cursor in a direction until the color changes
function editor:warpCursor(xStep, yStep, fill)
    self:writeHistory()
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
            if fill then self:drawPixel(false) end
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
        if key == config.keys.zoom_in[2] then
            if lk.isDown(config.keys.zoom_in[1]) then
                self:setZoom(1)
            end
        elseif key == config.keys.zoom_out[2] then
            if lk.isDown(config.keys.zoom_out[1]) then
                self:setZoom(-1)
            end
        end
    end
    self.mode:keypressed(key)

end

return editor