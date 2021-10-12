-- tt.lua: Text triggers for lua
-- Version: v1.0
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

local tt = {
    buffer = "",
    bindings = {},
    tick = 0,
    bufferLength = 32,
    bufferTimeout = 1,
    waitForTimeout = false,
    inputFilter = function() return true end
}

--==[[  BUFFER MANAGEMENT ]]==--

-- Sets the buffer length
function tt:setBufferLength(len)
    assert(tonumber(len), "Buffer length must be a number!")
    self.bufferLength = len
end

--  Set the buffer timeout (In seconds)
function tt:setBufferTimeout(time)
    assert(tonumber(time), "Buffer timeout must be a number!")
    self.bufferTimeout = time
end

--  Set the buffer timeout (In seconds)
function tt:setWaitForTimeout(wait)
    assert(type(wait) == "boolean", "'waitForTimeout' must be a boolean!")
    self.waitForTimeout = wait
end

function tt:setInputFilter(filt)
    assert(type(filt) == "function", "Input filter must be a function!")
    self.inputFilter = filt
end

-- Clear the buffer
function tt:clearBuffer()
    self.buffer = ""
end

-- returns the buffer
function tt:getBuffer()
    return self.buffer
end

-- Updating the buffer. 'char' should be the string thats added to the buffer.
function tt:updateBuffer(char)
    self.tick = 0
    -- Updating buffer
    self.buffer = self.buffer..char
    if #self.buffer > self.bufferLength then
        self.buffer = self.buffer:sub(#self.buffer - self.bufferLength)
    end

    -- Checking for triggers
    if not self.waitForTimeout then
        self:checkTriggers()
    end
end

-- Checks for triggers
function tt:checkTriggers()
    if self.inputFilter() then
        for trigger, binding in pairs(self.bindings) do
            if self.buffer:match(trigger.."$") then
                binding.func(unpack(binding.arguments))
                self:clearBuffer()
            end
        end
    end
end

--==[[ TRIGGER MANAGEMENT ]]==--

-- Create new trigger
function tt:new(trigger, func, ...)
    self.bindings[trigger] = {
        func = func,
        arguments = {...}
    }
end

-- Remove trigger
function tt:remove(trigger)
    if self.bindings[trigger] then
        self.bindings[trigger] = nil
    end
end

-- Update: Should be called per frame, dt is Delta time, the time since the last frame in seconds.
-- Techincally optional, But if not called, The buffer timeout feature won't work.
function tt:update(dt)
    if #self.buffer > 0 then
        self.tick = self.tick + dt
        if self.tick > self.bufferTimeout then
            if self.waitForTimeout then
                self:checkTriggers()
            end
            self:clearBuffer()
        end
    end
end

return tt