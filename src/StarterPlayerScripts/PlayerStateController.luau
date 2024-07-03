local Workspace = game:GetService("Workspace")
local CurrentCamera = Workspace.CurrentCamera

local PlayerStateController = {
    IsAlive = false,
    Character = nil,
    Humanoid = nil,
    HumanoidRootPart = nil,
    HumanoidState = nil,
    LastPosition = Vector2.new(),
    HoveredItem = nil,
    Conns = {}
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

    table.insert(self.Conns, humanoid.Died:Connect(function()
        self.Character = nil
        self.Humanoid = nil
        self.HumanoidRootPart = nil
        self.IsAlive = false
        self.LastPosition = nil
        for _, conn in self.Conns do conn:Disconnect() end
    end))

    table.insert(self.Conns, humanoid.StateChanged:Connect(function(_, new)
        self.HumanoidState = new
    end))
end

function PlayerStateController:CharacterIsNearWall()
    local raycastParams = RaycastParams.new()
    raycastParams.IgnoreWater = true
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = { Workspace.PlayerBuildings }

    local ray = Workspace:Raycast(CurrentCamera.CFrame.Position, CurrentCamera.CFrame.LookVector * 6, raycastParams)
    return ray
end

return PlayerStateController