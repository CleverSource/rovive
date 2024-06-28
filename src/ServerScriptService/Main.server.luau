-- Main server script, all setup happens here.
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Data Objects
local InventoryData = require(ReplicatedStorage.DataObjects.InventoryData)
local ItemData = require(ReplicatedStorage.DataObjects.ItemData)

-- Systems
local InventorySystem = require(ReplicatedStorage.Systems.InventorySystem)

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Server
local GetStateRemote = Remotes:Get("GetState")
local StateChangedRemote = Remotes:Get("StateChanged")
local EquipItemRemote = Remotes:Get("EquipItem")
local UnequipItemRemote = Remotes:Get("UnequipItem")

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