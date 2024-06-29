-- This system can NOT have context to local data.
-- It is possible that this system is handling a replicated effect
-- from the server and thus, needs to handle incoming data instead of persistent data.

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Assets
local Assets = ReplicatedStorage.Assets
local BulletTrail = Assets.Trails.BulletTrail

-- Systems
local CombatSystem = require(ReplicatedStorage.Systems.CombatSystem)

-- Packages
local FastCast = require(ReplicatedStorage.Packages.FastCast)
local PartCache = require(ReplicatedStorage.Packages.PartCache)

-- Modules
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)

-- Item Data
local ItemData = require(ReplicatedStorage.DataObjects.ItemData)

-- Game Data
local GameBulletData = require(ReplicatedStorage.GameBulletData)

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Client
local HandleHitRemote = Remotes:Get("HandleHit")

-- Bullet System
local BulletSystem = {}

-- Hit detection
-- TODO: other bullet trail types e.g. rockets
local BulletCache = PartCache.new(BulletTrail, 100, Workspace.Bullets)
local ClientCaster = FastCast.new()

-- cast, lastPoint, direction, length, velocity, bullet
local function OnLengthChanged(_, lastPoint, direction, length, _, bullet)
    if bullet then
        local bulletLength = bullet.Size.Z / 2
        local offset = CFrame.new(0, 0, -(length - bulletLength))
        bullet.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
    end
end

-- cast, result, velocity, bullet
local function OnRayHit(_, _, _, bullet)
    -- local hit = result.Instance
end

ClientCaster.LengthChanged:Connect(OnLengthChanged)
ClientCaster.RayHit:Connect(OnRayHit)
ClientCaster.CastTerminating:Connect(function(cast)
    local rayInfo = cast.RayInfo
    if rayInfo and rayInfo.CosmeticBulletObject then
        local bullet = rayInfo.CosmeticBulletObject
        BulletCache:ReturnPart(bullet)
    end
end)

-- Handle projectile shooting visuals
function BulletSystem:ProjectileShoot(player: Player, weapon: ItemData.ItemData, bulletOrigin: CFrame)
    local weaponData = GetStaticData(weapon.Name)

    for _ = 1, weaponData.BulletSpreadCount or 1 do
        task.spawn(function()
            local rayStart, rayDirection = CombatSystem:CalculateRaycast(weapon, bulletOrigin, 20)
            
            local raycastParams = RaycastParams.new()
            raycastParams.IgnoreWater = true
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = { workspace.CurrentCamera, player.Character, Workspace.Debris, Workspace.Bullets }
    
            local castBehavior = FastCast.newBehavior()
            castBehavior.MaxDistance = weaponData.BulletMaxDistance
            castBehavior.CanPierceFunction = CombatSystem.CanPierceObject
            castBehavior.RaycastParams = raycastParams
            castBehavior.Acceleration = GameBulletData.BulletAcceleration + (weaponData.BulletAcceleration or Vector3.new(0, 0, 0))
            castBehavior.AutoIgnoreContainer = true
            castBehavior.CosmeticBulletContainer = Workspace.Bullets
            castBehavior.CosmeticBulletProvider = BulletCache
    
            ClientCaster:Fire(rayStart, rayDirection, weaponData.BulletSpeed, castBehavior)
            RunService.RenderStepped:Wait()
        end)
    end
    
    HandleHitRemote:SendToServer(bulletOrigin)
end

return BulletSystem