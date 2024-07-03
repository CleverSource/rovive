-- Main client setup script
-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Client
local ReplicateRemote = Remotes:Get("Replicate")
local PickupItemRemote = Remotes:Get("PickupItem")

-- Systems
local Systems = script.Parent:WaitForChild("Systems")
local ToolSystem = require(Systems.ToolSystem)
local InputSystem = require(Systems.InputSystem)

-- Modules
local CountTable = require(ReplicatedStorage.Modules.CountTable)

-- ReplicatedStorage Systems
local RepSystems = ReplicatedStorage.Systems
local BulletSystem = require(RepSystems.BulletSystem)

-- Player State
local PlayerStateController = require(script.Parent.PlayerStateController)

-- Variables
local CurrentCamera = Workspace.CurrentCamera
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Player Gui
local InteractionGui = PlayerGui:WaitForChild("InteractionGui")
local InteractOverlay = InteractionGui:WaitForChild("InteractOverlay")

-- Initialize player's character
if Player.Character then
    PlayerStateController:AddCharacter(Player.Character)
end

Player.CharacterAdded:Connect(function(character)
    PlayerStateController:AddCharacter(character)
end)

-- Remote events
ReplicateRemote:Connect(function(typeOfReplication, ...)
    local data = {...}
    if typeOfReplication == "BulletReplicate" then
        BulletSystem:ProjectileShoot(unpack(data))
    end
end)

-- Player input
task.spawn(function()
    task.wait(1)

    -- Handle player input
    InputSystem:MapKeybinds()

    InputSystem.OnStateChanged:Connect(function(state, value)
        if state == "Reload" and value == true then
            ToolSystem:Reload()
        elseif state == "Interact" and value == true then
            PickupItemRemote:SendToServer(PlayerStateController.HoveredItem)
        end
    end)
end)

-- Interaction
local MAX_LOOK_DISTANCE = 10
local DEFAULT_KEYBIND = "E" -- TODO!

local function EnableInteractGui()
    InteractOverlay.Visible = true
    InteractOverlay.CenterPoint.Visible = true
end

local function DisableInteractGui()
    InteractOverlay.Visible = false
    InteractOverlay.CenterPoint.Visible = false
end

task.spawn(function()
    RunService.RenderStepped:Connect(function()
        if PlayerStateController.IsAlive then
            local ray = Ray.new(CurrentCamera.CFrame.Position, CurrentCamera.CFrame.LookVector * MAX_LOOK_DISTANCE)
            local isPlayerSwimming = PlayerStateController.HumanoidState == Enum.HumanoidStateType.Swimming

            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = { CurrentCamera, Player.Character, Workspace.Debris, Workspace.Bullets }
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.IgnoreWater = isPlayerSwimming

            local result = Workspace:Raycast(ray.Origin, ray.Direction, raycastParams)
            if result and result.Instance then
                local isItemPickup = result.Instance:IsDescendantOf(Workspace.DroppedItems)

                if isItemPickup then
                    if (PlayerStateController.HumanoidRootPart.Position - result.Position).Magnitude <= MAX_LOOK_DISTANCE then
                        local itemModel = result.Instance.Parent
                        local itemData = HttpService:JSONDecode(itemModel:GetAttribute("ItemData") or {})
                        if not itemData or CountTable(itemData) == 0 then
                            return
                        end

                        EnableInteractGui()

                        InteractOverlay.InteractText.Text = `'{DEFAULT_KEYBIND}' to pickup {itemData.Name} {itemData.Stack > 1 and `x{itemData.Stack}` or ""}`
                        PlayerStateController.HoveredItem = itemData
                    end
                end
            else
                DisableInteractGui()
            end
        end
    end)
end)