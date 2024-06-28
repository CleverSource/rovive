local Spring = {}

function Spring.new(position, velocity, target)
    local self = setmetatable({}, { __index = Spring })
    self.Position = position
    self.Velocity = velocity
    self.Target = target
    self.k = 0.05
    self.d = 0.2

    return self
end

function Spring:Update()
    local x = self.Target - self.Position
    local f = x * self.k
    self.Velocity = (self.Velocity * (1 - self.d)) + f
    self.Position = self.Position + self.Velocity
end

return Spring