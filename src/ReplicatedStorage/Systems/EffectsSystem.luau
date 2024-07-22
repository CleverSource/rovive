-- Services
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local RandomNum = require(ReplicatedStorage.Modules.RandomNum)
local StabilityAnchor = require(ReplicatedStorage.Modules.StabilityAnchor)

-- Assets
local Assets = ReplicatedStorage.Assets
local BulletEffects = Assets.BulletEffects
local DroppedItemHolders = { Assets.Tools, Assets.DroppedItemTemplates }

-- Bullet effects
local WaterSplash = BulletEffects.WaterSplash
local BulletHole = BulletEffects.BulletHole

-- Effects System
local EffectsSystem = {}

function EffectsSystem:MakeWaterSplash(position: Vector3)
    local water = WaterSplash:Clone()
    water.Parent = Workspace.Debris
    water.CFrame = CFrame.new(position)
    task.spawn(function()
        water.Water.Enabled = true
        task.wait(0.1)
        water.Water.Enabled = false
    end)
    water.Dust:Emit(25)
    -- TODO: sound and download all assets please. lol. please. download the stuff for trails & etc
    Debris:AddItem(water, 5)
end

function EffectsSystem:MakeBulletHole(ray: RaycastResult)
    local bulletHole = BulletHole:Clone()
    bulletHole.Parent = Workspace.Debris
    bulletHole.CFrame = CFrame.new(ray.Position, ray.Position + ray.Normal) * CFrame.Angles(0, 0, RandomNum(0, 360))
    bulletHole.Decal.Color3 = ray.Instance == Workspace.Terrain and ray.Instance:GetMaterialColor(ray.Material) or ray.Instance.BrickColor.Color
    bulletHole.Dirt:Emit(15)
    bulletHole.Dust:Emit(15)

    local changedConn
    if ray.Instance ~= Workspace.Terrain then
        changedConn = ray.Instance.Changed:Connect(function()
            bulletHole:Destroy()
            changedConn:Disconnect()
        end)
    end

    Debris:AddItem(bulletHole, 10)
end

function EffectsSystem:EquipItem(itemData)
    local scaleFactor = 0.75

    local inventoryObj: Player = itemData.InventoryObj
    EffectsSystem:UnequipItem(inventoryObj)

    local toolObject = Assets.Tools:FindFirstChild(itemData.Name)
    if toolObject and inventoryObj:IsA("Player") and inventoryObj.Character then
        toolObject = toolObject:Clone()
        toolObject.Name = "Tool"
        toolObject:ScaleTo(scaleFactor)
        for _, part in toolObject:GetChildren() do
            if part:IsA("BasePart") then
                part.Anchored = false
                part.CanCollide = false
            end
        end
        toolObject.PrimaryPart.CFrame = inventoryObj.Character.RightHand.CFrame
        toolObject.Parent = inventoryObj.Character

        local weld = Instance.new("Weld")
        weld.Name = "ToolWeld"
        weld.Part0 = inventoryObj.Character.RightHand
        weld.Part1 = toolObject.PrimaryPart
        weld.C0 = CFrame.new(0, 0, 0) * CFrame.Angles(-0.5 * math.pi, 0, 0)
        weld.C1 = inventoryObj.Character.RightHand.CFrame:ToObjectSpace(toolObject.PrimaryPart.CFrame)
        weld.Parent = inventoryObj.Character.RightHand
    else
        warn("Could not find tool object for item", itemData.Name)
    end
end

function EffectsSystem:UnequipItem(player)
    local character = player.Character

    if character then
        for _, tool in ipairs(character:GetDescendants()) do
            if tool.Name == "Tool" or tool.Name == "ToolWeld" then
                tool:Destroy()
            end
        end
    end
end

function EffectsSystem:MakeDroppedItem(itemData)
    local inventoryObj = itemData.InventoryObj
    if inventoryObj:IsA("Player") then
        inventoryObj = inventoryObj.Character.Head
    end

    local ray = Ray.new(inventoryObj.Position, inventoryObj.CFrame.LookVector * 4)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { inventoryObj }
    raycastParams.IgnoreWater = true

    local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction, raycastParams)

    local droppedItemObj: Model = nil
    for _, holder in DroppedItemHolders do
        local foundItem = holder:FindFirstChild(itemData.Name)
        if foundItem then
            droppedItemObj = holder[itemData.Name]:Clone()
            break
        end
    end

    if not droppedItemObj then
        droppedItemObj = Assets.DropSack:Clone()
    end

    if not droppedItemObj:IsA("Model") then
        local model = Instance.new("Model")
        model.Name = droppedItemObj.Name
        droppedItemObj.Anchored = false
        droppedItemObj.CanCollide = true
        droppedItemObj.Parent = model
        model.PrimaryPart = droppedItemObj
        droppedItemObj = model
    else
        for _, part in droppedItemObj:GetChildren() do
            if part:IsA("BasePart") then
                part.Anchored = false
                part.CanCollide = true
            end
        end
    end

    -- Set item data
    droppedItemObj.Name = itemData.Data.ItemId
    droppedItemObj:SetAttribute("ItemData", HttpService:JSONEncode(itemData.Data))

    if raycastResult ~= nil and (raycastResult.Instance:IsA("BasePart") or raycastResult.Instance:IsA("Terrain")) then
        droppedItemObj:PivotTo(CFrame.new(inventoryObj.Position) + Vector3.new(0, 2, 0))
    else
        droppedItemObj:PivotTo(CFrame.new(inventoryObj.Position + (inventoryObj.CFrame.LookVector * 2) + Vector3.new(0, 2, 0)))
    end

    local primaryPart = droppedItemObj.PrimaryPart
    primaryPart.AssemblyLinearVelocity = inventoryObj.CFrame.LookVector * 10
    primaryPart.CustomPhysicalProperties = PhysicalProperties.new(0.7, 2, 0.5, 100, 0)
    droppedItemObj.Parent = Workspace.DroppedItems
    primaryPart:SetNetworkOwner(inventoryObj)

    StabilityAnchor(primaryPart)
    Debris:AddItem(droppedItemObj, 300)
end

return EffectsSystem