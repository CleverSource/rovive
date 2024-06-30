-- Main server script, all setup happens here.
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Data Objects
local InventoryData = require(ReplicatedStorage.DataObjects.InventoryData)
local ItemData = require(ReplicatedStorage.DataObjects.ItemData)

-- Modules
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)

-- Packages
local FastCast = require(ReplicatedStorage.Packages.FastCast)

-- Systems
local InventorySystem = require(ReplicatedStorage.Systems.InventorySystem)
local CombatSystem = require(ReplicatedStorage.Systems.CombatSystem)

-- Game Data
local GameBulletData = require(ReplicatedStorage.GameBulletData)

-- Variables
local CurrentCamera = Workspace.CurrentCamera

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

-- Server hit detection
local MAX_RAYCAST_DISTANCE_TOLERANCE = 8.5 -- Calculated avg. distance a gun can shoot with an SEM of 2. This is legit.
local ServerCaster = FastCast.new()

local function OnRayHit(cast, result, velocity, bullet)
    local instance = result.Instance
    local userData = cast.UserData
    local weaponData = GetStaticData(userData.Weapon.Name)

    if instance then
        local hitHumanoid: Humanoid = instance.Parent:FindFirstChild("Humanoid")
        if hitHumanoid then
            hitHumanoid:TakeDamage(weaponData.PlayerDamage)
        end
    end
end

ServerCaster.RayHit:Connect(OnRayHit)

-- State remotes
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

    HandleHitRemote:Connect(function(player: Player, origin: CFrame)
        local character = player.Character
        local humanoid = character:FindFirstChild("Humanoid")
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local activeWeapon = InventorySystem:GetItemFromSlot(player, InventorySystem:GetEquippedItemSlot(player))

        if humanoid.Health <= 0 and activeWeapon == nil then
            return
        end

        local weaponData = GetStaticData(activeWeapon.Name)
        
        local raycastParams = RaycastParams.new()
        raycastParams.IgnoreWater = true
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = { CurrentCamera, player.Character, Workspace.Debris, Workspace.Bullets }

        local castBehavior = FastCast.newBehavior()
        castBehavior.MaxDistance = weaponData.BulletMaxDistance
        castBehavior.CanPierceFunction = CombatSystem.CanPierceObject
        castBehavior.RaycastParams = raycastParams
        castBehavior.Acceleration = GameBulletData.BulletAcceleration + (weaponData.BulletAcceleration or Vector3.new(0, 0, 0))
        castBehavior.AutoIgnoreContainer = true
        
        if (origin.Position - humanoidRootPart.Position).Magnitude < MAX_RAYCAST_DISTANCE_TOLERANCE then
            for _ = 1, weaponData.BulletSpreadCount or 1 do
                local rayStart, rayDirection = CombatSystem:CalculateRaycast(activeWeapon, origin)
                
                local cast = ServerCaster:Fire(rayStart, rayDirection, weaponData.BulletSpeed, castBehavior)
                cast.UserData = {
                    Player = player,
                    Weapon = activeWeapon
                }
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
        InventorySystem:AddItem(player, 10, ItemData.new("Buckshot", 50))
        local crate = workspace.TestCrate
        InventorySystem:InitializeInventory(InventoryData.new(crate, 10))
        InventorySystem:AddItem(crate, 2, ItemData.new("Double Barrel"))

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