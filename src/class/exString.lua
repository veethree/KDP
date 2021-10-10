-- exString: Extra string functions for lua
-- Version 1.0
--
-- exString aims to expand the standard lua string library
--
-- MIT License
-- 
-- Copyright (c) 2021 Pawel Þorkelsson
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local exString = {}

local function escape_magic(str)
    local magic = {"$","%", "^", "*", "(", ")", ".", "[", "]", "+", "-", "?"}
    for i,v in ipairs(magic) do
        str = str:gsub("%"..v, "%%%1")
    end
    return str
end

-- Appends exString methods to the standard string library
-- This is optional, But allows you to call the methods directly on strings
function exString.import()
    for k,v in pairs(exString) do
        string[k] = v
    end
end

-- Checks if a string ends with 'ending'
function exString.endsWith(str, ending)
    return str:find(ending.."$") and true or false
end

-- Checks if a string starts with 'start'
function exString.startsWith(str, start)
    return str:find("^"..start) and true or false
end

-- Appends its arguments to 'str' and returns it.
-- Optionally puts a delimiter between each argument
function exString.append(str, delimiter, ...)
    delimiter = delimiter or ""
    str = str..delimiter
    for i,v in ipairs({...}) do
        str = str..tostring(v)..delimiter
    end
    return str:sub(1, #str - #delimiter)
end

-- Splits a string by a specified delimiter, and returns the result as a table.
-- It doesn't seem to like $ as a delimiter.
function exString.split(str, delimiter)
    delimiter = delimiter or ","
    local segments = {}

   if not str:endsWith(delimiter) then str= str..delimiter end

    --Splitting
    local pat = "([^"..escape_magic(delimiter)..".+]+)"..escape_magic(delimiter)
    for seg in str:gmatch(pat) do
        segments[#segments + 1] = seg
    end
    return segments
end

-- Strips all leading & trailing white space & punctionation from 'str' and returns it
function exString.strip(str)
    local stripped = str:gsub("^[%p%s]+", ""):gsub("[%p%s]+$", "")
    return stripped
end

-- Replaces 'target' in 'str' with 'repl'
function exString.replace(str, target, repl)
    local res = str:gsub(target, repl)
    return res
end

-- prints the string to console
function exString.print(str)
    print(str)
end

return exString