-- Main server script, all setup happens here.
-- Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Data Objects
local InventoryData = require(ReplicatedStorage.DataObjects.InventoryData)
local ItemData = require(ReplicatedStorage.DataObjects.ItemData)

-- Modules
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)
local StabilityAnchor = require(ReplicatedStorage.Modules.StabilityAnchor)
local WeldBetween = require(ReplicatedStorage.Modules.WeldBetween)

-- Packages
local FastCast = require(ReplicatedStorage.Packages.FastCast)

-- Assets
local Assets = ReplicatedStorage.Assets
local Tools = Assets.Tools

-- Systems
local InventorySystem = require(ReplicatedStorage.Systems.InventorySystem)
local CombatSystem = require(ReplicatedStorage.Systems.CombatSystem)
local EffectsSystem = require(ReplicatedStorage.Systems.EffectsSystem)

-- Game Data
local GameBulletData = require(ReplicatedStorage.GameBulletData)
local GameMeleeData = require(ReplicatedStorage.GameMeleeData)

-- Variables
local CurrentCamera = Workspace.CurrentCamera

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Server
local GetStateRemote = Remotes:Get("GetState")
local StateChangedRemote = Remotes:Get("StateChanged")
local EquipItemRemote = Remotes:Get("EquipItem")
local UnequipItemRemote = Remotes:Get("UnequipItem")
local DropItemRemote = Remotes:Get("DropItem")
local HandleHitRemote = Remotes:Get("HandleHit")
local ReloadRemote = Remotes:Get("Reload")
local ReplicateRemote = Remotes:Get("Replicate")

-- Debug
local print = require(ReplicatedStorage.Debug.Print)

-- Store
local Store = require(ReplicatedStorage.Store).new()

-- Server hit detection
local MAX_RAYCAST_DISTANCE_TOLERANCE = 10 -- Calculated avg. distance a gun can shoot with an SEM of 2. This is legit.
local ServerCaster = FastCast.new()

-- Handle hit, after it's been detected
local function OnRayHit(cast, result: RaycastResult, _, bullet)
    local instance = result.Instance
    local userData = cast.UserData
    local weaponData = userData.Weapon.StaticData

    if instance then
        -- Deal damage to players
        local hitHumanoid: Humanoid = instance.Parent:FindFirstChildOfClass("Humanoid")
        if hitHumanoid then
            hitHumanoid:TakeDamage(weaponData.PlayerDamage)
        end

        -- Create thrown tool object on ground
        local tool = Tools:FindFirstChild(userData.Weapon.Name)
        if weaponData.WeaponType == "Melee" and tool and bullet then
            local conns = {}
            local toolObj = tool.PrimaryPart:Clone()
            Debris:AddItem(toolObj, 300)
            
            local _, _, _, R00, R01, R02, R10, R11, R12, R20, R21, R22 = bullet.CFrame:GetComponents()
            local rotationMatrix = CFrame.new(0, 0, 0, R00, R01, R02, R10, R11, R12, R20, R21, R22)
            local rotationOffset = CFrame.Angles(math.rad(-120), 0, 0)
            
            toolObj.CFrame = CFrame.new(result.Position) * rotationMatrix * rotationOffset
            toolObj.Parent = Workspace.DroppedItems
            toolObj.CanCollide = false
            toolObj.Anchored = true

            WeldBetween(toolObj, instance)

            if hitHumanoid then
                table.insert(conns, hitHumanoid.Died:Connect(function()
                    toolObj.CanCollide = true
                    toolObj.Anchored = false
                    StabilityAnchor(toolObj)
                    for _, conn in conns do conn:Disconnect() end
                end))
            end

            table.insert(conns, instance:GetPropertyChangedSignal("Parent"):Connect(function()
                toolObj.CanCollide = true
                toolObj.Anchored = false
                StabilityAnchor(toolObj)
                for _, conn in conns do conn:Disconnect() end
            end))
        end
    end
end

-- Hit detection
local function HandleHitDetection(player: Player, activeWeapon: ItemData.ItemData, origin: CFrame)
    local weaponData = activeWeapon.StaticData

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

    -- Handle throwable rendering on the server
    local tool = Tools:FindFirstChild(activeWeapon.Data.Name)
    if weaponData.WeaponType == "Melee" and tool ~= nil then
        castBehavior.CosmeticBulletContainer = Workspace.Debris
        castBehavior.CosmeticBulletTemplate = tool.PrimaryPart
    end

    for _ = 1, weaponData.BulletSpreadCount or 1 do
        local rayStart, rayDirection = CombatSystem:CalculateRaycast(activeWeapon.Data, origin)
        
        local cast = ServerCaster:Fire(rayStart, rayDirection, weaponData.BulletSpeed or 100, castBehavior)
        cast.UserData = {
            Player = player,
            Weapon = activeWeapon
        }
    end

    if weaponData.WeaponType == "Gun" then
        ReplicateRemote:SendToAllPlayersExcept({ player }, "BulletReplicate", player, activeWeapon, origin)
    end
