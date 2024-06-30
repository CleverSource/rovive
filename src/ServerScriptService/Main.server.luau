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
local ReloadRemote = Remotes:Get("Reload")

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
        local hitHumanoid: Humanoid = instance.Parent:FindFirstChildOfClass("Humanoid")
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
    end)

    UnequipItemRemote:Connect(function(player)
        InventorySystem:UnequipItem(player)
    end)

    ReloadRemote:SetCallback(function(player)
        local character = player.Character
        local humanoid = character:FindFirstChild("Humanoid")
        local activeWeapon = InventorySystem:GetItemData(player, InventorySystem:GetEquippedItemSlot(player))

        if humanoid.Health <= 0 and activeWeapon == nil then
            return 0
        end

        local ammoStacks = InventorySystem:GetAmmoStacks(player, activeWeapon.StaticData.AmmoType)
        local maxAmmo = activeWeapon.StaticData.MaxAmmo
        local obtainedAmmo = 0
        local ammoNeeded = (maxAmmo - activeWeapon.Data.Ammo)

        if activeWeapon.Data.Ammo >= maxAmmo then
            return maxAmmo
        end

        local stacksToUpdate = {}
        
        for i = #ammoStacks, 1, -1 do
            if obtainedAmmo >= maxAmmo then break end
            local stack = ammoStacks[i].Data.Stack
            if stack <= (ammoNeeded - obtainedAmmo) then
                obtainedAmmo += stack
                ammoStacks[i].Data = {}
                table.insert(stacksToUpdate, ammoStacks[i])
            elseif stack > (ammoNeeded - obtainedAmmo) then
                ammoStacks[i].Data.Stack -= (ammoNeeded - obtainedAmmo)
                obtainedAmmo = ammoNeeded
                table.insert(stacksToUpdate, ammoStacks[i])
                break
            end
        end

        local newAmmo = activeWeapon.Data.Ammo + obtainedAmmo
        activeWeapon.Data.Ammo = newAmmo
        InventorySystem:Update(activeWeapon)
        for _, stack in stacksToUpdate do
            InventorySystem:Update(stack)
        end

        return newAmmo
    end)

    HandleHitRemote:Connect(function(player: Player, origin: CFrame)
        local character = player.Character
        local humanoid = character:FindFirstChild("Humanoid")
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local activeWeapon = InventorySystem:GetItemData(player, InventorySystem:GetEquippedItemSlot(player))

        if activeWeapon.Data.Ammo == 0 then
            return
        end

        if humanoid.Health <= 0 and activeWeapon == nil then
            return
        end

        activeWeapon.Data.Ammo -= 1
        InventorySystem:Update(activeWeapon)

        local weaponData = GetStaticData(activeWeapon.Data.Name)
        
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
                local rayStart, rayDirection = CombatSystem:CalculateRaycast(activeWeapon.Data, origin)
                
                local cast = ServerCaster:Fire(rayStart, rayDirection, weaponData.BulletSpeed, castBehavior)
                cast.UserData = {
                    Player = player,
                    Weapon = activeWeapon.Data
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
        InventorySystem:AddItem(player, 2, ItemData.new("Double Barrel", 1, 20))
        InventorySystem:AddItem(player, 7, ItemData.new("Double Barrel"))
        InventorySystem:AddItem(player, 9, ItemData.new("Wood", 500))
        InventorySystem:AddItem(player, 10, ItemData.new("Buckshot", 1))
        InventorySystem:AddItem(player, 11, ItemData.new("Buckshot", 1))
        InventorySystem:AddItem(player, 12, ItemData.new("Buckshot", 3))
        InventorySystem:AddItem(player, 13, ItemData.new("Buckshot", 1337))
        local crate = workspace.TestCrate
        InventorySystem:InitializeInventory(InventoryData.new(crate, 10))
        InventorySystem:AddItem(crate, 2, ItemData.new("Double Barrel"))

        task.spawn(function()
            task.wait(2)
            InventorySystem:EquipItem(player, 2)
        end)
    end

    for _, player in Players:GetPlayers() do 
        playerAdded(player) 
    end
    Players.PlayerAdded:Connect(playerAdded)
end