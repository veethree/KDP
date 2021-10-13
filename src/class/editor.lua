local editor = {}

local min, max = math.min, math.max

function editor:load()
    self.safeWidth = lg.getWidth() * 0.8
    self.safeHeight = lg.getHeight() * 0.95
    self.border = 1
    self.color = {1, 1, 1, 1}
    self.palette = {}
    self.selectedColor = 1
    self.history = {}
    self.undoSteps = 0
    self.pixels = false
    self.cursorX = 0
    self.cursorY = 0
    self.selection = {x = 0, y = 0, originX = 0, originY = 0, width = 0, height = 0, pixels = {}}
    self.selectMode = false
    self.grabMode = false
    self.message = ""
    self.messageTimeout = 5
    self.messageTick = 0
end

function editor:new(width, height)
    width = tonumber(width)
    height = tonumber(height)
    self.width, self.height = width, height
    
    self.pixels = {}
    for y=1, height do
        self.pixels[y] = {}
        for x=1, width do
            self.pixels[y][x] = {0, 0, 0, 0}
        end
    end
    self.cellSize = min(floor(self.safeWidth / width), floor(self.safeHeight / height))

    self.cursorX = floor(width / 2)
    self.cursorY = floor(height / 2)
    self.cursorPixel = self.pixels[self.cursorY][self.cursorX]
    self:print("Created new image")
end

function editor:loadImage(path)
    self.pixels = {}
    local data
    if type(path) == "string" then
        if not fs.getInfo(path) then return false end
        data = love.image.newImageData(path)
    elseif type(path) == "userdata" then
        data = path
    end
    self.width = data:getWidth()
    self.height = data:getHeight()
    for y=1, self.height do
        self.pixels[y] = {}
        for x=1, self.width do
            local r, g, b, a = data:getPixel(x - 1, y - 1)
            self.pixels[y][x] = {r, g, b, a}
        end
    end
    self.cursorX = floor(self.width / 2)
    self.cursorY = floor(self.height / 2)
    self.cursorPixel = self.pixels[self.cursorY][self.cursorX]
    self.cellSize = min(floor(self.safeWidth / self.width), floor(self.safeHeight / self.height))
    self:print(f("Loaded image '%s'", path))
    return true
end

function editor:draw()
    if self.pixels then
        self.safeWidth = lg.getWidth() * 0.8
        self.safeHeight = lg.getHeight() * 0.95
        self.cellSize = min(floor(self.safeWidth / self.width), floor(self.safeHeight / self.height))

        local drawWidth = self.width * self.cellSize
        local drawHeight = self.height * self.cellSize
        local xOffset = (self.safeWidth / 2) - (drawWidth / 2)
        local yOffset = (self.safeHeight / 2) - (drawHeight / 2)
        -- Border
        lg.setColor(config.color.background_alt)
        lg.setLineWidth(4)
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
        -- Cursor
        lg.setColor(self.color)
        lg.setLineWidth(1)
        lg.rectangle("fill", xOffset + (self.cursorX - 1) * self.cellSize, yOffset + (self.cursorY - 1) * self.cellSize, self.cellSize - self.border, self.cellSize - self.border)

        lg.setColor(invertColor(self.color))
        lg.rectangle("line", xOffset + (self.cursorX - 1) * self.cellSize, yOffset + (self.cursorY - 1) * self.cellSize, self.cellSize - self.border, self.cellSize - self.border)

        -- Selection
        if self.selectMode then
            lg.setColor(config.color.selection)
            lg.rectangle("line", xOffset + (self.selection.x - 1) * self.cellSize, yOffset + (self.selection.y - 1) * self.cellSize, self.selection.width * self.cellSize, self.selection.height * self.cellSize)
        end

        if self.grabMode then
            local selectX = (self.selection.x - 1) * self.cellSize
            local selectY = (self.selection.y - 1) * self.cellSize
            for y=1, self.selection.height do 
                for x=1, self.selection.width do
                    lg.setColor(self.selection.pixels[y][x])
                    lg.rectangle("fill", xOffset + selectX + (x - 1) * self.cellSize, yOffset + selectY + (y - 1) * self.cellSize, self.cellSize, self.cellSize)
                end
            end
            lg.setColor(config.color.selection)
            lg.rectangle("line", xOffset + selectX, yOffset + selectY, self.selection.width * self.cellSize, self.selection.height * self.cellSize)
        end
    end

    -- Color palette
    local safePaletteWidth = (lg.getWidth() - self.safeWidth) * 0.9
    local diff = ((lg.getWidth() - self.safeWidth) - safePaletteWidth)
    local x = self.safeWidth + diff
    local y = 0
    local cw = safePaletteWidth / config.settings.max_palette_columns
    local ch = (self.safeHeight / config.settings.max_palette_rows)
    local col = 1
    for i,v in ipairs(self.palette) do
        lg.setColor(v)
        lg.rectangle("fill", x, y, cw, ch)
        lg.setColor(invertColor(v))
        if i == self.selectedColor then
            lg.rectangle("line", x, y, cw, ch)
        end
        x = x + cw
        col = col + 1
        if col > config.settings.max_palette_columns then
            --lg.setColor(config.color.text_default)
            --lg.printf(i-config.settings.max_palette_columns + 1 .."-"..i, -(lg.getWidth() - self.safeWidth) + diff, y, lg.getWidth(), "right")
            x = self.safeWidth + diff
            y = y + ch
            col = 1
        end
    end

    -- Info
    lg.setColor(self.color)
    lg.rectangle("fill", 0, self.safeHeight, lg.getWidth(), lg.getHeight() - self.safeHeight)
    
    lg.setColor(invertColor(self.color))
    lg.setFont(config.font.tiny)
    -- left
    lg.print(f("%dx%d", self.cursorX, self.cursorY), 12, self.safeHeight)
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
    x = x or self.cursorX
    y = y or self.cursorY
    self.cursorX, self.cursorY = x, y
