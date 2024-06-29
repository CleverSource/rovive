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

-- Modules
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)

-- Item Data
local ItemData = require(ReplicatedStorage.DataObjects.ItemData)

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Client
local HandleHitRemote = Remotes:Get("HandleHit")

-- Local Effect Systems
local BulletSystem = {}

-- Hit detection
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
    print("Hit on client!")
    if bullet then
        bullet:Destroy()
    end
end

ClientCaster.LengthChanged:Connect(OnLengthChanged)
ClientCaster.RayHit:Connect(OnRayHit)

-- Handle projectile shooting visuals
-- TODO: part cache for bullets (see CosmeticBulletProvider on FastCast docs)
function BulletSystem:ProjectileShoot(player: Player, weapon: ItemData.ItemData, bulletOrigin: CFrame)
    local weaponData = GetStaticData(weapon.Name)
    
    for _ = 1, weaponData.BulletSpreadCount or 1 do
        task.spawn(function()
            local rayStart, rayDirection = CombatSystem:CalculateRaycast(weapon, bulletOrigin, 20)--elapse)
            
            local raycastParams = RaycastParams.new()
            raycastParams.IgnoreWater = true
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = { workspace.CurrentCamera, player.Character, Workspace.Debris }
    
            local castBehavior = FastCast.newBehavior()
            castBehavior.MaxDistance = 500 -- TODO
            castBehavior.CanPierceFunction = function() -- TODO
                return false
            end
            castBehavior.RaycastParams = raycastParams
            castBehavior.Acceleration = Vector3.new(0, -9.81, 0)
            castBehavior.AutoIgnoreContainer = true
            castBehavior.CosmeticBulletContainer = Workspace.Debris
            castBehavior.CosmeticBulletTemplate = BulletTrail
    
            ClientCaster:Fire(rayStart, rayDirection, weaponData.BulletSpeed, castBehavior)
            RunService.RenderStepped:Wait()

            -- local hitDetect, raycastedPoint = CombatSystem:FindHitLocation(player, weapon, lastPoint, elapse)
        end)
    end

    HandleHitRemote:SendToServer(bulletOrigin, Vector3.new(0, 0, 0)) -- TODO: maybe use expected pos
end

return BulletSystem