end

ServerCaster.RayHit:Connect(OnRayHit)
ServerCaster.LengthChanged:Connect(CombatSystem.OnLengthChanged)
ServerCaster.CastTerminating:Connect(function(cast)
    local rayInfo = cast.RayInfo
    if rayInfo and rayInfo.CosmeticBulletObject then
        local bullet = rayInfo.CosmeticBulletObject

        if bullet then
            bullet:Destroy()
        end
    end
end)

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

    -- TODO: gathering, AND weird bug w/ aiming while meleeing
    DropItemRemote:Connect(function(player, slot)
        -- TODO: other inventories, e.g. dropping from chests
        if InventorySystem:GetEquippedItemSlot(player) == tonumber(slot) then
            InventorySystem:UnequipItem(player)
        end

        local item = InventorySystem:GetItemData(player, tonumber(slot))
        if item then
            item.Data = {}
            InventorySystem:Update(item)
            
            EffectsSystem:MakeDroppedItem(item)
        end
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

    HandleHitRemote:Connect(function(player: Player, origin: CFrame, thrownTool: boolean?)
        local character = player.Character
        local humanoid = character:FindFirstChild("Humanoid")
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local activeWeapon = InventorySystem:GetItemData(player, InventorySystem:GetEquippedItemSlot(player))

        if humanoid.Health <= 0 and activeWeapon == nil then
            return
        end

        local weaponData = GetStaticData(activeWeapon.Data.Name)

        if (origin.Position - humanoidRootPart.Position).Magnitude > MAX_RAYCAST_DISTANCE_TOLERANCE then
            print(`Declined hit {(origin.Position - humanoidRootPart.Position).Magnitude}`)
            return
        end

        if weaponData.WeaponType == "Melee" and thrownTool == true then
            local oldActiveWeapon = table.clone(activeWeapon)
            InventorySystem:UnequipItem(player)
            activeWeapon.Data = {}
            InventorySystem:Update(activeWeapon)

            HandleHitDetection(player, oldActiveWeapon, origin)
        elseif weaponData.WeaponType == "Gun"  then
            if activeWeapon.Data.Ammo == 0 then
                return
            end

            activeWeapon.Data.Ammo -= 1
            InventorySystem:Update(activeWeapon)
            
            HandleHitDetection(player, activeWeapon, origin)
        elseif weaponData.WeaponType == "Melee" then
            -- Old hit detection
            local rayStart, rayDirection = origin.Position, origin.LookVector * (weaponData.MeleeMaxDistance)
            local hit = CombatSystem:FindHitLocation(player, { rayStart, rayDirection })
    
            if not hit then
                for i = 1, #GameMeleeData.MeleeOffsets do
                    rayStart = (origin * GameMeleeData.MeleeOffsets[i]).Position
                    hit = CombatSystem:FindHitLocation(player, { rayStart, rayDirection })
    
                    if hit then
                        break
                    end
                end
            end

            if hit then
                OnRayHit({
                    UserData = {
                        Player = player,
                        Weapon = activeWeapon
                    }
                }, hit, nil, nil)
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
        InventorySystem:AddNewItem(player, 1, ItemData.new("Wood", 500))
        InventorySystem:AddNewItem(player, 2, ItemData.new("Double Barrel", 1))
        InventorySystem:AddNewItem(player, 4, ItemData.new("Double Barrel", 1, 13372))
        InventorySystem:AddNewItem(player, 3, ItemData.new("Sawblade Axe"))
        InventorySystem:AddNewItem(player, 9, ItemData.new("Wood", 500))
        InventorySystem:AddNewItem(player, 10, ItemData.new("Buckshot", 1))
        InventorySystem:AddNewItem(player, 11, ItemData.new("Buckshot", 1))
        InventorySystem:AddNewItem(player, 12, ItemData.new("Buckshot", 3))
        InventorySystem:AddNewItem(player, 13, ItemData.new("Buckshot", 1337))
        local crate = workspace.TestCrate
        InventorySystem:InitializeInventory(InventoryData.new(crate, 10))
        InventorySystem:AddNewItem(crate, 2, ItemData.new("Double Barrel"))

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