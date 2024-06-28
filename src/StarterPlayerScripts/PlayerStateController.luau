local PlayerStateController = {
    IsAlive = false,
    Character = nil,
    Humanoid = nil,
    HumanoidRootPart = nil,
    HumanoidState = nil,
    LastPosition = Vector2.new()
}

function PlayerStateController:AddCharacter(character: Instance)
    local humanoid: Humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    if not humanoidRootPart or not humanoid then
        return
    end

    self.Character = character
    self.Humanoid = humanoid
    self.HumanoidRootPart = humanoidRootPart
    self.IsAlive = true
    self.LastPosition = Vector2.new(humanoidRootPart.Position.X, humanoidRootPart.Position.Z)

    humanoid.Died:Connect(function()
        self.Character = nil
        self.Humanoid = nil
        self.HumanoidRootPart = nil
        self.IsAlive = false
        self.LastPosition = nil
    end)

    humanoid.StateChanged:Connect(function(_, new)
        self.HumanoidState = new
    end)
end

return PlayerStateController