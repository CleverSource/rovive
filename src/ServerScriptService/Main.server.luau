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
local MAX_RAYCAST_ANGLE_TOLERANCE = 0.1
local MAX_RAYCAST_DISTANCE_TOLERANCE = 15
local ServerCaster = FastCast.new()

local function OnRayHit(cast, result, velocity, bullet)
    -- local hit = result.Instance
    print("Hit on server!")
    print(result.Instance)
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

    HandleHitRemote:Connect(function(player: Player, origin, claimedPosition) -- TODO: maybe use claimed position
        local activeWeapon = InventorySystem:GetItemFromSlot(player, InventorySystem:GetEquippedItemSlot(player))
        local weaponData = GetStaticData(activeWeapon.Name)

        local rayStart, rayDirection = CombatSystem:CalculateRaycast(activeWeapon, origin, 20)
        
        local raycastParams = RaycastParams.new()
        raycastParams.IgnoreWater = true
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = { CurrentCamera, player.Character, Workspace.Debris }

        local castBehavior = FastCast.newBehavior()
        castBehavior.MaxDistance = 500 -- TODO
        castBehavior.CanPierceFunction = function() -- TODO
            return false
        end
        castBehavior.RaycastParams = raycastParams
        castBehavior.Acceleration = Vector3.new(0, -9.81, 0)
        castBehavior.AutoIgnoreContainer = true

        local cast = ServerCaster:Fire(rayStart, rayDirection, weaponData.BulletSpeed, castBehavior)
        cast.UserData = {
            Player = player,
            Weapon = activeWeapon
        }
        
        -- OLD
        -- if player.Character and claimedPosition then
        --     local humanoid = player.Character:FindFirstChild("Humanoid")
        --     local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")

        --     if not humanoid and not humanoidRootPart then return end
        --     if humanoid.Health <= 0 then return end

        --     local activeWeapon = InventorySystem:GetItemFromSlot(player, InventorySystem:GetEquippedItemSlot(player))
        --     local expectedRaycast = CombatSystem:FindHitLocation(player, activeWeapon, origin, elapse)
        --     if not expectedRaycast then return end

        --     local claimedDirection = (claimedPosition - origin.Position).Unit
        --     local dotProduct = claimedDirection:Dot(expectedRaycast.Position)
        --     local cosAngle = math.clamp(dotProduct, -1, 1)
        --     local angle = math.acos(cosAngle)
        --     local tolerance = math.deg(angle)

        --     local weaponData = GetStaticData(activeWeapon.Name)
            
        --     -- Handle hit
        --     if tolerance < MAX_RAYCAST_ANGLE_TOLERANCE and (claimedPosition - expectedRaycast.Position).Magnitude < MAX_RAYCAST_DISTANCE_TOLERANCE then
        --         local hit = expectedRaycast.Instance
        --         local hitHumanoid: Humanoid = hit.Parent:FindFirstChild("Humanoid")
        --         if hitHumanoid then
        --             hitHumanoid:TakeDamage(weaponData.PlayerDamage)
        --         end
        --     else
        --         -- TODO: bug, can't shoot behind an enemy
        --         warn(`Bad tolerance: {tolerance} | {(claimedPosition - expectedRaycast.Position).Magnitude}`)
        --     end
        -- end
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