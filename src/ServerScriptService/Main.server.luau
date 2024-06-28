-- Main server script, all setup happens here.
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Data Objects
local InventoryData = require(ReplicatedStorage.DataObjects.InventoryData)
local ItemData = require(ReplicatedStorage.DataObjects.ItemData)

-- Systems
local InventorySystem = require(ReplicatedStorage.Systems.InventorySystem)
local CombatSystem = require(ReplicatedStorage.Systems.CombatSystem)

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Server
local GetStateRemote = Remotes:Get("GetState")
local StateChangedRemote = Remotes:Get("StateChanged")
local EquipItemRemote = Remotes:Get("EquipItem")
local UnequipItemRemote = Remotes:Get("UnequipItem")
local HandleHitRemote = Remotes:Get("HandleHit")

-- Debug
local print = require(ReplicatedStorage.Debug.Print)

-- Store
local Store = require(ReplicatedStorage.Store).new()

do
    GetStateRemote:SetCallback(function()
        return Store:GetState()
    end)

    Store.OnStateChanged:Connect(function(newState)
        -- print("New state: ", newState)
        StateChangedRemote:SendToAllPlayers(newState)
    end)
end

-- Remotes
do
    local MAX_RAYCAST_ANGLE_TOLERANCE = 0.1
    local MAX_RAYCAST_DISTANCE_TOLERANCE = 20

    EquipItemRemote:Connect(function(player, slot)
        if slot == 0 or slot == nil then
            InventorySystem:UnequipItem(player)
        end
        InventorySystem:EquipItem(player, tonumber(slot))
        print(InventorySystem:GetItemFromSlot(player, InventorySystem:GetEquippedItemSlot(player)))
    end)

    UnequipItemRemote:Connect(function(player)
        InventorySystem:UnequipItem(player)
    end)

    HandleHitRemote:Connect(function(player: Player, weapon, origin, elapse, claimedPosition)
        if player.Character and claimedPosition then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoidRootPart then
                if humanoid.Health > 0 then
                    local expectedRaycast = CombatSystem:FindHitLocation(player, weapon, origin, elapse)
                    local claimedDirection = (claimedPosition - origin.Position).Unit
                    local dotProduct = claimedDirection:Dot(expectedRaycast.Position)
                    local cosAngle = math.clamp(dotProduct, -1, 1)
                    local angle = math.acos(cosAngle)
                    local tolerance = math.deg(angle)
                    if tolerance < MAX_RAYCAST_ANGLE_TOLERANCE and (claimedPosition - expectedRaycast.Position).Magnitude <= MAX_RAYCAST_DISTANCE_TOLERANCE then
                        -- Handle
                        print("Legit hit")
                    end
                end
            end
        end
        
    end)
end

-- PlayerAdded
do
    local function playerAdded(player: Player)
        -- Initialize inventory data
        local inventoryData = InventoryData.new(player, 36)
        InventorySystem:InitializeInventory(inventoryData)

        -- Testing
        InventorySystem:AddItem(player, 1, ItemData.new("Wood", 500))
        InventorySystem:AddItem(player, 2, ItemData.new("Double Barrel"))
        InventorySystem:AddItem(player, 7, ItemData.new("Double Barrel"))
        InventorySystem:AddItem(player, 9, ItemData.new("Wood", 500))
        local crate = workspace.TestCrate
        InventorySystem:InitializeInventory(InventoryData.new(crate, 10))

        task.spawn(function()
            player.CharacterAdded:Wait()
            InventorySystem:EquipItem(player, 2)
        end)
    end

    for _, player in Players:GetPlayers() do 
        playerAdded(player) 
    end
    Players.PlayerAdded:Connect(playerAdded)
end