local mode = {}

function mode:init(editor)
    self.editor = editor
    self.pixels = false
    self.x = 0
    self.y = 0
end

function mode:enter(selection)
    self.selection = selection
    self.editor:setCursor(self.selection.x + 1, self.selection.y + 1)
    self.x, self.y = self.editor.cursor.x - 1, self.editor.cursor.y - 1
end

function mode:leave()

end

function mode:cursorMoved(x, y)
    self.x, self.y = x - 1, y - 1
end

function mode:draw(xOffset, yOffset)
    lg.push()
    self.editor:scale()
    local cellSize = self.editor.cellSize
    lg.setColor(config.color.selection)
    lg.rectangle("line", xOffset + self.x * cellSize, yOffset + self.y * cellSize, self.selection.width * cellSize, self.selection.height * cellSize)
    for y=1, #self.selection.pixels do
        for x=1, #self.selection.pixels[y] do
            lg.setColor(self.selection.pixels[y][x])
            setAlpha(0.5)
            lg.rectangle("fill", xOffset + (self.x * cellSize) + (x - 1) * cellSize, yOffset + (self.y * cellSize) + (y - 1) * cellSize, cellSize, cellSize )
        end
    end
    lg.pop()
    --lg.setColor(config.color.selection)
    --lg.rectangle("fill", xOffset + self.x * cellSize, yOffset + self.y * cellSize, cellSize, cellSize )
    --lg.rectangle("fill", xOffset + self.selection.x * cellSize, yOffset + self.selection.y * cellSize, cellSize, cellSize )
end

function mode:keypressed(key)
    if key == config.keys.select_mode then
        self.editor:setMode("drawMode")
    elseif key == config.keys.cursor_draw then
        self.editor:placePixels(self.selection.pixels, self.x, self.y)
    end
end

return mode