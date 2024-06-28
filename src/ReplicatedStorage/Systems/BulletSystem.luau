-- This system can NOT have context to local data.
-- It is possible that this system is handling a replicated effect
-- from the server and thus, needs to handle incoming data instead of persistent data.

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Assets
local Assets = ReplicatedStorage.Assets
local BulletTrail = Assets.Trails.BulletTrail

-- Systems
local CombatSystem = require(ReplicatedStorage.Systems.CombatSystem)

-- Modules
local GetEndOfCFrameSegment = require(ReplicatedStorage.Modules.GetEndOfCFrameSegment)
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)

-- Item Data
local ItemData = require(ReplicatedStorage.DataObjects.ItemData)

-- Remotes
local Remotes = require(ReplicatedStorage.Remotes).Client
local HandleHitRemote = Remotes:Get("HandleHit")

-- Local Effect Systems
local BulletSystem = {}

-- Handle projectile shooting visuals
function BulletSystem:ProjectileShoot(player: Player, weapon: ItemData.ItemData, bulletOrigin: CFrame)
    local maxFlightTime = 5
    local currentPoint = bulletOrigin
    local staticData = GetStaticData(weapon.Name)
    
    for _ = 1, staticData.BulletSpreadCount or 1 do
        task.spawn(function()
            local bulletTrail = BulletTrail:Clone() -- TODO: other types of bullets
            bulletTrail.Parent = Workspace.Debris
    
            local firstTick = tick()
            local lastPoint = currentPoint

            -- lastPoint = workspace.Dummy.Dummy.Head.CFrame

            while tick() - firstTick < maxFlightTime do
                RunService.RenderStepped:Wait()

                local elapse = tick() - firstTick
                local hitDetect, raycastedPoint = CombatSystem:FindHitLocation(player, weapon, lastPoint, elapse)

                if hitDetect and hitDetect.Instance then
                    local hitPosition = hitDetect.Position
                    if player == Players.LocalPlayer then
                        HandleHitRemote:SendToServer(lastPoint, elapse, hitPosition)
                    end
                end

                bulletTrail.CFrame = GetEndOfCFrameSegment(lastPoint, raycastedPoint)
                lastPoint = raycastedPoint
            end

            bulletTrail:Destroy()
        end)
    end
end

return BulletSystem