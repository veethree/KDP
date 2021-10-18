-- Creating all the text triggers
--
--
--
--
-- Configuring tt
tt:setInputFilter(function() 
    if not console.visible and not prompt.visible then
        return true
    end
end)
tt:setBufferTimeout(config.settings.command_timeout)
tt:setBufferLength(8)

-- Editor modes

tt:new(config.keys.cut_mode, function() editor:setMode("cutMode") end)

-- Mirroring

tt:new(config.keys.horizontal_mirror, function() editor:setHorizontalMirror() end)
tt:new(config.keys.vertical_mirror, function() editor:setVerticalMirror() end)
tt:new(config.keys.clear_mirror, function()
    editor.verticalMirror = false
    editor.horizontalMirror = false
end)

-- Line fill
tt:new(config.keys.cursor_line_left, function() editor:fillLine(-1, 0) end)
tt:new(config.keys.cursor_line_right, function() editor:fillLine(1, 0) end)
tt:new(config.keys.cursor_line_up, function() editor:fillLine(0, -1) end)
tt:new(config.keys.cursor_line_down, function() editor:fillLine(0, 1) end)

--Cursor warp
tt:new(config.keys.cursor_warp_left, function() editor:setCursor(1) end)
tt:new(config.keys.cursor_warp_right, function() editor:setCursor(editor.width) end)
tt:new(config.keys.cursor_warp_up, function() editor:setCursor(nil, 1) end)
tt:new(config.keys.cursor_warp_down, function() editor:setCursor(nil, editor.height) end)

--Cursor color warp
tt:new(config.keys.cursor_warp_color_left, function() editor:warpCursor(-1, 0) end)
tt:new(config.keys.cursor_warp_color_right, function() editor:warpCursor(1, 0) end)
tt:new(config.keys.cursor_warp_color_up, function() editor:warpCursor(0, -1) end)
tt:new(config.keys.cursor_warp_color_down, function() editor:warpCursor(0, 1) end)

-- Cursor warp fill
tt:new(config.keys.cursor_line_color_left, function() editor:warpCursor(-1, 0, true) end)
tt:new(config.keys.cursor_line_color_right, function() editor:warpCursor(1, 0, true) end)
tt:new(config.keys.cursor_line_color_up, function() editor:warpCursor(0, -1, true) end)
tt:new(config.keys.cursor_line_color_down, function() editor:warpCursor(0, 1, true) end)

-- Settings toggles
tt:new(config.keys.toggle_fullscreen, function()
    config.settings.window_fullscreen = not config.settings.window_fullscreen
    updateWindow()
end)