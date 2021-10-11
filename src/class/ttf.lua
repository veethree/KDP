-- ttf: Table To File
-- A simple serialization library

local ttf = {}

local function table_length(tab)
    local count = 0
    for k,v in pairs(tab) do
        count = count + 1
    end
    return count
end

local function table_to_string(tab, recursion)
    recursion = recursion or false
    local output = "return {"
    if recursion then output = "" end
    local count = 1
    local length = table_length(tab)
    for key,val in pairs(tab) do
        if tonumber(key) then key = "" else key = key.."=" end
        if type(val) == "string" then val = '"'..val..'"' end
        if type(val) == "table" then val = "{"..table_to_string(val, true) end
        output = output..key..tostring(val)
        if count < length then output = output.."," end
        count = count + 1
    end
    output = output.."}"
    return output
end

function ttf.save(table, file_name)
    file_name = file_name or false
    local output = table_to_string(table)

    --print(output)

    fs.write(file_name, output)
end

function ttf.load(file_name)
    if fs.getInfo(file_name) then
        return fs.load(file_name)()
    end
end

return ttf