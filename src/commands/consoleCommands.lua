-- Creating all console commands

console:load()
console:hide()

-- Loaidng custom commands
for _, file in pairs(fs.getDirectoryItems("commands")) do
    if get_file_type(file) == "lua" then
        console:register(get_file_name(file), fs.load("commands/"..file)() )
    end
end

console:register("q", function() love.event.push("quit") end)

console:register("os", function() love.system.openURL("file://"..love.filesystem.getSaveDirectory()) end)

console:register("color", function(r, g, b, a)
    if r and not g and not b and not a then
        g = r
        b = r
    end
    a = a or 255
    editor.color = {r / 255, g / 255, b / 255, a / 255}
end)

console:register("selectPaletteColor", function(index)
    editor:selectPaletteColor(tonumber(index))
end)

console:register("ap", function(index)
    editor:addToPalette(nil, index)
end)

console:register("shade", function(factor)
    factor = factor or 1.1
    local new = copyColor(editor.color)
    for i=1, 3 do
        new[i] = editor.color[i] / factor
    end
    editor.color = new
end)

console:register("light", function(factor)
    factor = factor or 0.1
    local new = copyColor(editor.color)
    for i=1, 3 do
        new[i] = editor.color[i] + factor
    end
    editor.color = new
end)

console:register("new", function(w, h)
    if w and not h then
        h = w
    end
    editor:new(w or 16, h or 16)
end)

console:register("resize", function(w, h)
    if w and not h then h = w end
    if not tonumber(w) and not tonumber(h) then 
        editor:print("Invalid arguments")
        return 
    end
    editor:resizeImage(w, h)
    editor:print(f("Resized to %dx%d", w, h))
end)

console:register("save", function(...)
    local file = filenameFromTable({...}, "png")
    if #file < 1 then 
        editor:print("No file name provided")  
        return
    end
    editor:save(file)
end)

console:register("export", function(...)
    local args = {...}
    local scale = args[#args]
    if tonumber(scale) then remove(args, #args) else scale = 1 end
    local filename = filenameFromTable(args, "png")
    if #filename < 1 then
        editor:print("No file name provided")
    else
        editor:export(filename, scale)    
    end
end)

console:register("load", function(...)
    local path = filenameFromTable({...}, "png")
    if #path > 0 then
        path = "save/"..path
        editor:loadImageFromPath(path)
    end
end)

console:register("loadPalette", function(...)
    local file = filenameFromTable({...}, "png")
    if fs.getInfo("palettes/"..file) then
        editor:loadPalette("palettes/"..file)
    end
end)

-- "shaders"
console:register("invert", function()
    editor:map(function(pixel)
        return {1 - pixel[1], 1 - pixel[2], 1 - pixel[3], pixel[4]}
    end)
end)

console:register("grayscale", function()
    editor:map(function(pixel)
        local avg = pixel[1] + pixel[2] + pixel[3] / 3
        return {avg, avg, avg, pixel[4]}
    end)
end)

console:register("noise", function(strength)
    editor:map(function(pixel)
        strength = strength or 0.01
        local off = random() * strength
        return {pixel[1] + off, pixel[2] + off, pixel[3] + off, pixel[4]} 
    end)
end)