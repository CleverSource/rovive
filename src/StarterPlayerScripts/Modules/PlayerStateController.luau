-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Trove
local Trove = require(ReplicatedStorage.Packages.Trove)

-- Game Properties
local GameProperties = require(ReplicatedStorage.GameProperties)

-- Variables
local CurrentCamera = Workspace.CurrentCamera

local PlayerStateController = {
    IsAlive = false,
    Character = nil,
    Humanoid = nil,
    HumanoidRootPart = nil,
    HumanoidState = nil,
    LastPosition = Vector2.new(),
    HoveredItem = nil,
    Trove = nil
}

function PlayerStateController:AddCharacter(character: Instance)
    local humanoid: Humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    if not humanoidRootPart or not humanoid then
        return
    end

    self.Character = character
    self.Humanoid = humanoid
    self.Humanoid.WalkSpeed = GameProperties.DefaultWalkSpeed
    self.HumanoidRootPart = humanoidRootPart
    self.IsAlive = true
    self.CurrentPosition = Vector2.new(humanoidRootPart.Position.X, humanoidRootPart.Position.Z)
    self.LastPosition = Vector2.new(humanoidRootPart.Position.X, humanoidRootPart.Position.Z)
    self.Trove = Trove.new()
    
    self.Trove:Connect(humanoid.Died, function()
        self.Character = nil
        self.Humanoid = nil
        self.HumanoidRootPart = nil
        self.IsAlive = false
        self.LastPosition = nil
        self.Trove:Clean()
    end)

    self.Trove:Connect(humanoid.StateChanged, function(_, new)
        self.HumanoidState = new
    end)
end

function PlayerStateController:CharacterIsNearWall()
    local raycastParams = RaycastParams.new()
    raycastParams.IgnoreWater = true
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    raycastParams.FilterDescendantsInstances = { Workspace.PlayerBuildings }

    local ray = Workspace:Raycast(CurrentCamera.CFrame.Position, CurrentCamera.CFrame.LookVector * 6, raycastParams)
    return ray
end

function PlayerStateController:Update()
    if not self.IsAlive then return end
    self.LastPosition = self.CurrentPosition
    self.CurrentPosition = Vector2.new(self.HumanoidRootPart.Position.X, self.HumanoidRootPart.Position.Z)
end

return PlayerStateController