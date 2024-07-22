-- Main server script, all setup happens here.
-- Services
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

-- Data Objects
local InventoryData = require(ReplicatedStorage.DataObjects.InventoryData)
local ItemData = require(ReplicatedStorage.DataObjects.ItemData)

-- Modules
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)
local StabilityAnchor = require(ReplicatedStorage.Modules.StabilityAnchor)
local WeldBetween = require(ReplicatedStorage.Modules.WeldBetween)
local CountTable = require(ReplicatedStorage.Modules.CountTable)

-- Packages
local FastCast = require(ReplicatedStorage.Packages.FastCast)

-- Assets
local Assets = ReplicatedStorage.Assets
local Tools = Assets.Tools

-- Systems
local InventorySystem = require(ReplicatedStorage.Systems.InventorySystem)
local CombatSystem = require(ReplicatedStorage.Systems.CombatSystem)
local EffectsSystem = require(ReplicatedStorage.Systems.EffectsSystem)

-- Server Systems
local ServerAnimator = require(ServerStorage.ServerSystems.ServerAnimator)

-- Game Data
local GameBulletData = require(ReplicatedStorage.GameBulletData)
local GameMeleeData = require(ReplicatedStorage.GameMeleeData)
local GameProperties = require(ReplicatedStorage.GameProperties)

-- Variables
local CurrentCamera = Workspace.CurrentCamera

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Server
local GetStateRemote = Remotes:Get("GetState")
local StateChangedRemote = Remotes:Get("StateChanged")
local EquipItemRemote = Remotes:Get("EquipItem")
local UnequipItemRemote = Remotes:Get("UnequipItem")
local DropItemRemote = Remotes:Get("DropItem")
local PickupItemRemote = Remotes:Get("PickupItem")
local MoveItemRemote = Remotes:Get("MoveItem")
local HandleHitRemote = Remotes:Get("HandleHit")
local ReloadRemote = Remotes:Get("Reload")
local ReplicateRemote = Remotes:Get("Replicate")

-- Debug
local print = require(ReplicatedStorage.Debug.Print)

-- Store
local Store = require(ReplicatedStorage.Store).new()

-- Trove
local Trove = require(ReplicatedStorage.Packages.Trove).new()

-- Server hit detection
local MAX_RAYCAST_DISTANCE_TOLERANCE = 10 -- Calculated avg. distance a gun can shoot with an SEM of 2. This is legit.
local ServerCaster = FastCast.new()

