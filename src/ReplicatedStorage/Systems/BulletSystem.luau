-- This system can NOT have context to local data.
-- It is possible that this system is handling a replicated effect
-- from the server and thus, needs to handle incoming data instead of persistent data.

-- Services
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Assets
local Assets = ReplicatedStorage.Assets
local BulletTrail = Assets.Trails.BulletTrail

-- Systems
local CombatSystem = require(ReplicatedStorage.Systems.CombatSystem)
local EffectsSystem = require(ReplicatedStorage.Systems.EffectsSystem)

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
local BulletCache = PartCache.new(BulletTrail, 100, Workspace.Bullets)
local ClientCaster = FastCast.new()

-- cast, result, velocity, bullet
local function OnRayHit(cast, result: RaycastResult, _, _)
    local weaponData = GetStaticData(cast.UserData.Weapon.Name)

    local hit = result.Instance
    local humanoid = hit.Parent:FindFirstChild("Humanoid") or hit.Parent.Parent:FindFirstChildOfClass("Humanoid")
    local terrainHit: RaycastResult = cast.UserData.TerrainHit

    -- Handle water splashes
    if terrainHit and terrainHit.Instance == Workspace.Terrain and terrainHit.Material == Enum.Material.Water then
        EffectsSystem:MakeWaterSplash(terrainHit.Position)
    end

    -- Gun specific effects
    if weaponData.WeaponType == "Gun" then
        -- Handle bullet holes
        if hit and hit.CanCollide == true then
            if humanoid == nil then
                EffectsSystem:MakeBulletHole(result)
            end
        end
    end
end

ClientCaster.RayHit:Connect(OnRayHit)
ClientCaster.LengthChanged:Connect(CombatSystem.OnLengthChanged)
ClientCaster.CastTerminating:Connect(function(cast)
    local rayInfo = cast.RayInfo
    if rayInfo and rayInfo.CosmeticBulletObject then
        local bullet = rayInfo.CosmeticBulletObject

        if cast.UserData.UsingCache then
            BulletCache:ReturnPart(bullet)
        elseif cast.UserData.UsingCache == false then
            bullet:Destroy()
        end
    end
end)

-- Handle projectile shooting visuals
function BulletSystem:ProjectileShoot(player: Player, weapon: ItemData.ItemData, bulletOrigin: CFrame, bulletModel: Instance?)
    local weaponData = GetStaticData(weapon.Name)

    -- TODO: some day sync up the spread algo between client & server
    for _ = 1, weaponData.BulletSpreadCount or 1 do
        task.spawn(function()
            local rayStart, rayDirection = CombatSystem:CalculateRaycast(weapon, bulletOrigin)
            local hit = CombatSystem:FindHitLocation(player, { rayStart, rayDirection }, false)

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

            if not bulletModel then
                castBehavior.CosmeticBulletProvider = BulletCache
            else
                castBehavior.CosmeticBulletTemplate = bulletModel:Clone()
            end

            local clientCast = ClientCaster:Fire(rayStart, rayDirection, weaponData.BulletSpeed or 100, castBehavior)
            clientCast.UserData = { TerrainHit = hit, UsingCache = not bulletModel, Weapon = weapon }
            RunService.RenderStepped:Wait()
        end)
    end
    
    HandleHitRemote:SendToServer(bulletOrigin)
end

return BulletSystem