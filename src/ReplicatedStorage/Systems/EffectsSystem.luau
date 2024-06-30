-- Services
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Assets
local Assets = ReplicatedStorage.Assets
local WaterSplash = Assets.BulletEffects.WaterSplash

-- Effects System
local EffectsSystem = {}

function EffectsSystem:MakeWaterSplash(position)
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

function EffectsSystem:MakeBulletHole()
    print("Bullet hole")
end

return EffectsSystem