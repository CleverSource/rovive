-- Main server script, all setup happens here.
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Data Objects
local InventoryData = require(ReplicatedStorage.DataObjects.InventoryData)
local ItemData = require(ReplicatedStorage.DataObjects.ItemData)

-- Modules
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)

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
    local MAX_RAYCAST_DISTANCE_TOLERANCE = 15

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

    HandleHitRemote:Connect(function(player: Player, origin, elapse, claimedPosition)
        if player.Character and claimedPosition then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")

            if not humanoid and not humanoidRootPart then return end
            if humanoid.Health <= 0 then return end

            local activeWeapon = InventorySystem:GetItemFromSlot(player, InventorySystem:GetEquippedItemSlot(player))
            local expectedRaycast = CombatSystem:FindHitLocation(player, activeWeapon, origin, elapse)
            if not expectedRaycast then return end

            local claimedDirection = (claimedPosition - origin.Position).Unit
            local dotProduct = claimedDirection:Dot(expectedRaycast.Position)
            local cosAngle = math.clamp(dotProduct, -1, 1)
            local angle = math.acos(cosAngle)
            local tolerance = math.deg(angle)

            local weaponData = GetStaticData(activeWeapon.Name)
            
            -- Handle hit
            if tolerance < MAX_RAYCAST_ANGLE_TOLERANCE and (claimedPosition - expectedRaycast.Position).Magnitude < MAX_RAYCAST_DISTANCE_TOLERANCE then
                local hit = expectedRaycast.Instance
                local hitHumanoid: Humanoid = hit.Parent:FindFirstChild("Humanoid")
                if hitHumanoid then
                    hitHumanoid:TakeDamage(weaponData.PlayerDamage)
                end
            else
                -- TODO: bug, can't shoot behind an enemy
                warn(`Bad tolerance: {tolerance} | {(claimedPosition - expectedRaycast.Position).Magnitude}`)
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