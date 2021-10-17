local drawMode = {}

function drawMode:init(editor)
    self.editor = editor
end

function drawMode:enter()

end

function drawMode:leave()

end

function drawMode:draw(xOffset, yOffset)
    lg.setColor(self.editor.color)
    lg.setLineWidth(1)
    lg.rectangle("fill", xOffset + (self.editor.cursor.x - 1) * self.editor.cellSize, yOffset + (self.editor.cursor.y - 1) * self.editor.cellSize, self.editor.cellSize - self.editor.border, self.editor.cellSize - self.editor.border)

    lg.setColor(invertColor(self.editor.color))
    lg.rectangle("line", xOffset + (self.editor.cursor.x - 1) * self.editor.cellSize, yOffset + (self.editor.cursor.y - 1) * self.editor.cellSize, self.editor.cellSize - self.editor.border, self.editor.cellSize - self.editor.border)

    -- Horizontal Mirror
    if self.editor.horizontalMirror then
        local mirrorX = self.editor.horizontalMirror - self.editor.cursor.x + self.editor.horizontalMirror
        lg.setColor(config.color.mirror)
        lg.rectangle("fill", xOffset + (mirrorX - 1) * self.editor.cellSize, yOffset + (self.editor.cursor.y - 1) * self.editor.cellSize, self.editor.cellSize - self.editor.border, self.editor.cellSize - self.editor.border)
    end
    -- Vertical Mirror
    if self.editor.verticalMirror then
        local mirrorY = self.editor.verticalMirror - self.editor.cursor.y + self.editor.verticalMirror
        lg.setColor(config.color.mirror)
        lg.rectangle("fill", xOffset + (self.editor.cursor.x - 1) * self.editor.cellSize, yOffset + (mirrorY - 1) * self.editor.cellSize, self.editor.cellSize - self.editor.border, self.editor.cellSize - self.editor.border)
    end
end

function drawMode:cursorMoved(x, y)
    if lk.isDown(config.keys.cursor_draw) then
        self.editor:drawPixel()
    elseif lk.isDown(config.keys.cursor_erase) then
        self.editor:erasePixel()
    end
end

function drawMode:keypressed(key)
    -- Palette navigation
    if key == config.keys.cursor_left then
        local xStep, yStep = -1, 0
        if lk.isDown(config.keys.move_palette_cursor) then
            editor:movePaletteCursor(xStep, yStep)
        end
    elseif key == config.keys.cursor_right then
        local xStep, yStep = 1, 0
        if lk.isDown(config.keys.move_palette_cursor) then
            editor:movePaletteCursor(xStep, yStep)
        end
    elseif key == config.keys.cursor_up then
        local xStep, yStep = 0, -1
        if lk.isDown(config.keys.move_palette_cursor) then
            editor:movePaletteCursor(xStep, yStep)
        end
    elseif key == config.keys.cursor_down then
        local xStep, yStep = 0, 1
        if lk.isDown(config.keys.move_palette_cursor) then
            editor:movePaletteCursor(xStep, yStep)
        end
    end
    -- Other shit
    if key == config.keys.cursor_draw then
        self.editor:drawPixel()
    elseif key == config.keys.cursor_erase then
        self.editor:erasePixel()
    elseif key == config.keys.cursor_fill then
        self.editor:fill()
    elseif key == config.keys.cursor_pick then
        self.editor:pickPixel()
    elseif key == config.keys.undo then
        self.editor:undo()
    elseif key == config.keys.redo then
        self.editor:redo()
    elseif key == config.keys.select_mode then
        self.editor:setMode("selectMode")
    end
end

return drawMode
