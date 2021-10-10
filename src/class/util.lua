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