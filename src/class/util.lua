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

function filenameFromTable(tab, ext)
    ext = ext or "png"
    local filename = ""
    if #tab < 1 then return filename end
    for i,v in ipairs(tab) do
        filename = filename..v
        if i < #tab then filename = filename.." " end
    end
    filename = filename.."."..ext
    return filename
end

function saveImage(image, path)
    if fs.getInfo(path) then
       return false
    else
        image:encode("png", path)
        return true
    end
end

function getCharBytes(string, char)
	char = char or 1
	local b = string.byte(string, char)
	local bytes = 1
	if b > 0 and b <= 127 then
      bytes = 1
   elseif b >= 194 and b <= 223 then
      bytes = 2
   elseif b >= 224 and b <= 239 then
      bytes = 3
   elseif b >= 240 and b <= 244 then
      bytes = 4
   end
	return bytes
end

function len(str)
	local pos = 1
	local len = 0
	while pos <= #str do
		len = len + 1
		pos = pos + getCharBytes(str, pos)
	end
	return len
end

function sub(str, s, e)
	s = s or 1
	e = e or len(str)

	if s < 1 then s = 1 end
	if e < 1 then e = len(str) + e + 1 end
	if e > len(str) then e = len(str) end

	if s > e then return "" end

	local sByte = 0
	local eByte = 1

	local pos = 1
	local i = 0
	while pos <= #str do
		i = i + 1
		if i == s then
			sByte = pos
		end
		pos = pos + getCharBytes(str, pos)
		if i == e then
			eByte = pos - 1
			break
		end
	end

	return string.sub(str, sByte, eByte)
end