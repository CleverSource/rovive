-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Player State
local PlayerStateController = require(script.Parent.PlayerStateController)

-- Variables
local Player = Players.LocalPlayer

-- Systems
local ToolSystem = require(script.Parent.ToolSystem)
local InventorySystem = require(ReplicatedStorage.Systems.InventorySystem)
local InputSystem = require(script.Parent.InputSystem)

-- Functions
local function CalculateViewModelOffset()
    local cframe = CFrame.new()
    local angles = CFrame.Angles(0, 0, 0)

    local currentTick = tick()
    local currentPosition = Vector2.new(PlayerStateController.HumanoidRootPart.Position.X, PlayerStateController.HumanoidRootPart.Position.Z)

    local currentImportantState = InputSystem:GetImportantState()

    -- Animation speed changes based on movement speed
    local currentAnimationSpeed = PlayerStateController.Humanoid.WalkSpeed < 20 and PlayerStateController.Humanoid.WalkSpeed or 20
    currentAnimationSpeed = currentAnimationSpeed / 1.5

    if PlayerStateController.HumanoidState == Enum.HumanoidStateType.Swimming then
        currentAnimationSpeed = currentAnimationSpeed * 0.5
    end

    -- Walking sway
    if (currentPosition - PlayerStateController.LastPosition).Magnitude > 0.01 then
        if currentImportantState == nil then
            cframe = cframe * CFrame.new(math.sin(currentTick * currentAnimationSpeed) / 14, math.sin(currentTick * (currentAnimationSpeed * 2)) / 10, 0)
        elseif currentImportantState == "Aim" then
            cframe = cframe * CFrame.new(math.sin(currentTick * (currentAnimationSpeed / 2)) / 60, math.sin(currentTick * (currentAnimationSpeed / 2)) / 80, 0)
        -- elseif currentImportantState == "Sprint" then

        end
    else
        if currentImportantState == nil or currentImportantState == "Sprint" then
            cframe = cframe * CFrame.new(math.sin(currentTick) / 30, math.sin(currentTick * 2) / 30, 0)
        end
    end

    -- Mouse sway
    local mouseDelta = UserInputService:GetMouseDelta()
    ToolSystem.SpringY.Target = (mouseDelta.Y) * 10
    ToolSystem.SpringX.Target = mouseDelta.X * 4

    local changeX = ToolSystem.SpringX.Position / (45 * (InputSystem:IsStateActive("Aim") and 2 or 1))
    local changeY = ToolSystem.SpringY.Position / (60 * (InputSystem:IsStateActive("Aim") and 2 or 1))
    if math.abs(changeX) > 15 then
        changeX = 15 * (changeX > 0 and 1 or -1)
    end
    if math.abs(changeY) > 20 then
        changeY = 20 * (changeY > 0 and 1 or -1)
    end

    angles = angles * CFrame.Angles(math.rad(-changeY), math.rad(-changeX), 0)

    PlayerStateController.LastPosition = currentPosition
    return (cframe * angles)
end

-- Handle equipped items
Player:GetAttributeChangedSignal("EquippedSlot"):Connect(function()
    local newSlot = Player:GetAttribute("EquippedSlot")
    if newSlot ~= nil then
        if not PlayerStateController.Humanoid or PlayerStateController.Humanoid.Health <= 0 or not PlayerStateController.IsAlive then
            return
        end

        local item = InventorySystem:GetItemFromSlot(Players.LocalPlayer, newSlot)
        ToolSystem:ChangeTool(item)

        local originOffset = CalculateViewModelOffset()
        local offsets = ToolSystem:GetToolOffsets(item)
        originOffset = originOffset * CFrame.new(offsets.Sideways, offsets.Vertical, offsets.Depth)

        ToolSystem:SetOffset(originOffset * CFrame.Angles(-math.rad(90), 0, 0))
    else
        ToolSystem:Unequip()
    end
end)

do
    local lastLerpTime = tick()

    RunService.RenderStepped:Connect(function()
        if not ToolSystem.Origin then return end
        if not PlayerStateController.IsAlive then return end

        local currentTime = tick()
        local elapse = currentTime - lastLerpTime
        lastLerpTime = currentTime

        local originOffset = CalculateViewModelOffset()

        ToolSystem:UpdateOrigin(elapse)

        local offsets = ToolSystem:GetToolOffsets(InventorySystem:GetItemFromSlot(Players.LocalPlayer, InventorySystem:GetEquippedItemSlot(Players.LocalPlayer)))
        
        -- Aiming
        if InputSystem:IsStateActive("Aim") then
            if ToolSystem:GetWeaponType() == "Gun" then
                local depth = offsets.AimDepth
                originOffset = originOffset * CFrame.new(ToolSystem.SidewaysOffset, -ToolSystem.VerticalOffset, depth)
            else
                originOffset = originOffset * CFrame.new(offsets.Sideways, offsets.Vertical, offsets.Depth)
            end
        else
            originOffset = originOffset * CFrame.new(offsets.Sideways, offsets.Vertical, offsets.Depth)
        end


        ToolSystem:SetOffset(originOffset)
        ToolSystem.SpringX:Update()
        ToolSystem.SpringY:Update()
    end)
end