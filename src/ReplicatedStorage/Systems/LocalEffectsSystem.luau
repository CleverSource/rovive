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

-- Modules
local VerticalPositionAtTime = require(ReplicatedStorage.Modules.VerticalPositionAtTime)
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)
local GetEndOfCFrameSegment = require(ReplicatedStorage.Modules.GetEndOfCFrameSegment)

-- Variables
local CurrentCamera = Workspace.CurrentCamera

-- Item Data
local ItemData = require(ReplicatedStorage.DataObjects.ItemData)

-- Local Effect Systems
local LocalEffectsSystem = {}

local function MetersToStuds(meters)
    return meters / 0.05
end

-- Handle projectile shooting visuals
function LocalEffectsSystem:ProjectileShoot(player: Player, weapon: ItemData.ItemData, shootingAngle: number, bulletOrigin: CFrame, spreadData: table?)
    local maxFlightTime = 5
    local staticData = GetStaticData(weapon.Name)
    local bulletSpeed = staticData.BulletSpeed or 7
    local currentPoint = bulletOrigin

    if spreadData == nil then
        spreadData = { Vector3.new() }
    end
    shootingAngle = shootingAngle < 0 and 0 or shootingAngle
    
    for i = 1, #spreadData do
        task.spawn(function()
            local bulletTrail = BulletTrail:Clone() -- TODO: other types of bullets
            bulletTrail.Parent = Workspace.Debris
    
            local firstTick = tick()
            local lastPoint = bulletOrigin

            while tick() - firstTick < maxFlightTime do
                RunService.RenderStepped:Wait()

                local elapse = tick() - firstTick

                local xChange = MetersToStuds(bulletSpeed * elapse)
                local yChange = MetersToStuds(VerticalPositionAtTime(bulletSpeed, shootingAngle, elapse))

                local raycastedPoint: CFrame = (currentPoint * CFrame.new(0, yChange, 0)) + ((currentPoint.LookVector + spreadData[i]) * xChange)
                local rayStart = lastPoint.Position
                local rayDistance = (lastPoint.Position - raycastedPoint.Position).Magnitude
                local rayDirection = (raycastedPoint.Position - lastPoint.Position).Unit * rayDistance

                local raycastParams = RaycastParams.new() -- TODO: move this up, get this working for now
                raycastParams.IgnoreWater = true
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.FilterDescendantsInstances = { CurrentCamera, player.Character, Workspace.Debris }

                local ray: RaycastResult = Workspace:Raycast(rayStart, rayDirection, raycastParams)
                if ray and ray.Instance then
                    print("Hit!", ray.Instance)
                end
                bulletTrail.CFrame = GetEndOfCFrameSegment(lastPoint, raycastedPoint)
                lastPoint = raycastedPoint

                -- break -- Instantly stop bullet hits for now! TODO: DONT DO THIS DEBUG DEBUG
                bulletTrail:Destroy()
            end
        end)
    end
end

return LocalEffectsSystem