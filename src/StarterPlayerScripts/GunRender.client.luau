-- alex
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Player State
local PlayerStateController = require(script.Parent:WaitForChild("PlayerStateController"))

-- Variables
local Player = Players.LocalPlayer
local MovementHistory = {}

-- Constants
local GRACE_PERIOD_FRAMES = 14
local PLAYER_MAGNITUDE_THRESHOLD = 0.01

-- Systems
local Systems = ReplicatedStorage:WaitForChild("Systems")
local InventorySystem = require(Systems.InventorySystem)

local ToolSystem = require(script.Parent.Systems.ToolSystem)
local InputSystem = require(script.Parent.Systems.InputSystem)

-- Functions
local function CalculateViewModelOffset()
    local cframe = CFrame.new()
    local angles = CFrame.Angles(0, 0, 0)

    local currentTick = tick()
    local currentPosition = Vector2.new(PlayerStateController.HumanoidRootPart.Position.X, PlayerStateController.HumanoidRootPart.Position.Z)

    -- Is player moving based on frame grace period
    local playerMoving = false
    local moveCount = 0

    local movementMagnitude = (currentPosition - PlayerStateController.LastPosition).Magnitude
    table.insert(MovementHistory, 1, movementMagnitude)

    if #MovementHistory > GRACE_PERIOD_FRAMES then
        table.remove(MovementHistory)
    end

    for _, magnitude in ipairs(MovementHistory) do
        if magnitude > PLAYER_MAGNITUDE_THRESHOLD then
            moveCount = moveCount + 1
        end
    end

    if moveCount > GRACE_PERIOD_FRAMES / 2 then
        playerMoving = true
    end

    -- Animation speed changes based on movement speed
    local currentImportantState = InputSystem:GetImportantState()
    local currentAnimationSpeed = PlayerStateController.Humanoid.WalkSpeed < 20 and PlayerStateController.Humanoid.WalkSpeed or 20
    currentAnimationSpeed = currentAnimationSpeed / 1.5

    if PlayerStateController.HumanoidState == Enum.HumanoidStateType.Swimming then
        currentAnimationSpeed = currentAnimationSpeed * 0.5
    end

    -- Walking sway
    if playerMoving then
    -- if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.A) then
        if currentImportantState == nil then
            cframe = cframe * CFrame.new(math.sin(currentTick * currentAnimationSpeed) / 14, math.sin(currentTick * (currentAnimationSpeed * 2)) / 10, 0)
        elseif currentImportantState == "Aim" then
            cframe = cframe * CFrame.new(math.sin(currentTick * (currentAnimationSpeed / 2)) / 60, math.sin(currentTick * (currentAnimationSpeed / 2)) / 80, 0)
        elseif currentImportantState == "Sprint" then
            if ToolSystem:GetWeaponType() == "Gun" then
                -- TODO: make this check weapon hold type? (e.g. pistol, rifle, melee, etc)
                cframe = cframe * CFrame.new(0, -0.75, 0) * CFrame.new(math.sin(currentTick * currentAnimationSpeed) / 40, math.sin(currentTick * (currentAnimationSpeed * 2)) / 5, math.sin(currentTick * currentAnimationSpeed) / 40)
                        * CFrame.Angles(0, math.rad(math.sin(currentTick * currentAnimationSpeed) * 8), 0)
            elseif ToolSystem:GetWeaponType() == "Melee" then
                cframe = cframe * CFrame.new(0, -1, 0) * CFrame.new(math.sin(currentTick * currentAnimationSpeed) / 40, math.sin(currentTick * (currentAnimationSpeed * 2)) / 5, 0) 
                    * CFrame.Angles(0, math.rad(math.sin(currentTick * currentAnimationSpeed) * 8), -math.rad(math.sin(currentTick * currentAnimationSpeed) * 10))
            end
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
do
    local function equipActiveSlotAttribute()
        local newSlot = Player:GetAttribute("EquippedSlot")
        if newSlot ~= nil then
            if not PlayerStateController.Humanoid or PlayerStateController.Humanoid.Health <= 0 or not PlayerStateController.IsAlive then
                return
            end

            local item = InventorySystem:GetItemData(Players.LocalPlayer, newSlot)
            ToolSystem:ChangeTool(item.Data)

            local originOffset = CalculateViewModelOffset()
            local offsets = ToolSystem:GetToolOffsets(item)
            originOffset = originOffset * CFrame.new(offsets.Sideways, offsets.Vertical, offsets.Depth)

            ToolSystem:SetOffset(originOffset * CFrame.Angles(-math.rad(90), 0, 0))
        else
            ToolSystem:Unequip()
        end
    end

    Player:GetAttributeChangedSignal("EquippedSlot"):Connect(function()
        equipActiveSlotAttribute()
    end)
    equipActiveSlotAttribute()
end

-- Handle gun animations
do
    RunService.RenderStepped:Connect(function(elapse)
        if not ToolSystem.Origin then return end
        if not PlayerStateController.IsAlive then return end

        local originOffset = CalculateViewModelOffset()

        ToolSystem:UpdateOrigin(elapse)

        local itemData = InventorySystem:GetItemData(Players.LocalPlayer, InventorySystem:GetEquippedItemSlot(Players.LocalPlayer))
        local offsets = ToolSystem:GetToolOffsets(itemData.Data)

        -- Gun shooting
        if ToolSystem:IsReadyToFire() then 
            if (ToolSystem:GetWeaponType() == "Gun" and not PlayerStateController:CharacterIsNearWall()) or ToolSystem:GetWeaponType() == "Melee" then
                ToolSystem:Fire()
            else
                InputSystem:ForceStopAction("Fire")
            end
        end
        
        -- Aiming
        if InputSystem:IsStateActive("Aim") then
            if ToolSystem:GetWeaponType() == "Gun" then
                originOffset = originOffset * CFrame.new(ToolSystem.SidewaysOffset, -ToolSystem.VerticalOffset, offsets.AimDepth)
            elseif ToolSystem:GetWeaponType() == "Melee" then
                originOffset = originOffset * CFrame.new(offsets.Sideways, offsets.AimVertical, offsets.AimDepth)
                                    * CFrame.Angles(math.rad(60), 0, -math.rad(30)) * CFrame.new(-0.5, 0, 0)
            else
                originOffset = originOffset * CFrame.new(offsets.Sideways, offsets.Vertical, offsets.Depth)
            end
        else
            originOffset = originOffset * CFrame.new(offsets.Sideways, offsets.Vertical, offsets.Depth)
        end

        ToolSystem:SetOffset(originOffset)
        ToolSystem.SpringY:Update()
        ToolSystem.SpringX:Update()
    end)
end