local editor = {}

local min, max = math.min, math.max

function editor:load()
    self.safeWidth = lg.getWidth() * 0.8
    self.safeHeight = lg.getHeight() * 0.9
    self.border = 1
    self.color = {1, 1, 1, 1}
    self.palette = {}
    self.selected = 1
    self.history = {}
    self.undoSteps = 0
    self.pixels = false
    self.cursorX = 0
    self.cursorY = 0
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
    return true
end

function editor:draw()
    if self.pixels then
        local drawWidth = self.width * self.cellSize
        local drawHeight = self.height * self.cellSize
        local xOffset = (self.safeWidth / 2) - (drawWidth / 2)
        local yOffset = (self.safeHeight / 2) - (drawHeight / 2)
        -- Border
        lg.setColor(self.color)
        lg.setLineWidth(3)
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
    end

    -- Palette
    for i,v in ipairs(self.palette) do
        local y = (lg.getHeight() / #self.palette) * (i - 1)
        local xOffset = 12
        if self.selected == i then
            xOffset = 0
        end
        lg.setColor(v)
        lg.rectangle("fill", xOffset + self.safeWidth, y, lg.getWidth() - self.safeWidth, lg.getHeight() / #self.palette)
        lg.setColor(invertColor(v))
        lg.setFont(config.font.tiny)
        lg.print(i, xOffset + self.safeWidth + 12, y)
    end

    -- Info
    lg.setColor(config.color.text_alt)
    lg.setFont(config.font.tiny)
    lg.print(f("%d x %d %d", self.cursorX, self.cursorY, #self.history), 12, self.safeHeight)
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
    self.selected = index
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
end

--<<[[ EDITING ]]>>--

function editor:drawPixel()
    self:writeHistory()
    self.pixels[self.cursorY][self.cursorX] = copyColor(self.color)
end

function editor:erasePixel()
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
    local x, y = self.cursorX, self.cursorY
    while self:inBounds(x, y) do
        self:drawPixel()
        x = x + xStep
        y = y + yStep
        self.cursorX, self.cursorY = x, y
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
            copy[y][x] = {}
            copy[y][x][1] = self.pixels[y][x][1]
            copy[y][x][2] = self.pixels[y][x][2]
            copy[y][x][3] = self.pixels[y][x][3]
            copy[y][x][4] = self.pixels[y][x][4]
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
    data:encode("png", file)
end

--<<[[ SETTINGS ]]>>--

function editor:toggleBorder()
    if self.border == 1 then self.border = 0 else self.border = 1 end
end

return editor