-- Handle hit, after it's been detected
local function OnRayHit(cast, result: RaycastResult, _, bullet)
    local instance = result.Instance
    local userData = cast.UserData
    local weaponData = userData.Weapon.StaticData

    if instance then
        -- TODO: proper hit handling
        -- Deal damage to players
        local hitHumanoid: Humanoid = instance.Parent:FindFirstChildOfClass("Humanoid")
        if hitHumanoid then
            hitHumanoid:TakeDamage(weaponData.PlayerDamage)
        end

        -- Create thrown tool object on ground
        local tool = Tools:FindFirstChild(userData.Weapon.Name)
        if weaponData.WeaponType == "Melee" and tool and bullet then
            local toolModel = tool:Clone()
            local toolObj = toolModel.PrimaryPart
            Debris:AddItem(toolModel, 300)

            -- TODO: iron out the math on this in the future, specifically, items showing through walls
            -- TODO: tools despawn they never hit the ground or an object
            local _, _, _, R00, R01, R02, R10, R11, R12, R20, R21, R22 = bullet.CFrame:GetComponents()
            local rotationMatrix = CFrame.new(0, 0, 0, R00, R01, R02, R10, R11, R12, R20, R21, R22)
            local rotationOffset = CFrame.Angles(math.rad(-120), 0, 0)

            toolObj.CFrame = CFrame.new(result.Position) * rotationMatrix * rotationOffset
            toolModel.Parent = Workspace.DroppedItems
            toolObj.CanCollide = false
            toolObj.Anchored = false

            WeldBetween(toolObj, instance)
            toolModel.Name = userData.Weapon.Data.ItemId
            toolModel:SetAttribute("ItemData", HttpService:JSONEncode(userData.Weapon.Data))

            if hitHumanoid then
                Trove:Connect(hitHumanoid.Died, function()
                    toolObj.CanCollide = true
                    toolObj.Anchored = false
                    StabilityAnchor(toolObj)
                    Trove:Clean()
                end)
            end

            Trove:Connect(toolObj:GetPropertyChangedSignal("Parent"), function()
                toolObj.CanCollide = true
                toolObj.Anchored = false
                StabilityAnchor(toolObj)
                Trove:Clean()
            end)
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
        castBehavior.CosmeticBulletTemplate = tool.PrimaryPart:Clone()
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
ServerCaster.LengthChanged:Connect(function(cast, lastPoint, direction, length, velocity, bullet)
    CombatSystem:OnLengthChanged(cast, lastPoint, direction, length, velocity, bullet)
end)
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
    local function UnequipItem(player)
        InventorySystem:UnequipItem(player)
        EffectsSystem:UnequipItem(player)
        ServerAnimator:StopAnimations(player)
    end

    -- Equip/Unequip item
    EquipItemRemote:Connect(function(player, slot)
        -- Handle equip in the inventory system
        slot = tonumber(slot)
        if slot < 25 or slot > 30 then
            return
        end
        if slot == 0 or slot == nil then
            UnequipItem(player)
        end
        InventorySystem:EquipItem(player, tonumber(slot))

        -- Display tool in player's hand
        local equippedItem = InventorySystem:GetEquippedItemSlot(player)
        if equippedItem then
            local itemData = InventorySystem:GetItemData(player, equippedItem)
            if itemData.StaticData.Equipable then
                EffectsSystem:EquipItem(itemData)
            end

             -- Handle server animation
            ServerAnimator:PlayAnimation(player, itemData)
        end
    end)

    UnequipItemRemote:Connect(function(player)
        UnequipItem(player)
    end)

    -- Pickup item
    PickupItemRemote:SetCallback(function(player, itemData)
        if itemData == nil then
            return false
        end

        if CountTable(InventorySystem:GetBestStacks(player, itemData.Name)) == 0 and InventorySystem:IsInventoryFull(player) == true then
            return false
        end
        
        local character = player.Character
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

        local physicalItem = Workspace.DroppedItems:FindFirstChild(itemData.ItemId)
        if physicalItem and (humanoidRootPart.Position - physicalItem.PrimaryPart.Position).Magnitude <= GameProperties.MaxLootDistance then
            local trustedItemData = physicalItem:GetAttribute("ItemData")
            physicalItem:Destroy()

            InventorySystem:AddItem(player, HttpService:JSONDecode(trustedItemData))
        
            return true
        end
        
        return false
    end)

    -- Move item
    MoveItemRemote:Connect(function(player, fromSlot, toSlot)
        local equippedSlot = InventorySystem:GetEquippedItemSlot(player)

        -- Unequip items if they are in the fromSlot or toSlot
        if equippedSlot == fromSlot or equippedSlot == toSlot then
            UnequipItem(player)
        end

        InventorySystem:MoveItem(player, fromSlot, toSlot)
    end)

    -- Drop item
    DropItemRemote:Connect(function(player, slot)
        -- TODO: other inventories, e.g. dropping from chests
        if InventorySystem:GetEquippedItemSlot(player) == tonumber(slot) then
            UnequipItem(player)
        end

        local item = InventorySystem:GetItemData(player, tonumber(slot))
        if item then
            local oldItem = table.clone(item) 
            item.Data = {}
            InventorySystem:Update(item)
            
            EffectsSystem:MakeDroppedItem(oldItem)
        end
    end)

    -- Reload item
    ReloadRemote:SetCallback(function(player)
        local character = player.Character
        local humanoid = character:FindFirstChild("Humanoid")
        local activeWeapon = InventorySystem:GetItemData(player, InventorySystem:GetEquippedItemSlot(player))

        if humanoid.Health <= 0 and activeWeapon == nil then
            return 0
        end

        local ammoStacks = InventorySystem:GetBestStacks(player, activeWeapon.StaticData.AmmoType)
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

    -- Handle hit
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
            UnequipItem(player)
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

        -- TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING 
        -- TODO: Testing
        -- for i = 1, inventoryData.InventorySlots do
        --     InventorySystem:AddNewItem(player, ItemData.new("Wood", 999))
        -- end

        local crate = workspace.TestCrate
        InventorySystem:InitializeInventory(InventoryData.new(crate, 10))
        InventorySystem:AddNewItem(crate, ItemData.new("Double Barrel"), 2)

        -- task.spawn(function()
        --     while task.wait(1) do
        --         InventorySystem:AddNewItem(crate, ItemData.new("Double Barrel"))
        --     end
        -- end)

        task.spawn(function()
            task.wait(4)
            InventorySystem:AddNewItem(player, ItemData.new("Double Barrel"), 25)
            InventorySystem:AddNewItem(player, ItemData.new("Buckshot", 20))
            InventorySystem:AddNewItem(player, ItemData.new("Buckshot", 20))
            InventorySystem:AddNewItem(player, ItemData.new("Buckshot", 20))
            InventorySystem:AddNewItem(player, ItemData.new("Buckshot", 59))
            InventorySystem:AddNewItem(player, ItemData.new("Buckshot", 2))
            InventorySystem:AddNewItem(player, ItemData.new("Sawblade Axe"), 26)
            InventorySystem:AddNewItem(player, ItemData.new("Wood", 692), 27)
            
            task.wait(1)
            InventorySystem:EquipItem(player, 36)
            -- EffectsSystem:MakeDroppedItem(InventorySystem:GetItemData(player, 1))
            -- EffectsSystem:MakeDroppedItem(InventorySystem:CreateItemData(ItemData.new("Double Barrel"), crate, nil))
            -- InventorySystem:EquipItem(player, 2)
        end)
        -- TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING TESTING 
    end

    for _, player in Players:GetPlayers() do 
        playerAdded(player) 
    end
    Players.PlayerAdded:Connect(playerAdded)
end