end

function editor:moveCursor(x, y)
    self.cursorX = self.cursorX + x
    if self.cursorX < 1 then self.cursorX = 1 elseif self.cursorX > self.width then self.cursorX = self.width end

    self.cursorY = self.cursorY + y
    if self.cursorY < 1 then self.cursorY = 1 elseif self.cursorY > self.width then self.cursorY = self.width end

    self.cursorPixel = self.pixels[self.cursorY][self.cursorX]

    if self.selectMode and not self.grabMode then
        if self.cursorX < self.selection.originX then
            self.selection.x = self.cursorX
            self.selection.width = self.selection.originX - self.cursorX
        else
            self.selection.x = self.selection.originX
            self.selection.width = (self.cursorX - self.selection.originX) + 1
        end
        
        if self.cursorY < self.selection.originY then
            self.selection.y = self.cursorY
            self.selection.height = self.selection.originY - self.cursorY
        else
            self.selection.y = self.selection.originY
            self.selection.height = (self.cursorY - self.selection.originY) + 1
        end

        if self.selection.width == 0 then self.selection.width = 1 end
        if self.selection.height == 0 then self.selection.height = 1 end
        self:updateSelection()
    elseif self.grabMode then
        self.selection.x = self.cursorX - (self.selection.width - 1)
        self.selection.y = self.cursorY - (self.selection.height - 1)

        if self.selection.x < 1 then
            self.selection.x = 1
            self.cursorX = self.selection.width
        end

        if self.selection.y < 1 then
            self.selection.y = 1
            self.cursorY = self.selection.height
        end
    end

    if lk.isDown(config.keys.cursor_draw) then
        self:drawPixel()
    elseif lk.isDown(config.keys.cursor_erase) then
        self:erasePixel()
    end
end

function editor:warpCursor(xStep, yStep, color)
    color = color or self.cursorPixel
    local x, y = self.cursorX, self.cursorY
    while true do
        x = x + xStep
        y = y + yStep
        if not self:inBounds(x, y) or not compareColor(color, self.pixels[y][x]) then
            self:moveCursor(-xStep, -yStep)
            break
        else
            self:moveCursor(xStep, yStep)
        end
    end
end

--<<[[ PALETTE ]]>>--

function editor:selectPaletteColor(index)
    if index < 1 then index = 1 elseif index > #self.palette then index = #self.palette end
    self.color = self.palette[index]
    self.selectedColor = index
end

function editor:movePaletteCursor(x, y)
    self:selectPaletteColor(self.selectedColor + x)
    if y > 0 then
        self:selectPaletteColor(self.selectedColor + config.settings.max_palette_columns)
    elseif y < 0 then
        self:selectPaletteColor(self.selectedColor - config.settings.max_palette_columns)
    end
