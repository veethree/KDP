local prompt = {}

function prompt:init()
    self.text = ""
    self.options = {}
    self.response = function() return end
    self.visible = false
    self.textPosition = {x = 0, y = 0}
    self.optionsPosition = {x = 0, y = 0}
    self.shade = {0, 0, 0, 0}
end

function prompt:new(text, options, func)
    self.text = text
    self.options = options
    self.response = func
    self.visible = true

    self.textPosition = {x = 0, y = -50}
    self.optionsPosition = {x = 0, y = lg.getHeight() * 1.5}
    self.shade = {0, 0, 0, 0}
    self:show() 
end

function prompt:show()
    smoof:new(self.shade, config.color.prompt_shade)
    smoof:new(self.textPosition, {y = lg.getHeight() * 0.4})
    smoof:new(self.optionsPosition, {y = lg.getHeight() * 0.6})
    self.visible = true
end


--function smoof:new(object, target, smoof_value, completion_threshold, bind, callback)
function prompt:hide()
    smoof:new(self.shade, {0, 0, 0, 0}, nil, nil, nil, {onArrive = function()  prompt:init() end})
    smoof:new(self.textPosition, {y = -lg.getHeight() * 0.5})
    smoof:new(self.optionsPosition, {y = lg.getHeight() * 1.5})
    self.visible = false
end

function prompt:update(dt)

end

function prompt:draw()
    lg.setColor(self.shade)
    lg.rectangle("fill", 0, 0, lg.getWidth(), lg.getHeight())
    lg.setFont(config.font.large)
    lg.setColor(config.color.text_default)
    lg.printf(self.text, self.textPosition.x, self.textPosition.y, lg.getWidth(), "center")

    lg.setFont(config.font.small)
    local s = ""
    for i,v in ipairs(self.options) do
        s = s..i..": "..v.." "
    end
    lg.printf(s, self.optionsPosition.x, self.optionsPosition.y, lg.getWidth(), "center")
end

function prompt:keypressed(key)
    if tonumber(key) then
        local res = self.options[tonumber(key)] or false
        self.response(res)
        self:hide()
    end    
end

return prompt