local drawMode = {}

function drawMode:init(editor)
    self.editor = editor
end

function drawMode:enter()

end

function drawMode:leave()

end

function drawMode:draw(xOffset, yOffset)
    self.editor:drawCursor()
    self.editor:drawMirror()
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
