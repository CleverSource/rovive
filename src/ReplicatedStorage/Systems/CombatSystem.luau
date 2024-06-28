-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Modules
local GetStaticData = require(ReplicatedStorage.Modules.GetStaticData)
local VerticalPositionAtTime = require(ReplicatedStorage.Modules.VerticalPositionAtTime)
local RandomNum = require(ReplicatedStorage.Modules.RandomNum)

-- Variables
local CurrentCamera = Workspace.CurrentCamera

-- Functions
local function MetersToStuds(meters)
    return meters / 0.05
end

-- Combat System
local CombatSystem = {}

function CombatSystem:FindHitLocation(player, weapon, origin, elapse)
    local staticData = GetStaticData(weapon.Name)
    local bulletSpeed = staticData.BulletSpeed or 7

    local spread = Vector3.new()
    if staticData.BulletPattern == "Spread" then
        local spreadAmount = staticData.BulletSpread * 100
        spread = Vector3.new(RandomNum(-spreadAmount, spreadAmount) / 100, RandomNum(-spreadAmount, spreadAmount) / 100, RandomNum(-spreadAmount, spreadAmount) / 100)
    end

    local shootingAngle = math.rad(origin.LookVector.Y * 90)
    shootingAngle = shootingAngle < 0 and 0 or shootingAngle

    local xChange = MetersToStuds(bulletSpeed * elapse)
    local yChange = MetersToStuds(VerticalPositionAtTime(bulletSpeed, shootingAngle, elapse))

    local raycastedPoint: CFrame = (origin * CFrame.new(0, yChange, 0)) + ((origin.LookVector + spread) * xChange)
    local rayStart = origin.Position
    local rayDistance = (origin.Position - raycastedPoint.Position).Magnitude
    local rayDirection = (raycastedPoint.Position - origin.Position).Unit * rayDistance

    local raycastParams = RaycastParams.new()
    raycastParams.IgnoreWater = true
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { CurrentCamera, player.Character, Workspace.Debris }

    local ray: RaycastResult = Workspace:Raycast(rayStart, rayDirection, raycastParams)

    return ray, raycastedPoint
end

function CombatSystem:HandleHitOnPlayer()
    
end

return CombatSystem