-- Main client setup script
-- Services
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Client
local ReplicateRemote = Remotes:Get("Replicate")
local PickupItemRemote = Remotes:Get("PickupItem")
local EquipItemRemote = Remotes:Get("EquipItem")
local UnequipItemRemote = Remotes:Get("UnequipItem")

-- Systems
local Systems = script.Parent:WaitForChild("Systems")
local ToolSystem = require(Systems.ToolSystem)
local InputSystem = require(Systems.InputSystem)

-- Modules
local CountTable = require(ReplicatedStorage.Modules.CountTable)

-- ReplicatedStorage Systems
local RepSystems = ReplicatedStorage.Systems
local BulletSystem = require(RepSystems.BulletSystem)
local InventorySystem = require(RepSystems.InventorySystem)

-- Player State
local PlayerStateController = require(script.Parent.Modules.PlayerStateController)

-- Variables
local CurrentCamera = Workspace.CurrentCamera
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Player Gui
local InteractionGui = PlayerGui:WaitForChild("InteractionGui")
local InteractOverlay = InteractionGui:WaitForChild("InteractOverlay")

-- Dropped items
local DroppedItems = Workspace.DroppedItems

-- Game properties
local GameProperties = require(ReplicatedStorage.GameProperties)

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

-- Debounces
local EQUIP_DEBOUNCE = 0.5
local CAN_EQUIP = true

-- Player input
task.spawn(function()
    task.wait(1) -- TODO: don't like this.

    -- Handle player input
    InputSystem:MapKeybinds()

    InputSystem.OnStateChanged:Connect(function(state, value, key)
        if state == "Reload" and value == true then
            ToolSystem:Reload()
        elseif state == "Equip" and value == true then
            local slot = (key.KeyCode.Value - 48) + 24
            local inventoryData = InventorySystem:GetInventoryFromObject(Player)

            if CAN_EQUIP then
                if slot ~= inventoryData.Data.EquippedSlot then
                    InventorySystem:EquipItem(Players.LocalPlayer, tonumber(slot))
                    EquipItemRemote:SendToServer(slot)

                    task.spawn(function()
                        CAN_EQUIP = false
                        task.wait(EQUIP_DEBOUNCE)
                        CAN_EQUIP = true
                    end)
                else
                    InventorySystem:UnequipItem(Players.LocalPlayer)
                    UnequipItemRemote:SendToServer()
                end
            end
        elseif state == "Interact" and value == true then
            if PlayerStateController.HoveredItem ~= nil then
                local hoveredItemData = PlayerStateController.HoveredItem
                if CountTable(InventorySystem:GetBestStacks(Player, hoveredItemData.Name)) == 0 and InventorySystem:IsInventoryFull(Player) == true then
                    return
                end

                -- Picking up animation
                local toolModel: Instance = DroppedItems:FindFirstChild(hoveredItemData.ItemId)
                if toolModel and toolModel.PrimaryPart then
                    local toolModelClone = toolModel:Clone()
                    local weld = toolModelClone:FindFirstChildWhichIsA("Weld", true)
                    if weld then weld:Destroy() end
                    toolModelClone.Parent = Workspace.Debris
                    Debris:AddItem(toolModelClone, 15)

                    for _, part in toolModelClone:GetChildren() do
                        if part:IsA("BasePart") then
                            part.Anchored = true
                            part.CanCollide = false
                            TweenService:Create(part, TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
                                Size = Vector3.new(0, 0, 0),
                                Transparency = 1,
                                CFrame = CFrame.new(PlayerStateController.HumanoidRootPart.CFrame.Position)
                            }):Play()
                        end
                    end
                end

                -- Request pickup on server
                PickupItemRemote:CallServerAsync(hoveredItemData):andThen(function(success)
                    if success then
                        toolModel:Destroy()
                    end                    
                end)
            end
        end
    end)
end)

-- Interaction
local DEFAULT_KEYBIND = "E" -- TODO!

local function EnableInteractGui()
    InteractOverlay.Visible = true
    InteractOverlay.CenterPoint.Visible = true
end

local function DisableInteractGui()
    InteractOverlay.Visible = false
    InteractOverlay.CenterPoint.Visible = false
    PlayerStateController.HoveredItem = nil
end

-- TODO: change this to have different if-else structure
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        PlayerStateController:Update()

        if PlayerStateController.IsAlive then
            local ray = Ray.new(CurrentCamera.CFrame.Position, CurrentCamera.CFrame.LookVector * GameProperties.MaxLootDistance)
            local isPlayerSwimming = PlayerStateController.HumanoidState == Enum.HumanoidStateType.Swimming

            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = { CurrentCamera, Player.Character, Workspace.Debris, Workspace.Bullets }
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.IgnoreWater = isPlayerSwimming

            local result = Workspace:Raycast(ray.Origin, ray.Direction, raycastParams)
            if result and result.Instance then
                local isItemPickup = result.Instance:IsDescendantOf(Workspace.DroppedItems)

                if isItemPickup then
                    if (PlayerStateController.HumanoidRootPart.Position - result.Position).Magnitude <= GameProperties.MaxLootDistance then
                        local itemModel = result.Instance.Parent
                        local itemData = HttpService:JSONDecode(itemModel:GetAttribute("ItemData") or {})
                        if not itemData or CountTable(itemData) == 0 then
                            DisableInteractGui()
                            return
                        end

                        EnableInteractGui()

                        InteractOverlay.InteractText.Text = `'{DEFAULT_KEYBIND}' to pickup {itemData.Name} {itemData.Stack > 1 and `x{itemData.Stack}` or ""}`
                        PlayerStateController.HoveredItem = itemData
                    end
                else
                    DisableInteractGui()
                end
            else
                DisableInteractGui()
            end
        end
    end)
end)