local selectMode = {}

function selectMode:init(editor)
    self.editor = editor

    self.originX = 0
    self.originY = 0
    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0

    self.pixels = {}
end

function selectMode:enter()
    self.originX, self.originY = self.editor.cursor.x - 1, self.editor.cursor.y - 1
    self.x, self.y = self.originX, self.originY
    self.width, self.height = 1, 1
    self:updateSelection()
end

function selectMode:leave()
    return self
end

function selectMode:update(dt)

end

function selectMode:cursorMoved(x, y)
    self.x, self.y = x - 1, y - 1
    
    if self.x > self.originX then
        self.x = self.originX 
        self.width = x - self.originX 
    else
        self.width = self.originX - self.x + 1
    end

    if self.y > self.originY then
        self.y = self.originY 
        self.height = y - self.originY
    else
        self.height = self.originY - self.y + 1
    end

    self:updateSelection()
end

function selectMode:updateSelection()
    self.pixels = {}
    for y=1, self.height do
        self.pixels[y] = {}
        for x=1, self.width do
           self.pixels[y][x] = copyColor(self.editor:getPixel(x + self.x, y + self.y))
        end
    end
end

function selectMode:draw(xOffset, yOffset)
    local cellSize = self.editor.cellSize
    lg.setColor(config.color.selection)
    lg.rectangle("line", xOffset + self.x * cellSize, yOffset + self.y * cellSize, self.width * cellSize, self.height * cellSize)

    --lg.rectangle("fill", xOffset + self.x * cellSize, yOffset + self.y * cellSize, cellSize, cellSize )
    --lg.setColor(0, 1, 0)
    --lg.rectangle("fill", self.originX * cellSize, self.originY * cellSize, cellSize , cellSize)

    --lg.print("origin: "..self.originX.."x"..self.originY.."\n"..
    --         "normal: "..self.x.."x"..self.y.."\n"..
    --         "width : "..self.width.."x".. self.height, 100, 100)

    local scale = 4
    for y=1, self.height do
        for x=1, self.width do
            lg.setColor(self.pixels[y][x])
            lg.rectangle("fill", x * scale, 100 + y * scale, scale, scale)
        end
    end
end

function selectMode:keypressed(key)
    if key == config.keys.select_mode then
        self.editor:setMode("drawMode")
    elseif key == config.keys.copy_mode then
        self.editor:setMode("copyMode")
    elseif key == config.keys.cut_mode then
        self.editor:setMode("cutMode")
    end
end

return selectMode