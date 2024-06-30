-- Services
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local RandomNum = require(ReplicatedStorage.Modules.RandomNum)

-- Assets
local Assets = ReplicatedStorage.Assets
local WaterSplash = Assets.BulletEffects.WaterSplash
local BulletHole = Assets.BulletEffects.BulletHole

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
        end)
    end

    task.delay(10, function()
        if changedConn then
            changedConn:Disconnect()
        end
        bulletHole:Destroy()
    end)
end

return EffectsSystem