end

function editor:addToPalette(color, index)
    color = color or self.color
    index = index or #self.palette
    index = tonumber(index)
    for i,v in ipairs(self.palette) do
        if compareColor(color, v) then
            return
        end
    end
    if index > #self.palette then
        for i=#self.palette, #self.palette + (index - #self.palette) do
            self.palette[i] = {0, 0, 0, 0}
        end
    end
    insert(self.palette, index, color)
end

function editor:loadPalette(path)
    self.palette = {}
    local data = love.image.newImageData(path)
    for i=0, data:getWidth() - 1 do
        local r, g, b, a = data:getPixel(i, 0)
        self.palette[i + 1] = {r, g, b, a}
    end
    self:selectPaletteColor(1)
    self:print(f("Loaded palette '%s'", path))
end

--<<[[ EDITING ]]>>--

function editor:drawPixel()
    self:writeHistory()
    if self.selectMode and self.grabMode then 
        for y=self.selection.y, self.selection.y + self.selection.height - 1 do
            for x=self.selection.x, self.selection.x + self.selection.width - 1 do
                self.pixels[y][x] = copyColor(self.selection.pixels[y - self.selection.y + 1][x - self.selection.x + 1])
            end
        end
        self.selectMode = false
        self.grabMode = false
    else
        self.pixels[self.cursorY][self.cursorX] = copyColor(self.color)
    end
end

function editor:erasePixel()
    if self.selectMode then return end
    self:writeHistory()

    self.pixels[self.cursorY][self.cursorX] = {0, 0, 0, 0}
end

function editor:pickPixel()
    self.color = self.pixels[self.cursorY][self.cursorX]
end

function editor:getPixel()
    return self.pixels[self.cursorY][self.cursorX]
end

function editor:fill(x, y, target)
    if self.selectMode then return end
    if not target then self:writeHistory() end
    
    x = x or self.cursorX
    y = y or self.cursorY
    target = target or self.pixels[y][x]

    if x < 1 or x > self.width or y < 1 or y > self.height 
    or not compareColor(self.pixels[y][x], target) or compareColor(self.pixels[y][x], self.color) then
        return
    end

    self.pixels[y][x] = copyColor(self.color)

    self:fill(x-1, y, target)
    self:fill(x+1, y, target)
    self:fill(x, y-1, target)
    self:fill(x, y+1, target)
end

function editor:fillLine(xStep, yStep)
    if self.selectMode then return end
    local x, y = self.cursorX, self.cursorY
    while self:inBounds(x, y) do
        self:drawPixel()
        x = x + xStep
        y = y + yStep
        self:moveCursor(xStep, yStep)
    end
end

function editor:warpLine(xStep, yStep, color)
    if self.selectMode then return end
    color = color or self.cursorPixel
    local x, y = self.cursorX, self.cursorY
    while true do
        x = x + xStep
        y = y + yStep
        if not self:inBounds(x, y) or not compareColor(color, self.pixels[y][x]) then
            self:moveCursor(-xStep, -yStep)
            break
        else
            self:moveCursor(xStep, yStep)
            self:drawPixel()
        end
    end
end

function editor:setSelectMode(set)
    set = set or not self.selectMode
    self.selectMode = set
    self.grabMode = false
    if self.selectMode then
        self.selection.originX, self.selection.originY = self.cursorX, self.cursorY
        self.selection.x, self.selection.y = self.cursorX, self.cursorY
        self.selection.width, self.selection.height = 1, 1
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

function editor:setGrabMode(set)
    set = set or not self.grabMode
    
    if self.selectMode then
        self.grabMode = set
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
    if #self.history - self.undoSteps > 0 then
        self.pixels = self.history[#self.history - self.undoSteps]
        self.undoSteps = self.undoSteps + 1
    end
end

function editor:redo()
    if #self.history - self.undoSteps > 0 then
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
    data:encode("png", "save/"..file)
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
    canvas:newImageData():encode("png", "export/"..filename)
    self:print(f("Exported image as '%s' at %dx%d", filename, canvas:getWidth(), canvas:getHeight()))
end 
--<<[[ SETTINGS ]]>>--

function editor:toggleBorder()
    if self.border == 1 then self.border = 0 else self.border = 1 end
end

return editor