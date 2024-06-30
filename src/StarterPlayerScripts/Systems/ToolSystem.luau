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
local ShootingEffects = Assets.ShootingEffects

-- Utility
local GetStaticDataModule = require(ReplicatedStorage.Modules.GetStaticData)

-- Player State
local PlayerStateController = require(script.Parent.Parent.PlayerStateController)

-- Systems
local InputSystem = require(script.Parent.InputSystem)
local BulletSystem = require(ReplicatedStorage.Systems.BulletSystem)
local InventorySystem = require(ReplicatedStorage.Systems.InventorySystem)

-- Constants
local VIEWMODEL_TEXTURE_ID = "rbxassetid://18239537672"

-- Game Data
local GameItemData = require(ReplicatedStorage.GameItemData)

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Client
local ReloadRemote = Remotes:Get("Reload")

-- Data Objects
local ItemData = require(ReplicatedStorage.DataObjects.ItemData)

local ToolSystem = {
    Origin = nil, -- View model humanoid root part (origin)
    Offset = nil, -- View model offset
    ViewModel = nil, -- View model ref
    CurrentTool = nil,
    CurrentItem = nil,
    SidewaysOffset = nil, -- Aiming sideways offset
    VerticalOffset = nil, -- Aiming vertical offset
    SpringX = Spring.new(0, 0, 4),
    SpringY = Spring.new(0, 0, 4),
    LastFireTick = 0 -- Last time weapon was fired
}

function ToolSystem:GetStaticData()
    if not self.CurrentItem then return nil end
    return GetStaticDataModule(self.CurrentItem.Name)
end

function ToolSystem:GetWeaponType(): () -> GameItemData.WeaponType
    local staticData = self:GetStaticData()
    if staticData then
        return staticData.WeaponType
    end
end

function ToolSystem:GetBulletPattern(): () -> GameItemData.BulletPattern
    local staticData = self:GetStaticData()
    if staticData then
        return staticData.BulletPattern
    end
end

function ToolSystem:ClearViewModel()
    for _, child in Camera:GetChildren() do
        if child.Name == "ViewModel" then
            child:Destroy()
        end
    end
    self.Origin = nil
end

function ToolSystem:StopAnimation(animationName: string, fadeTime: number?)
    if self.ViewModel then
        for _, track: AnimationTrack in self.ViewModel.Humanoid:GetPlayingAnimationTracks() do
            if track.Name == animationName then
                track:Stop(fadeTime or 0.1)
            end
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

    -- if track.Name == "Idle" then
    --     self.SidewaysOffset = self.CurrentTool.ScreenCenter.CFrame.X - self.Origin.CFrame.X
    --     self.VerticalOffset = self.CurrentTool.ScreenCenter.CFrame.Y - self.Origin.CFrame.Y
    -- end

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

    viewModel.LeftArm.TextureID = VIEWMODEL_TEXTURE_ID
    viewModel.RightArm.TextureID = VIEWMODEL_TEXTURE_ID
    viewModel.LeftArm.BrickColor = Player.Character.Head.BrickColor
    viewModel.RightArm.BrickColor = Player.Character.Head.BrickColor

    local tool = self:GetToolFromItem(item):Clone()
    tool.Parent = viewModel
    tool.RightArmWeld.Part0 = viewModel.RightArm
    tool.RightArmWeld.Part1 = tool.PrimaryPart

    for _, effect in ShootingEffects:GetChildren() do
        effect = effect:Clone()
        effect.Parent = tool.ShootingPoint
    end
    
    self.SidewaysOffset = tool.ScreenCenter.CFrame.X - viewModel.HumanoidRootPart.CFrame.X
    self.VerticalOffset = tool.ScreenCenter.CFrame.Y - viewModel.HumanoidRootPart.CFrame.Y
    self.ViewModel = viewModel
    self.CurrentTool = tool
    self.CurrentItem = item
    self.Origin = viewModel.HumanoidRootPart
end

function ToolSystem:Unequip()
    InputSystem:ForceStopAction("Fire")
    InputSystem:ForceStopAction("Reload")
    self:ClearViewModel()
    self.ViewModel = nil
    self.CurrentTool = nil
    self.CurrentItem = nil
    self.Offset = nil
end

function ToolSystem:ChangeTool(item: ItemData.ItemData)
    InputSystem:ForceStopAction("Fire")
    InputSystem:ForceStopAction("Reload")
    self:ClearViewModel()
    self:SetupToolForEquip(item)
    self:PlayAnimation("Idle")
    self:PlayAnimation("Draw")
end

function ToolSystem:UpdateOffset(elapse: number)
    local offset = self.Offset

    if not offset then
        -- Is it even possible to not have an offset?
        return CFrame.new()
    else
        local lerp = 0.2
        local root = 0.3
        local fps = 1 / 60
        lerp = root * (elapse / fps)
        if lerp > 1 then
            lerp = 1
        end

        local cframe: CFrame = self.Offset:Lerp(offset, lerp)
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
                        * self:UpdateOffset(elapse)
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

function ToolSystem:IsReadyToFire()
    if not self.CurrentItem then return false end
    local staticData = self:GetStaticData()
    return InputSystem:IsStateActive("Fire") == true and tick() - self.LastFireTick > staticData.FireRate
end

function ToolSystem:Reload()
    local staticData = self:GetStaticData()
    if PlayerStateController.IsAlive == false or self.CurrentItem == nil then 
        InputSystem:ForceStopAction("Reload")
        return 
    end
    if self.CurrentItem.Ammo >= staticData.MaxAmmo then
        InputSystem:ForceStopAction("Reload")
        return
    end
    if #InventorySystem:GetAmmoStacks(Player, staticData.AmmoType) <= 0 then
        self:PlayAnimation("ReloadAttempt", true)
        InputSystem:ForceStopAction("Reload")
        return
    end

    self:StopAnimation("Idle", 1)

    self:PlayAnimation("Reload", true)
    task.spawn(function()
        ReloadRemote:CallServerAsync():andThen(function(ammo)
            if ammo then
                InputSystem:ForceStopAction("Reload")
                self.CurrentItem.Ammo = ammo
            end
        end)
    end)
    
    self:PlayAnimation("Idle")
end

function ToolSystem:Fire()
    InputSystem:ForceStopAction("Fire")

    if PlayerStateController.IsAlive == false or self.CurrentItem == nil then return end
    if self.CurrentItem.Ammo == 0 then
        return
    end
    self.CurrentItem.Ammo -= 1

    self.LastFireTick = tick()
    local isHipFire = InputSystem:IsStateActive("Aim") == false

    self:PlayAnimation("Shoot")
    self.CurrentTool.ShootingPoint.Fire:Emit(8)
    self.CurrentTool.ShootingPoint.MuzzlePuff:Emit(20)

    -- Handle shooting and local hit detection
    if self:GetWeaponType() == "Gun" then
        local bulletOrigin = isHipFire and self.CurrentTool.ShootingPoint.CFrame or Camera.CFrame

        BulletSystem:ProjectileShoot(Player, self.CurrentItem, bulletOrigin)
    end
end

return ToolSystem