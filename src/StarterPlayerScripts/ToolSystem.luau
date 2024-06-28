-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Variables
local Player = Players.LocalPlayer
local ViewModelAsset = ReplicatedStorage.Assets.ViewModel
local Camera = Workspace.CurrentCamera

-- Modules
local Spring = require(ReplicatedStorage.Modules.Spring)

-- Assets
local Assets = ReplicatedStorage.Assets
local Tools = Assets.Tools

-- Data Objects
local ItemData = require(ReplicatedStorage.DataObjects.ItemData)

local ToolSystem = {
    Origin = nil,
    Offset = nil,
    ViewModel = nil,
    CurrentTool = nil,
    SpringX = Spring.new(0, 0, 4),
    SpringY = Spring.new(0, 0, 4)
}

function ToolSystem:ClearViewModel()
    for _, child in Camera:GetChildren() do
        if child.Name == "ViewModel" then
            child:Destroy()
        end
    end
    self.Origin = nil
end

function ToolSystem:StopAnimation(animationName: string, fadeTime: number?)
    for _, track: AnimationTrack in self.ViewModel.Humanoid:GetPlayingAnimationTracks() do
        if track.Name == animationName then
            track:Stop(fadeTime or 0.1)
        end
    end
end

function ToolSystem:PlayAnimation(animationName: string, yield: boolean?)
    local animation = self.CurrentTool.Animations:FindFirstChild(animationName)
    if not animation then
        return
    end

    local track: AnimationTrack = self.ViewModel.Humanoid:LoadAnimation(animation)
    track:Play()
    track.Name = animationName
    track:AdjustSpeed(1)

    if yield then
        local waiting = true 
        track.Stopped:Connect(function()
            waiting = false
        end)
        while waiting and track do
            task.wait()
        end
    end
end

function ToolSystem:SetupToolForEquip(item: ItemData.ItemData)
    local viewModel = ViewModelAsset:Clone()
    viewModel.Parent = Camera
    self.ViewModel = viewModel

    viewModel.LeftArm.TextureID = "rbxassetid://3455123465" -- TODO: upload own version of this texture
    viewModel.RightArm.TextureID = "rbxassetid://3455123465"
    viewModel.LeftArm.BrickColor = Player.Character.Head.BrickColor
    viewModel.RightArm.BrickColor = Player.Character.Head.BrickColor

    local tool = self:GetToolFromItem(item):Clone()
    tool.Parent = viewModel
    tool.RightArmWeld.Part0 = viewModel.RightArm
    tool.RightArmWeld.Part1 = tool.PrimaryPart
    self.CurrentTool = tool

    self.Origin = viewModel.HumanoidRootPart
end

function ToolSystem:ChangeTool(item: ItemData.ItemData)
    self:ClearViewModel()
    self:SetupToolForEquip(item)
    self:PlayAnimation("Idle")
    self:PlayAnimation("Draw")
end

function ToolSystem:GetOffset(elapse: number)
    local offset = self.Offset

    if not offset then
        return CFrame.new()
    else
        local lerp = 0.2
        local root = 0.3
        local fps = 1 / 60
        lerp = root * (elapse / fps)
        if lerp > 1 then
            lerp = 1 
        end

        local cframe = self.Offset:lerp(offset, lerp)
        self.Offset = cframe
        return cframe
    end
end

function ToolSystem:SetOffset(goal)
    self.Offset = goal
end

function ToolSystem:UpdateOrigin(elapse: number)
    if not self.Origin then return end
    self.Origin.CFrame = Camera.CFrame
                        * self:GetOffset(elapse)
                        * CFrame.Angles(0, math.rad(180), 0)
end

function ToolSystem:GetToolFromItem(item: ItemData.ItemData)
    local tool = Tools:FindFirstChild(item.Name)
    if not tool then
        return
    end

    return tool
end

function ToolSystem:GetToolOffsets(item: ItemData.ItemData)
    local tool = self:GetToolFromItem(item)
    if not tool then
        return
    end

    return {
        AimDepth = tool:GetAttribute("AimDepth") or 0,
        Depth = tool:GetAttribute("Depth") or 0,
        Sideways = tool:GetAttribute("Sideways") or 0,
        Vertical = tool:GetAttribute("Vertical") or 0
    }
end

return ToolSystem