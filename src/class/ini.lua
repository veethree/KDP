local ini = {}

-- Appends a section header to "data"
local function header(data, section)
    return data.."["..section.."]\n"
end

-- Appends a key value pair to "data"
local function kv(data, key, value)
    return data..tostring(key).."="..tostring(value).."\n"
end

-- Converts "tab" to  a ini like string and saves it to "file"
function ini.save(tab, file)
    local data = ""

    for section, values in pairs(tab) do
        data = header(data, section)-- Section header
        for key, value in pairs(values) do
            if type(value) == "string" then
                data = kv(data, key, '"'..value..'"')
            elseif type(value) == "table" then
                local val = "{"
                for i,v in ipairs(value) do
                    val = val..v
                    if i < #value then
                        val = val..", "
                    end
                end
                val = val.."}"
                data = kv(data, key, val)
            else
                data = kv(data, key, value)
            end
        end
    end

    fs.write(file, data)
end

function ini.load(file)
    assert(fs.getInfo(file), f("'%s' does not exists.", file))
    local data = {}
    local currentHeader = ""
    for line in fs.lines(file) do
        -- Header
        local header = line:match("(%[%w+%])")
        if header then
            currentHeader = header:sub(2, -2)
            data[currentHeader] = {}
        end
        -- Key value pair
        local key, val = line:match("(.+)=(.+)")
        if key and val then
            -- if val:match('".+"') then -- String
            --     data[currentHeader][key] = val:sub(2, -2)
            -- elseif tonumber(val) then
            --     data[currentHeader][key] = tonumber(val)
            -- elseif val:match("{.+}") or val == "true" or val == "false" then
            --     val = "return "..val
            --     data[currentHeader][key] = loadstring(val)()
            --     print(data[currentHeader][key])
            -- end

            val = "return "..val
            data[currentHeader][key] = loadstring(val)()
        end
    end
    return data
end

return ini