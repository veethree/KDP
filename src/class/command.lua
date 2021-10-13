local cmd = {}

function cmd:load()
    self.width = lg.getWidth() - 24
    self.height = (config.font.small:getAscent() - config.font.small:getDescent())

    self.x = 12
    self.y = 12
    self.margin = 5
    self.visible_x = self.x
    self.visible_y = self.y
    self.hidden_x = self.x
    self.hidden_y = -self.height
    
    self.command = ""
    self.promptString = ""
    self.cursor = "|"
    self.promtChar = "> "
    self.visible = true

    self.input = true
    self.inputSleep = 0.1
    self.inputSleepTick = 0

    self.commands = {}
end

function cmd:register(command, func)
    self.commands[command] = func
end

function cmd:prompt(prompt)
    self.command = ""
    self.promptString = prompt
end

function cmd:show()
    self.visible = true
    self.input = false
    self.inputSleepTick = self.inputSleep
    smoof:new(self, {x = self.visible_x, y = self.visible_y})
end

function cmd:hide()
    self.visible = false
    smoof:new(self, {x = self.hidden_x, y = self.hidden_y})
end

function cmd:toggle()
    self.visible = not self.visible
    if self.visible then
        self:show()
    else self:hide() end
end

function cmd:draw()
    -- input sleep
    if not self.input then
        local dt = love.timer.getDelta()
        self.inputSleepTick = self.inputSleepTick - dt
        if self.inputSleepTick < 0 then
            self.input = true
        end
    end

    self.width = lg.getWidth() - 24
    self.height = (config.font.small:getAscent() - config.font.small:getDescent())
    
    lg.setColor(config.color.background_alt)
    lg.rectangle("fill", self.x, self.y, self.width, self.height)
    lg.setColor(config.color.text_default)
    lg.setFont(config.font.small)
    local sep = ""
    if #self.promptString > 0 then sep = ": " end
    local totalString = self.promtChar..self.promptString..sep..self.command
    lg.print(totalString, self.x + self.margin, self.y)
    local cursorX = self.x + config.font.small:getWidth(totalString)
    lg.print(self.cursor, cursorX + self.margin, self.y)
end

function cmd:textinput(t)
    if self.visible and self.input then self.command = self.command..t end
end

function cmd:backspace()
    if self.visible and self.input then self.command = sub(self.command, 1, -2) end
end

function cmd:run()
    local spl = self.command:split(" ")
    --for i,v in ipairs(spl) do print(v) end
    local command = spl[1]
    if self.commands[command] and self.visible then
        table.remove(spl, 1)
        self.commands[command](unpack(spl))
        self.command = ""
        self:hide()
    end
end

return cmd