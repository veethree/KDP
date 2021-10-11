function color(r, g, b, a)
    a = a or 255
    return {r / 255, g / 255, b / 255, a / 255}
end

function copyColor(color)
    local c = {}
    for i,v in ipairs(color) do
        c[i] = v
    end
    return c
end

function invertColor(col)
    local inverted = {}
    for i,v in ipairs(col) do
        inverted[i] = 1 - v
    end
    inverted[4] = col[4] or 1
    return inverted
end

function compareColor(a, b)
    local same = true
    for i,v in ipairs(a) do
        if v ~= b[i] then
            same = false
            break
        end
    end
    return same
end

function requireFolder(folder)
    if fs.getInfo(folder) then
        for i,v in ipairs(fs.getDirectoryItems(folder)) do
            if get_file_type(v) == "lua" then
                _G[get_file_name(v)] = require(folder.."."..get_file_name(v))
            end
        end
    else
        error(string.format("Folder '%s' does not exists", folder))
    end
end

function get_file_type(file_name)
    return string.match(file_name, "%..+"):sub(2)
end

function get_file_name(file_name)
    return string.match(file_name, ".+%."):sub(1, -2)
end